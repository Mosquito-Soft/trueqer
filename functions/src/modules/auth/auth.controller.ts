import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { authService } from './auth.service.js';

const GoogleAuthSchema = z.object({
  id_token: z.string().min(1, 'Google ID token is required'),
  display_name: z.string().optional(),
  email: z.string().email().optional(),
  avatar_url: z.string().url().optional(),
});

export class AuthController {
  public async loginWithGoogle(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const validated = GoogleAuthSchema.parse(req.body);

      const result = await authService.authenticateGoogle({
        idToken: validated.id_token,
        displayNameOverride: validated.display_name,
        emailOverride: validated.email,
        avatarUrlOverride: validated.avatar_url,
      });

      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }
}

export const authController = new AuthController();
