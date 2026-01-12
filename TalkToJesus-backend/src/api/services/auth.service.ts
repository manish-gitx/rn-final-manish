import { OAuth2Client } from 'google-auth-library';
import { supabase } from '../../config/supabase';
import { signToken } from '../../utils/jwt';
import logger from '../../utils/logger';
import dotenv from 'dotenv';

dotenv.config();

// Multiple client IDs for different platforms
const clientIds = [
    process.env.GOOGLE_CLIENT_ID_WEB!,
    process.env.GOOGLE_CLIENT_ID_IOS!,
    process.env.GOOGLE_CLIENT_ID_ANDROID!,
].filter(Boolean); // Remove any undefined values

export const createOrGetUser = async (token: string): Promise<{ user: any; token: string }> => {
    try {
        logger.info('Starting user creation or retrieval process');
        
        // Try to verify token with any of the client IDs
        let payload: any = null;
        let verifiedClientId: string | null = null;

        for (const clientId of clientIds) {
            try {
                const client = new OAuth2Client(clientId);
                const ticket = await client.verifyIdToken({
                    idToken: token,
                    audience: clientId,
                });
                payload = ticket.getPayload();

                if (payload && payload.email) {
                    verifiedClientId = clientId;
                    logger.info('Token verified as Google Sign In', { clientId, email: payload.email });
                    break;
                }
            } catch (error) {
                // Try next client ID
                continue;
            }
        }

        if (!payload || !payload.email) {
            logger.warn('Invalid Google token - could not verify with any client ID');
            throw new Error('Invalid Google token');
        }

        const { email, name, picture, sub } = payload;
        logger.info('Google token verified successfully', { email, providerId: sub });

        let { data: user, error } = await supabase
            .from('users')
            .select('*')
            .eq('email', email)
            .single();

        if (error && error.code !== 'PGRST116') { // PGRST116: no rows found
            logger.error('Database error while fetching user', { error, email });
            throw error;
        }

        if (user) {
            logger.info('Existing user found, updating last login', { userId: user.id, email });
            // User exists, update last_login_at
            const { error: updateError } = await supabase
                .from('users')
                .update({ last_login_at: new Date() })
                .eq('id', user.id);

            if (updateError) {
                logger.error('Error updating user last login', { error: updateError, userId: user.id });
                throw updateError;
            }

            // Fetch updated user
            const { data: updatedUser } = await supabase
                .from('users')
                .select('*')
                .eq('id', user.id)
                .single();

            if (updatedUser) {
                user = updatedUser;
            }
        } else {
            logger.info('Creating new user', { email });
            // User does not exist, create a new one
            const { data: newUser, error: createError } = await supabase
                .from('users')
                .insert({
                    email,
                    display_name: name,
                    photo_url: picture,
                    last_login_at: new Date(),
                })
                .select()
                .single();

            if (createError) {
                logger.error('Error creating new user', { error: createError, email });
                throw createError;
            }
            user = newUser;
            logger.info('New user created successfully', { userId: user.id, email });
        }

        if (!user) {
            logger.error('Failed to create or find user', { email });
            throw new Error('Failed to create or find user');
        }

        // Sign and return custom JWT with user
        const jwt = signToken({ userId: user.id });
        logger.info('JWT token generated successfully', { userId: user.id });
        
        return { user, token: jwt };
    } catch (error) {
        logger.error('Error in createOrGetUser', error);
        throw error;
    }
};
