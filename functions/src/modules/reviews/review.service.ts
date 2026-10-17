import crypto from 'crypto';
import { executeQuery, withTransaction } from '../../config/database.js';
import { AppError, PaginatedResponse, ReviewItem } from '../../types/index.js';

export class ReviewService {
  /**
   * Submits a blind review for a completed swap.
   * Review remains unrevealed until counterpart submits or 48 hours expire.
   */
  public async submitReview(params: {
    swapId: string;
    reviewerId: string;
    rating: number;
    comment: string;
    skillConfirmed: boolean;
  }): Promise<{ review_id: string; swap_id: string; status: string; is_revealed: boolean; created_at: string; message: string }> {
    const { swapId, reviewerId, rating, comment, skillConfirmed } = params;

    if (rating < 1 || rating > 5) {
      throw new AppError({ code: 'INVALID_RATING', message: 'Rating must be an integer between 1 and 5.', statusCode: 422 });
    }

    if (!comment || comment.trim().length < 10) {
      throw new AppError({ code: 'COMMENT_TOO_SHORT', message: 'Comment must contain at least 10 characters.', statusCode: 422 });
    }

    return await withTransaction(async (conn) => {
      // Fetch swap and lock row
      const [swaps]: any = await conn.execute(
        'SELECT * FROM swaps WHERE swap_id = ? FOR UPDATE',
        [swapId]
      );

      if (!swaps || swaps.length === 0) {
        throw new AppError({ code: 'SWAP_NOT_FOUND', message: 'Swap not found.', statusCode: 404 });
      }

      const swap = swaps[0];

      if (swap.status !== 'COMPLETED') {
        throw new AppError({
          code: 'SWAP_NOT_COMPLETED',
          message: 'Reviews can only be submitted for completed swaps.',
          statusCode: 409,
        });
      }

      if (swap.requester_id !== reviewerId && swap.receiver_id !== reviewerId) {
        throw new AppError({ code: 'FORBIDDEN', message: 'You are not a participant in this swap.', statusCode: 403 });
      }

      const revieweeId = swap.requester_id === reviewerId ? swap.receiver_id : swap.requester_id;

      // Check if reviewer has already submitted
      const [existing]: any = await conn.execute(
        'SELECT review_id FROM reviews WHERE swap_id = ? AND reviewer_id = ? LIMIT 1',
        [swapId, reviewerId]
      );

      if (existing && existing.length > 0) {
        throw new AppError({
          code: 'REVIEW_ALREADY_EXISTS',
          message: 'You have already submitted a review for this swap.',
          statusCode: 409,
        });
      }

      const reviewId = crypto.randomUUID();

      // Check if counterpart already submitted their review
      const [counterpartReview]: any = await conn.execute(
        'SELECT review_id FROM reviews WHERE swap_id = ? AND reviewer_id = ? LIMIT 1',
        [swapId, revieweeId]
      );

      const hasCounterpartSubmitted = counterpartReview && counterpartReview.length > 0;
      const isRevealed = hasCounterpartSubmitted; // Reveal immediately if both submitted!
      const revealedAt = isRevealed ? new Date() : null;

      await conn.execute(
        `INSERT INTO reviews 
         (review_id, swap_id, reviewer_id, reviewee_id, rating, comment, skill_confirmed, is_revealed, revealed_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [reviewId, swapId, reviewerId, revieweeId, rating, comment, skillConfirmed, isRevealed, revealedAt]
      );

      if (hasCounterpartSubmitted) {
        // Unhide counterpart review as well
        await conn.execute(
          'UPDATE reviews SET is_revealed = TRUE, revealed_at = ? WHERE swap_id = ?',
          [revealedAt, swapId]
        );

        // Asynchronously recalculate reputation scores for both participants
        setImmediate(async () => {
          try {
            await this.recalculateReputation(reviewerId);
            await this.recalculateReputation(revieweeId);
          } catch (err) {
            console.error('[Reputation Trigger Error]:', err);
          }
        });
      }

      return {
        review_id: reviewId,
        swap_id: swapId,
        status: 'SUBMITTED',
        is_revealed: isRevealed,
        created_at: new Date().toISOString(),
        message: isRevealed
          ? 'Mutual review completed! Both reviews are now revealed on your public profiles.'
          : 'Review saved in blind mode. It will be revealed when your partner submits theirs or in 48 hours.',
      };
    });
  }

  /**
   * Recalculates user reputation metrics in users table.
   * Triggered asynchronously when blind reviews are revealed.
   */
  public async recalculateReputation(userId: string): Promise<void> {
    const statsSql = `
      SELECT 
        COUNT(*) AS total_revs,
        COALESCE(AVG(rating), 0) AS avg_score
      FROM reviews
      WHERE reviewee_id = ? AND is_revealed = TRUE
    `;
    const rows: any[] = await executeQuery(statsSql, [userId]);
    const total = rows[0]?.total_revs || 0;
    const avgScore = Number(rows[0]?.avg_score || 0).toFixed(2);

    await executeQuery(
      `UPDATE users 
       SET average_rating = ?, total_reviews = ?
       WHERE user_id = ?`,
      [avgScore, total, userId]
    );
  }

  /**
   * Retrieves paginated revealed reviews for a user's public profile.
   */
  public async getUserRevealedReviews(
    userId: string,
    page: number = 1,
    limit: number = 10
  ): Promise<PaginatedResponse<ReviewItem>> {
    const offset = (page - 1) * limit;

    const countSql = `
      SELECT COUNT(*) AS total
      FROM reviews
      WHERE reviewee_id = ? AND is_revealed = TRUE
    `;
    const countRows: any[] = await executeQuery(countSql, [userId]);
    const total = countRows[0]?.total || 0;

    const dataSql = `
      SELECT 
        r.review_id, r.swap_id, r.rating, r.comment, r.skill_confirmed, r.created_at,
        u.user_id AS reviewer_id, u.display_name AS reviewer_name, u.avatar_url AS reviewer_avatar
      FROM reviews r
      JOIN users u ON r.reviewer_id = u.user_id
      WHERE r.reviewee_id = ? AND r.is_revealed = TRUE
      ORDER BY r.created_at DESC
      LIMIT ? OFFSET ?
    `;
    const rows: any[] = await executeQuery(dataSql, [userId, limit, offset]);

    const data: ReviewItem[] = rows.map((r) => ({
      review_id: r.review_id,
      swap_id: r.swap_id,
      reviewer: {
        user_id: r.reviewer_id,
        display_name: r.reviewer_name,
        avatar_url: r.reviewer_avatar,
      },
      rating: r.rating,
      comment: r.comment,
      skill_confirmed: Boolean(r.skill_confirmed),
      created_at: new Date(r.created_at).toISOString(),
    }));

    return {
      data,
      pagination: {
        page,
        limit,
        total,
        total_pages: Math.ceil(total / limit) || 1,
      },
    };
  }
}

export const reviewService = new ReviewService();
