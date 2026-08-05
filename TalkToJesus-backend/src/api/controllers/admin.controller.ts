import { Response } from 'express';
import { z } from 'zod';
import { AuthenticatedRequest } from '../middlewares/auth.middleware';
import {
    getOverview,
    getTimeseries,
    getLanguageSplit,
    getLatencyBreakdown,
} from '../services/adminStats.service';
import {
    listUsers,
    updateUser,
    listSongs,
    createSong,
    updateSong,
    deleteSong,
    listConversations,
    getHealth,
    recordAuditEntry,
    listAuditLog,
} from '../services/admin.service';
import { listWebhookEvents } from '../services/webhookEvent.service';
import { listFeatureFlags, setFeatureFlag } from '../services/featureFlag.service';
import { supabase } from '../../config/supabase';
import { signToken } from '../../utils/jwt';
import logger from '../../utils/logger';

const parsePage = (value: unknown) => Math.max(1, Number(value) || 1);
const parseLimit = (value: unknown, max = 100, fallback = 20) =>
    Math.min(max, Math.max(1, Number(value) || fallback));

const fail = (res: Response, error: any, message: string) => {
    logger.error(message, { error });
    return res.status(500).json({ error: message, details: error?.message });
};

// ---------------------------------------------------------------- login

const loginSchema = z.object({
    email: z.string().min(1),
    password: z.string().min(1),
});

/**
 * Email + password login for the browser console only, so the dashboard can be
 * opened on a laptop without running a Google OAuth popup.
 *
 * Credentials come from ADMIN_EMAIL / ADMIN_PASSWORD. The account must ALSO
 * exist in the users table with is_admin = true — the env pair alone grants
 * nothing, so revoking the flag in the database revokes console access too.
 * The token returned is an ordinary user JWT, so authMiddleware handles it
 * unchanged.
 */
export const adminLoginHandler = async (req: AuthenticatedRequest, res: Response) => {
    try {
        const parsed = loginSchema.safeParse(req.body);
        if (!parsed.success) {
            return res.status(400).json({ error: 'Email and password are required' });
        }

        const expectedEmail = process.env.ADMIN_EMAIL;
        const expectedPassword = process.env.ADMIN_PASSWORD;

        if (!expectedEmail || !expectedPassword) {
            logger.error('Admin login attempted but ADMIN_EMAIL/ADMIN_PASSWORD are not configured');
            return res.status(500).json({ error: 'Admin login is not configured on this server' });
        }

        const emailMatches =
            parsed.data.email.trim().toLowerCase() === expectedEmail.trim().toLowerCase();
        const passwordMatches = parsed.data.password === expectedPassword;

        if (!emailMatches || !passwordMatches) {
            logger.warn('Failed admin login attempt', { email: parsed.data.email });
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        const { data: user, error } = await supabase
            .from('users')
            .select('id, email, display_name, is_admin')
            .eq('email', expectedEmail)
            .single();

        if (error || !user) {
            logger.error('Admin login: configured email has no user row', { error });
            return res.status(401).json({
                error: 'No user account exists for the configured admin email',
            });
        }

        if (user.is_admin !== true) {
            logger.warn('Admin login: user exists but is_admin is false', { userId: user.id });
            return res.status(403).json({ error: 'This account is not an admin' });
        }

        const token = signToken({ userId: user.id });
        logger.info('Admin logged in to console', { userId: user.id, email: user.email });

        res.json({ token, user });
    } catch (error) {
        fail(res, error, 'Admin login failed');
    }
};

// ---------------------------------------------------------------- analytics

export const overviewHandler = async (_req: AuthenticatedRequest, res: Response) => {
    try {
        res.json(await getOverview());
    } catch (error) {
        fail(res, error, 'Failed to build overview');
    }
};

export const timeseriesHandler = async (req: AuthenticatedRequest, res: Response) => {
    try {
        const days = Math.min(90, Math.max(1, Number(req.query.days) || 30));
        res.json({ days, series: await getTimeseries(days) });
    } catch (error) {
        fail(res, error, 'Failed to build timeseries');
    }
};

export const languagesHandler = async (_req: AuthenticatedRequest, res: Response) => {
    try {
        res.json({ languages: await getLanguageSplit() });
    } catch (error) {
        fail(res, error, 'Failed to build language split');
    }
};

export const latencyHandler = async (_req: AuthenticatedRequest, res: Response) => {
    try {
        res.json(await getLatencyBreakdown());
    } catch (error) {
        fail(res, error, 'Failed to build latency breakdown');
    }
};

// ---------------------------------------------------------------- users

export const listUsersHandler = async (req: AuthenticatedRequest, res: Response) => {
    try {
        const page = parsePage(req.query.page);
        const limit = parseLimit(req.query.limit);
        const search = typeof req.query.search === 'string' ? req.query.search : undefined;
        const { data, count } = await listUsers(page, limit, search);
        res.json({ data, count, page, limit });
    } catch (error) {
        fail(res, error, 'Failed to list users');
    }
};

const updateUserSchema = z
    .object({
        is_admin: z.boolean().optional(),
        conversation_count: z.number().int().min(0).max(100000).optional(),
    })
    .refine((value) => Object.keys(value).length > 0, {
        message: 'Provide at least one field to update',
    });

export const updateUserHandler = async (req: AuthenticatedRequest, res: Response) => {
    try {
        const parsed = updateUserSchema.safeParse(req.body);
        if (!parsed.success) {
            return res.status(400).json({ error: 'Invalid request', details: parsed.error.issues });
        }

        const targetId = req.params.id;

        // Removing your own admin rights mid-demo locks you out of the console.
        if (parsed.data.is_admin === false && targetId === req.user.id) {
            return res.status(400).json({
                error: 'Refusing to revoke your own admin access',
            });
        }

        const updated = await updateUser(targetId, parsed.data);

        void recordAuditEntry({
            adminUserId: req.user.id,
            adminEmail: req.user.email,
            action: 'user.update',
            target: targetId,
            meta: parsed.data,
        });

        res.json(updated);
    } catch (error) {
        fail(res, error, 'Failed to update user');
    }
};

// ---------------------------------------------------------------- songs

export const listSongsHandler = async (req: AuthenticatedRequest, res: Response) => {
    try {
        const page = parsePage(req.query.page);
        const limit = parseLimit(req.query.limit);
        const search = typeof req.query.search === 'string' ? req.query.search : undefined;
        const { data, count } = await listSongs(page, limit, search);
        res.json({ data, count, page, limit });
    } catch (error) {
        fail(res, error, 'Failed to list songs');
    }
};

const songSchema = z.object({
    title: z.string().min(1).max(200),
    duration: z.string().min(1).max(20),
    image_url: z.string().url(),
    audio_url: z.string().url(),
});

export const createSongHandler = async (req: AuthenticatedRequest, res: Response) => {
    try {
        const parsed = songSchema.safeParse(req.body);
        if (!parsed.success) {
            return res.status(400).json({ error: 'Invalid request', details: parsed.error.issues });
        }

        const song = await createSong(parsed.data);

        void recordAuditEntry({
            adminUserId: req.user.id,
            adminEmail: req.user.email,
            action: 'song.create',
            target: song?.id,
            meta: { title: parsed.data.title },
        });

        res.status(201).json(song);
    } catch (error) {
        fail(res, error, 'Failed to create song');
    }
};

export const updateSongHandler = async (req: AuthenticatedRequest, res: Response) => {
    try {
        const parsed = songSchema.partial().safeParse(req.body);
        if (!parsed.success || Object.keys(parsed.data).length === 0) {
            return res.status(400).json({
                error: 'Invalid request',
                details: parsed.success ? 'No fields to update' : parsed.error.issues,
            });
        }

        const song = await updateSong(req.params.id, parsed.data);

        void recordAuditEntry({
            adminUserId: req.user.id,
            adminEmail: req.user.email,
            action: 'song.update',
            target: req.params.id,
            meta: parsed.data,
        });

        res.json(song);
    } catch (error) {
        fail(res, error, 'Failed to update song');
    }
};

export const deleteSongHandler = async (req: AuthenticatedRequest, res: Response) => {
    try {
        await deleteSong(req.params.id);

        void recordAuditEntry({
            adminUserId: req.user.id,
            adminEmail: req.user.email,
            action: 'song.delete',
            target: req.params.id,
        });

        res.json({ success: true });
    } catch (error) {
        fail(res, error, 'Failed to delete song');
    }
};

// ---------------------------------------------------------------- ops

export const listConversationsHandler = async (req: AuthenticatedRequest, res: Response) => {
    try {
        const page = parsePage(req.query.page);
        const limit = parseLimit(req.query.limit);
        const { data, count } = await listConversations(page, limit);
        res.json({ data, count, page, limit });
    } catch (error) {
        fail(res, error, 'Failed to list conversations');
    }
};

export const listWebhooksHandler = async (req: AuthenticatedRequest, res: Response) => {
    try {
        const page = parsePage(req.query.page);
        const limit = parseLimit(req.query.limit);
        const { data, count } = await listWebhookEvents(page, limit);
        res.json({ data, count, page, limit });
    } catch (error) {
        fail(res, error, 'Failed to list webhook events');
    }
};

export const healthHandler = async (_req: AuthenticatedRequest, res: Response) => {
    try {
        res.json(await getHealth());
    } catch (error) {
        fail(res, error, 'Failed to build health report');
    }
};

export const listFlagsHandler = async (_req: AuthenticatedRequest, res: Response) => {
    try {
        res.json({ flags: await listFeatureFlags() });
    } catch (error) {
        fail(res, error, 'Failed to list feature flags');
    }
};

const flagSchema = z.object({
    key: z.string().min(1),
    value: z.union([z.boolean(), z.number(), z.string()]),
});

export const updateFlagHandler = async (req: AuthenticatedRequest, res: Response) => {
    try {
        const parsed = flagSchema.safeParse(req.body);
        if (!parsed.success) {
            return res.status(400).json({ error: 'Invalid request', details: parsed.error.issues });
        }

        await setFeatureFlag(parsed.data.key, parsed.data.value);

        void recordAuditEntry({
            adminUserId: req.user.id,
            adminEmail: req.user.email,
            action: 'flag.update',
            target: parsed.data.key,
            meta: { value: parsed.data.value },
        });

        res.json({ success: true, ...parsed.data });
    } catch (error: any) {
        if (error?.message?.startsWith('Unknown feature flag')) {
            return res.status(400).json({ error: error.message });
        }
        fail(res, error, 'Failed to update feature flag');
    }
};

export const auditLogHandler = async (req: AuthenticatedRequest, res: Response) => {
    try {
        const limit = parseLimit(req.query.limit, 200, 50);
        res.json({ data: await listAuditLog(limit) });
    } catch (error) {
        fail(res, error, 'Failed to list audit log');
    }
};

/** Confirms to the console UI that the pasted token belongs to an admin. */
export const meHandler = async (req: AuthenticatedRequest, res: Response) => {
    res.json({
        id: req.user.id,
        email: req.user.email,
        display_name: req.user.display_name,
        is_admin: req.user.is_admin === true,
    });
};
