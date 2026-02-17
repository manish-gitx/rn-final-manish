import crypto from 'crypto';
import { verifyWebhookSignature } from '../../utils/razorpay';

describe('Razorpay Utility', () => {
  const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET_DEV!;

  describe('verifyWebhookSignature', () => {
    it('should return true for a valid signature', () => {
      const body = JSON.stringify({ event: 'subscription.charged', payload: {} });
      const signature = crypto
        .createHmac('sha256', webhookSecret)
        .update(body)
        .digest('hex');

      expect(verifyWebhookSignature(body, signature)).toBe(true);
    });

    it('should return false for an invalid signature', () => {
      const body = JSON.stringify({ event: 'subscription.charged' });
      const wrongSignature = crypto
        .createHmac('sha256', 'wrong-secret')
        .update(body)
        .digest('hex');

      expect(verifyWebhookSignature(body, wrongSignature)).toBe(false);
    });

    it('should return false for a signature with wrong length', () => {
      const body = JSON.stringify({ event: 'test' });
      expect(verifyWebhookSignature(body, 'short')).toBe(false);
    });

    it('should return false for tampered body', () => {
      const originalBody = JSON.stringify({ event: 'subscription.charged' });
      const signature = crypto
        .createHmac('sha256', webhookSecret)
        .update(originalBody)
        .digest('hex');

      const tamperedBody = JSON.stringify({ event: 'subscription.cancelled' });
      expect(verifyWebhookSignature(tamperedBody, signature)).toBe(false);
    });
  });
});
