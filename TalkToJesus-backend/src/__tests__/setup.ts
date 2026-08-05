// Set required environment variables before any module loads.
//
// Several modules read process.env at import time and would otherwise throw or
// mis-configure themselves. Keep this list complete: anything missing here is a
// test that only passes on a machine with a real .env file, which is how the
// auth.service suite came to pass locally and fail in CI.
process.env.JWT_SECRET = 'test-jwt-secret-key';
process.env.SUPABASE_URL = 'https://test.supabase.co';
process.env.SUPABASE_KEY = 'test-supabase-key';
process.env.RAZORPAY_KEY_ID_DEV = 'rzp_test_key';
process.env.RAZORPAY_KEY_SECRET_DEV = 'rzp_test_secret';
process.env.RAZORPAY_WEBHOOK_SECRET_DEV = 'webhook_test_secret';

// auth.service.ts builds its clientIds array at module load and filters out
// undefined entries. Without these the array is empty, the verification loop
// never runs, and every call throws 'Invalid Google token' regardless of how
// OAuth2Client is mocked.
process.env.GOOGLE_CLIENT_ID_WEB = 'test-google-client-id-web';
process.env.GOOGLE_CLIENT_ID_IOS = 'test-google-client-id-ios';
process.env.GOOGLE_CLIENT_ID_ANDROID = 'test-google-client-id-android';

process.env.NODE_ENV = 'test';
