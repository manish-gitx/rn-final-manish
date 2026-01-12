import { Router } from 'express';
import { 
    getCurrentSubscriptionHandler, 
    cancelSubscriptionHandler 
} from '../controllers/subscription.controller';
import { createSubscriptionHandler } from '../controllers/payment.controller';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();

// Create subscription (replaces create-order)
router.post('/create', authMiddleware, createSubscriptionHandler);

// Get current subscription
router.get('/current', authMiddleware, getCurrentSubscriptionHandler);

// Cancel subscription
router.post('/cancel', authMiddleware, cancelSubscriptionHandler);

export default router;

