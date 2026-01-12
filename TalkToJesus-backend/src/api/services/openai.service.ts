import axios from 'axios';
import logger from '../../utils/logger';

export const callOpenAI = async (message: string, systemPrompt: string): Promise<string> => {
    try {
        const messages = [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: message },
        ];

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
