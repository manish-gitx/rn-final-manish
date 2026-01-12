import { Router } from 'express';
import { createSubscriptionHandler } from '../controllers/payment.controller';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();

// Keep backward compatibility - redirect to subscription create
router.post('/create-order', authMiddleware, createSubscriptionHandler);

export default router;
