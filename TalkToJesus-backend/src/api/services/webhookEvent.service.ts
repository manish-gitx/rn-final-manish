import { supabase } from '../../config/supabase';
import logger from '../../utils/logger';

/**
 * Audit trail of every Razorpay webhook we receive, including the ones whose
 * HMAC signature failed verification. Recording rejected payloads is the point:
 * it is the evidence that signature checking is actually running.
 *
 * Never throws — webhook delivery must not fail because auditing failed, or
 * Razorpay will retry a request we already processed.
 */
export const recordWebhookEvent = async (params: {
    eventType: string;
    razorpaySubscriptionId?: string | null;
    signatureValid: boolean;
    payload?: unknown;
}): Promise<void> => {
    try {
        const { error } = await supabase.from('webhook_events').insert({
            event_type: params.eventType,
            razorpay_subscription_id: params.razorpaySubscriptionId ?? null,
            signature_valid: params.signatureValid,
            payload: params.payload ?? null,
        });

        if (error) {
            logger.warn('Failed to record webhook event (non-fatal)', {
                error,
                event_type: params.eventType,
            });
        }
    } catch (error) {
        logger.warn('Unexpected error recording webhook event (non-fatal)', {
            error,
            event_type: params.eventType,
        });
    }
};

export const listWebhookEvents = async (page: number, limit: number) => {
    const from = (page - 1) * limit;
    const to = from + limit - 1;

    const { data, error, count } = await supabase
        .from('webhook_events')
        .select('id, event_type, razorpay_subscription_id, signature_valid, created_at', {
            count: 'exact',
        })
        .order('created_at', { ascending: false })
        .range(from, to);

    if (error) {
        logger.error('Error listing webhook events', { error, page, limit });
        throw error;
    }

    return { data, count };
};
