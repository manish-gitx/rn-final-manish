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

// Helper to build a chainable Supabase query mock
function mockQuery(result: { data: any; error: any; count?: any }) {
  const chain: any = {};
  const methods = ['select', 'eq', 'in', 'order', 'limit', 'update', 'insert', 'range', 'ilike'];
  methods.forEach((m) => {
    chain[m] = jest.fn().mockReturnValue(chain);
  });
  chain.single = jest.fn().mockResolvedValue(result);
  return chain;
}

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

    it('should return false when user exceeds free tier and has no subscription', async () => {
      let callCount = 0;
      mockSupabase.from = jest.fn().mockImplementation(() => {
        callCount++;
        if (callCount === 1) {
          return mockQuery({ data: { conversation_count: 5 }, error: null });
        }
        return mockQuery({ data: null, error: { code: 'PGRST116' } });
      });

      const result = await hasActiveSubscription('user-1');
      expect(result).toBe(false);
    });

    it('should return true for active subscription within access period', async () => {
      const lastChargedAt = Math.floor(Date.now() / 1000) - (10 * 24 * 60 * 60); // 10 days ago
      let callCount = 0;
      mockSupabase.from = jest.fn().mockImplementation(() => {
        callCount++;
        if (callCount === 1) {
          return mockQuery({ data: { conversation_count: 5 }, error: null });
        }
        return mockQuery({
          data: {
            id: 'sub-1',
            status: 'active',
            last_charged_at: lastChargedAt,
            created_at: new Date().toISOString(),
          },
          error: null,
        });
      });

      const result = await hasActiveSubscription('user-1');
      expect(result).toBe(true);
    });

    it('should return false for expired subscription', async () => {
      const lastChargedAt = Math.floor(Date.now() / 1000) - (60 * 24 * 60 * 60); // 60 days ago
      let callCount = 0;
      mockSupabase.from = jest.fn().mockImplementation(() => {
        callCount++;
        if (callCount === 1) {
          return mockQuery({ data: { conversation_count: 5 }, error: null });
        }
        return mockQuery({
          data: {
            id: 'sub-1',
            status: 'active',
            last_charged_at: lastChargedAt,
            created_at: new Date(Date.now() - 60 * 24 * 60 * 60 * 1000).toISOString(),
          },
          error: null,
        });
      });

      const result = await hasActiveSubscription('user-1');
      expect(result).toBe(false);
    });

    it('should return true for new subscription within grace period (no last_charged_at)', async () => {
      let callCount = 0;
      mockSupabase.from = jest.fn().mockImplementation(() => {
        callCount++;
        if (callCount === 1) {
          return mockQuery({ data: { conversation_count: 5 }, error: null });
        }
        return mockQuery({
          data: {
            id: 'sub-1',
            status: 'authenticated',
            last_charged_at: null,
            created_at: new Date().toISOString(), // just created
          },
          error: null,
        });
      });

      const result = await hasActiveSubscription('user-1');
      expect(result).toBe(true);
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
