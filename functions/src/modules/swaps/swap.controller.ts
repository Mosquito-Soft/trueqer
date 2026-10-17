import { Response, NextFunction } from 'express';
import { z } from 'zod';
import { AuthenticatedRequest, AppError } from '../../types/index.js';
import { swapService } from './swap.service.js';

const CreateProposalSchema = z.object({
  target_user_id: z.string().uuid(),
  offered_skill_id: z.string().uuid(),
  requested_skill_id: z.string().uuid(),
  initial_message: z.string().min(1).max(300),
});

const UpdateStatusSchema = z.object({
  action: z.enum(['ACCEPT', 'REJECT', 'SCHEDULE', 'CANCEL']),
  scheduled_at: z.string().datetime().optional(),
  meeting_location: z.string().max(255).optional(),
  cancellation_reason: z.string().max(255).optional(),
});

const ValidateQrSchema = z.object({
  swap_id: z.string().uuid(),
  totp_token: z.string().min(6).max(8),
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
});

export class SwapController {
  public async createProposal(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user?.userId;
      if (!userId) {
        throw new AppError({ code: 'UNAUTHORIZED', message: 'User not authenticated.', statusCode: 401 });
      }

      const validated = CreateProposalSchema.parse(req.body);

      const swap = await swapService.createProposal({
        requesterId: userId,
        targetUserId: validated.target_user_id,
        offeredSkillId: validated.offered_skill_id,
        requestedSkillId: validated.requested_skill_id,
        initialMessage: validated.initial_message,
      });

      res.status(201).json(swap);
    } catch (error) {
      next(error);
    }
  }

  public async updateStatus(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user?.userId;
      if (!userId) {
        throw new AppError({ code: 'UNAUTHORIZED', message: 'User not authenticated.', statusCode: 401 });
      }

      const { swap_id } = req.params;
      const validated = UpdateStatusSchema.parse(req.body);

      const updated = await swapService.transitionStatus({
        swapId: swap_id,
        userId,
        action: validated.action,
        scheduledAt: validated.scheduled_at,
        meetingLocation: validated.meeting_location,
        cancellationReason: validated.cancellation_reason,
      });

      res.status(200).json(updated);
    } catch (error) {
      next(error);
    }
  }

  public async getQrToken(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user?.userId;
      if (!userId) {
        throw new AppError({ code: 'UNAUTHORIZED', message: 'User not authenticated.', statusCode: 401 });
      }

      const { swap_id } = req.params;
      const qrPayload = await swapService.getQrToken(swap_id, userId);

      res.status(200).json(qrPayload);
    } catch (error) {
      next(error);
    }
  }

  public async validateQr(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user?.userId;
      if (!userId) {
        throw new AppError({ code: 'UNAUTHORIZED', message: 'User not authenticated.', statusCode: 401 });
      }

      const validated = ValidateQrSchema.parse(req.body);

      const result = await swapService.validateMeetingQr({
        swapId: validated.swap_id,
        userId,
        totpToken: validated.totp_token,
        latitude: validated.latitude,
        longitude: validated.longitude,
      });

      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }
}

export const swapController = new SwapController();
