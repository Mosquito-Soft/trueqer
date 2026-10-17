import { executeQuery, withTransaction } from '../../config/database.js';
import { AppError, PublicProfileResponse, PaginatedResponse, SkillItem } from '../../types/index.js';
import { calculateDistanceKm } from '../../utils/geo.js';

export class UserService {
  /**
   * Retrieves public profile strictly filtering out sensitive PII (emails, exact coordinates).
   */
  public async getPublicProfile(
    userId: string,
    requesterLat?: number,
    requesterLng?: number
  ): Promise<PublicProfileResponse> {
    const userSql = `
      SELECT 
        user_id, display_name, avatar_url, bio, is_available,
        average_rating, total_swaps, total_reviews, punctuality_score,
        fuzzy_lat, fuzzy_lng, zone_name, created_at
      FROM users
      WHERE user_id = ?
      LIMIT 1
    `;
    const users: any[] = await executeQuery(userSql, [userId]);

    if (!users || users.length === 0) {
      throw new AppError({
        code: 'USER_NOT_FOUND',
        message: `User with identifier '${userId}' does not exist.`,
        statusCode: 404,
      });
    }

    const user = users[0];

    // Compute approximate distance if requester provided coordinates
    let distanceKm: number | null = null;
    if (requesterLat !== undefined && requesterLng !== undefined && user.fuzzy_lat && user.fuzzy_lng) {
      distanceKm = calculateDistanceKm(
        requesterLat,
        requesterLng,
        Number(user.fuzzy_lat),
        Number(user.fuzzy_lng)
      );
    }

    // Fetch hybrid skills (offered and desired)
    const skillsSql = `
      SELECT 
        s.skill_id, s.name, s.category, us.skill_type, us.proficiency_level
      FROM user_skills us
      INNER JOIN skills s ON us.skill_id = s.skill_id
      WHERE us.user_id = ?
      ORDER BY s.name ASC
    `;
    const skillsRows: any[] = await executeQuery(skillsSql, [userId]);

    const offered: SkillItem[] = [];
    const desired: SkillItem[] = [];

    for (const row of skillsRows) {
      const item: SkillItem = {
        skill_id: row.skill_id,
        name: row.name,
        category: row.category,
        proficiency_level: row.proficiency_level,
      };
      if (row.skill_type === 'OFFERED') {
        offered.push(item);
      } else {
        desired.push(item);
      }
    }

    return {
      user_id: user.user_id,
      basic_info: {
        display_name: user.display_name,
        avatar_url: user.avatar_url,
        bio: user.bio,
      },
      location: {
        zone_name: user.zone_name || 'Neighborhood area',
        distance_km: distanceKm,
      },
      reputation: {
        average_score: Number(user.average_rating) || 0,
        total_reviews: Number(user.total_reviews) || 0,
        punctuality_score: Number(user.punctuality_score) || 0,
      },
      skills: {
        offered,
        desired,
      },
      availability_status: user.is_available ? 'AVAILABLE' : 'UNAVAILABLE',
      metadata: {
        joined_at: new Date(user.created_at).toISOString(),
      },
    };
  }

  /**
   * Search profiles matching filters, ordering available users first [REQ-05].
   */
  public async searchProfiles(params: {
    query?: string;
    category?: string;
    skillId?: string;
    h3Index?: string;
    page: number;
    limit: number;
  }): Promise<PaginatedResponse<any>> {
    const { query, category, skillId, h3Index, page, limit } = params;
    const offset = (page - 1) * limit;

    const conditions: string[] = ['1=1'];
    const sqlParams: any[] = [];

    if (query) {
      conditions.push('(u.display_name LIKE ? OR u.bio LIKE ?)');
      sqlParams.push(`%${query}%`, `%${query}%`);
    }

    if (h3Index) {
      conditions.push('u.h3_index = ?');
      sqlParams.push(h3Index);
    }

    if (skillId) {
      conditions.push(`
        EXISTS (
          SELECT 1 FROM user_skills us 
          WHERE us.user_id = u.user_id 
            AND us.skill_id = ? 
            AND us.skill_type = 'OFFERED'
        )
      `);
      sqlParams.push(skillId);
    } else if (category) {
      conditions.push(`
        EXISTS (
          SELECT 1 FROM user_skills us 
          JOIN skills s ON us.skill_id = s.skill_id
          WHERE us.user_id = u.user_id 
            AND s.category = ? 
            AND us.skill_type = 'OFFERED'
        )
      `);
      sqlParams.push(category);
    }

    const whereClause = conditions.join(' AND ');

    // Count total matches
    const countSql = `SELECT COUNT(*) AS total FROM users u WHERE ${whereClause}`;
    const countRows: any[] = await executeQuery(countSql, sqlParams);
    const total = countRows[0]?.total || 0;

    // Fetch page ordered by availability status first, then reputation
    const dataSql = `
      SELECT 
        u.user_id, u.display_name, u.avatar_url, u.bio, u.zone_name,
        u.is_available, u.average_rating, u.total_reviews
      FROM users u
      WHERE ${whereClause}
      ORDER BY u.is_available DESC, u.average_rating DESC, u.created_at DESC
      LIMIT ? OFFSET ?
    `;
    const rows: any[] = await executeQuery(dataSql, [...sqlParams, limit, offset]);

    const results = rows.map((u) => ({
      user_id: u.user_id,
      display_name: u.display_name,
      avatar_url: u.avatar_url,
      bio: u.bio,
      zone_name: u.zone_name,
      distance_km: null,
      availability_status: u.is_available ? 'AVAILABLE' : 'UNAVAILABLE',
      reputation: {
        average_score: Number(u.average_rating) || 0,
        total_reviews: Number(u.total_reviews) || 0,
      },
      offered_skills: [],
      desired_skills: [],
    }));

    return {
      data: results,
      pagination: {
        page,
        limit,
        total,
        total_pages: Math.ceil(total / limit) || 1,
      },
    };
  }

  /**
   * GDPR Right to Erasure [REQ-03]: Executes immediate physical cascade purge in ACID transaction.
   */
  public async deleteUser(userId: string): Promise<void> {
    await withTransaction(async (conn) => {
      // Deleting user cascades to user_skills, swaps, messages, and reviews via FK ON DELETE CASCADE
      const [res]: any = await conn.execute('DELETE FROM users WHERE user_id = ?', [userId]);
      if (res.affectedRows === 0) {
        throw new AppError({
          code: 'USER_NOT_FOUND',
          message: 'User account not found for deletion.',
          statusCode: 404,
        });
      }
    });
  }
}

export const userService = new UserService();
