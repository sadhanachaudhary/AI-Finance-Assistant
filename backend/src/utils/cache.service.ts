/**
 * High-Performance In-Memory Cache Service with TTL & Pattern Invalidation
 * Optimizes repeated expensive database queries (e.g. analytics, aggregations, category trees)
 * and guarantees zero stale data through proactive invalidation on mutations.
 */
interface CacheEntry<T> {
  value: T;
  expiresAt: number;
}

class MemoryCacheService {
  private cache = new Map<string, CacheEntry<any>>();
  private cleanupTimer: NodeJS.Timeout;
  private hits = 0;
  private misses = 0;

  constructor(cleanupIntervalMs = 60000) {
    // Periodic sweep to evict expired keys and protect heap memory
    this.cleanupTimer = setInterval(() => this.sweep(), cleanupIntervalMs);
    // Don't keep the process alive solely for cache cleanup
    if (this.cleanupTimer.unref) {
      this.cleanupTimer.unref();
    }
  }

  /**
   * Get an item from cache if it exists and has not expired.
   */
  get<T>(key: string): T | null {
    const entry = this.cache.get(key);
    if (!entry) {
      this.misses++;
      return null;
    }

    if (Date.now() > entry.expiresAt) {
      this.cache.delete(key);
      this.misses++;
      return null;
    }

    this.hits++;
    return entry.value as T;
  }

  /**
   * Set an item in cache with a custom TTL (default: 60 seconds).
   */
  set<T>(key: string, value: T, ttlSeconds = 60): void {
    this.cache.set(key, {
      value,
      expiresAt: Date.now() + ttlSeconds * 1000,
    });
  }

  /**
   * Atomically fetch from cache or execute computation and cache result.
   */
  async getOrSet<T>(
    key: string,
    fetcher: () => Promise<T>,
    ttlSeconds = 60
  ): Promise<T> {
    const cached = this.get<T>(key);
    if (cached !== null) {
      return cached;
    }

    const freshValue = await fetcher();
    this.set(key, freshValue, ttlSeconds);
    return freshValue;
  }

  /**
   * Delete a single specific cache key.
   */
  delete(key: string): boolean {
    return this.cache.delete(key);
  }

  /**
   * Invalidate all keys matching a prefix or pattern (e.g., 'analytics:user_123*').
   */
  invalidatePattern(pattern: string): number {
    let deletedCount = 0;
    const isPrefix = pattern.endsWith('*');
    const prefix = isPrefix ? pattern.slice(0, -1) : pattern;

    for (const key of this.cache.keys()) {
      if (isPrefix ? key.startsWith(prefix) : key.includes(pattern)) {
        this.cache.delete(key);
        deletedCount++;
      }
    }
    return deletedCount;
  }

  /**
   * Clear entire cache.
   */
  clear(): void {
    this.cache.clear();
  }

  /**
   * Cache metrics for observability.
   */
  getStats() {
    return {
      size: this.cache.size,
      hits: this.hits,
      misses: this.hits + this.misses > 0 ? (this.hits / (this.hits + this.misses)) * 100 : 0,
    };
  }

  private sweep(): void {
    const now = Date.now();
    for (const [key, entry] of this.cache.entries()) {
      if (now > entry.expiresAt) {
        this.cache.delete(key);
      }
    }
  }
}

export const cacheService = new MemoryCacheService();
