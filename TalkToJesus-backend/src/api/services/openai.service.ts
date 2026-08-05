import axios from 'axios';
import logger from '../../utils/logger';

export interface ConversationTurn {
    user_message: string | null;
    assistant_text: string | null;
}

/**
 * @param history Prior turns, oldest first. Passing these makes the assistant
 *                coherent across a session instead of answering each question
 *                in isolation.
 */
export const callOpenAI = async (
    message: string,
    systemPrompt: string,
    history: ConversationTurn[] = []
): Promise<string> => {
    try {
        const priorMessages = history.flatMap((turn) => {
            const pair: Array<{ role: string; content: string }> = [];
            if (turn.user_message) pair.push({ role: 'user', content: turn.user_message });
            if (turn.assistant_text) pair.push({ role: 'assistant', content: turn.assistant_text });
            return pair;
        });

        const messages = [
            { role: 'system', content: systemPrompt },
            ...priorMessages,
            { role: 'user', content: message },
        ];

        if (priorMessages.length > 0) {
            logger.info('Including conversation context', { prior_messages: priorMessages.length });
        }

        const requestBody = {
            model: process.env.OPENAI_MODEL || 'gpt-4o',
            max_tokens: Number(process.env.OPENAI_MAX_TOKENS) || 800,
            temperature: Number(process.env.OPENAI_TEMPERATURE) || 0.7,
            messages: messages,
        };

        const response = await axios.post('https://api.openai.com/v1/chat/completions', requestBody, {
            headers: {
                'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`,
                'Content-Type': 'application/json',
            },
        });

        if (response.status !== 200) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        if (response.data.usage) {
            logger.info('OpenAI usage:', {
                promptTokens: response.data.usage.prompt_tokens,
                completionTokens: response.data.usage.completion_tokens,
                totalTokens: response.data.usage.total_tokens,
            });
        }

        return response.data?.choices?.[0]?.message?.content || 'No response from OpenAI API';

    } catch (error) {
        logger.error('Error calling OpenAI API:', error);
        throw error;
    }
};
