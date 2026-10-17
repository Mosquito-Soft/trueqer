import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { AppError } from '../types/index.js';

/**
 * Central Error Handler conforming to Trueqer OpenAPI 3.0.3 error schemas:
 * - 400 Bad Request
 * - 401 Unauthorized
 * - 403 Forbidden
 * - 404 Not Found
 * - 409 Conflict
 * - 422 Unprocessable Entity
 * - 500 Internal Server Error
 */
export function errorHandler(
  err: any,
  _req: Request,
  res: Response,
  _next: NextFunction
): void {
  // Handle Zod validation errors (HTTP 422)
  if (err instanceof ZodError) {
    res.status(422).json({
      code: 'VALIDATION_FAILED',
      message: 'Request payload failed schema validation.',
      status: 422,
      errors: err.errors.map((e) => ({
        field: e.path.join('.'),
        message: e.message,
      })),
    });
    return;
  }

  // Handle Domain AppError
  if (err instanceof AppError) {
    res.status(err.statusCode).json({
      code: err.code,
      message: err.message,
      status: err.statusCode,
      details: err.details || null,
    });
    return;
  }

  // Handle MySQL Duplicate Entry (HTTP 409)
  if (err.code === 'ER_DUP_ENTRY') {
    res.status(409).json({
      code: 'DUPLICATE_RESOURCE',
      message: 'A resource with these unique attributes already exists.',
      status: 409,
    });
    return;
  }

  // Handle unexpected internal server error
  console.error('[Unhandled Server Error]:', err);
  res.status(500).json({
    code: 'INTERNAL_SERVER_ERROR',
    message: 'An unexpected internal error occurred on the API Gateway.',
    status: 500,
  });
}
