/**
 * The admin console's identity.
 *
 * The console signs in with ADMIN_EMAIL/ADMIN_PASSWORD from the environment
 * rather than the app's Google OAuth flow, and the principal it produces is
 * synthetic: there is deliberately no users row behind it. That keeps the
 * console usable on a database that has never had supabase-admin-setup.sql
 * applied, and means no real account has to be promoted to reach it.
 *
 * The trade-off, stated plainly: with no row there is no is_admin flag to flip,
 * so access cannot be revoked from the database. Rotating ADMIN_PASSWORD is the
 * only revocation, and tokens already issued stay valid until they expire.
 * Anything that needs per-admin accountability should use real accounts.
 */

/** Sentinel user id. Not a UUID on purpose — it must never match a users row. */
export const CONSOLE_ADMIN_ID = 'console-admin';

/** JWT claim marking a token minted by POST /api/admin/login. */
export const CONSOLE_ADMIN_CLAIM = 'console_admin';

export interface ConsoleAdminPrincipal {
    id: string;
    email: string;
    display_name: string;
    is_admin: true;
    is_console_admin: true;
}

export const buildConsoleAdmin = (email: string): ConsoleAdminPrincipal => ({
    id: CONSOLE_ADMIN_ID,
    email,
    display_name: 'Admin',
    is_admin: true,
    is_console_admin: true,
});

export const isConsoleAdminId = (id: unknown): boolean => id === CONSOLE_ADMIN_ID;
