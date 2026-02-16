import { supabase } from '../../config/supabase';
import { razorpay, getRazorpayKeyId } from '../../utils/razorpay';
import logger from '../../utils/logger';
import { Subscription } from '../../models/subscription.model';

const FREE_CONVERSATION_LIMIT = 3;
const SUBSCRIPTION_MONTH_DAYS = 30; // Billing cycle is monthly (30 days)
const GRACE_PERIOD_DAYS = 1; // 1 day grace period after subscription period ends for payment processing

/**
 * Check if user has active subscription for current month
 * Returns true if:
 * 1. User has conversation_count <= 3 (free tier)
 * 2. User has active subscription with valid last_charged_at within grace period
 */
export const hasActiveSubscription = async (userId: string): Promise<boolean> => {
    try {
        // First, check user's conversation count
        const { data: user, error: userError } = await supabase
            .from('users')
            .select('conversation_count')
            .eq('id', userId)
            .single();

        if (userError || !user) {
            logger.error('User not found', { user_id: userId, error: userError });
            return false;
        }

        // Free tier: allow if conversation_count <= 3
        if (user.conversation_count < FREE_CONVERSATION_LIMIT) {
            logger.info('User within free tier limit', { 
                user_id: userId, 
                conversation_count: user.conversation_count 
            });
            return true;
        }

        // If user has exceeded free tier, check for active subscription
        const { data: subscription, error: subError } = await supabase
            .from('subscriptions')
            .select('*')
            .eq('user_id', userId)
            .in('status', ['active', 'authenticated'])
            .order('created_at', { ascending: false })
            .limit(1)
            .single();

        if (subError || !subscription) {
            logger.info('No active subscription found', { user_id: userId });
            return false;
        }

        // Check if subscription has been charged recently
        if (!subscription.last_charged_at) {
            // Grace period: if subscription was created within the last 24 hours,
            // the user just paid but the charged webhook hasn't arrived yet
            const createdAt = new Date(subscription.created_at);
            const oneDayAgo = new Date();
            oneDayAgo.setDate(oneDayAgo.getDate() - 1);
            if (createdAt >= oneDayAgo) {
                logger.info('Subscription within new-purchase grace period', {
                    user_id: userId,
                    subscription_id: subscription.id,
                    created_at: subscription.created_at
                });
                return true;
            }
            logger.info('Subscription exists but never charged and grace period expired', {
                user_id: userId,
                subscription_id: subscription.id
            });
            return false;
        }

        // Calculate access period: one month from last_charged_at + 1 day grace period
        const lastChargedDate = new Date(subscription.last_charged_at * 1000);
        const accessEndDate = new Date(lastChargedDate);
        accessEndDate.setDate(accessEndDate.getDate() + SUBSCRIPTION_MONTH_DAYS + GRACE_PERIOD_DAYS);
        const now = new Date();

        // Check if we're within access period (month + grace period)
        if (now <= accessEndDate) {
            logger.info('User has active subscription within access period', { 
                user_id: userId, 
                last_charged_at: subscription.last_charged_at,
                access_end: accessEndDate.toISOString()
            });
            return true;
        }

        logger.info('Subscription access period expired', { 
            user_id: userId, 
            last_charged_at: subscription.last_charged_at,
            access_end: accessEndDate.toISOString()
        });
        return false;
    } catch (error) {
        logger.error('Error checking active subscription', { error, user_id: userId });
        return false;
    }
};

/**
 * Create a Razorpay subscription
 */
export const createSubscription = async (plan_id: string, user_id: string) => {
    try {
        logger.info('Creating subscription', { plan_id, user_id });
        
        // 1. Fetch plan details
        const { data: plan, error: planError } = await supabase
            .from('plans')
            .select('*')
            .eq('id', plan_id)
            .single();

        if (planError || !plan) {
            logger.error('Plan not found', { plan_id, error: planError });
            throw new Error('Plan not found');
        }

        if (!plan.razorpay_plan_id) {
            logger.error('Plan missing razorpay_plan_id', { plan_id });
            throw new Error('Plan missing Razorpay plan ID');
        }

        logger.info('Plan found', { plan_id, plan_name: plan.name, razorpay_plan_id: plan.razorpay_plan_id });
        
        // 2. Create Razorpay subscription
        // For 12 months subscription, total_count = 12
        const subscriptionOptions = {
            plan_id: plan.razorpay_plan_id,
            customer_notify: true,
            quantity: 1,
            total_count: 12, // 12 months
        };

        logger.info('Razorpay key ID', { razorpay_key_id: getRazorpayKeyId() });

        logger.info('Creating Razorpay subscription', { options: subscriptionOptions });
        const razorpaySubscription = await razorpay.subscriptions.create(subscriptionOptions);
        logger.info('Razorpay subscription created', { razorpay_subscription_id: razorpaySubscription.id });

        // 3. Store subscription in database
        const { data: newSubscription, error: subscriptionError } = await supabase
            .from('subscriptions')
            .insert({
                user_id,
                plan_id,
                razorpay_subscription_id: razorpaySubscription.id,
                status: razorpaySubscription.status as Subscription['status'],
                current_start: razorpaySubscription.current_start || null,
                current_end: razorpaySubscription.current_end || null,
                last_charged_at: null, // Will be updated when webhook is received
                charge_at: razorpaySubscription.charge_at || null,
                start_at: razorpaySubscription.start_at || null,
                end_at: razorpaySubscription.end_at || null,
                quantity: razorpaySubscription.quantity || 1,
                total_count: razorpaySubscription.total_count || 12,
                paid_count: razorpaySubscription.paid_count || 0,
            })
            .select()
            .single();

        if (subscriptionError) {
            logger.error('Error storing subscription', { error: subscriptionError, user_id, plan_id });
            throw subscriptionError;
        }

        logger.info('Subscription stored successfully', { 
            subscription_id: newSubscription.id, 
            razorpay_subscription_id: razorpaySubscription.id 
        });
        
        return {
            ...newSubscription,
            razorpay_subscription: razorpaySubscription,
            razorpay_key_id: getRazorpayKeyId(),
        };
    } catch (error) {
        logger.error('Error creating subscription', { error, plan_id, user_id });
        throw error;
    }
};

/**
 * Fetch subscription from Razorpay and update in database
 */
export const fetchAndUpdateSubscription = async (subscriptionId: string, userId: string) => {
    try {
        logger.info('Fetching subscription from Razorpay', { subscriptionId, userId });

        // Fetch from Razorpay
        const razorpaySubscription = await razorpay.subscriptions.fetch(subscriptionId);
        logger.info('Subscription fetched from Razorpay', { 
            subscription_id: subscriptionId,
            status: razorpaySubscription.status 
        });

        // Update in database
        const updateData: any = {
            status: razorpaySubscription.status as Subscription['status'],
            current_start: razorpaySubscription.current_start || null,
            current_end: razorpaySubscription.current_end || null,
            charge_at: razorpaySubscription.charge_at || null,
            start_at: razorpaySubscription.start_at || null,
            end_at: razorpaySubscription.end_at || null,
            quantity: razorpaySubscription.quantity || 1,
            total_count: razorpaySubscription.total_count || 12,
            paid_count: razorpaySubscription.paid_count || 0,
            updated_at: new Date().toISOString(),
        };

        // Update last_charged_at if subscription was charged
        if (razorpaySubscription.status === 'active' && razorpaySubscription.current_start) {
            // If current_start is recent, it might be the last charge
            // We'll rely on webhooks for accurate last_charged_at, but update if we have better info
            const { data: existingSub } = await supabase
                .from('subscriptions')
                .select('last_charged_at')
                .eq('razorpay_subscription_id', subscriptionId)
                .single();

            // Only update last_charged_at if we don't have it or if current_start is newer
            if (!existingSub?.last_charged_at || 
                (razorpaySubscription.current_start && 
                 razorpaySubscription.current_start > existingSub.last_charged_at)) {
                updateData.last_charged_at = razorpaySubscription.current_start;
            }
        }

        const { data: updatedSubscription, error: updateError } = await supabase
            .from('subscriptions')
            .update(updateData)
            .eq('razorpay_subscription_id', subscriptionId)
            .eq('user_id', userId)
            .select()
            .single();

        if (updateError) {
            logger.error('Error updating subscription in database', { 
                error: updateError, 
                subscription_id: subscriptionId 
            });
            throw updateError;
        }

        logger.info('Subscription updated in database', { subscription_id: subscriptionId });
        
        return {
            ...updatedSubscription,
            razorpay_subscription: razorpaySubscription,
        };
    } catch (error) {
        logger.error('Error fetching subscription', { error, subscriptionId, userId });
        throw error;
    }
};

/**
 * Cancel a subscription
 */
export const cancelSubscription = async (subscriptionId: string, userId: string) => {
    try {
        logger.info('Cancelling subscription', { subscriptionId, userId });

        // Cancel in Razorpay
        const razorpaySubscription = await razorpay.subscriptions.cancel(subscriptionId,true);
        logger.info('Subscription cancelled in Razorpay', { 
            subscription_id: subscriptionId,
            status: razorpaySubscription.status as Subscription['status']
        });

        // Update in database
        const { data: updatedSubscription, error: updateError } = await supabase
            .from('subscriptions')
            .update({
                status: razorpaySubscription.status as Subscription['status'],
                current_start: razorpaySubscription.current_start || null,
                current_end: razorpaySubscription.current_end || null,
                end_at: razorpaySubscription.end_at || null,
                updated_at: new Date().toISOString(),
            })
            .eq('razorpay_subscription_id', subscriptionId)
            .eq('user_id', userId)
            .select()
            .single();

        if (updateError) {
            logger.error('Error updating subscription in database', { 
                error: updateError, 
                subscription_id: subscriptionId 
            });
            throw updateError;
        }

        logger.info('Subscription cancelled and updated in database', { subscription_id: subscriptionId });
        
        return {
            ...updatedSubscription,
            razorpay_subscription: razorpaySubscription,
        };
    } catch (error) {
        logger.error('Error cancelling subscription', { error, subscriptionId, userId });
        throw error;
    }
};

/**
 * Get user's current subscription
 */
export const getUserSubscription = async (userId: string) => {
    try {
        logger.info('Fetching user subscription', { userId });

        const { data: subscription, error } = await supabase
            .from('subscriptions')
            .select('*, plans(*)')
            .eq('user_id', userId)
            .order('created_at', { ascending: false })
            .limit(1)
            .single();

        if (error && error.code !== 'PGRST116') { // PGRST116 is "not found"
            logger.error('Error fetching subscription', { error, userId });
            throw error;
        }

        return subscription || null;
    } catch (error) {
        logger.error('Error getting user subscription', { error, userId });
        throw error;
    }
};

/**
 * Increment user's conversation count
 */
export const incrementConversationCount = async (userId: string): Promise<number> => {
    try {
        // Fetch current count
        const { data: user, error: userError } = await supabase
            .from('users')
            .select('conversation_count')
            .eq('id', userId)
            .single();

        if (userError) {
            throw userError;
        }

        const newCount = (user.conversation_count || 0) + 1;
        
        const { error: updateError } = await supabase
            .from('users')
            .update({ conversation_count: newCount })
            .eq('id', userId);

        if (updateError) {
            throw updateError;
        }

        logger.info('Conversation count incremented', { userId, newCount });
        return newCount;
    } catch (error) {
        logger.error('Error incrementing conversation count', { error, userId });
        throw error;
    }
};

