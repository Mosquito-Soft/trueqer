import express, { Express, Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import { authenticate } from './middleware/auth.js';
import { errorHandler } from './middleware/errorHandler.js';
import { authController } from './modules/auth/auth.controller.js';
import { userController } from './modules/users/user.controller.js';
import { swapController } from './modules/swaps/swap.controller.js';
import { messageController } from './modules/messages/message.controller.js';
import { reviewController } from './modules/reviews/review.controller.js';

dotenv.config();

export const app: Express = express();

// Security and body parsers
app.use(helmet());
app.use(cors({ origin: true, credentials: true }));
app.use(express.json({ limit: '1mb' }));

// Health Check
app.get('/health', (_req: Request, res: Response) => {
  res.status(200).json({ status: 'ok', service: 'trueqer-api-gateway', timestamp: new Date().toISOString() });
});

// ------------------------------------------------------------------------------
// Public Routes (No Bearer Token Required)
// ------------------------------------------------------------------------------
const publicRouter = express.Router();
publicRouter.post('/auth/google', (req, res, next) => authController.loginWithGoogle(req, res, next));
app.use('/api/v1', publicRouter);

// ------------------------------------------------------------------------------
// Protected API v1 Router (Requires Bearer Authentication)
// ------------------------------------------------------------------------------
const apiRouter = express.Router();
apiRouter.use(authenticate);

// Users & Search Routes
apiRouter.get('/users/:user_id/public-profile', (req, res, next) => userController.getPublicProfile(req, res, next));
apiRouter.get('/users/:user_id/reviews', (req, res, next) => userController.getRevealedReviews(req, res, next));
apiRouter.delete('/users/me', (req, res, next) => userController.deleteAccount(req, res, next));
apiRouter.get('/search', (req, res, next) => userController.search(req, res, next));

// Swaps (State Machine & Light Scheduling) Routes
apiRouter.post('/swaps/request', (req, res, next) => swapController.createProposal(req, res, next));
apiRouter.patch('/swaps/:swap_id/status', (req, res, next) => swapController.updateStatus(req, res, next));
apiRouter.get('/swaps/:swap_id/qr-token', (req, res, next) => swapController.getQrToken(req, res, next));

// Proof of Meeting Routes (Dynamic TOTP QR + Geofencing)
apiRouter.post('/meetings/validate-qr', (req, res, next) => swapController.validateQr(req, res, next));

// Guided Transactional Chat Routes (Locked until MATCHED)
apiRouter.get('/swaps/:swap_id/messages', (req, res, next) => messageController.getMessages(req, res, next));
apiRouter.post('/swaps/:swap_id/messages', (req, res, next) => messageController.sendMessage(req, res, next));

// Blind Reviews & Reputation Routes
apiRouter.post('/swaps/:swap_id/reviews', (req, res, next) => reviewController.submitReview(req, res, next));

// Mount Protected Router
app.use('/api/v1', apiRouter);

// Centralized Error Handling Middleware
app.use(errorHandler);

// Standalone server bootstrap
const PORT = process.env.PORT || 5001;
if (process.env.NODE_ENV !== 'test') {
  app.listen(PORT, () => {
    console.log(`[Trueqer API Gateway] Serverless Gateway running on port ${PORT}`);
  });
}
