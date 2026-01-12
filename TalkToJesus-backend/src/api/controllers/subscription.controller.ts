import { Response } from 'express';
import { AuthenticatedRequest } from '../middlewares/auth.middleware';
import { 
    getUserSubscription, 
    fetchAndUpdateSubscription, 
    cancelSubscription 
} from '../services/subscription.service';
import logger from '../../utils/logger';

/**
 * Get current subscription for authenticated user
 */
export const getCurrentSubscriptionHandler = async (req: AuthenticatedRequest, res: Response) => {
    try {
        const user = req.user;
        
        if (!user) {
            return res.status(401).json({ message: 'Unauthorized' });
        }

        logger.info('Fetching current subscription', { user_id: user.id });
        let subscription = await getUserSubscription(user.id);

        // If subscription exists, fetch latest from Razorpay and update
        if (subscription && subscription.razorpay_subscription_id) {
            try {
                subscription = await fetchAndUpdateSubscription(
                    subscription.razorpay_subscription_id,
                    user.id
                );
            } catch (error: any) {
                logger.warn('Error fetching subscription from Razorpay, returning local data', { 
                    error: error.message,
                    subscription_id: subscription.razorpay_subscription_id 
                });
                // Continue with local data if Razorpay fetch fails
            }
        }

        if (!subscription) {
            return res.status(200).json({ subscription: null });
        }

        res.status(200).json({ subscription });
    } catch (error: any) {
        logger.error('Error getting current subscription', { error, user_id: req.user?.id });
        res.status(500).json({ message: error.message });
    }
};

/**
 * Cancel subscription for authenticated user
 */
export const cancelSubscriptionHandler = async (req: AuthenticatedRequest, res: Response) => {
    try {
        const user = req.user;
        
        if (!user) {
            return res.status(401).json({ message: 'Unauthorized' });
        }

        // Get user's subscription
        const subscription = await getUserSubscription(user.id);

        if (!subscription || !subscription.razorpay_subscription_id) {
            return res.status(404).json({ message: 'No active subscription found' });
        }

        logger.info('Cancelling subscription', { 
            user_id: user.id, 
            subscription_id: subscription.razorpay_subscription_id 
        });

        const cancelledSubscription = await cancelSubscription(
            subscription.razorpay_subscription_id,
            user.id
        );

        res.status(200).json({ subscription: cancelledSubscription });
    } catch (error: any) {
        logger.error('Error cancelling subscription', { error, user_id: req.user?.id });
        res.status(500).json({ message: error.message });
    }
};

