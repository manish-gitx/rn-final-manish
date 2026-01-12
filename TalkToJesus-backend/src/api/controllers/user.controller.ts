import { Response } from 'express';
import { AuthenticatedRequest } from '../middlewares/auth.middleware';

export const getMeHandler = (req: AuthenticatedRequest, res: Response) => {
    res.status(200).json(req.user);
};
