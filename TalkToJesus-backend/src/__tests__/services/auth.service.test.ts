jest.mock('../../config/supabase');
jest.mock('../../utils/jwt');
jest.mock('google-auth-library');
jest.mock('../../utils/logger', () => ({
  __esModule: true,
  default: { info: jest.fn(), warn: jest.fn(), error: jest.fn() },
}));

import { supabase } from '../../config/supabase';
import { signToken } from '../../utils/jwt';
import { OAuth2Client } from 'google-auth-library';
import { createOrGetUser } from '../../api/services/auth.service';

const mockSupabase = supabase as any;
const mockSignToken = signToken as jest.Mock;
const MockOAuth2Client = OAuth2Client as jest.MockedClass<typeof OAuth2Client>;

function mockQuery(result: { data: any; error: any }) {
  const chain: any = {};
  const methods = ['select', 'eq', 'in', 'order', 'limit', 'update', 'insert'];
  methods.forEach((m) => {
    chain[m] = jest.fn().mockReturnValue(chain);
  });
  chain.single = jest.fn().mockResolvedValue(result);
  return chain;
}

describe('Auth Service', () => {
  const googlePayload = {
    email: 'test@example.com',
    name: 'Test User',
    picture: 'https://photo.url',
    sub: 'google-id-123',
  };

  beforeEach(() => {
    jest.clearAllMocks();
    mockSignToken.mockReturnValue('mock-jwt-token');

    // Set up Google OAuth mock
    MockOAuth2Client.mockImplementation(() => ({
      verifyIdToken: jest.fn().mockResolvedValue({
        getPayload: () => googlePayload,
      }),
    } as any));
  });

  it('should create a new user when not found in DB', async () => {
    const newUser = { id: 'user-new', email: 'test@example.com' };

    let callCount = 0;
    mockSupabase.from = jest.fn().mockImplementation(() => {
      callCount++;
      if (callCount === 1) {
        // select user - not found
        return mockQuery({ data: null, error: { code: 'PGRST116' } });
      }
      // insert new user
      return mockQuery({ data: newUser, error: null });
    });

    const result = await createOrGetUser('google-token');

    expect(result.user).toEqual(newUser);
    expect(result.token).toBe('mock-jwt-token');
    expect(mockSignToken).toHaveBeenCalledWith({ userId: 'user-new' });
  });

  it('should return existing user and update last_login_at', async () => {
    const existingUser = { id: 'user-existing', email: 'test@example.com' };
    const updatedUser = { ...existingUser, last_login_at: new Date().toISOString() };

    let callCount = 0;
    mockSupabase.from = jest.fn().mockImplementation(() => {
      callCount++;
      if (callCount === 1) {
        // select user - found
        return mockQuery({ data: existingUser, error: null });
      }
      if (callCount === 2) {
        // update last_login_at
        return mockQuery({ data: null, error: null });
      }
      // fetch updated user
      return mockQuery({ data: updatedUser, error: null });
    });

    const result = await createOrGetUser('google-token');

    expect(result.user).toEqual(updatedUser);
    expect(result.token).toBe('mock-jwt-token');
  });

  it('should throw on invalid Google token', async () => {
    MockOAuth2Client.mockImplementation(() => ({
      verifyIdToken: jest.fn().mockRejectedValue(new Error('Invalid token')),
    } as any));

    await expect(createOrGetUser('bad-token')).rejects.toThrow('Invalid Google token');
  });
});
