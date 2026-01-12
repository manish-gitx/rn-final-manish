import { Request, Response, NextFunction } from 'express';
import { verifyToken } from '../../utils/jwt';
import { supabase } from '../../config/supabase';
import logger from '../../utils/logger';

export interface AuthenticatedRequest extends Request {
    user?: any;
}

export const authMiddleware = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            logger.warn('No authorization token provided', { 
                path: req.path, 
                method: req.method 
            });
            return res.status(401).json({ message: 'Unauthorized: No token provided' });
        }

        const token = authHeader.split(' ')[1];
        const decoded = verifyToken(token);

        if (!decoded) {
            logger.warn('Invalid JWT token', { 
                path: req.path, 
                method: req.method 
            });
            return res.status(401).json({ message: 'Unauthorized: Invalid token' });
        }

        logger.info('JWT token verified, fetching user', { 
            userId: decoded.userId, 
            path: req.path 
        });

        const { data: user, error } = await supabase
            .from('users')
            .select('*')
            .eq('id', decoded.userId)
            .single();

        if (error || !user) {
            logger.warn('User not found in database', { 
                userId: decoded.userId, 
                error, 
                path: req.path 
            });
            return res.status(401).json({ message: 'Unauthorized: User not found' });
        }

        logger.info('User authenticated successfully', { 
            userId: user.id, 
            email: user.email, 
            path: req.path 
        });

        req.user = user;
        next();
    } catch (error) {
        logger.error('Error in auth middleware', { error, path: req.path });
        return res.status(500).json({ message: 'Internal server error' });
    }
};
