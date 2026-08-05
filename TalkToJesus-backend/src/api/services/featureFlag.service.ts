import { supabase } from '../../config/supabase';
import logger from '../../utils/logger';

export interface FeatureFlags {
    free_tier_limit: number;
    maintenance_mode: boolean;
    tts_enabled: boolean;
    multi_turn_enabled: boolean;
    multi_turn_window: number;
}

export const DEFAULT_FLAGS: FeatureFlags = {
    free_tier_limit: 3,
    maintenance_mode: false,
    tts_enabled: true,
    multi_turn_enabled: true,
    multi_turn_window: 6,
};

// Flags are read on every conversation request, so cache briefly to avoid a
// round-trip per turn. The admin console's edits show up within CACHE_TTL_MS.
const CACHE_TTL_MS = 15_000;
let cached: { flags: FeatureFlags; at: number } | null = null;

export const invalidateFlagCache = (): void => {
    cached = null;
};

/**
 * Never throws — falls back to DEFAULT_FLAGS so a flags table problem cannot
 * take down the conversation endpoint.
 */
export const getFeatureFlags = async (): Promise<FeatureFlags> => {
    if (cached && Date.now() - cached.at < CACHE_TTL_MS) {
        return cached.flags;
    }

    try {
        const { data, error } = await supabase.from('feature_flags').select('key, value');

        if (error || !data) {
            logger.warn('Failed to load feature flags, using defaults', { error });
            return DEFAULT_FLAGS;
        }

        const flags: FeatureFlags = { ...DEFAULT_FLAGS };
        for (const row of data) {
            if (row.key in flags) {
                (flags as any)[row.key] = row.value;
            }
        }

        cached = { flags, at: Date.now() };
        return flags;
    } catch (error) {
        logger.warn('Unexpected error loading feature flags, using defaults', { error });
        return DEFAULT_FLAGS;
    }
};

export const setFeatureFlag = async (key: string, value: unknown): Promise<void> => {
    if (!(key in DEFAULT_FLAGS)) {
        throw new Error(`Unknown feature flag: ${key}`);
    }

    const { error } = await supabase
        .from('feature_flags')
        .update({ value, updated_at: new Date().toISOString() })
        .eq('key', key);

    if (error) {
        logger.error('Error updating feature flag', { error, key });
        throw error;
    }

    invalidateFlagCache();
    logger.info('Feature flag updated', { key, value });
};

export const listFeatureFlags = async () => {
    const { data, error } = await supabase
        .from('feature_flags')
        .select('key, value, description, updated_at')
        .order('key');

    if (error) {
        logger.error('Error listing feature flags', { error });
        throw error;
    }

    return data;
};
