# Talk to Jesus Backend API

A comprehensive backend API for the Talk to Jesus app, providing authentication, payment processing, and real-time conversation features.

## Table of Contents

- [Authentication APIs](#authentication-apis)
- [User Management APIs](#user-management-apis)
- [Songs APIs](#songs-apis)
- [Plans APIs](#plans-apis)
- [Subscription APIs](#subscription-apis)
- [Conversation APIs](#conversation-apis)
- [Webhook APIs](#webhook-apis)
- [Environment Variables](#environment-variables)
- [Database Schema](#database-schema)

---

## Authentication APIs

### Create or Get User
**POST** `/api/auth/create-or-get-user`

Creates a new user or retrieves an existing user using Google OAuth token. Returns both the user object and a custom JWT token.

**Request Body:**
```json
{
  "token": "google_oauth_id_token"
}
```

**Response (200 OK):**
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "display_name": "John Doe",
    "photo_url": "https://example.com/photo.jpg",
    "conversation_count": 0,
    "created_at": "2024-01-01T00:00:00.000Z",
    "last_login_at": "2024-01-01T00:00:00.000Z"
  },
  "token": "jwt_token_here"
}
```

**Error Responses:**
- `400 Bad Request` - Invalid request body or invalid Google token
- `500 Internal Server Error` - Authentication or database error

---

## User Management APIs

### Get Current User
**GET** `/api/user/me`

Returns the authenticated user's profile information.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (200 OK):**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "display_name": "John Doe",
  "photo_url": "https://example.com/photo.jpg",
  "conversation_count": 5,
  "created_at": "2024-01-01T00:00:00.000Z",
  "last_login_at": "2024-01-01T00:00:00.000Z"
}
```

**Error Responses:**
- `401 Unauthorized` - Invalid or missing token
- `500 Internal Server Error` - Server error

---

## Songs APIs

### Get Songs
**GET** `/api/songs`

Retrieves a paginated list of songs with optional search functionality.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Query Parameters:**
- `page` (optional, default: 1) - Page number for pagination
- `limit` (optional, default: 10) - Number of songs per page
- `search` (optional) - Search term to filter songs by title

**Example Request:**
```
GET /api/songs?page=1&limit=5&search=worship
```

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "uuid",
      "title": "Amazing Grace",
      "duration": "3:45",
      "image_url": "https://example.com/cover.jpg",
      "audio_url": "https://example.com/audio.mp3",
      "created_at": "2024-01-01T00:00:00.000Z"
    }
  ],
  "count": 25
}
```

**Error Responses:**
- `401 Unauthorized` - Invalid or missing token
- `400 Bad Request` - Invalid query parameters
- `500 Internal Server Error` - Server error

---

## Plans APIs

### Get Subscription Plans
**GET** `/api/plans`

Retrieves all available subscription plans.

**Response (200 OK):**
```json
[
  {
    "id": "uuid",
    "name": "Monthly Plan",
    "price": 49900,
    "razorpay_plan_id": "plan_7wAosPWtrkhqZw",
    "interval": 1,
    "period": "monthly",
    "cycles": 12,
    "is_prod": false,
    "created_at": "2024-01-01T00:00:00.000Z"
  }
]
```

**Note:** Plans are automatically filtered based on the current environment:
- In **development** mode (`NODE_ENV !== 'production'`): Returns only plans where `is_prod = false`
- In **production** mode (`NODE_ENV === 'production'`): Returns only plans where `is_prod = true`

**Response Fields:**
- `id`: Unique plan identifier (UUID)
- `name`: Plan name
- `price`: Plan price in paise (49900 = ₹499)
- `razorpay_plan_id`: Razorpay plan ID for subscription creation (different for dev/prod)
- `interval`: Billing interval (e.g., 1 for monthly)
- `period`: Billing period - `"daily"`, `"weekly"`, `"monthly"`, or `"yearly"`
- `cycles`: Total number of billing cycles (e.g., 12 for 12 months)
- `is_prod`: Boolean indicating if this is a production plan (`true`) or development plan (`false`)
- `created_at`: Plan creation timestamp

**Note:** 
- Currently, there is one plan available at ₹499 per month (49900 paise) for 12 months.
- Plans are automatically filtered by environment - development returns dev plans, production returns prod plans.
- Razorpay credentials are also environment-specific (see Environment Variables section).

**Error Responses:**
- `500 Internal Server Error` - Server error

---

## Subscription APIs

### Create Subscription
**POST** `/api/subscription/create`

Creates a new Razorpay subscription for the authenticated user. The subscription is for 12 months at ₹499 per month, charged upfront.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "plan_id": "uuid"
}
```

**Response (200 OK):**
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "plan_id": "uuid",
  "razorpay_subscription_id": "sub_00000000000001",
  "status": "created",
  "current_start": null,
  "current_end": null,
  "last_charged_at": null,
  "charge_at": 1580453311,
  "start_at": 1580626111,
  "end_at": 1583433000,
  "quantity": 1,
  "total_count": 12,
  "paid_count": 0,
  "created_at": "2024-01-01T00:00:00.000Z",
  "updated_at": "2024-01-01T00:00:00.000Z",
  "razorpay_subscription": {
    "id": "sub_00000000000001",
    "entity": "subscription",
    "plan_id": "plan_00000000000001",
    "status": "created",
    "short_url": "https://rzp.io/i/z3b1R61A9"
  },
  "razorpay_key_id": "rzp_test_xyz123"
}
```

**Note:** 
- The `razorpay_subscription_id` and `razorpay_key_id` are included for frontend integration.
- Use `razorpay_key_id` to identify whether you're in production or development mode (keys starting with `rzp_test_` are for development, `rzp_live_` are for production).
- The subscription charges ₹499 upfront for the first month.
- Users get 3 free conversations before requiring a subscription.

**Error Responses:**
- `401 Unauthorized` - Invalid or missing token
- `400 Bad Request` - Invalid request body or plan not found
- `500 Internal Server Error` - Server error

---

### Get Current Subscription
**GET** `/api/subscription/current`

Retrieves the current subscription for the authenticated user. Automatically fetches and updates the latest status from Razorpay.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (200 OK):**
```json
{
  "subscription": {
    "id": "uuid",
    "user_id": "uuid",
    "plan_id": "uuid",
    "razorpay_subscription_id": "sub_00000000000001",
    "status": "active",
    "current_start": 1577355871,
    "current_end": 1582655400,
    "last_charged_at": 1577355871,
    "charge_at": 1577385991,
    "start_at": 1577385991,
    "end_at": 1603737000,
    "quantity": 1,
    "total_count": 12,
    "paid_count": 1,
    "created_at": "2024-01-01T00:00:00.000Z",
    "updated_at": "2024-01-01T00:00:00.000Z",
    "plans": {
      "id": "uuid",
      "name": "Monthly Plan",
      "price": 49900,
      "razorpay_plan_id": "plan_7wAosPWtrkhqZw",
      "interval": 1,
      "period": "monthly",
      "cycles": 12
    }
  }
}
```

**Response (200 OK) - No Subscription:**
```json
{
  "subscription": null
}
```

**Error Responses:**
- `401 Unauthorized` - Invalid or missing token
- `500 Internal Server Error` - Server error

---

### Cancel Subscription
**POST** `/api/subscription/cancel`

Cancels the current subscription for the authenticated user. The subscription will be cancelled at the end of the current billing cycle.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (200 OK):**
```json
{
  "subscription": {
    "id": "uuid",
    "user_id": "uuid",
    "plan_id": "uuid",
    "razorpay_subscription_id": "sub_00000000000001",
    "status": "cancelled",
    "current_start": 1580453311,
    "current_end": 1581013800,
    "last_charged_at": 1577355871,
    "end_at": 1580288092,
    "quantity": 1,
    "total_count": 12,
    "paid_count": 1,
    "created_at": "2024-01-01T00:00:00.000Z",
    "updated_at": "2024-01-01T00:00:00.000Z"
  }
}
```

**Error Responses:**
- `401 Unauthorized` - Invalid or missing token
- `404 Not Found` - No active subscription found
- `500 Internal Server Error` - Server error

---

## Conversation APIs

### Send Message (Voice)
**POST** `/api/conversation/send-message`

Processes an audio message from the user and returns Jesus' response in both text and audio format. Increments the user's conversation count after successful response.

**Access Control:**
- Users get **3 free conversations** without a subscription
- After 3 conversations, users must have an **active subscription** to continue
- Subscription access is valid for 30 days from last charge + 1 day grace period

**Headers:**
```
Authorization: Bearer <jwt_token>
Content-Type: multipart/form-data
```

**Request Body:**
```
audio: <audio_file> (required) - Audio file in supported format (mp3, wav, webm, m4a, ogg)
```

**Response (200 OK):**
```json
{
  "success": true,
  "user_message": "నమస్కారం, నేను ఒత్తిడిలో ఉన్నాను",
  "assistant_text": "[gently] [warmly] నా బిడ్డ, నేను నిన్ను ప్రేమిస్తున్నాను. మీ ఒత్తిడిని నేను అర్థం చేసుకుంటున్నాను.",
  "assistant_audio": "data:audio/mpeg;base64,/9j/4AAQSkZJRgABAQAAAQ...",
  "conversation_count": 4
}
```

**Error Responses:**
- `401 Unauthorized` - Invalid or missing token
- `400 Bad Request` - No audio file provided or transcription failed
- `402 Payment Required` - Subscription required (exceeded free tier limit)
- `500 Internal Server Error` - TTS generation failed or server error

**Note:** 
- The response includes emotional tags in the assistant_text that are processed by ElevenLabs for expressive speech generation.
- The `conversation_count` field shows the total number of conversations the user has had.

---

## Webhook APIs

### Razorpay Webhook
**POST** `/api/webhook/razorpay`

Handles Razorpay subscription webhooks to update subscription status and track payment charges.

**Supported Events:**
- `subscription.authenticated` - First payment made on subscription
- `subscription.activated` - Subscription moved to active state
- `subscription.charged` - **Most important** - Successful charge on subscription (updates `last_charged_at`)
- `subscription.completed` - All invoices generated, subscription completed
- `subscription.updated` - Subscription updated
- `subscription.pending` - Payment failed, subscription in pending state
- `subscription.halted` - All retries exhausted, subscription halted
- `subscription.cancelled` - Subscription cancelled
- `subscription.paused` - Subscription paused
- `subscription.resumed` - Subscription resumed

**Headers:**
```
X-Razorpay-Signature: <webhook_signature>
Content-Type: application/json
```

**Request Body Example (subscription.charged):**
```json
{
  "event": "subscription.charged",
  "payload": {
    "subscription": {
      "entity": {
        "id": "sub_00000000000001",
        "entity": "subscription",
        "plan_id": "plan_00000000000001",
        "status": "active",
        "current_start": 1577355871,
        "current_end": 1582655400,
        "charge_at": 1577385991,
        "start_at": 1577385991,
        "end_at": 1603737000,
        "quantity": 1,
        "total_count": 12,
        "paid_count": 1
      }
    }
  }
}
```

**Response (200 OK):**
```json
{
  "received": true
}
```

**Error Responses:**
- `400 Bad Request` - Invalid signature or no signature provided
- `500 Internal Server Error` - Webhook processing failed

**Note:** The `subscription.charged` event is critical as it updates the `last_charged_at` timestamp, which determines user access to conversation features. The system grants access for 30 days from the last charge date, plus a 1-day grace period.

---

## Environment Variables

Create a `.env` file in the root directory with the following variables:

```env
# Server Configuration
PORT=5000
NODE_ENV=development
LOG_LEVEL=info

# Supabase Configuration
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_anon_key

# JWT Configuration
JWT_SECRET=your_jwt_secret

# Google OAuth Configuration
GOOGLE_CLIENT_ID_WEB=your_google_client_id_web
GOOGLE_CLIENT_ID_IOS=your_google_client_id_ios
GOOGLE_CLIENT_ID_ANDROID=your_google_client_id_android
GOOGLE_CLIENT_SECRET=your_google_client_secret

# Razorpay Configuration - Development
RAZORPAY_KEY_ID_DEV=your_razorpay_dev_key_id
RAZORPAY_KEY_SECRET_DEV=your_razorpay_dev_key_secret
RAZORPAY_WEBHOOK_SECRET_DEV=your_razorpay_dev_webhook_secret

# Razorpay Configuration - Production
RAZORPAY_KEY_ID_PROD=your_razorpay_prod_key_id
RAZORPAY_KEY_SECRET_PROD=your_razorpay_prod_key_secret
RAZORPAY_WEBHOOK_SECRET_PROD=your_razorpay_prod_webhook_secret

# OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key
OPENAI_MODEL=gpt-4o
OPENAI_MAX_TOKENS=800
OPENAI_TEMPERATURE=0.7

# ElevenLabs Configuration
ELEVENLABS_API_KEY=your_elevenlabs_api_key
ELEVENLABS_VOICE_ID=your_telugu_voice_id
ELEVENLABS_MODEL=eleven_multilingual_v2
```

---

## Database Schema

### Users Table
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  photo_url TEXT,
  conversation_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_login_at TIMESTAMP WITH TIME ZONE
);
```

### Songs Table
```sql
CREATE TABLE songs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  duration TEXT NOT NULL,
  image_url TEXT NOT NULL,
  audio_url TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Plans Table
```sql
CREATE TABLE plans (
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
```

### Subscriptions Table
```sql
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  razorpay_subscription_id TEXT UNIQUE NOT NULL,
  plan_id UUID REFERENCES plans(id),
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
```

---

## Getting Started

1. Install dependencies:
```bash
npm install
```

2. Set up environment variables in `.env` file

3. Create the required database tables in Supabase (see Database Schema section)

4. Run the development server:
```bash
npm run dev
```

5. Build for production:
```bash
npm run build
npm start
```

---

## API Features

- **Authentication**: Google OAuth with custom JWT tokens
- **Subscription Management**: Razorpay subscription integration (₹499/month for 12 months)
- **Free Tier**: 3 free conversations for all users before requiring subscription
- **Real-time Conversation**: Voice-to-voice conversation with Jesus in Telugu
- **Subscription Access Control**: 30-day access period from last charge + 1-day grace period
- **Comprehensive Logging**: Winston logger with structured logging
- **Error Handling**: Detailed error responses with appropriate HTTP status codes
- **Type Safety**: Full TypeScript implementation with proper type definitions

---

## Support

For any issues or questions, please refer to the application logs or contact the development team.
