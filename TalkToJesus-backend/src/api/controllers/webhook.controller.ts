import { Request, Response } from 'express';
import { handleRazorpayWebhook } from '../services/webhook.service';
import { verifyWebhookSignature } from '../../utils/razorpay';
import logger from '../../utils/logger';

export const razorpayWebhookHandler = async (req: Request, res: Response) => {
    try {
        const signature = req.headers['x-razorpay-signature'] as string;
        const webhookBody = JSON.stringify(req.body);

        if (!signature) {
            logger.warn('No Razorpay signature provided in webhook request');
            return res.status(400).json({ message: 'No signature provided' });
        }

        if (!verifyWebhookSignature(webhookBody, signature)) {
            logger.warn('Invalid Razorpay webhook signature');
            return res.status(400).json({ message: 'Invalid signature' });
        }

        logger.info('Processing Razorpay webhook', { event: req.body.event });
        await handleRazorpayWebhook(req.body);
        res.status(200).json({ received: true });
    } catch (error: any) {
        logger.error('Error processing Razorpay webhook', error);
        res.status(500).json({ message: error.message });
    }
};
