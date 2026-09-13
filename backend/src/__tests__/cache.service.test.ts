import { cacheService } from '../utils/cache.service';

describe('MemoryCacheService Unit Tests', () => {
  beforeEach(() => {
    cacheService.clear();
  });

  test('Sets and retrieves value correctly within TTL', () => {
    cacheService.set('user:101', { name: 'Alice', balance: 5000 }, 60);
    const cached = cacheService.get<{ name: string; balance: number }>('user:101');
    expect(cached).toEqual({ name: 'Alice', balance: 5000 });
  });

  test('Returns null for missing or expired keys', () => {
    expect(cacheService.get('nonexistent_key')).toBeNull();

    // Set with 0 ttl (already expired)
    cacheService.set('expired_key', 'value', -1);
    expect(cacheService.get('expired_key')).toBeNull();
  });

  test('getOrSet returns cached value or invokes fetcher on miss', async () => {
    let callCount = 0;
    const fetcher = async () => {
      callCount++;
      return { total: 1000 };
    };

    const first = await cacheService.getOrSet('calc:totals', fetcher, 60);
    expect(first).toEqual({ total: 1000 });
    expect(callCount).toBe(1);

    // Second call should return cached value without executing fetcher
    const second = await cacheService.getOrSet('calc:totals', fetcher, 60);
    expect(second).toEqual({ total: 1000 });
    expect(callCount).toBe(1);
  });

  test('Invalidates keys by pattern prefix', () => {
    cacheService.set('analytics:user_1', { summary: 'A' }, 60);
    cacheService.set('analytics:user_2', { summary: 'B' }, 60);
    cacheService.set('profile:user_1', { name: 'Alice' }, 60);

    const deleted = cacheService.invalidatePattern('analytics:*');
    expect(deleted).toBe(2);
    expect(cacheService.get('analytics:user_1')).toBeNull();
    expect(cacheService.get('analytics:user_2')).toBeNull();
    expect(cacheService.get('profile:user_1')).not.toBeNull();
  });

  test('Tracks hit and miss metrics', () => {
    cacheService.set('item:1', 'A', 60);
    cacheService.get('item:1'); // hit
    cacheService.get('item:2'); // miss

    const stats = cacheService.getStats();
    expect(stats.hits).toBe(1);
    expect(stats.misses).toBe(50); // 1 hit / 2 total = 50%
  });
});
