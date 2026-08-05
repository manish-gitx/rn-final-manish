-- ================================================
-- TalkToJesus Backend - Admin & Analytics Setup
-- ================================================
-- Run this in your Supabase SQL Editor AFTER supabase-setup.sql.
--
-- Kept as a separate script on purpose: supabase-setup.sql contains a plain
-- CREATE TRIGGER (no IF NOT EXISTS), so re-running that file errors out.
-- This script is safe to run more than once.
--
-- What this adds:
--   1. users.is_admin            - gates the /api/admin/* routes
--   2. conversation_logs         - per-turn transcript + latency breakdown
--                                  (also powers conversation history + multi-turn context)
--   3. webhook_events            - Razorpay event audit trail
--   4. feature_flags             - runtime toggles editable from the admin console
--   5. admin_audit_log           - who changed what from the admin console

-- ================================================
-- 1. ADMIN FLAG ON USERS
-- ================================================
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN NOT NULL DEFAULT false;

-- Time-series queries on signups need this; the base schema only indexes email.
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);

-- ================================================
-- 2. CONVERSATION LOGS
-- ================================================
-- One row per successful conversation turn. Written fire-and-forget by the
-- conversation controller, so a failure here must never break a user request.
CREATE TABLE IF NOT EXISTS conversation_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  language TEXT NOT NULL DEFAULT 'en',
  input_mode TEXT NOT NULL DEFAULT 'voice' CHECK (input_mode IN ('voice', 'text')),
  user_message TEXT,
  assistant_text TEXT,
  stt_ms INTEGER,
  llm_ms INTEGER,
  tts_ms INTEGER,
  total_ms INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_conversation_logs_created_at ON conversation_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_conversation_logs_user_id ON conversation_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_conversation_logs_language ON conversation_logs(language);
-- Composite index for the history endpoint (latest N turns for one user).
CREATE INDEX IF NOT EXISTS idx_conversation_logs_user_created
  ON conversation_logs(user_id, created_at DESC);

-- ================================================
-- 3. WEBHOOK EVENTS
-- ================================================
CREATE TABLE IF NOT EXISTS webhook_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type TEXT NOT NULL,
  razorpay_subscription_id TEXT,
  signature_valid BOOLEAN NOT NULL DEFAULT false,
  payload JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_webhook_events_created_at ON webhook_events(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_webhook_events_type ON webhook_events(event_type);

-- ================================================
-- 4. FEATURE FLAGS
-- ================================================
CREATE TABLE IF NOT EXISTS feature_flags (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  description TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

INSERT INTO feature_flags (key, value, description) VALUES
  ('free_tier_limit',   '3'::jsonb,     'Number of free conversations before the paywall'),
  ('maintenance_mode',  'false'::jsonb, 'Reject conversation requests with a friendly message'),
  ('tts_enabled',       'true'::jsonb,  'Synthesize speech; when false, text-only responses'),
  ('multi_turn_enabled','true'::jsonb,  'Send prior turns to the LLM as context'),
  ('multi_turn_window', '6'::jsonb,     'How many prior turns to include as context')
ON CONFLICT (key) DO NOTHING;

-- ================================================
-- 5. ADMIN AUDIT LOG
-- ================================================
CREATE TABLE IF NOT EXISTS admin_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  admin_email TEXT,
  action TEXT NOT NULL,
  target TEXT,
  meta JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_audit_log_created_at ON admin_audit_log(created_at DESC);

-- ================================================
-- 6. ROW LEVEL SECURITY
-- ================================================
-- Same posture as the four base tables: RLS on, no policies. The backend uses
-- a secret/service-tier SUPABASE_KEY which bypasses RLS, so these tables are
-- unreachable from any browser or anon key. All access is server-mediated.
ALTER TABLE conversation_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE webhook_events    ENABLE ROW LEVEL SECURITY;
ALTER TABLE feature_flags     ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_audit_log   ENABLE ROW LEVEL SECURITY;

-- ================================================
-- 7. PROMOTE YOUR ADMIN ACCOUNT
-- ================================================
-- Replace with the Google account you sign in with, then run:
-- UPDATE users SET is_admin = true WHERE email = 'you@example.com';

-- ================================================
-- SETUP COMPLETE
-- ================================================
