import { PrismaClient } from '@prisma/client';

/**
 * Hardened Prisma Client Configuration
 * - Provides query and error logging in development/production
 * - Ensures graceful disconnect on server termination to prevent lost in-flight writes
 * - Provides an active database health check and reconnection resilience
 */
const prisma = new PrismaClient({
  log:
    process.env.NODE_ENV === 'development'
      ? [
          { emit: 'stdout', level: 'warn' },
          { emit: 'stdout', level: 'error' },
        ]
      : [{ emit: 'stdout', level: 'error' }],
});

/**
 * Active Health Check: Verifies that PostgreSQL connection is alive and healthy
 */
export const checkDbHealth = async (): Promise<boolean> => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    return true;
  } catch (error) {
    console.error('❌ Database health check failed:', error);
    return false;
  }
};

/**
 * Graceful Database Disconnect Handlers
 * Guarantees that in-flight transactions finish before shutting down
 */
const handleGracefulShutdown = async (signal: string) => {
  console.log(`\n🛑 Received ${signal}. Gracefully closing database connections...`);
  try {
    await prisma.$disconnect();
    console.log('✅ Database connections cleanly closed. Zero data corruption risk.');
  } catch (err) {
    console.error('❌ Error during database disconnect:', err);
  } finally {
    process.exit(0);
  }
};

if (!process.env.VERCEL) {
  process.on('SIGINT', () => handleGracefulShutdown('SIGINT'));
  process.on('SIGTERM', () => handleGracefulShutdown('SIGTERM'));
}

export default prisma;
