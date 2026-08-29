/**
 * Creates (or promotes) the admin console account.
 *
 *   npx ts-node scripts/promote-admin.ts
 *
 * Reads ADMIN_EMAIL from .env and makes sure a matching users row exists with
 * is_admin = true. That row is what POST /api/admin/login looks up after the
 * ADMIN_EMAIL/ADMIN_PASSWORD check, and what adminMiddleware re-checks on every
 * subsequent request.
 *
 * The account is credential-based on purpose: it does not need to be a real
 * Google account, because the admin console signs in through /api/admin/login
 * rather than the app's OAuth flow.
 *
 * Safe to run repeatedly.
 */

import dotenv from 'dotenv';
import { createClient } from '@supabase/supabase-js';

dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_KEY;
const adminEmail = process.env.ADMIN_EMAIL;

if (!supabaseUrl || !supabaseKey) {
    console.error('SUPABASE_URL and SUPABASE_KEY must be set in .env');
    process.exit(1);
}

if (!adminEmail || adminEmail.includes('change-me')) {
    console.error('ADMIN_EMAIL is unset or still the placeholder. Set a real value in .env first.');
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

const main = async () => {
    // is_admin lives in supabase-admin-setup.sql, not the base schema. Probe it
    // first so a missing column reports the real cause instead of a PostgREST
    // error about an unknown field.
    const probe = await supabase.from('users').select('id, is_admin').limit(1);
    if (probe.error) {
        console.error('Cannot read users.is_admin:', probe.error.message);
        console.error('Run supabase-admin-setup.sql in the Supabase SQL editor first.');
        process.exit(1);
    }

    const { data: existing, error: lookupError } = await supabase
        .from('users')
        .select('id, email, is_admin')
        .eq('email', adminEmail)
        .maybeSingle();

    if (lookupError) {
        console.error('Lookup failed:', lookupError.message);
        process.exit(1);
    }

    if (existing) {
        if (existing.is_admin === true) {
            console.log(`Already an admin: ${adminEmail} (${existing.id})`);
            return;
        }
        const { error } = await supabase
            .from('users')
            .update({ is_admin: true })
            .eq('id', existing.id);
        if (error) {
            console.error('Promote failed:', error.message);
            process.exit(1);
        }
        console.log(`Promoted existing user to admin: ${adminEmail} (${existing.id})`);
        return;
    }

    const { data: created, error: insertError } = await supabase
        .from('users')
        .insert({
            email: adminEmail,
            display_name: 'Admin',
            is_admin: true,
            conversation_count: 0,
            last_login_at: new Date().toISOString(),
        })
        .select('id')
        .single();

    if (insertError) {
        console.error('Create failed:', insertError.message);
        process.exit(1);
    }

    console.log(`Created admin user: ${adminEmail} (${created.id})`);
};

main().catch((err) => {
    console.error(err);
    process.exit(1);
});
