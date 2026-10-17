import { Response, NextFunction } from 'express';
import { AuthenticatedRequest, AppError } from '../../types/index.js';
import { userService } from './user.service.js';
import { reviewService } from '../reviews/review.service.js';

export class UserController {
  public async getPublicProfile(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { user_id } = req.params;
      const requesterLat = req.query.requester_lat ? Number(req.query.requester_lat) : undefined;
      const requesterLng = req.query.requester_lng ? Number(req.query.requester_lng) : undefined;

      if (!user_id) {
        throw new AppError({
          code: 'BAD_REQUEST',
          message: 'user_id route parameter is required.',
          statusCode: 400,
        });
      }

      const profile = await userService.getPublicProfile(user_id, requesterLat, requesterLng);
      res.status(200).json(profile);
    } catch (error) {
      next(error);
    }
  }

  public async getRevealedReviews(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { user_id } = req.params;
      const page = req.query.page ? parseInt(String(req.query.page), 10) : 1;
      const limit = req.query.limit ? parseInt(String(req.query.limit), 10) : 10;

      const reviews = await reviewService.getUserRevealedReviews(user_id, page, limit);
      res.status(200).json(reviews);
    } catch (error) {
      next(error);
    }
  }

  public async search(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const query = req.query.query ? String(req.query.query) : undefined;
      const category = req.query.category ? String(req.query.category) : undefined;
      const skillId = req.query.skill_id ? String(req.query.skill_id) : undefined;
      const h3Index = req.query.h3_index ? String(req.query.h3_index) : undefined;
      const page = req.query.page ? parseInt(String(req.query.page), 10) : 1;
      const limit = req.query.limit ? parseInt(String(req.query.limit), 10) : 20;

      const results = await userService.searchProfiles({
        query,
        category,
        skillId,
        h3Index,
        page,
        limit,
      });

      res.status(200).json(results);
    } catch (error) {
      next(error);
    }
  }

  public async deleteAccount(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user?.userId;
      if (!userId) {
        throw new AppError({
          code: 'UNAUTHORIZED',
          message: 'Authenticated user ID is missing.',
          statusCode: 401,
        });
      }

      await userService.deleteUser(userId);
      res.status(200).json({
        success: true,
        message: 'User account and all personal records have been permanently purged (GDPR).',
      });
    } catch (error) {
      next(error);
    }
  }
}

export const userController = new UserController();
