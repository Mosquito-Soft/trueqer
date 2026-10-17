import { Response, NextFunction } from 'express';
import { z } from 'zod';
import { AuthenticatedRequest, AppError } from '../../types/index.js';
import { reviewService } from './review.service.js';

const SubmitReviewSchema = z.object({
  rating: z.number().int().min(1).max(5),
  comment: z.string().min(10).max(500),
  skill_confirmed: z.boolean(),
});

export class ReviewController {
  public async submitReview(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user?.userId;
      if (!userId) {
        throw new AppError({ code: 'UNAUTHORIZED', message: 'User not authenticated.', statusCode: 401 });
      }

      const { swap_id } = req.params;
      const validated = SubmitReviewSchema.parse(req.body);

      const result = await reviewService.submitReview({
        swapId: swap_id,
        reviewerId: userId,
        rating: validated.rating,
        comment: validated.comment,
        skillConfirmed: validated.skill_confirmed,
      });

      res.status(201).json(result);
    } catch (error) {
      next(error);
    }
  }
}

export const reviewController = new ReviewController();
