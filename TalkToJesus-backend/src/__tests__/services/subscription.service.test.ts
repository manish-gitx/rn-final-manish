jest.mock('../../config/supabase');
jest.mock('../../utils/razorpay');
jest.mock('../../utils/logger', () => ({
  __esModule: true,
  default: { info: jest.fn(), warn: jest.fn(), error: jest.fn() },
}));

import { supabase } from '../../config/supabase';
import {
  hasActiveSubscription,
  getUserSubscription,
  incrementConversationCount,
} from '../../api/services/subscription.service';

const mockSupabase = supabase as any;

// Helper to build a chainable Supabase query mock.
//
// The chain itself is thenable, not just `.single()`. Supabase resolves a query
// builder whenever it is awaited, and hasActiveSubscription awaits the
// subscriptions query directly (no `.single()`) to get an array back. Without
// `then` here, `await chain` yields the chain object, data/error come back
// undefined, and the function bails out early — which silently made every
// "expect false" assertion pass for the wrong reason.
function mockQuery(result: { data: any; error: any; count?: any }) {
  const chain: any = {};
  const methods = ['select', 'eq', 'in', 'order', 'limit', 'update', 'insert', 'range', 'ilike'];
  methods.forEach((m) => {
    chain[m] = jest.fn().mockReturnValue(chain);
  });
  chain.single = jest.fn().mockResolvedValue(result);
  chain.then = (resolve: any, reject: any) => Promise.resolve(result).then(resolve, reject);
  return chain;
}

const daysAgo = (n: number) => new Date(Date.now() - n * 24 * 60 * 60 * 1000).toISOString();

describe('Subscription Service', () => {
  beforeEach(() => jest.clearAllMocks());

  describe('hasActiveSubscription', () => {
    it('should return true when user is within free tier (count < 3)', async () => {
      mockSupabase.from = jest.fn().mockReturnValue(
        mockQuery({ data: { conversation_count: 2 }, error: null })
      );

      const result = await hasActiveSubscription('user-1');
      expect(result).toBe(true);
    });

    it('should respect a custom free tier limit', async () => {
      mockSupabase.from = jest.fn().mockReturnValue(
        mockQuery({ data: { conversation_count: 4 }, error: null })
      );

      // Default limit of 3 would deny; an admin-raised limit of 10 allows.
      expect(await hasActiveSubscription('user-1', 10)).toBe(true);
    });

    it('should return false when user exceeds free tier and has no subscription', async () => {
      let callCount = 0;
      mockSupabase.from = jest.fn().mockImplementation(() => {
        callCount++;
        if (callCount === 1) {
          return mockQuery({ data: { conversation_count: 5 }, error: null });
        }
        return mockQuery({ data: [], error: null });
      });

      const result = await hasActiveSubscription('user-1');
      expect(result).toBe(false);
    });

    it('should return true for an active subscription', async () => {
      let callCount = 0;
      mockSupabase.from = jest.fn().mockImplementation(() => {
        callCount++;
        if (callCount === 1) {
          return mockQuery({ data: { conversation_count: 5 }, error: null });
        }
        return mockQuery({
          data: [
            {
              id: 'sub-1',
              status: 'active',
              last_charged_at: Math.floor(Date.now() / 1000) - 10 * 24 * 60 * 60,
              created_at: daysAgo(10),
            },
          ],
          error: null,
        });
      });

      const result = await hasActiveSubscription('user-1');
      expect(result).toBe(true);
    });

    it('should prefer an active subscription over a stale created one', async () => {
      let callCount = 0;
      mockSupabase.from = jest.fn().mockImplementation(() => {
        callCount++;
        if (callCount === 1) {
          return mockQuery({ data: { conversation_count: 5 }, error: null });
        }
        return mockQuery({
          data: [
            { id: 'sub-old', status: 'created', last_charged_at: null, created_at: daysAgo(30) },
            { id: 'sub-new', status: 'active', last_charged_at: null, created_at: daysAgo(1) },
          ],
          error: null,
        });
      });

      expect(await hasActiveSubscription('user-1')).toBe(true);
    });

    it('should return true for an authenticated subscription', async () => {
      let callCount = 0;
      mockSupabase.from = jest.fn().mockImplementation(() => {
        callCount++;
        if (callCount === 1) {
          return mockQuery({ data: { conversation_count: 5 }, error: null });
        }
        return mockQuery({
          data: [
            {
              id: 'sub-1',
              status: 'authenticated',
              last_charged_at: null,
              created_at: new Date().toISOString(),
            },
          ],
          error: null,
        });
      });

      const result = await hasActiveSubscription('user-1');
      expect(result).toBe(true);
    });

    it('should return true for a created subscription inside the 24h grace period', async () => {
      let callCount = 0;
      mockSupabase.from = jest.fn().mockImplementation(() => {
        callCount++;
        if (callCount === 1) {
          return mockQuery({ data: { conversation_count: 5 }, error: null });
        }
        return mockQuery({
          data: [
            {
              id: 'sub-1',
              status: 'created',
              last_charged_at: null,
              created_at: new Date().toISOString(),
            },
          ],
          error: null,
        });
      });

      expect(await hasActiveSubscription('user-1')).toBe(true);
    });

    it('should return false for a created subscription past the 24h grace period', async () => {
      let callCount = 0;
      mockSupabase.from = jest.fn().mockImplementation(() => {
        callCount++;
        if (callCount === 1) {
          return mockQuery({ data: { conversation_count: 5 }, error: null });
        }
        return mockQuery({
          data: [
            {
              id: 'sub-1',
              status: 'created',
              last_charged_at: null,
              created_at: daysAgo(3),
            },
          ],
          error: null,
        });
      });

      expect(await hasActiveSubscription('user-1')).toBe(false);
    });

    it('should return false when user not found', async () => {
      mockSupabase.from = jest.fn().mockReturnValue(
        mockQuery({ data: null, error: { code: 'PGRST116' } })
      );

      const result = await hasActiveSubscription('nonexistent');
      expect(result).toBe(false);
    });
  });

  describe('getUserSubscription', () => {
    it('should return the latest subscription', async () => {
      const mockSub = { id: 'sub-1', user_id: 'user-1', status: 'active' };
      mockSupabase.from = jest.fn().mockReturnValue(
        mockQuery({ data: mockSub, error: null })
      );

      const result = await getUserSubscription('user-1');
      expect(result).toEqual(mockSub);
    });

    it('should return null when no subscription exists', async () => {
      mockSupabase.from = jest.fn().mockReturnValue(
        mockQuery({ data: null, error: { code: 'PGRST116' } })
      );

      const result = await getUserSubscription('user-1');
      expect(result).toBeNull();
    });
  });

  describe('incrementConversationCount', () => {
    it('should increment and return the new count', async () => {
      let callCount = 0;
      mockSupabase.from = jest.fn().mockImplementation(() => {
        callCount++;
        if (callCount === 1) {
          // select current count
          return mockQuery({ data: { conversation_count: 5 }, error: null });
        }
        // update
        const chain = mockQuery({ data: null, error: null });
        chain.single = undefined; // update doesn't call .single()
        return chain;
      });

      const result = await incrementConversationCount('user-1');
      expect(result).toBe(6);
    });
  });
});
