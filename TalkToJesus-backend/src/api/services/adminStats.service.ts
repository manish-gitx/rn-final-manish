import { supabase } from '../../config/supabase';
import logger from '../../utils/logger';

const ACTIVE_STATUSES = ['active', 'authenticated'];

/** Percentile from an unsorted numeric array. Returns null for an empty set. */
export const percentile = (values: number[], p: number): number | null => {
    if (values.length === 0) return null;
    const sorted = [...values].sort((a, b) => a - b);
    const rank = (p / 100) * (sorted.length - 1);
    const lower = Math.floor(rank);
    const upper = Math.ceil(rank);
    if (lower === upper) return Math.round(sorted[lower]);
    return Math.round(sorted[lower] + (rank - lower) * (sorted[upper] - sorted[lower]));
};

/** Monthly recurring revenue in rupees. Plan prices are stored in paise. */
export const computeMrrRupees = (
    subscriptions: Array<{ plans?: { price?: number | null } | null }>
): number => {
    const paise = subscriptions.reduce((sum, sub) => sum + (sub.plans?.price ?? 0), 0);
    return Math.round(paise / 100);
};

export const computeConversionRate = (totalUsers: number, payingUsers: number): number => {
    if (totalUsers === 0) return 0;
    return Math.round((payingUsers / totalUsers) * 1000) / 10; // one decimal place
};

export const getOverview = async () => {
    try {
        const [usersRes, convoRes, subsRes, latencyRes] = await Promise.all([
            supabase.from('users').select('id', { count: 'exact', head: true }),
            supabase.from('conversation_logs').select('id', { count: 'exact', head: true }),
            supabase
                .from('subscriptions')
                .select('user_id, status, plans(price)')
                .in('status', ACTIVE_STATUSES),
            supabase
                .from('conversation_logs')
                .select('total_ms')
                .not('total_ms', 'is', null)
                .order('created_at', { ascending: false })
                .limit(500),
        ]);

        const totalUsers = usersRes.count ?? 0;
        const totalConversations = convoRes.count ?? 0;
        const activeSubs = (subsRes.data ?? []) as any[];

        // One user could in principle hold more than one active subscription row.
        const payingUsers = new Set(activeSubs.map((s) => s.user_id)).size;

        const latencies = (latencyRes.data ?? [])
            .map((row: any) => row.total_ms)
            .filter((ms: unknown): ms is number => typeof ms === 'number');

        const avgLatencyMs =
            latencies.length > 0
                ? Math.round(latencies.reduce((a: number, b: number) => a + b, 0) / latencies.length)
                : null;

        return {
            total_users: totalUsers,
            total_conversations: totalConversations,
            active_subscriptions: activeSubs.length,
            paying_users: payingUsers,
            mrr_rupees: computeMrrRupees(activeSubs),
            conversion_rate_pct: computeConversionRate(totalUsers, payingUsers),
            avg_latency_ms: avgLatencyMs,
        };
    } catch (error) {
        logger.error('Error building admin overview', { error });
        throw error;
    }
};

/** Conversations and signups per day for the last `days` days, zero-filled. */
export const getTimeseries = async (days: number) => {
    try {
        const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString();

        const [convoRes, userRes] = await Promise.all([
            supabase.from('conversation_logs').select('created_at').gte('created_at', since),
            supabase.from('users').select('created_at').gte('created_at', since),
        ]);

        const bucket = (rows: Array<{ created_at: string }> | null) => {
            const counts = new Map<string, number>();
            for (const row of rows ?? []) {
                const day = new Date(row.created_at).toISOString().slice(0, 10);
                counts.set(day, (counts.get(day) ?? 0) + 1);
            }
            return counts;
        };

        const conversationCounts = bucket(convoRes.data as any);
        const signupCounts = bucket(userRes.data as any);

        // Zero-fill so the chart shows quiet days instead of collapsing them.
        const series: Array<{ date: string; conversations: number; signups: number }> = [];
        for (let i = days - 1; i >= 0; i--) {
            const day = new Date(Date.now() - i * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
            series.push({
                date: day,
                conversations: conversationCounts.get(day) ?? 0,
                signups: signupCounts.get(day) ?? 0,
            });
        }

        return series;
    } catch (error) {
        logger.error('Error building admin timeseries', { error, days });
        throw error;
    }
};

export const getLanguageSplit = async () => {
    try {
        const { data, error } = await supabase.from('conversation_logs').select('language');
        if (error) throw error;

        const counts = new Map<string, number>();
        for (const row of data ?? []) {
            const lang = (row as any).language || 'unknown';
            counts.set(lang, (counts.get(lang) ?? 0) + 1);
        }

        const total = data?.length ?? 0;
        return Array.from(counts.entries())
            .map(([language, count]) => ({
                language,
                count,
                pct: total === 0 ? 0 : Math.round((count / total) * 1000) / 10,
            }))
            .sort((a, b) => b.count - a.count);
    } catch (error) {
        logger.error('Error building language split', { error });
        throw error;
    }
};

/**
 * p50/p95 for each pipeline stage over the most recent turns.
 * This is the chart that explains where the 3-6 seconds actually goes.
 */
export const getLatencyBreakdown = async (sampleSize = 500) => {
    try {
        const { data, error } = await supabase
            .from('conversation_logs')
            .select('stt_ms, llm_ms, tts_ms, total_ms, input_mode')
            .order('created_at', { ascending: false })
            .limit(sampleSize);

        if (error) throw error;

        const rows = (data ?? []) as any[];
        const column = (key: string) =>
            rows.map((r) => r[key]).filter((v: unknown): v is number => typeof v === 'number');

        const stage = (key: string) => {
            const values = column(key);
            return {
                p50: percentile(values, 50),
                p95: percentile(values, 95),
                samples: values.length,
            };
        };

        return {
            sample_size: rows.length,
            voice_turns: rows.filter((r) => r.input_mode === 'voice').length,
            text_turns: rows.filter((r) => r.input_mode === 'text').length,
            stt: stage('stt_ms'),
            llm: stage('llm_ms'),
            tts: stage('tts_ms'),
            total: stage('total_ms'),
        };
    } catch (error) {
        logger.error('Error building latency breakdown', { error });
        throw error;
    }
};
