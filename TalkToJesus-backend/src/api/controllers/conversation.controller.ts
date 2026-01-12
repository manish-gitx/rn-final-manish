import { Response } from 'express';
import { AuthenticatedRequest } from '../middlewares/auth.middleware';
import { transcribeAudio } from '../services/stt.service';
import { callOpenAI } from '../services/openai.service';
import { generateSpeech } from '../services/elevenLabs.service';
import { getSystemPrompt } from '../../config/prompts';
import { hasActiveSubscription, incrementConversationCount } from '../services/subscription.service';
import logger from '../../utils/logger';

export const sendMessageHandler = async (req: AuthenticatedRequest, res: Response) => {
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

        // Check if user has active subscription or is within free tier
        const hasAccess = await hasActiveSubscription(user.id);
        if (!hasAccess) {
            return res.status(402).json({
                error: 'Subscription required',
                message: 'You have exceeded the free tier limit. Please subscribe to continue talking to Jesus.',
            });
        }

        logger.info('Transcribing audio...', { userId: user.id, filename: audioFile.originalname, language });
        
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

        if (!transcribedText || transcribedText.trim().length === 0) {
            return res.status(400).json({ 
                error: 'Empty transcription',
                message: 'Could not transcribe audio. Please try again with clearer audio.'
            });
        }
        logger.info('Audio transcribed successfully', { userId: user.id, text: transcribedText });

        const systemPrompt = getSystemPrompt(language);

        logger.info('Getting AI response...', { userId: user.id, language });
        const aiResponse = await callOpenAI(transcribedText, systemPrompt);
        logger.info('AI response received', { userId: user.id, response: aiResponse });

        logger.info('Converting to speech...', { userId: user.id });
        const audioData = await generateSpeech(aiResponse);

        if (!audioData) {
            return res.status(500).json({
                error: 'Failed to generate speech',
                assistant_text: aiResponse,
            });
        }
        logger.info('Speech generated successfully', { userId: user.id });
        
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
