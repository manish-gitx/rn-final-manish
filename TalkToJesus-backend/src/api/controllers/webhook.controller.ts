import { Request, Response } from 'express';
import { handleRazorpayWebhook } from '../services/webhook.service';
import { recordWebhookEvent } from '../services/webhookEvent.service';
import { verifyWebhookSignature } from '../../utils/razorpay';
import logger from '../../utils/logger';

const extractSubscriptionId = (body: any): string | null =>
    body?.payload?.subscription?.entity?.id ?? body?.payload?.subscription?.id ?? null;

export const razorpayWebhookHandler = async (req: Request, res: Response) => {
    const eventType = req.body?.event ?? 'unknown';
    const subscriptionId = extractSubscriptionId(req.body);

    try {
        const signature = req.headers['x-razorpay-signature'] as string;
        const webhookBody = JSON.stringify(req.body);

        if (!signature) {
            logger.warn('No Razorpay signature provided in webhook request');
            // Audit the rejection, but don't block the response on it.
            void recordWebhookEvent({
                eventType,
                razorpaySubscriptionId: subscriptionId,
                signatureValid: false,
                payload: req.body,
            });
            return res.status(400).json({ message: 'No signature provided' });
        }

        if (!verifyWebhookSignature(webhookBody, signature)) {
            logger.warn('Invalid Razorpay webhook signature');
            void recordWebhookEvent({
                eventType,
                razorpaySubscriptionId: subscriptionId,
                signatureValid: false,
                payload: req.body,
            });
            return res.status(400).json({ message: 'Invalid signature' });
        }

        void recordWebhookEvent({
            eventType,
            razorpaySubscriptionId: subscriptionId,
            signatureValid: true,
            payload: req.body,
        });

        logger.info('Processing Razorpay webhook', { event: req.body.event });
        await handleRazorpayWebhook(req.body);
        res.status(200).json({ received: true });
    } catch (error: any) {
        logger.error('Error processing Razorpay webhook', error);
        res.status(500).json({ message: error.message });
    }
};
