import { supabase } from '../../config/supabase';
import logger from '../../utils/logger';
import { Subscription } from '../../models/subscription.model';

export const handleRazorpayWebhook = async (payload: any) => {
    try {
        const event = payload.event;
        logger.info('Processing Razorpay webhook', { event });
        
        // Handle subscription events
        if (event.startsWith('subscription.')) {
            await handleSubscriptionWebhook(event, payload);
            return;
        }

        // Handle other events if needed
        logger.info('Ignoring non-subscription webhook event', { event });
    } catch (error) {
        logger.error('Error processing Razorpay webhook', { error, payload });
        throw error;
    }
};

/**
 * Handle subscription-related webhook events
 */
const handleSubscriptionWebhook = async (event: string, payload: any) => {
    try {
        // Razorpay webhook structure: { event: "...", payload: { subscription: { entity: {...} } } }
        const subscription = payload.payload?.subscription?.entity || payload.payload?.subscription;
        
        if (!subscription || !subscription.id) {
            logger.error('Subscription data missing in webhook payload', { 
                event, 
                payload_keys: Object.keys(payload),
                payload_payload_keys: payload.payload ? Object.keys(payload.payload) : 'no payload'
            });
            return;
        }

        const subscriptionId = subscription.id;
        logger.info('Processing subscription webhook', { 
            event, 
            subscription_id: subscriptionId,
            status: subscription.status 
        });

        // Find subscription in database
        const { data: dbSubscription, error: subError } = await supabase
            .from('subscriptions')
            .select('*')
            .eq('razorpay_subscription_id', subscriptionId)
            .single();

        if (subError || !dbSubscription) {
            logger.error('Subscription not found in database', { 
                subscription_id: subscriptionId, 
                error: subError 
            });
            // Don't throw - subscription might be created externally
            return;
        }

        // Prepare update data
        const updateData: any = {
            status: subscription.status as Subscription['status'],
            current_start: subscription.current_start || null,
            current_end: subscription.current_end || null,
            charge_at: subscription.charge_at || null,
            start_at: subscription.start_at || null,
            end_at: subscription.end_at || null,
            quantity: subscription.quantity || 1,
            total_count: subscription.total_count || 12,
            paid_count: subscription.paid_count || 0,
            updated_at: new Date().toISOString(),
        };

        // Handle specific events
        switch (event) {
            case 'subscription.charged':
                // This is the most important event - update last_charged_at
                logger.info('Subscription charged event received', { 
                    subscription_id: subscriptionId,
                    current_start: subscription.current_start 
                });
                
                // For subscription.charged, we can also check if there's an invoice in the payload
                // The charge time is typically when current_start is set (billing cycle start)
                // Use current_start as it represents when the billing period started (when charged)
                const chargeTime = subscription.current_start || Math.floor(Date.now() / 1000);
                updateData.last_charged_at = chargeTime;
                
                logger.info('Updating subscription last_charged_at', { 
                    subscription_id: subscriptionId,
                    last_charged_at: chargeTime,
                    current_start: subscription.current_start
                });
                break;

            case 'subscription.authenticated':
                logger.info('Subscription authenticated', { subscription_id: subscriptionId });
                // First payment made, might be upfront charge
                if (subscription.current_start) {
                    updateData.last_charged_at = subscription.current_start;
                }
                break;

            case 'subscription.activated':
                logger.info('Subscription activated', { subscription_id: subscriptionId });
                break;

            case 'subscription.pending':
                logger.info('Subscription pending (payment failed)', { subscription_id: subscriptionId });
                break;

            case 'subscription.halted':
                logger.info('Subscription halted (all retries exhausted)', { subscription_id: subscriptionId });
                break;

            case 'subscription.cancelled':
                logger.info('Subscription cancelled', { subscription_id: subscriptionId });
                updateData.end_at = subscription.end_at || subscription.ended_at || null;
                break;

            case 'subscription.completed':
                logger.info('Subscription completed', { subscription_id: subscriptionId });
                break;

            case 'subscription.paused':
                logger.info('Subscription paused', { subscription_id: subscriptionId });
                break;

            case 'subscription.resumed':
                logger.info('Subscription resumed', { subscription_id: subscriptionId });
                break;

            case 'subscription.updated':
                logger.info('Subscription updated', { subscription_id: subscriptionId });
                break;

            default:
                logger.info('Unhandled subscription event', { event, subscription_id: subscriptionId });
        }

        // Update subscription in database
        const { error: updateError } = await supabase
            .from('subscriptions')
            .update(updateData)
            .eq('razorpay_subscription_id', subscriptionId);

        if (updateError) {
            logger.error('Error updating subscription in database', { 
                error: updateError, 
                subscription_id: subscriptionId 
            });
            throw updateError;
        }

        logger.info('Subscription updated successfully in database', { 
            subscription_id: subscriptionId,
            event,
            status: subscription.status 
        });

    } catch (error) {
        logger.error('Error handling subscription webhook', { error, event, payload });
        throw error;
    }
};

