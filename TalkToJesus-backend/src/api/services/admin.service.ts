import { supabase } from '../../config/supabase';
import logger from '../../utils/logger';
import { getRazorpayKeyId } from '../../utils/razorpay';

const SERVER_STARTED_AT = Date.now();

/**
 * Paginated user list with subscription status joined in.
 * Pagination mirrors getSongs in song.service.ts.
 */
export const listUsers = async (page: number, limit: number, search?: string) => {
    const from = (page - 1) * limit;
    const to = from + limit - 1;

    let query = supabase
        .from('users')
        .select(
            'id, email, display_name, photo_url, conversation_count, is_admin, created_at, last_login_at',
            { count: 'exact' }
        );

    if (search) {
        query = query.ilike('email', `%${search}%`);
    }

    const { data, error, count } = await query
        .order('created_at', { ascending: false })
        .range(from, to);

    if (error) {
        logger.error('Error listing users', { error, page, limit, search });
        throw error;
    }

    const users = data ?? [];
    if (users.length === 0) {
        return { data: users, count };
    }

    // Single follow-up query for all subscriptions on this page rather than
    // one per user.
    const { data: subs, error: subError } = await supabase
        .from('subscriptions')
        .select('user_id, status, last_charged_at, plans(name, price)')
        .in(
            'user_id',
            users.map((u: any) => u.id)
        );

    if (subError) {
        logger.warn('Could not join subscriptions onto user list', { error: subError });
    }

    const byUser = new Map<string, any>();
    for (const sub of (subs ?? []) as any[]) {
        const existing = byUser.get(sub.user_id);
        // Prefer an active row if the user has more than one.
        if (!existing || (sub.status === 'active' && existing.status !== 'active')) {
            byUser.set(sub.user_id, sub);
        }
    }

    return {
        data: users.map((user: any) => ({
            ...user,
            subscription: byUser.get(user.id) ?? null,
        })),
        count,
    };
};

export interface UpdateUserInput {
    is_admin?: boolean;
    conversation_count?: number;
}

export const updateUser = async (userId: string, updates: UpdateUserInput) => {
    const { data, error } = await supabase
        .from('users')
        .update(updates)
        .eq('id', userId)
        .select('id, email, display_name, conversation_count, is_admin')
        .single();

    if (error) {
        logger.error('Error updating user', { error, userId, updates });
        throw error;
    }

    logger.info('Admin updated user', { userId, updates });
    return data;
};

export const listSongs = async (page: number, limit: number, search?: string) => {
    const from = (page - 1) * limit;
    const to = from + limit - 1;

    let query = supabase.from('songs').select('*', { count: 'exact' });
    if (search) {
        query = query.ilike('title', `%${search}%`);
    }

    const { data, error, count } = await query
        .order('created_at', { ascending: false })
        .range(from, to);

    if (error) {
        logger.error('Error listing songs for admin', { error });
        throw error;
    }

    return { data, count };
};

export interface SongInput {
    title: string;
    duration: string;
    image_url: string;
    audio_url: string;
}

export const createSong = async (song: SongInput) => {
    const { data, error } = await supabase.from('songs').insert(song).select('*').single();

    if (error) {
        logger.error('Error creating song', { error, song });
        throw error;
    }

    logger.info('Admin created song', { id: data?.id, title: song.title });
    return data;
};

export const updateSong = async (id: string, updates: Partial<SongInput>) => {
    const { data, error } = await supabase
        .from('songs')
        .update(updates)
        .eq('id', id)
        .select('*')
        .single();

    if (error) {
        logger.error('Error updating song', { error, id, updates });
        throw error;
    }

    logger.info('Admin updated song', { id });
    return data;
};

export const deleteSong = async (id: string) => {
    const { error } = await supabase.from('songs').delete().eq('id', id);

    if (error) {
        logger.error('Error deleting song', { error, id });
        throw error;
    }

    logger.info('Admin deleted song', { id });
};

export const listConversations = async (page: number, limit: number) => {
    const from = (page - 1) * limit;
    const to = from + limit - 1;

    const { data, error, count } = await supabase
        .from('conversation_logs')
        .select(
            'id, user_id, language, input_mode, user_message, assistant_text, stt_ms, llm_ms, tts_ms, total_ms, created_at',
            { count: 'exact' }
        )
        .order('created_at', { ascending: false })
        .range(from, to);

    if (error) {
        logger.error('Error listing conversations for admin', { error });
        throw error;
    }

    return { data, count };
};

/**
 * Backend liveness plus a real Supabase round-trip. The db_ping_ms number is
 * what makes a Cloud Run cold start visible on the dashboard.
 */
export const getHealth = async () => {
    const dbStart = Date.now();
    let dbOk = true;
    try {
        const { error } = await supabase.from('users').select('id', { head: true, count: 'exact' });
        if (error) dbOk = false;
    } catch {
        dbOk = false;
    }
    const dbPingMs = Date.now() - dbStart;

    return {
        status: dbOk ? 'healthy' : 'degraded',
        version: '1.0.0',
        node_version: process.version,
        environment: process.env.NODE_ENV || 'development',
        uptime_seconds: Math.round((Date.now() - SERVER_STARTED_AT) / 1000),
        process_uptime_seconds: Math.round(process.uptime()),
        memory_mb: Math.round(process.memoryUsage().rss / 1024 / 1024),
        database: { ok: dbOk, ping_ms: dbPingMs },
        razorpay_key_id: getRazorpayKeyId(),
        integrations: {
            openai: Boolean(process.env.OPENAI_API_KEY),
            elevenlabs: Boolean(process.env.ELEVENLABS_API_KEY),
            supabase: Boolean(process.env.SUPABASE_URL),
        },
        timestamp: new Date().toISOString(),
    };
};

export const recordAuditEntry = async (params: {
    adminUserId: string;
    adminEmail: string;
    action: string;
    target?: string;
    meta?: unknown;
}): Promise<void> => {
    try {
        await supabase.from('admin_audit_log').insert({
            admin_user_id: params.adminUserId,
            admin_email: params.adminEmail,
            action: params.action,
            target: params.target ?? null,
            meta: params.meta ?? null,
        });
    } catch (error) {
        logger.warn('Failed to write admin audit entry (non-fatal)', { error, action: params.action });
    }
};

export const listAuditLog = async (limit: number) => {
    const { data, error } = await supabase
        .from('admin_audit_log')
        .select('id, admin_email, action, target, meta, created_at')
        .order('created_at', { ascending: false })
        .limit(limit);

    if (error) {
        logger.error('Error listing audit log', { error });
        throw error;
    }

    return data;
};
