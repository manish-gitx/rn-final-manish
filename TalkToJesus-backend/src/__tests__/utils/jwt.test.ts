import { signToken, verifyToken } from '../../utils/jwt';
import jwt from 'jsonwebtoken';

describe('JWT Utility', () => {
  const testPayload = { userId: 'user-123', email: 'test@example.com' };

  describe('signToken', () => {
    it('should return a valid JWT string', () => {
      const token = signToken(testPayload);
      expect(typeof token).toBe('string');
      expect(token.split('.')).toHaveLength(3); // JWT has 3 parts
    });

    it('should embed the payload in the token', () => {
      const token = signToken(testPayload);
      const decoded = jwt.decode(token) as any;
      expect(decoded.userId).toBe('user-123');
      expect(decoded.email).toBe('test@example.com');
    });

    it('should set expiration to 70 days', () => {
      const token = signToken(testPayload);
      const decoded = jwt.decode(token) as any;
      const expectedExpiry = decoded.iat + 70 * 24 * 60 * 60;
      expect(decoded.exp).toBe(expectedExpiry);
    });
  });

  describe('verifyToken', () => {
    it('should return decoded payload for a valid token', () => {
      const token = signToken(testPayload);
      const decoded = verifyToken(token);
      expect(decoded).not.toBeNull();
      expect(decoded.userId).toBe('user-123');
      expect(decoded.email).toBe('test@example.com');
    });

    it('should return null for an invalid token', () => {
      const result = verifyToken('invalid.token.string');
      expect(result).toBeNull();
    });

    it('should return null for a token signed with a different secret', () => {
      const token = jwt.sign(testPayload, 'wrong-secret', { expiresIn: '1d' });
      const result = verifyToken(token);
      expect(result).toBeNull();
    });

    it('should return null for an expired token', () => {
      const token = jwt.sign(testPayload, process.env.JWT_SECRET!, { expiresIn: '0s' });
      const result = verifyToken(token);
      expect(result).toBeNull();
    });
  });
});
