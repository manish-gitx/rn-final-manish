import { supabase } from '../../config/supabase';
import logger from '../../utils/logger';
import { ConversationLog, ConversationTurnInput } from '../../models/conversationLog.model';

/**
 * Persist one completed conversation turn.
 *
 * Deliberately never throws: the user already has their answer by the time this
 * runs, so a logging failure must not turn a successful conversation into a 500.
 * Callers should NOT await this on the request path.
 */
export const logConversationTurn = async (turn: ConversationTurnInput): Promise<void> => {
    try {
        const { error } = await supabase.from('conversation_logs').insert({
            user_id: turn.user_id,
            language: turn.language,
            input_mode: turn.input_mode,
            user_message: turn.user_message,
            assistant_text: turn.assistant_text,
            stt_ms: turn.stt_ms ?? null,
            llm_ms: turn.llm_ms ?? null,
            tts_ms: turn.tts_ms ?? null,
            total_ms: turn.total_ms ?? null,
        });

        if (error) {
            logger.warn('Failed to write conversation log (non-fatal)', {
                error,
                user_id: turn.user_id,
            });
            return;
        }

        logger.info('Conversation turn logged', {
            user_id: turn.user_id,
            language: turn.language,
            input_mode: turn.input_mode,
            total_ms: turn.total_ms,
        });
    } catch (error) {
        logger.warn('Unexpected error writing conversation log (non-fatal)', {
            error,
            user_id: turn.user_id,
        });
    }
};

/**
 * Most recent turns for a user, oldest-first, for use as LLM context.
 *
 * Returns an empty array on any failure so a context lookup can never break a
 * conversation — the user just gets a single-turn reply instead.
 */
export const getRecentTurns = async (
    userId: string,
    limit: number
): Promise<Array<Pick<ConversationLog, 'user_message' | 'assistant_text'>>> => {
    try {
        if (limit <= 0) return [];

        const { data, error } = await supabase
            .from('conversation_logs')
            .select('user_message, assistant_text')
            .eq('user_id', userId)
            .order('created_at', { ascending: false })
            .limit(limit);

        if (error || !data) {
            logger.warn('Failed to load conversation context (non-fatal)', { error, user_id: userId });
            return [];
        }

        // Query is newest-first for the index; the LLM needs oldest-first.
        return data.reverse();
    } catch (error) {
        logger.warn('Unexpected error loading conversation context (non-fatal)', {
            error,
            user_id: userId,
        });
        return [];
    }
};

/**
 * Paginated conversation history for the signed-in user.
 * Mirrors the pagination shape used by getSongs.
 */
export const getConversationHistory = async (userId: string, page: number, limit: number) => {
    try {
        const from = (page - 1) * limit;
        const to = from + limit - 1;

        const { data, error, count } = await supabase
            .from('conversation_logs')
            .select('id, language, input_mode, user_message, assistant_text, total_ms, created_at', {
                count: 'exact',
            })
            .eq('user_id', userId)
            .order('created_at', { ascending: false })
            .range(from, to);

        if (error) {
            logger.error('Error fetching conversation history', { error, user_id: userId, page, limit });
            throw error;
        }

        logger.info('Conversation history fetched', {
            user_id: userId,
            count: data?.length || 0,
            total_count: count,
            page,
        });

        return { data, count };
    } catch (error) {
        logger.error('Error in getConversationHistory service', { error, user_id: userId });
        throw error;
    }
};
