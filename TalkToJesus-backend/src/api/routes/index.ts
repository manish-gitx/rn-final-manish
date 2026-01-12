import { Router } from 'express';
import authRouter from './auth.routes';
import userRouter from './user.routes';
import songRouter from './song.routes';
import planRouter from './plan.routes';
import paymentRouter from './payment.routes';
import subscriptionRouter from './subscription.routes';
import webhookRouter from './webhook.routes';
import conversationRouter from './conversation.routes';

const router = Router();

router.use('/auth', authRouter);
router.use('/user', userRouter);
router.use('/songs', songRouter);
router.use('/plans', planRouter);
router.use('/payment', paymentRouter); // Kept for backward compatibility, redirects to subscription
router.use('/subscription', subscriptionRouter);
router.use('/webhook', webhookRouter);
router.use('/conversation', conversationRouter);

export default router;
