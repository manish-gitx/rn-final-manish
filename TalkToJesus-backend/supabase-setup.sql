-- ================================================
-- TalkToJesus Backend - Supabase Database Setup
-- ================================================
-- Run this SQL in your Supabase SQL Editor to create all necessary tables

-- Enable UUID extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ================================================
-- 1. USERS TABLE
-- ================================================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  photo_url TEXT,
  conversation_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_login_at TIMESTAMP WITH TIME ZONE
);

-- Create index on email for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- ================================================
-- 2. SONGS TABLE
-- ================================================
CREATE TABLE IF NOT EXISTS songs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  duration TEXT NOT NULL,
  image_url TEXT NOT NULL,
  audio_url TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on title for search functionality
CREATE INDEX IF NOT EXISTS idx_songs_title ON songs(title);

-- ================================================
-- 3. PLANS TABLE
-- ================================================
CREATE TABLE IF NOT EXISTS plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  price INTEGER NOT NULL, -- in paise (49900 for ₹499)
  razorpay_plan_id TEXT NOT NULL, -- Razorpay plan ID
  interval INTEGER NOT NULL, -- Billing interval (e.g., 1 for monthly)
  period TEXT CHECK (period IN ('daily', 'weekly', 'monthly', 'yearly')) NOT NULL, -- Billing period
  cycles INTEGER NOT NULL, -- Total number of billing cycles (e.g., 12 for 12 months)
  is_prod BOOLEAN NOT NULL DEFAULT false, -- true for production plans, false for development plans
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on is_prod for environment-based filtering
CREATE INDEX IF NOT EXISTS idx_plans_is_prod ON plans(is_prod);

-- ================================================
-- 4. SUBSCRIPTIONS TABLE
-- ================================================
CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  razorpay_subscription_id TEXT UNIQUE NOT NULL,
  plan_id UUID REFERENCES plans(id) ON DELETE SET NULL,
  status TEXT CHECK (status IN ('created', 'authenticated', 'active', 'pending', 'halted', 'cancelled', 'completed', 'paused', 'resumed')) DEFAULT 'created',
  current_start BIGINT, -- Unix timestamp
  current_end BIGINT, -- Unix timestamp
  last_charged_at BIGINT, -- Unix timestamp - when subscription was last charged
  charge_at BIGINT, -- Unix timestamp - next charge date
  start_at BIGINT, -- Unix timestamp - subscription start date
  end_at BIGINT, -- Unix timestamp - subscription end date
  quantity INTEGER DEFAULT 1,
  total_count INTEGER DEFAULT 12, -- Total billing cycles (12 months)
  paid_count INTEGER DEFAULT 0, -- Number of successful payments
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_razorpay_id ON subscriptions(razorpay_subscription_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);

-- ================================================
-- 5. INSERT SAMPLE PLAN (DEVELOPMENT)
-- ================================================
-- Insert a development plan for testing
INSERT INTO plans (name, price, razorpay_plan_id, interval, period, cycles, is_prod)
VALUES (
  'Monthly Plan - Dev',
  49900, -- ₹499 in paise
  'plan_dev_test_id', -- Replace with your Razorpay DEV plan ID
  1,
  'monthly',
  12,
  false
)
ON CONFLICT DO NOTHING;

-- ================================================
-- 6. INSERT SAMPLE PLAN (PRODUCTION)
-- ================================================
-- Insert a production plan (uncomment when ready for production)
-- INSERT INTO plans (name, price, razorpay_plan_id, interval, period, cycles, is_prod)
-- VALUES (
--   'Monthly Plan - Prod',
--   49900, -- ₹499 in paise
--   'plan_prod_real_id', -- Replace with your Razorpay PROD plan ID
--   1,
--   'monthly',
--   12,
--   true
-- )
-- ON CONFLICT DO NOTHING;

-- ================================================
-- 7. ROW LEVEL SECURITY (RLS) POLICIES
-- ================================================
-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE songs ENABLE ROW LEVEL SECURITY;
ALTER TABLE plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- Since you're using service role key from backend, you might want to disable RLS
-- OR create policies that allow service role to access everything
-- For service role access (recommended for backend-only access):
-- The service role key bypasses RLS, so no policies needed if using service_role key

-- If using anon key, you'll need to create appropriate policies
-- Example policy for anon key (adjust based on your needs):
-- CREATE POLICY "Allow all operations for service role" ON users FOR ALL USING (true);
-- CREATE POLICY "Allow all operations for service role" ON songs FOR ALL USING (true);
-- CREATE POLICY "Allow all operations for service role" ON plans FOR ALL USING (true);
-- CREATE POLICY "Allow all operations for service role" ON subscriptions FOR ALL USING (true);

-- ================================================
-- 8. FUNCTIONS & TRIGGERS
-- ================================================
-- Update updated_at timestamp automatically for subscriptions
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_subscriptions_updated_at
    BEFORE UPDATE ON subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ================================================
-- SETUP COMPLETE!
-- ================================================
-- Next steps:
-- 1. Update your Razorpay plan IDs in the plans table
-- 2. Add songs to the songs table
-- 3. Configure your .env file with Supabase credentials
-- 4. Test the API endpoints

