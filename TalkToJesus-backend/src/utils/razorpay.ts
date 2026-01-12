/**
 * Razorpay Utility Functions
 * 
 * This module provides Razorpay client initialization and webhook signature verification
 * for secure payment processing and webhook handling.
 * 
 * @fileoverview Razorpay integration utilities
 */

import Razorpay from 'razorpay';
import crypto from 'crypto';
import logger from './logger';
import dotenv from 'dotenv';

dotenv.config();

// Determine environment
const isProduction = process.env.NODE_ENV === 'production';

// Use environment-specific Razorpay credentials
const key_id = isProduction 
    ? process.env.RAZORPAY_KEY_ID_PROD 
    : process.env.RAZORPAY_KEY_ID_DEV;

const key_secret = isProduction 
    ? process.env.RAZORPAY_KEY_SECRET_PROD 
    : process.env.RAZORPAY_KEY_SECRET_DEV;

const webhook_secret = isProduction 
    ? process.env.RAZORPAY_WEBHOOK_SECRET_PROD 
    : process.env.RAZORPAY_WEBHOOK_SECRET_DEV;

if (!key_id || !key_secret) {
    const envType = isProduction ? 'production' : 'development';
    throw new Error(`Razorpay Key ID and Key Secret must be provided for ${envType} environment variables`);
}

if (!webhook_secret) {
    const envType = isProduction ? 'production' : 'development';
    throw new Error(`Razorpay Webhook Secret must be provided for ${envType} environment`);
}

logger.info('Initializing Razorpay client', { 
    environment: process.env.NODE_ENV,
    isProduction,
    key_id_prefix: key_id?.substring(0, 8) // Log first 8 chars for debugging
});

/**
 * Razorpay Client Instance
 * 
 * Initialized Razorpay client with API credentials from environment variables.
 * Uses different credentials for production and development environments.
 * Used for creating orders, processing payments, and other Razorpay operations.
 */
export const razorpay = new Razorpay({
    key_id,
    key_secret,
});

/**
 * RazorpayX Client Instance
 * 
 * Initialized RazorpayX client, a sub-product of Razorpay, for handling payouts.
 * Uses the same API credentials as the main Razorpay client.
 */
export const razorpayX = new Razorpay({
    key_id,
    key_secret,
});

/**
 * Get current Razorpay Key ID
 * Useful for returning to frontend clients
 */
export const getRazorpayKeyId = (): string => {
    return key_id;
};

/**
 * Verify Razorpay Webhook Signature
 * 
 * Verifies the authenticity of incoming webhook requests from Razorpay
 * using HMAC SHA256 signature verification.
 * 
 * @param webhookBody - Raw webhook request body as string
 * @param signature - Razorpay signature from X-Razorpay-Signature header
 * @returns boolean indicating if signature is valid
 */
export function verifyWebhookSignature(webhookBody: string, signature: string): boolean {
    try {
        logger.info('Verifying Razorpay webhook signature');
        
        // Create HMAC SHA256 hash
        const expectedSignature = crypto
            .createHmac('sha256', webhook_secret!)
            .update(webhookBody)
            .digest('hex');
        
        // Compare signatures using crypto.timingSafeEqual for security
        const providedSignature = Buffer.from(signature, 'utf8');
        const expectedSignatureBuffer = Buffer.from(expectedSignature, 'utf8');
        
        // Ensure both signatures are the same length to prevent timing attacks
        if (providedSignature.length !== expectedSignatureBuffer.length) {
            logger.warn('Webhook signature length mismatch');
            return false;
        }
        
        const isValid = crypto.timingSafeEqual(providedSignature, expectedSignatureBuffer);
        
        if (isValid) {
            logger.info('Webhook signature verified successfully');
        } else {
            logger.warn('Invalid webhook signature');
            logger.warn(`Provided signature: ${signature}`);
            logger.warn(`Expected signature: ${expectedSignature}`);
        }
        
        return isValid;
    } catch (error) {
        logger.error('Error verifying webhook signature', error);
        return false;
    }
}
