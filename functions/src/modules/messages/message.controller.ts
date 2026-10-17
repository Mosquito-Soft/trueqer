import { Response, NextFunction } from 'express';
import { z } from 'zod';
import { AuthenticatedRequest, AppError } from '../../types/index.js';
import { messageService } from './message.service.js';

const SendMessageSchema = z.object({
  message_type: z.enum(['TEXT', 'QUICK_REPLY', 'ACTION_WIDGET']),
  content: z.string().min(1).max(300),
  widget_payload: z.record(z.any()).optional().nullable(),
});

export class MessageController {
  public async getMessages(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user?.userId;
      if (!userId) {
        throw new AppError({ code: 'UNAUTHORIZED', message: 'User not authenticated.', statusCode: 401 });
      }

      const { swap_id } = req.params;
      const limit = req.query.limit ? parseInt(String(req.query.limit), 10) : 50;

      const messages = await messageService.getMessages(swap_id, userId, limit);
      res.status(200).json({ swap_id, messages });
    } catch (error) {
      next(error);
    }
  }

  public async sendMessage(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user?.userId;
      if (!userId) {
        throw new AppError({ code: 'UNAUTHORIZED', message: 'User not authenticated.', statusCode: 401 });
      }

      const { swap_id } = req.params;
      const validated = SendMessageSchema.parse(req.body);

      const message = await messageService.sendMessage({
        swapId: swap_id,
        senderId: userId,
        messageType: validated.message_type,
        content: validated.content,
        widgetPayload: validated.widget_payload,
      });

      res.status(201).json(message);
    } catch (error) {
      next(error);
    }
  }
}

export const messageController = new MessageController();
