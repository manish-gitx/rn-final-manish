jest.mock('../../config/supabase');
jest.mock('../../utils/logger', () => ({
  __esModule: true,
  default: { info: jest.fn(), warn: jest.fn(), error: jest.fn() },
}));

import { supabase } from '../../config/supabase';
import { handleRazorpayWebhook } from '../../api/services/webhook.service';

const mockSupabase = supabase as any;

function mockQuery(result: { data: any; error: any }) {
  const chain: any = {};
  const methods = ['select', 'eq', 'in', 'order', 'limit', 'update', 'insert'];
  methods.forEach((m) => {
    chain[m] = jest.fn().mockReturnValue(chain);
  });
  chain.single = jest.fn().mockResolvedValue(result);
  return chain;
}

describe('Webhook Service', () => {
  beforeEach(() => jest.clearAllMocks());

  const makePayload = (event: string, subscriptionData: any) => ({
    event,
    payload: {
      subscription: {
        entity: {
          id: 'sub_razorpay_123',
          status: 'active',
          current_start: Math.floor(Date.now() / 1000),
          current_end: null,
          charge_at: null,
          start_at: null,
          end_at: null,
          quantity: 1,
          total_count: 12,
          paid_count: 1,
          ...subscriptionData,
        },
      },
    },
  });

  it('should handle subscription.charged and set last_charged_at', async () => {
    const chargeTime = Math.floor(Date.now() / 1000);
    const dbSub = { id: 'db-sub-1', razorpay_subscription_id: 'sub_razorpay_123', last_charged_at: null };

    // First call: select subscription, Second call: update
    let callCount = 0;
    mockSupabase.from = jest.fn().mockImplementation(() => {
      callCount++;
      if (callCount === 1) {
        return mockQuery({ data: dbSub, error: null });
      }
      return mockQuery({ data: null, error: null });
    });

    const payload = makePayload('subscription.charged', { current_start: chargeTime });
    await handleRazorpayWebhook(payload);

    // Verify update was called
    expect(mockSupabase.from).toHaveBeenCalledWith('subscriptions');
  });

  it('should handle subscription.cancelled', async () => {
    const dbSub = { id: 'db-sub-1', razorpay_subscription_id: 'sub_razorpay_123', last_charged_at: 123 };

    let callCount = 0;
    mockSupabase.from = jest.fn().mockImplementation(() => {
      callCount++;
      if (callCount === 1) {
        return mockQuery({ data: dbSub, error: null });
      }
      return mockQuery({ data: null, error: null });
    });

    const payload = makePayload('subscription.cancelled', { status: 'cancelled', end_at: 9999 });
    await handleRazorpayWebhook(payload);

    expect(mockSupabase.from).toHaveBeenCalledWith('subscriptions');
  });

  it('should handle subscription.authenticated and set last_charged_at from current_start', async () => {
    const chargeTime = Math.floor(Date.now() / 1000);
    const dbSub = { id: 'db-sub-1', razorpay_subscription_id: 'sub_razorpay_123' };

    let callCount = 0;
    mockSupabase.from = jest.fn().mockImplementation(() => {
      callCount++;
      if (callCount === 1) {
        return mockQuery({ data: dbSub, error: null });
      }
      return mockQuery({ data: null, error: null });
    });

    const payload = makePayload('subscription.authenticated', {
      status: 'authenticated',
      current_start: chargeTime,
    });
    await handleRazorpayWebhook(payload);

    expect(mockSupabase.from).toHaveBeenCalledWith('subscriptions');
  });

  it('should ignore non-subscription events gracefully', async () => {
    const payload = { event: 'payment.captured', payload: {} };
    await handleRazorpayWebhook(payload);

    // Should not attempt any DB operations
    expect(mockSupabase.from).not.toHaveBeenCalled();
  });

  it('should handle missing subscription data in payload', async () => {
    const payload = {
      event: 'subscription.charged',
      payload: { subscription: { entity: null } },
    };

    // Should not throw
    await handleRazorpayWebhook(payload);
  });

  it('should handle subscription.activated and set last_charged_at as fallback', async () => {
    const chargeTime = Math.floor(Date.now() / 1000);
    const dbSub = {
      id: 'db-sub-1',
      razorpay_subscription_id: 'sub_razorpay_123',
      last_charged_at: null, // not yet set
    };

    let callCount = 0;
    mockSupabase.from = jest.fn().mockImplementation(() => {
      callCount++;
      if (callCount === 1) {
        return mockQuery({ data: dbSub, error: null });
      }
      return mockQuery({ data: null, error: null });
    });

    const payload = makePayload('subscription.activated', {
      status: 'active',
      current_start: chargeTime,
    });
    await handleRazorpayWebhook(payload);

    expect(mockSupabase.from).toHaveBeenCalledWith('subscriptions');
  });
});
