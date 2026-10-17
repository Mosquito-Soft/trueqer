import mysql, { Pool, PoolConnection } from 'mysql2/promise';
import dotenv from 'dotenv';

dotenv.config();

/**
 * Enterprise MySQL Connection Pool with ACID Transaction support.
 * Designed for serverless container environments with connection reuse
 * and strict isolation to prevent race conditions.
 */
export const pool: Pool = mysql.createPool({
  host: process.env.DB_HOST || '127.0.0.1',
  port: Number(process.env.DB_PORT) || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'trueqer_db',
  waitForConnections: true,
  connectionLimit: Number(process.env.DB_CONNECTION_LIMIT) || 10,
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 10000,
});

/**
 * Executes a callback within a managed ACID transaction.
 * Automatically performs START TRANSACTION, COMMIT on success,
 * or ROLLBACK on failure, ensuring the connection is always released back to the pool.
 *
 * @param callback Async function receiving an isolated MySQL PoolConnection.
 * @returns The resolved value of the callback.
 */
export async function withTransaction<T>(
  callback: (connection: PoolConnection) => Promise<T>
): Promise<T> {
  const connection: PoolConnection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const result = await callback(connection);
    await connection.commit();
    return result;
  } catch (error) {
    try {
      await connection.rollback();
    } catch (rollbackError) {
      console.error('[Database] Failed to rollback transaction:', rollbackError);
    }
    throw error;
  } finally {
    connection.release();
  }
}

/**
 * Simple query helper for read-only or single-statement operations.
 */
export async function executeQuery<T = any>(
  sql: string,
  params: any[] = []
): Promise<T> {
  const [rows] = await pool.execute(sql, params);
  return rows as T;
}
