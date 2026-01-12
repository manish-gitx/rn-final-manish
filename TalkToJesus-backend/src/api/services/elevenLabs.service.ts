import axios from 'axios';
import logger from '../../utils/logger';

function addEmotionalTags(text: string): string {
    if (!text) return text;

    const hasExistingTags = /\[(gentle|warmly|soothing|confidently|reverently|encouragingly|authoritative|compassionate|loving|prayerful|encouraging|gently|caringly|peacefully|hopefully)\]/i.test(text);

    if (hasExistingTags) {
        return text;
    }

    const defaultTags = {
        compassionate: '[gentle]',
        loving: '[warmly]',
        comforting: '[soothing]',
        authoritative: '[confidently]',
        prayerful: '[reverently]',
         reverently: '[reverently]',
        encouraging: '[encouragingly]',
        gentle: '[gently]',
        caring: '[caringly]',
        peaceful: '[peacefully]',
        hopeful: '[hopefully]',
    };

    let emotionalTags = [];

    if (text.includes('ప్రేమ') || text.includes('ప్రియుడా') || text.includes('బిడ్డ')) {
        emotionalTags.push(defaultTags.loving, defaultTags.caring);
    }
    if (text.includes('ఆదరించు') || text.includes('ఆదుకో') || text.includes('సాంత్వన')) {
        emotionalTags.push(defaultTags.compassionate, defaultTags.gentle);
    }
    if (text.includes('ప్రార్థన') || text.includes('దీవెన') || text.includes('ఆశీర్వాద')) {
        emotionalTags.push(defaultTags.prayerful, defaultTags.reverently);
    }
    if (text.includes('ధైర్యం') || text.includes('ఆశ') || text.includes('ఉత్సాహ')) {
        emotionalTags.push(defaultTags.encouraging, defaultTags.hopeful);
    }

    if (emotionalTags.length === 0) {
        emotionalTags.push(defaultTags.loving, defaultTags.compassionate);
    }

    const tagsString = emotionalTags.join(' ');
    return `${tagsString} ${text}`;
}

export const generateSpeech = async (text: string): Promise<string | null> => {
    try {
        if (!process.env.ELEVENLABS_API_KEY) {
            logger.warn('ElevenLabs API key not configured, skipping TTS');
            return null;
        }

        const voiceId = process.env.ELEVENLABS_VOICE_ID;
        const model = process.env.ELEVENLABS_MODEL || 'eleven_multilingual_v2';
        
        const processedText = addEmotionalTags(text);
        
        logger.info('Generating speech with ElevenLabs...');

        const response = await axios.post(`https://api.elevenlabs.io/v1/text-to-speech/${voiceId}`, {
            text: processedText,
            model_id: model,
            voice_settings: {
                stability: 0.5,
                similarity_boost: 0.5,
                style: 0.6,
                use_speaker_boost: true,
            },
        }, {
            headers: {
                'Accept': 'audio/mpeg',
                'Content-Type': 'application/json',
                'xi-api-key': process.env.ELEVENLABS_API_KEY,
            },
            responseType: 'arraybuffer',
        });
        
        if (response.status !== 200) {
            throw new Error(`ElevenLabs API error: ${response.status} - ${response.statusText}`);
        }
        
        const audioBase64 = Buffer.from(response.data).toString('base64');
        logger.info('Speech generated successfully');
        return `data:audio/mpeg;base64,${audioBase64}`;

    } catch (error: any) {
        logger.error('Error generating speech:', error.message);
        return null;
    }
};
