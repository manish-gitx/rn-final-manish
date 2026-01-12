import { Response } from 'express';
import { z } from 'zod';
import { createSubscription } from '../services/subscription.service';
import { AuthenticatedRequest } from '../middlewares/auth.middleware';
import logger from '../../utils/logger';

const createSubscriptionSchema = z.object({
    plan_id: z.string(),
});

export const createSubscriptionHandler = async (req: AuthenticatedRequest, res: Response) => {
    try {
        const { plan_id } = createSubscriptionSchema.parse(req.body);
        const user = req.user;
        
        if (!user) {
            return res.status(401).json({ message: 'Unauthorized' });
        }

        logger.info('Creating subscription', { plan_id, user_id: user.id });
        const subscription = await createSubscription(plan_id, user.id);
        res.status(200).json(subscription);
    } catch (error: any) {
        logger.error('Error creating subscription', { error, user_id: req.user?.id });
        if (error instanceof z.ZodError) {
            return res.status(400).json({ message: 'Invalid request body', error: error.message });
        }
        res.status(500).json({ message: error.message });
    }
};
