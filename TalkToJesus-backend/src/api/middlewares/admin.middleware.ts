import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from './auth.middleware';
import logger from '../../utils/logger';

/**
 * Gate for /api/admin/*. Must run AFTER authMiddleware.
 *
 * Costs no extra database round-trip: authMiddleware already does
 * `select('*')` on the users row and attaches it to req.user, so is_admin is
 * present. The claim is never read from the JWT — flipping is_admin to false in
 * the database revokes access immediately, without waiting for a 70-day token
 * to expire.
 */
export const adminMiddleware = (
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
) => {
    const user = req.user;

    if (!user) {
        logger.warn('Admin route reached without an authenticated user', { path: req.path });
        return res.status(401).json({ message: 'Unauthorized' });
    }

    if (user.is_admin !== true) {
        logger.warn('Non-admin user attempted to access admin route', {
            userId: user.id,
            email: user.email,
            path: req.path,
        });
        // 404 rather than 403: don't confirm the admin surface exists to
        // someone who isn't allowed to use it.
        return res.status(404).json({ message: 'Not found' });
    }

    logger.info('Admin access granted', { userId: user.id, email: user.email, path: req.path });
    next();
};
