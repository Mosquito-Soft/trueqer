import crypto from 'crypto';
import { executeQuery, withTransaction } from '../../config/database.js';
import { AppError, ChatMessage, MessageType } from '../../types/index.js';

export class MessageService {
  /**
   * Retrieves messages for a swap.
   * Communication channel is strictly locked until swap reaches MATCHED or subsequent states.
   */
  public async getMessages(swapId: string, userId: string, limit: number = 50): Promise<ChatMessage[]> {
    // Check swap access and status
    const [swaps]: any = await executeQuery('SELECT * FROM swaps WHERE swap_id = ? LIMIT 1', [swapId]);

    if (!swaps || swaps.length === 0) {
      throw new AppError({ code: 'SWAP_NOT_FOUND', message: 'Swap not found.', statusCode: 404 });
    }

    const swap = swaps[0];

    if (swap.requester_id !== userId && swap.receiver_id !== userId) {
      throw new AppError({ code: 'FORBIDDEN', message: 'You are not a participant in this swap.', statusCode: 403 });
    }

    // Guardrail: Chat is locked if swap is still PENDING or has been REJECTED
    if (['PENDING', 'REJECTED'].includes(swap.status)) {
      throw new AppError({
        code: 'CHAT_LOCKED',
        message: 'Communication channel remains locked until proposal is accepted (MATCHED).',
        statusCode: 403,
      });
    }

    const sql = `
      SELECT message_id, swap_id, sender_id, message_type, content, widget_payload, is_system, created_at
      FROM messages
      WHERE swap_id = ?
      ORDER BY created_at ASC
      LIMIT ?
    `;
    const rows: any[] = await executeQuery(sql, [swapId, limit]);

    return rows.map((r) => ({
      message_id: r.message_id,
      swap_id: r.swap_id,
      sender_id: r.sender_id,
      message_type: r.message_type as MessageType,
      content: r.content,
      widget_payload: r.widget_payload ? (typeof r.widget_payload === 'string' ? JSON.parse(r.widget_payload) : r.widget_payload) : null,
      is_system: Boolean(r.is_system),
      created_at: new Date(r.created_at).toISOString(),
    }));
  }

  /**
   * Sends a message enforcing guardrails (max 300 chars, no media, Action Widgets).
   */
  public async sendMessage(params: {
    swapId: string;
    senderId: string;
    messageType: MessageType;
    content: string;
    widgetPayload?: Record<string, any> | null;
  }): Promise<ChatMessage> {
    const { swapId, senderId, messageType, content, widgetPayload } = params;

    // Guardrail: 300 chars limit
    if (!content || content.trim().length === 0) {
      throw new AppError({ code: 'EMPTY_CONTENT', message: 'Message content cannot be empty.', statusCode: 422 });
    }

    if (content.length > 300) {
      throw new AppError({
        code: 'CONTENT_TOO_LONG',
        message: 'Message exceeds maximum allowable length of 300 characters.',
        statusCode: 422,
      });
    }

    return await withTransaction(async (conn) => {
      const [swaps]: any = await conn.execute(
        'SELECT status, requester_id, receiver_id FROM swaps WHERE swap_id = ? LIMIT 1',
        [swapId]
      );

      if (!swaps || swaps.length === 0) {
        throw new AppError({ code: 'SWAP_NOT_FOUND', message: 'Swap not found.', statusCode: 404 });
      }

      const swap = swaps[0];

      if (swap.requester_id !== senderId && swap.receiver_id !== senderId) {
        throw new AppError({ code: 'FORBIDDEN', message: 'You are not a participant in this swap.', statusCode: 403 });
      }

      // Guardrail: Double opt-in lock
      if (['PENDING', 'REJECTED'].includes(swap.status)) {
        throw new AppError({
          code: 'CHAT_LOCKED',
          message: 'Messaging is locked until the swap reaches MATCHED status.',
          statusCode: 403,
        });
      }

      const messageId = crypto.randomUUID();
      const payloadJson = widgetPayload ? JSON.stringify(widgetPayload) : null;

      await conn.execute(
        `INSERT INTO messages 
         (message_id, swap_id, sender_id, message_type, content, widget_payload, is_system)
         VALUES (?, ?, ?, ?, ?, ?, FALSE)`,
        [messageId, swapId, senderId, messageType, content, payloadJson]
      );

      return {
        message_id: messageId,
        swap_id: swapId,
        sender_id: senderId,
        message_type: messageType,
        content,
        widget_payload: widgetPayload || null,
        is_system: false,
        created_at: new Date().toISOString(),
      };
    });
  }
}

export const messageService = new MessageService();
