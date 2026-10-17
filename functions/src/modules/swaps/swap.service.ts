import crypto from 'crypto';
import { executeQuery, withTransaction } from '../../config/database.js';
import { AppError, SwapDetail, SwapStatus } from '../../types/index.js';
import { TotpService } from '../../utils/totp.js';
import { calculateHaversineDistanceMeters } from '../../utils/geo.js';

export class SwapService {
  /**
   * Initiates a new bilateral swap proposal with PENDING status [REQ-07].
   * Also inserts initial guided message (max 300 chars) within the same transaction.
   */
  public async createProposal(params: {
    requesterId: string;
    targetUserId: string;
    offeredSkillId: string;
    requestedSkillId: string;
    initialMessage: string;
  }): Promise<SwapDetail> {
    const { requesterId, targetUserId, offeredSkillId, requestedSkillId, initialMessage } = params;

    if (requesterId === targetUserId) {
      throw new AppError({
        code: 'INVALID_SWAP_PARTIES',
        message: 'A user cannot propose a skill swap with themselves.',
        statusCode: 422,
      });
    }

    if (initialMessage.length > 300) {
      throw new AppError({
        code: 'MESSAGE_TOO_LONG',
        message: 'Initial message exceeds maximum allowed limit of 300 characters.',
        statusCode: 422,
      });
    }

    return await withTransaction(async (conn) => {
      // Check target user existence and availability
      const [targetUsers]: any = await conn.execute(
        'SELECT user_id, is_available FROM users WHERE user_id = ? LIMIT 1',
        [targetUserId]
      );
      if (!targetUsers || targetUsers.length === 0) {
        throw new AppError({
          code: 'USER_NOT_FOUND',
          message: 'Target recipient user does not exist.',
          statusCode: 404,
        });
      }

      // Check for an ongoing active swap between these two users
      const [existingActive]: any = await conn.execute(
        `SELECT swap_id FROM swaps 
         WHERE ((requester_id = ? AND receiver_id = ?) OR (requester_id = ? AND receiver_id = ?))
           AND status IN ('PENDING', 'MATCHED', 'SCHEDULED')
         LIMIT 1`,
        [requesterId, targetUserId, targetUserId, requesterId]
      );

      if (existingActive && existingActive.length > 0) {
        throw new AppError({
          code: 'SWAP_ALREADY_EXISTS',
          message: 'An active swap agreement or proposal is already in progress between these users.',
          statusCode: 409,
        });
      }

      const swapId = crypto.randomUUID();
      const messageId = crypto.randomUUID();

      // Insert swap record
      await conn.execute(
        `INSERT INTO swaps 
         (swap_id, requester_id, receiver_id, offered_skill_id, requested_skill_id, status)
         VALUES (?, ?, ?, ?, ?, 'PENDING')`,
        [swapId, requesterId, targetUserId, offeredSkillId, requestedSkillId]
      );

      // Insert initial context message
      await conn.execute(
        `INSERT INTO messages 
         (message_id, swap_id, sender_id, message_type, content, is_system)
         VALUES (?, ?, ?, 'TEXT', ?, FALSE)`,
        [messageId, swapId, requesterId, initialMessage]
      );

      const [rows]: any = await conn.execute(
        'SELECT * FROM swaps WHERE swap_id = ? LIMIT 1',
        [swapId]
      );
      return rows[0] as SwapDetail;
    });
  }

  /**
   * Atomic state machine transition handler ([REQ-08] - [REQ-12]).
   */
  public async transitionStatus(params: {
    swapId: string;
    userId: string;
    action: 'ACCEPT' | 'REJECT' | 'SCHEDULE' | 'CANCEL';
    scheduledAt?: string;
    meetingLocation?: string;
    cancellationReason?: string;
  }): Promise<SwapDetail> {
    const { swapId, userId, action, scheduledAt, meetingLocation, cancellationReason } = params;

    return await withTransaction(async (conn) => {
      // Lock swap row for update
      const [swaps]: any = await conn.execute(
        'SELECT * FROM swaps WHERE swap_id = ? FOR UPDATE',
        [swapId]
      );

      if (!swaps || swaps.length === 0) {
        throw new AppError({
          code: 'SWAP_NOT_FOUND',
          message: `Swap with ID '${swapId}' does not exist.`,
          statusCode: 404,
        });
      }

      const swap: SwapDetail = swaps[0];
      const isRequester = swap.requester_id === userId;
      const isReceiver = swap.receiver_id === userId;

      if (!isRequester && !isReceiver) {
        throw new AppError({
          code: 'FORBIDDEN',
          message: 'You are not a participant in this swap.',
          statusCode: 403,
        });
      }

      let newStatus: SwapStatus = swap.status;
      let qrSecret: string | null = swap.qr_secret || null;

      switch (action) {
        case 'ACCEPT': {
          // Double opt-in: Only the receiver can accept a PENDING proposal [REQ-08, REQ-09]
          if (swap.status !== 'PENDING') {
            throw new AppError({
              code: 'INVALID_STATE_TRANSITION',
              message: `Cannot accept swap with status '${swap.status}'. Only PENDING swaps can be accepted.`,
              statusCode: 409,
            });
          }
          if (!isReceiver) {
            throw new AppError({
              code: 'FORBIDDEN',
              message: 'Only the proposal recipient can accept the swap.',
              statusCode: 403,
            });
          }
          newStatus = 'MATCHED';
          break;
        }

        case 'REJECT': {
          if (swap.status !== 'PENDING') {
            throw new AppError({
              code: 'INVALID_STATE_TRANSITION',
              message: `Cannot reject swap with status '${swap.status}'.`,
              statusCode: 409,
            });
          }
          if (!isReceiver) {
            throw new AppError({
              code: 'FORBIDDEN',
              message: 'Only the proposal recipient can reject the swap.',
              statusCode: 403,
            });
          }
          newStatus = 'REJECTED';
          break;
        }

        case 'SCHEDULE': {
          // Light Scheduling agreement: Requires MATCHED status [REQ-11, REQ-12]
          if (swap.status !== 'MATCHED') {
            throw new AppError({
              code: 'INVALID_STATE_TRANSITION',
              message: `Cannot schedule swap with status '${swap.status}'. Must be MATCHED first.`,
              statusCode: 409,
            });
          }
          if (!scheduledAt || !meetingLocation) {
            throw new AppError({
              code: 'MISSING_SCHEDULE_DATA',
              message: 'scheduled_at and meeting_location are required to schedule a meeting.',
              statusCode: 422,
            });
          }
          newStatus = 'SCHEDULED';
          qrSecret = TotpService.generateSecret();
          break;
        }

        case 'CANCEL': {
          if (['COMPLETED', 'CANCELLED', 'REJECTED'].includes(swap.status)) {
            throw new AppError({
              code: 'INVALID_STATE_TRANSITION',
              message: `Cannot cancel swap that is already '${swap.status}'.`,
              statusCode: 409,
            });
          }
          newStatus = 'CANCELLED';
          break;
        }

        default:
          throw new AppError({
            code: 'BAD_REQUEST',
            message: `Unsupported action '${action}'.`,
            statusCode: 400,
          });
      }

      // Execute update
      await conn.execute(
        `UPDATE swaps 
         SET status = ?, 
             scheduled_at = COALESCE(?, scheduled_at),
             meeting_location = COALESCE(?, meeting_location),
             cancellation_reason = COALESCE(?, cancellation_reason),
             qr_secret = COALESCE(?, qr_secret)
         WHERE swap_id = ?`,
        [
          newStatus,
          scheduledAt ? new Date(scheduledAt) : null,
          meetingLocation || null,
          cancellationReason || null,
          qrSecret,
          swapId,
        ]
      );

      // Insert system audit message for transparency
      const auditMsgId = crypto.randomUUID();
      await conn.execute(
        `INSERT INTO messages (message_id, swap_id, sender_id, message_type, content, is_system)
         VALUES (?, ?, ?, 'TEXT', ?, TRUE)`,
        [auditMsgId, swapId, userId, `Swap status updated to ${newStatus}.`]
      );

      const [updatedRows]: any = await conn.execute(
        'SELECT * FROM swaps WHERE swap_id = ? LIMIT 1',
        [swapId]
      );
      return updatedRows[0] as SwapDetail;
    });
  }

  /**
   * Generates dynamic TOTP payload for display as QR code by meeting host.
   */
  public async getQrToken(swapId: string, userId: string): Promise<{
    swap_id: string;
    totp_token: string;
    expires_in_seconds: number;
    refresh_interval_seconds: number;
    server_timestamp: string;
  }> {
    const [swaps]: any = await executeQuery('SELECT * FROM swaps WHERE swap_id = ? LIMIT 1', [swapId]);

    if (!swaps || swaps.length === 0) {
      throw new AppError({ code: 'SWAP_NOT_FOUND', message: 'Swap not found.', statusCode: 404 });
    }

    const swap: SwapDetail = swaps[0];

    if (swap.status !== 'SCHEDULED') {
      throw new AppError({
        code: 'SWAP_NOT_SCHEDULED',
        message: 'Proof-of-Meeting QR code can only be generated for SCHEDULED swaps.',
        statusCode: 409,
      });
    }

    if (swap.requester_id !== userId && swap.receiver_id !== userId) {
      throw new AppError({ code: 'FORBIDDEN', message: 'Unauthorized.', statusCode: 403 });
    }

    const secret = swap.qr_secret || TotpService.generateSecret();
    const token = TotpService.generateToken(secret);

    return {
      swap_id: swapId,
      totp_token: token,
      expires_in_seconds: 30,
      refresh_interval_seconds: 30,
      server_timestamp: new Date().toISOString(),
    };
  }

  /**
   * Validates scanned dynamic QR token and GPS coordinates to transition swap to COMPLETED.
   */
  public async validateMeetingQr(params: {
    swapId: string;
    userId: string;
    totpToken: string;
    latitude: number;
    longitude: number;
  }): Promise<{ success: boolean; swap_id: string; status: SwapStatus; completed_at: string; message: string }> {
    const { swapId, userId, totpToken, latitude, longitude } = params;

    return await withTransaction(async (conn) => {
      const [swaps]: any = await conn.execute(
        'SELECT * FROM swaps WHERE swap_id = ? FOR UPDATE',
        [swapId]
      );

      if (!swaps || swaps.length === 0) {
        throw new AppError({ code: 'SWAP_NOT_FOUND', message: 'Swap not found.', statusCode: 404 });
      }

      const swap: SwapDetail = swaps[0];

      if (swap.status !== 'SCHEDULED') {
        throw new AppError({
          code: 'SWAP_NOT_SCHEDULED',
          message: `Swap cannot be completed because current status is '${swap.status}'.`,
          statusCode: 409,
        });
      }

      if (swap.requester_id !== userId && swap.receiver_id !== userId) {
        throw new AppError({ code: 'FORBIDDEN', message: 'Caller is not a swap participant.', statusCode: 403 });
      }

      if (!swap.qr_secret) {
        throw new AppError({
          code: 'QR_NOT_INITIALIZED',
          message: 'Swap has not generated a valid Proof-of-Meeting secret.',
          statusCode: 400,
        });
      }

      // Verify dynamic TOTP RFC 6238 token
      const isTokenValid = TotpService.verifyToken(swap.qr_secret, totpToken);
      if (!isTokenValid) {
        throw new AppError({
          code: 'INVALID_TOTP_TOKEN',
          message: 'The scanned QR code has expired or is invalid. Please scan the refreshed QR code.',
          statusCode: 400,
        });
      }

      // Check partner's approximate location if available
      const counterpartId = swap.requester_id === userId ? swap.receiver_id : swap.requester_id;
      const [partners]: any = await conn.execute(
        'SELECT fuzzy_lat, fuzzy_lng FROM users WHERE user_id = ? LIMIT 1',
        [counterpartId]
      );

      if (partners && partners.length > 0 && partners[0].fuzzy_lat && partners[0].fuzzy_lng) {
        const partnerLat = Number(partners[0].fuzzy_lat);
        const partnerLng = Number(partners[0].fuzzy_lng);
        const distanceMeters = calculateHaversineDistanceMeters(latitude, longitude, partnerLat, partnerLng);
        
        // Allowed threshold: within 10 km of counterpart's approximate zone (prevents cross-country spoofing)
        if (distanceMeters > 10000) {
          throw new AppError({
            code: 'PROXIMITY_CHECK_FAILED',
            message: 'Geographic distance between participants exceeds allowed in-person threshold.',
            statusCode: 403,
          });
        }
      }

      const completedAt = new Date();

      // Transition to COMPLETED
      await conn.execute(
        'UPDATE swaps SET status = "COMPLETED", completed_at = ? WHERE swap_id = ?',
        [completedAt, swapId]
      );

      // Increment total_swaps counter for both users
      await conn.execute(
        'UPDATE users SET total_swaps = total_swaps + 1 WHERE user_id IN (?, ?)',
        [swap.requester_id, swap.receiver_id]
      );

      return {
        success: true,
        swap_id: swapId,
        status: 'COMPLETED',
        completed_at: completedAt.toISOString(),
        message: 'Proof-of-meeting verified. Swap completed successfully. Reviews are now unlocked.',
      };
    });
  }
}

export const swapService = new SwapService();
