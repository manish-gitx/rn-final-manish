jest.mock('../../config/supabase');
jest.mock('../../utils/logger', () => ({
  __esModule: true,
  default: { info: jest.fn(), warn: jest.fn(), error: jest.fn() },
}));

import {
  percentile,
  computeMrrRupees,
  computeConversionRate,
} from '../../api/services/adminStats.service';

describe('Admin Stats Service', () => {
  describe('percentile', () => {
    it('returns null for an empty set', () => {
      expect(percentile([], 50)).toBeNull();
    });

    it('returns the only value for a single sample', () => {
      expect(percentile([1200], 50)).toBe(1200);
      expect(percentile([1200], 95)).toBe(1200);
    });

    it('computes the median of an odd-length set', () => {
      expect(percentile([300, 100, 200], 50)).toBe(200);
    });

    it('interpolates the median of an even-length set', () => {
      expect(percentile([100, 200, 300, 400], 50)).toBe(250);
    });

    it('computes p95 near the top of the range', () => {
      const values = Array.from({ length: 100 }, (_, i) => i + 1); // 1..100
      // Linear interpolation on rank 0.95 * 99 = 94.05 -> between 95 and 96.
      expect(percentile(values, 95)).toBe(95);
    });

    it('does not mutate the input array', () => {
      const values = [500, 100, 300];
      percentile(values, 50);
      expect(values).toEqual([500, 100, 300]);
    });
  });

  describe('computeMrrRupees', () => {
    it('returns 0 with no subscriptions', () => {
      expect(computeMrrRupees([])).toBe(0);
    });

    it('converts paise to rupees', () => {
      expect(computeMrrRupees([{ plans: { price: 49900 } }])).toBe(499);
    });

    it('sums across subscriptions', () => {
      expect(
        computeMrrRupees([
          { plans: { price: 49900 } },
          { plans: { price: 49900 } },
          { plans: { price: 19900 } },
        ])
      ).toBe(1197);
    });

    it('treats a missing or null plan as zero rather than throwing', () => {
      expect(computeMrrRupees([{ plans: null }, {}, { plans: { price: 49900 } }])).toBe(499);
    });
  });

  describe('computeConversionRate', () => {
    it('returns 0 when there are no users, without dividing by zero', () => {
      expect(computeConversionRate(0, 0)).toBe(0);
    });

    it('computes a percentage to one decimal place', () => {
      expect(computeConversionRate(128, 17)).toBe(13.3);
    });

    it('returns 100 when every user pays', () => {
      expect(computeConversionRate(10, 10)).toBe(100);
    });

    it('returns 0 when nobody pays', () => {
      expect(computeConversionRate(250, 0)).toBe(0);
    });
  });
});
