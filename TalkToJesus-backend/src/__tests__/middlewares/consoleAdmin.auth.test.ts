jest.mock('../../utils/logger', () => ({
  __esModule: true,
  default: { info: jest.fn(), warn: jest.fn(), error: jest.fn() },
}));

// The whole point of the console-admin path is that it never reaches the
// database, so any call to supabase here is a failure of the feature.
const selectSpy = jest.fn();
jest.mock('../../config/supabase', () => ({
  supabase: { from: (...args: any[]) => { selectSpy(...args); throw new Error('database must not be touched'); } },
}));

import { authMiddleware } from '../../api/middlewares/auth.middleware';
import { adminMiddleware } from '../../api/middlewares/admin.middleware';
import { signToken } from '../../utils/jwt';
import { CONSOLE_ADMIN_ID, CONSOLE_ADMIN_CLAIM } from '../../config/consoleAdmin';

function mockRes() {
  const res: any = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

const consoleToken = () => signToken({ userId: CONSOLE_ADMIN_ID, [CONSOLE_ADMIN_CLAIM]: true });

describe('Console admin authentication', () => {
  const ORIGINAL_ADMIN_EMAIL = process.env.ADMIN_EMAIL;

  beforeEach(() => {
    jest.clearAllMocks();
    process.env.ADMIN_EMAIL = 'admin@talktojesus.local';
  });

  afterAll(() => {
    process.env.ADMIN_EMAIL = ORIGINAL_ADMIN_EMAIL;
  });

  it('authenticates a console token without reading the users table', async () => {
    const req: any = { path: '/stats/overview', headers: { authorization: `Bearer ${consoleToken()}` } };
    const res = mockRes();
    const next = jest.fn();

    await authMiddleware(req, res, next);

    expect(next).toHaveBeenCalled();
    expect(selectSpy).not.toHaveBeenCalled();
    expect(req.user).toMatchObject({
      id: CONSOLE_ADMIN_ID,
      email: 'admin@talktojesus.local',
      is_admin: true,
    });
  });

  it('passes the admin gate once authenticated', async () => {
    const req: any = { path: '/users', headers: { authorization: `Bearer ${consoleToken()}` } };
    const res = mockRes();

    await authMiddleware(req, res, jest.fn());
    const next = jest.fn();
    adminMiddleware(req, res, next);

    expect(next).toHaveBeenCalled();
    expect(res.status).not.toHaveBeenCalled();
  });

  it('rejects a console token once ADMIN_EMAIL is removed', async () => {
    const token = consoleToken();
    delete process.env.ADMIN_EMAIL;

    const req: any = { path: '/stats/overview', headers: { authorization: `Bearer ${token}` } };
    const res = mockRes();
    const next = jest.fn();

    await authMiddleware(req, res, next);

    // Clearing the credentials is the only revocation available, so it has to
    // actually invalidate tokens that were already handed out.
    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  it('does not let a forged claim through without a valid signature', async () => {
    const forged = [
      Buffer.from(JSON.stringify({ alg: 'HS256', typ: 'JWT' })).toString('base64url'),
      Buffer.from(JSON.stringify({ userId: CONSOLE_ADMIN_ID, [CONSOLE_ADMIN_CLAIM]: true })).toString('base64url'),
      'not-a-real-signature',
    ].join('.');

    const req: any = { path: '/stats/overview', headers: { authorization: `Bearer ${forged}` } };
    const res = mockRes();
    const next = jest.fn();

    await authMiddleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });
});
