export type ConversationInputMode = 'voice' | 'text';

export interface ConversationLog {
    id: string; // uuid
    user_id: string; // uuid
    language: string; // 'en' | 'te'
    input_mode: ConversationInputMode;
    user_message: string | null;
    assistant_text: string | null;
    stt_ms: number | null;
    llm_ms: number | null;
    tts_ms: number | null;
    total_ms: number | null;
    created_at: string; // timestamp
}

export interface ConversationTurnInput {
    user_id: string;
    language: string;
    input_mode: ConversationInputMode;
    user_message: string;
    assistant_text: string;
    stt_ms?: number;
    llm_ms?: number;
    tts_ms?: number;
    total_ms?: number;
}
