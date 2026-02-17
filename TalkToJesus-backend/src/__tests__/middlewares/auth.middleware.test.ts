import { Request, Response, NextFunction } from 'express';
import { authMiddleware, AuthenticatedRequest } from '../../api/middlewares/auth.middleware';

// Mock dependencies
jest.mock('../../utils/jwt');
jest.mock('../../config/supabase');
jest.mock('../../utils/logger', () => ({
  __esModule: true,
  default: { info: jest.fn(), warn: jest.fn(), error: jest.fn() },
}));

import { verifyToken } from '../../utils/jwt';
import { supabase } from '../../config/supabase';

const mockVerifyToken = verifyToken as jest.Mock;
const mockSupabase = supabase as any;

describe('Auth Middleware', () => {
  let req: Partial<AuthenticatedRequest>;
  let res: Partial<Response>;
  let next: NextFunction;

  beforeEach(() => {
    req = { headers: {}, path: '/test', method: 'GET' };
    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    };
    next = jest.fn();
    jest.clearAllMocks();
  });

  it('should return 401 when no authorization header', async () => {
    await authMiddleware(req as AuthenticatedRequest, res as Response, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({ message: 'Unauthorized: No token provided' });
    expect(next).not.toHaveBeenCalled();
  });

  it('should return 401 when authorization header is not Bearer', async () => {
    req.headers = { authorization: 'Basic abc123' };

    await authMiddleware(req as AuthenticatedRequest, res as Response, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({ message: 'Unauthorized: No token provided' });
  });

  it('should return 401 when JWT token is invalid', async () => {
    req.headers = { authorization: 'Bearer invalid-token' };
    mockVerifyToken.mockReturnValue(null);

    await authMiddleware(req as AuthenticatedRequest, res as Response, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({ message: 'Unauthorized: Invalid token' });
  });

  it('should return 401 when user is not found in database', async () => {
    req.headers = { authorization: 'Bearer valid-token' };
    mockVerifyToken.mockReturnValue({ userId: 'user-123' });
    mockSupabase.from = jest.fn().mockReturnValue({
      select: jest.fn().mockReturnValue({
        eq: jest.fn().mockReturnValue({
          single: jest.fn().mockResolvedValue({ data: null, error: null }),
        }),
      }),
    });

    await authMiddleware(req as AuthenticatedRequest, res as Response, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({ message: 'Unauthorized: User not found' });
  });

  it('should set req.user and call next() on valid auth', async () => {
    const mockUser = { id: 'user-123', email: 'test@example.com' };
    req.headers = { authorization: 'Bearer valid-token' };
    mockVerifyToken.mockReturnValue({ userId: 'user-123' });
    mockSupabase.from = jest.fn().mockReturnValue({
      select: jest.fn().mockReturnValue({
        eq: jest.fn().mockReturnValue({
          single: jest.fn().mockResolvedValue({ data: mockUser, error: null }),
        }),
      }),
    });

    await authMiddleware(req as AuthenticatedRequest, res as Response, next);

    expect(req.user).toEqual(mockUser);
    expect(next).toHaveBeenCalled();
    expect(res.status).not.toHaveBeenCalled();
  });

  it('should return 500 on unexpected error', async () => {
    req.headers = { authorization: 'Bearer valid-token' };
    mockVerifyToken.mockImplementation(() => { throw new Error('unexpected'); });

    await authMiddleware(req as AuthenticatedRequest, res as Response, next);

    expect(res.status).toHaveBeenCalledWith(500);
    expect(res.json).toHaveBeenCalledWith({ message: 'Internal server error' });
  });
});
