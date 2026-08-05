jest.mock('../../utils/logger', () => ({
  __esModule: true,
  default: { info: jest.fn(), warn: jest.fn(), error: jest.fn() },
}));

import { adminMiddleware } from '../../api/middlewares/admin.middleware';

function mockRes() {
  const res: any = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

describe('Admin Middleware', () => {
  beforeEach(() => jest.clearAllMocks());

  it('should return 401 when no user is attached to the request', () => {
    const req: any = { path: '/stats/overview' };
    const res = mockRes();
    const next = jest.fn();

    adminMiddleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  it('should return 404 when the user is not an admin', () => {
    const req: any = { path: '/users', user: { id: 'u1', email: 'a@b.com', is_admin: false } };
    const res = mockRes();
    const next = jest.fn();

    adminMiddleware(req, res, next);

    // 404 rather than 403 so the admin surface is not confirmed to non-admins.
    expect(res.status).toHaveBeenCalledWith(404);
    expect(next).not.toHaveBeenCalled();
  });

  it('should return 404 when is_admin is missing entirely', () => {
    const req: any = { path: '/users', user: { id: 'u1', email: 'a@b.com' } };
    const res = mockRes();
    const next = jest.fn();

    adminMiddleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(404);
    expect(next).not.toHaveBeenCalled();
  });

  it('should reject a truthy-but-not-true is_admin value', () => {
    // Guards against a string "false" from a loosely typed source being treated
    // as authorisation.
    const req: any = { path: '/users', user: { id: 'u1', email: 'a@b.com', is_admin: 'false' } };
    const res = mockRes();
    const next = jest.fn();

    adminMiddleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(404);
    expect(next).not.toHaveBeenCalled();
  });

  it('should call next() for an admin user', () => {
    const req: any = { path: '/users', user: { id: 'u1', email: 'a@b.com', is_admin: true } };
    const res = mockRes();
    const next = jest.fn();

    adminMiddleware(req, res, next);

    expect(next).toHaveBeenCalled();
    expect(res.status).not.toHaveBeenCalled();
  });
});
