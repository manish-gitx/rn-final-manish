// Set required environment variables before any module loads
process.env.JWT_SECRET = 'test-jwt-secret-key';
process.env.SUPABASE_URL = 'https://test.supabase.co';
process.env.SUPABASE_KEY = 'test-supabase-key';
process.env.RAZORPAY_KEY_ID_DEV = 'rzp_test_key';
process.env.RAZORPAY_KEY_SECRET_DEV = 'rzp_test_secret';
process.env.RAZORPAY_WEBHOOK_SECRET_DEV = 'webhook_test_secret';
process.env.NODE_ENV = 'test';
