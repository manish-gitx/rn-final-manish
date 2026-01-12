import axios from 'axios';
import FormData from 'form-data';
import logger from '../../utils/logger';

export const transcribeAudio = async (audioBuffer: Buffer, filename: string): Promise<string> => {
    try {
        const formData = new FormData();
        
        // Determine content type based on file extension
        let contentType = 'audio/wav';
        if (filename.toLowerCase().endsWith('.m4a')) {
            contentType = 'audio/mp4';
        } else if (filename.toLowerCase().endsWith('.mp3')) {
            contentType = 'audio/mpeg';
        } else if (filename.toLowerCase().endsWith('.webm')) {
            contentType = 'audio/webm';
        } else if (filename.toLowerCase().endsWith('.ogg')) {
            contentType = 'audio/ogg';
        }
        
        formData.append('file', audioBuffer, {
            filename: filename,
            contentType: contentType,
        });
        formData.append('model', 'whisper-1');
        // Removed language parameter - Whisper will auto-detect Telugu and other languages
        
        logger.info('Sending audio to Whisper API', { filename, contentType });

        const response = await axios.post('https://api.openai.com/v1/audio/transcriptions', formData, {
            headers: {
                'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`,
                ...formData.getHeaders(),
            },
        });

        if (response.status !== 200) {
            throw new Error(`Whisper API error: ${response.status} - ${response.statusText}`);
        }

        const transcribedText = response.data.text;
        logger.info('Audio transcribed successfully', { text: transcribedText });
        return transcribedText;

    } catch (error: any) {
        if (error.response?.data?.error) {
            const apiError = error.response.data.error;
            logger.error('OpenAI Whisper API error:', {
                code: apiError.code,
                message: apiError.message,
                type: apiError.type,
            });
            throw new Error(`Transcription failed: ${apiError.message}`);
        }
        logger.error('Error transcribing audio:', error.message);
        throw error;
    }
};
