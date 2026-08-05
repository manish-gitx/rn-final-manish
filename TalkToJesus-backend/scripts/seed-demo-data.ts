/**
 * Seeds synthetic analytics data so the admin console has realistic charts for
 * a demo instead of an empty dashboard.
 *
 *   npx ts-node scripts/seed-demo-data.ts            # seed
 *   npx ts-node scripts/seed-demo-data.ts --clear    # remove seeded rows only
 *
 * Everything written here is tagged so it can be removed again:
 *   - users            emails end with @demo.talktojesus.local
 *   - conversation_logs assistant_text ends with the SEED_MARKER
 *   - webhook_events    payload.seeded = true
 *
 * This is demonstration data, not production traffic. Say so if asked.
 */

import dotenv from 'dotenv';
import { createClient } from '@supabase/supabase-js';

dotenv.config();

const SEED_MARKER = '​[seed]'; // zero-width space + tag: invisible in the UI
const DEMO_EMAIL_DOMAIN = '@demo.talktojesus.local';
const DAYS = 30;

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_KEY;

if (!supabaseUrl || !supabaseKey) {
    console.error('SUPABASE_URL and SUPABASE_KEY must be set in .env');
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

const DEMO_USERS = [
    'ravi.kumar', 'anitha.p', 'joseph.m', 'lakshmi.n', 'david.s',
    'priya.r', 'samuel.j', 'grace.t', 'thomas.a', 'esther.k',
];

const EN_PROMPTS: Array<[string, string]> = [
    ['I feel anxious about my exams.', 'Peace, my child. "Do not be anxious about anything..." — Philippians 4:6'],
    ['I lost my job last week.', 'My child, I have not forgotten you. "I know the plans I have for you..." — Jeremiah 29:11'],
    ['How do I forgive someone who hurt me?', 'Forgiveness is a gift you give yourself. "Be kind to one another, forgiving..." — Ephesians 4:32'],
    ['I feel alone.', 'You are never alone, my child. "I will never leave you nor forsake you." — Hebrews 13:5'],
    ['Help me be patient with my family.', 'Patience is love that has learned to wait. "Love is patient, love is kind." — 1 Corinthians 13:4'],
    ['What should I pray about today?', 'Begin with gratitude, my child. Name three gifts, then bring Me your burden.'],
];

const TE_PROMPTS: Array<[string, string]> = [
    ['నాకు చాలా భయంగా ఉంది.', 'నా బిడ్డా, భయపడకు. "నేను నీకు తోడై యున్నాను." — యెషయా 41:10'],
    ['నా కుటుంబం కోసం ప్రార్థించండి.', 'నా బిడ్డా, నీ కుటుంబాన్ని నా చేతుల్లో ఉంచుతున్నాను.'],
    ['నేను క్షమించలేకపోతున్నాను.', 'నా బిడ్డా, క్షమాపణ ఒక ప్రయాణం. నేను నీతో నడుస్తాను.'],
];

// Deterministic PRNG so repeated runs produce a stable-looking dataset.
let seed = 42;
const rand = () => {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    return seed / 0x7fffffff;
};
const randInt = (min: number, max: number) => Math.floor(rand() * (max - min + 1)) + min;
const pick = <T>(arr: T[]): T => arr[Math.floor(rand() * arr.length)];

async function clear() {
    console.log('Clearing seeded data...');

    const { data: users } = await supabase
        .from('users')
        .select('id')
        .like('email', `%${DEMO_EMAIL_DOMAIN}`);

    const userIds = (users ?? []).map((u: any) => u.id);

    const { error: convoErr } = await supabase
        .from('conversation_logs')
        .delete()
        .like('assistant_text', `%${SEED_MARKER}`);
    if (convoErr) console.error('  conversation_logs:', convoErr.message);
    else console.log('  conversation_logs cleared');

    const { error: hookErr } = await supabase
        .from('webhook_events')
        .delete()
        .contains('payload', { seeded: true });
    if (hookErr) console.error('  webhook_events:', hookErr.message);
    else console.log('  webhook_events cleared');

    if (userIds.length) {
        const { error: userErr } = await supabase.from('users').delete().in('id', userIds);
        if (userErr) console.error('  users:', userErr.message);
        else console.log(`  ${userIds.length} demo users cleared`);
    }

    console.log('Done.');
}

async function seedData() {
    console.log(`Seeding ${DAYS} days of demo data...`);

    // ---- users -------------------------------------------------------------
    const userRows = DEMO_USERS.map((name, i) => ({
        email: `${name}${DEMO_EMAIL_DOMAIN}`,
        display_name: name.split('.').map((p) => p[0].toUpperCase() + p.slice(1)).join(' '),
        conversation_count: randInt(0, 18),
        created_at: new Date(Date.now() - (DAYS - i * 2) * 86400000).toISOString(),
        last_login_at: new Date(Date.now() - randInt(0, 5) * 86400000).toISOString(),
    }));

    const { data: users, error: userError } = await supabase
        .from('users')
        .upsert(userRows, { onConflict: 'email' })
        .select('id, email');

    if (userError) {
        console.error('Failed to seed users:', userError.message);
        console.error('Has supabase-admin-setup.sql been run against this project?');
        process.exit(1);
    }
    console.log(`  ${users?.length ?? 0} users`);

    const userIds = (users ?? []).map((u: any) => u.id);
    if (!userIds.length) {
        console.error('No demo users available; aborting.');
        process.exit(1);
    }

    // ---- conversation logs -------------------------------------------------
    const logs: any[] = [];
    for (let d = DAYS - 1; d >= 0; d--) {
        // Gentle upward trend plus a weekend dip, so the chart has a shape.
        const dayDate = new Date(Date.now() - d * 86400000);
        const isWeekend = [0, 6].includes(dayDate.getDay());
        const base = 4 + Math.round((DAYS - d) / 5);
        const count = Math.max(1, randInt(base - 2, base + 3) - (isWeekend ? 2 : 0));

        for (let i = 0; i < count; i++) {
            const isTelugu = rand() < 0.36;
            const [prompt, reply] = isTelugu ? pick(TE_PROMPTS) : pick(EN_PROMPTS);
            const isText = rand() < 0.25;

            const sttMs = isText ? 0 : randInt(700, 1900);
            const llmMs = randInt(900, 2600);
            const ttsMs = randInt(800, 2200);

            const at = new Date(dayDate);
            at.setHours(randInt(6, 23), randInt(0, 59), randInt(0, 59), 0);

            logs.push({
                user_id: pick(userIds),
                language: isTelugu ? 'te' : 'en',
                input_mode: isText ? 'text' : 'voice',
                user_message: prompt,
                assistant_text: reply + SEED_MARKER,
                stt_ms: sttMs,
                llm_ms: llmMs,
                tts_ms: ttsMs,
                total_ms: sttMs + llmMs + ttsMs + randInt(40, 220),
                created_at: at.toISOString(),
            });
        }
    }

    // Chunked to stay under request size limits.
    for (let i = 0; i < logs.length; i += 100) {
        const { error } = await supabase.from('conversation_logs').insert(logs.slice(i, i + 100));
        if (error) {
            console.error('Failed to seed conversation_logs:', error.message);
            process.exit(1);
        }
    }
    console.log(`  ${logs.length} conversation turns`);

    // ---- webhook events ----------------------------------------------------
    const events = ['subscription.charged', 'subscription.activated', 'subscription.authenticated', 'subscription.cancelled'];
    const hooks = Array.from({ length: 12 }, (_, i) => ({
        event_type: pick(events),
        razorpay_subscription_id: `sub_DEMO${1000 + i}`,
        // A couple of rejected ones, so the signature column shows both states.
        signature_valid: i % 7 !== 0,
        payload: { seeded: true },
        created_at: new Date(Date.now() - randInt(0, DAYS) * 86400000).toISOString(),
    }));

    const { error: hookError } = await supabase.from('webhook_events').insert(hooks);
    if (hookError) console.error('Failed to seed webhook_events:', hookError.message);
    else console.log(`  ${hooks.length} webhook events`);

    console.log('\nDone. Open /admin to see the dashboard.');
    console.log('Remove it again with: npx ts-node scripts/seed-demo-data.ts --clear');
}

const run = process.argv.includes('--clear') ? clear : seedData;
run().catch((error) => {
    console.error(error);
    process.exit(1);
});
