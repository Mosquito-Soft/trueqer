import crypto from 'crypto';

/**
 * RFC 6238 TOTP (Time-Based One-Time Password) implementation for Proof-of-Meeting QR code.
 * Provides ephemeral 6-digit tokens rotating every 30 seconds.
 */
export class TotpService {
  private static readonly STEP_SECONDS = 30;
  private static readonly DIGITS = 6;

  /**
   * Generates a random Base32 secret for a scheduled swap.
   */
  public static generateSecret(): string {
    return crypto.randomBytes(20).toString('hex');
  }

  /**
   * Generates a 6-digit TOTP token for a given secret at the current time (or specified timestamp).
   */
  public static generateToken(secret: string, timestampMs: number = Date.now()): string {
    const timeStep = Math.floor(timestampMs / 1000 / this.STEP_SECONDS);
    const timeBuffer = Buffer.alloc(8);
    timeBuffer.writeBigInt64BE(BigInt(timeStep));

    const hmac = crypto.createHmac('sha1', Buffer.from(secret, 'hex'));
    hmac.update(timeBuffer);
    const digest = hmac.digest();

    const offset = digest[digest.length - 1] & 0xf;
    const binary =
      ((digest[offset] & 0x7f) << 24) |
      ((digest[offset + 1] & 0xff) << 16) |
      ((digest[offset + 2] & 0xff) << 8) |
      (digest[offset + 3] & 0xff);

    const token = (binary % Math.pow(10, this.DIGITS)).toString().padStart(this.DIGITS, '0');
    return token;
  }

  /**
   * Validates a TOTP token against a secret with +/- 1 time-step window to accommodate clock drift.
   */
  public static verifyToken(secret: string, token: string): boolean {
    const currentMs = Date.now();
    const windowOffsets = [-1, 0, 1]; // +/- 30 seconds drift tolerance

    for (const offset of windowOffsets) {
      const checkTimestamp = currentMs + offset * this.STEP_SECONDS * 1000;
      const expectedToken = this.generateToken(secret, checkTimestamp);
      if (crypto.timingSafeEqual(Buffer.from(token), Buffer.from(expectedToken))) {
        return true;
      }
    }
    return false;
  }
}
