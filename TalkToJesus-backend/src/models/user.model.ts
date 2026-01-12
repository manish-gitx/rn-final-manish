export interface User {
    id: string; // uuid
    email: string;
    display_name: string | null;
    photo_url: string | null;
    conversation_count: number; // Number of conversations user has had
    created_at: string; // timestamp
    last_login_at: string; // timestamp
}
