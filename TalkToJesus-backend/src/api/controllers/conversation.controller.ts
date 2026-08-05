import { Response } from 'express';
import { AuthenticatedRequest } from '../middlewares/auth.middleware';
import { transcribeAudio } from '../services/stt.service';
import { callOpenAI } from '../services/openai.service';
import { generateSpeech } from '../services/elevenLabs.service';
import { getSystemPrompt } from '../../config/prompts';
import { hasActiveSubscription, incrementConversationCount } from '../services/subscription.service';
import { getFeatureFlags } from '../services/featureFlag.service';
import {
    logConversationTurn,
    getRecentTurns,
    getConversationHistory,
} from '../services/conversationLog.service';
import { ConversationInputMode } from '../../models/conversationLog.model';
import logger from '../../utils/logger';

/**
 * Shared pipeline for both voice and text input.
 *
 * `sttMs` is 0 for the text path — that difference is exactly what the admin
 * latency chart is meant to show.
 */
const generateReply = async (params: {
    userId: string;
    text: string;
    language: string;
    inputMode: ConversationInputMode;
    sttMs: number;
    startedAt: number;
    flags: Awaited<ReturnType<typeof getFeatureFlags>>;
}) => {
    const { userId, text, language, inputMode, sttMs, startedAt, flags } = params;

    const history = flags.multi_turn_enabled
        ? await getRecentTurns(userId, flags.multi_turn_window)
        : [];

    const systemPrompt = getSystemPrompt(language);

    logger.info('Getting AI response...', { userId, language, context_turns: history.length });
    const llmStart = Date.now();
    const aiResponse = await callOpenAI(text, systemPrompt, history);
    const llmMs = Date.now() - llmStart;
    logger.info('AI response received', { userId, response: aiResponse, llm_ms: llmMs });

    let audioData: string | null = null;
    let ttsMs = 0;

    if (flags.tts_enabled) {
        logger.info('Converting to speech...', { userId });
        const ttsStart = Date.now();
        audioData = await generateSpeech(aiResponse);
        ttsMs = Date.now() - ttsStart;
        logger.info('Speech generated', { userId, tts_ms: ttsMs, ok: Boolean(audioData) });
    } else {
        logger.info('TTS disabled by feature flag, returning text only', { userId });
    }

    const totalMs = Date.now() - startedAt;

    // Fire-and-forget: the reply is already assembled, logging must not delay
    // or fail the response.
    void logConversationTurn({
        user_id: userId,
        language,
        input_mode: inputMode,
        user_message: text,
        assistant_text: aiResponse,
        stt_ms: sttMs,
        llm_ms: llmMs,
        tts_ms: ttsMs,
        total_ms: totalMs,
    });

    return { aiResponse, audioData, totalMs };
};

export const sendMessageHandler = async (req: AuthenticatedRequest, res: Response) => {
    const startedAt = Date.now();

    try {
        const user = req.user;
        const audioFile = req.file;
        const language = req.body.language || 'en'; // Default to English if not provided

        if (!user) {
            return res.status(401).json({ message: 'Unauthorized' });
        }

        if (!audioFile) {
            return res.status(400).json({
                error: 'Audio file is required',
                message: 'Please provide an audio file in the request'
            });
        }

        const flags = await getFeatureFlags();

        if (flags.maintenance_mode) {
            return res.status(503).json({
                error: 'Maintenance mode',
                message: 'Talk to Jesus is briefly unavailable. Please try again in a few minutes.',
            });
        }

        // Check if user has active subscription or is within free tier
        const hasAccess = await hasActiveSubscription(user.id, flags.free_tier_limit);
        if (!hasAccess) {
            return res.status(402).json({
                error: 'Subscription required',
                message: 'You have exceeded the free tier limit. Please subscribe to continue talking to Jesus.',
            });
        }

        logger.info('Transcribing audio...', { userId: user.id, filename: audioFile.originalname, language });

        const sttStart = Date.now();
        let transcribedText: string;
        try {
            transcribedText = await transcribeAudio(audioFile.buffer, audioFile.originalname);
        } catch (transcriptionError: any) {
            logger.error('Transcription failed', { error: transcriptionError.message, userId: user.id });
            return res.status(400).json({
                error: 'Transcription failed',
                message: transcriptionError.message || 'Could not transcribe audio. Please try again.'
            });
        }
        const sttMs = Date.now() - sttStart;

        if (!transcribedText || transcribedText.trim().length === 0) {
            return res.status(400).json({
                error: 'Empty transcription',
                message: 'Could not transcribe audio. Please try again with clearer audio.'
            });
        }
        logger.info('Audio transcribed successfully', { userId: user.id, text: transcribedText, stt_ms: sttMs });

        const { aiResponse, audioData } = await generateReply({
            userId: user.id,
            text: transcribedText,
            language,
            inputMode: 'voice',
            sttMs,
            startedAt,
            flags,
        });

        if (flags.tts_enabled && !audioData) {
            return res.status(500).json({
                error: 'Failed to generate speech',
                assistant_text: aiResponse,
            });
        }

        // Increment conversation count after successful response
        logger.info('Incrementing conversation count...', { userId: user.id });
        const newConversationCount = await incrementConversationCount(user.id);
        logger.info('Conversation count incremented', {
            new_count: newConversationCount,
            userId: user.id
        });

        res.json({
            success: true,
            user_message: transcribedText,
            assistant_text: aiResponse,
            assistant_audio: audioData,
            conversation_count: newConversationCount,
        });

    } catch (error: any) {
        logger.error('Error in sendMessageHandler:', error);
        if (error.message.includes('Subscription required')) {
            return res.status(402).json({
                error: 'Subscription required',
                message: 'You have exceeded the free tier limit. Please subscribe to continue talking to Jesus.',
            });
        }
        res.status(500).json({
            error: 'Failed to process message',
            details: error.message,
        });
    }
};

/**
 * Text-input twin of sendMessageHandler. Skips Whisper entirely, which removes
 * roughly a third of the end-to-end latency and makes the feature usable in a
 * noisy room or on a bad microphone.
 */
export const sendTextMessageHandler = async (req: AuthenticatedRequest, res: Response) => {
    const startedAt = Date.now();

    try {
        const user = req.user;
        const language = req.body.language || 'en';
        const message = typeof req.body.message === 'string' ? req.body.message.trim() : '';

        if (!user) {
            return res.status(401).json({ message: 'Unauthorized' });
        }

        if (!message) {
            return res.status(400).json({
                error: 'Message is required',
                message: 'Please provide a non-empty message.',
            });
        }

        if (message.length > 2000) {
            return res.status(400).json({
                error: 'Message too long',
                message: 'Please keep your message under 2000 characters.',
            });
        }

        const flags = await getFeatureFlags();

        if (flags.maintenance_mode) {
            return res.status(503).json({
                error: 'Maintenance mode',
                message: 'Talk to Jesus is briefly unavailable. Please try again in a few minutes.',
            });
        }

        const hasAccess = await hasActiveSubscription(user.id, flags.free_tier_limit);
        if (!hasAccess) {
            return res.status(402).json({
                error: 'Subscription required',
                message: 'You have exceeded the free tier limit. Please subscribe to continue talking to Jesus.',
            });
        }

        const { aiResponse, audioData } = await generateReply({
            userId: user.id,
            text: message,
            language,
            inputMode: 'text',
            sttMs: 0,
            startedAt,
            flags,
        });

        const newConversationCount = await incrementConversationCount(user.id);

        res.json({
            success: true,
            user_message: message,
            assistant_text: aiResponse,
            assistant_audio: audioData,
            conversation_count: newConversationCount,
        });
    } catch (error: any) {
        logger.error('Error in sendTextMessageHandler:', error);
        res.status(500).json({
            error: 'Failed to process message',
            details: error.message,
        });
    }
};

export const getHistoryHandler = async (req: AuthenticatedRequest, res: Response) => {
    try {
        const user = req.user;
        if (!user) {
            return res.status(401).json({ message: 'Unauthorized' });
        }

        const page = Math.max(1, Number(req.query.page) || 1);
        const limit = Math.min(50, Math.max(1, Number(req.query.limit) || 20));

        const { data, count } = await getConversationHistory(user.id, page, limit);

        res.json({ data, count, page, limit });
    } catch (error: any) {
        logger.error('Error in getHistoryHandler:', error);
        res.status(500).json({
            error: 'Failed to fetch conversation history',
            details: error.message,
        });
    }
};
