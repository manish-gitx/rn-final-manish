# Testing Guide

**Current status: 62 backend tests and 75 frontend tests, all passing.**

## Running Tests

### Backend (Node.js/TypeScript — Jest)

```bash
cd TalkToJesus-backend

# Run all tests
npm test

# Run a specific test file
npx jest src/__tests__/utils/jwt.test.ts

# Run tests matching a pattern
npx jest --testPathPattern="services"

# Run with coverage report
npx jest --coverage
```

### Frontend (Flutter/Dart — flutter_test)

```bash
cd talktojesus-frontend

# Run all tests
flutter test

# Run a specific test file
flutter test test/domain/models/user_model_test.dart

# Run tests in a directory
flutter test test/domain/models/

# Run with coverage
flutter test --coverage
```

---

## Backend Tests

Located in `TalkToJesus-backend/src/__tests__/`

### Utilities

**`utils/jwt.test.ts`** — JWT token signing and verification
- signToken returns a valid JWT string
- signToken embeds the payload in the token
- signToken sets expiration to 70 days
- verifyToken returns decoded payload for a valid token
- verifyToken returns null for an invalid token
- verifyToken returns null for a token signed with a different secret
- verifyToken returns null for an expired token

**`utils/razorpay.test.ts`** — Razorpay webhook signature verification
- Returns true for a valid signature
- Returns false for an invalid signature
- Returns false for a signature with wrong length
- Returns false for tampered body

### Middleware

**`middlewares/auth.middleware.test.ts`** — JWT auth middleware
- Returns 401 when no authorization header
- Returns 401 when authorization header is not Bearer
- Returns 401 when JWT token is invalid
- Returns 401 when user is not found in database
- Sets req.user and calls next() on valid auth
- Returns 500 on unexpected error

### Services

**`services/auth.service.test.ts`** — Google OAuth user creation/login
- Creates a new user when not found in DB
- Returns existing user and updates last_login_at
- Throws on invalid Google token

**`services/subscription.service.test.ts`** — Subscription access and management
- hasActiveSubscription: returns true for free tier (count < 3)
- hasActiveSubscription: respects an admin-raised free tier limit
- hasActiveSubscription: returns false when user exceeds free tier with no subscription
- hasActiveSubscription: returns true for an active subscription
- hasActiveSubscription: prefers an active subscription over a stale created one
- hasActiveSubscription: returns true for an authenticated subscription
- hasActiveSubscription: returns true for a created subscription inside the 24h grace period
- hasActiveSubscription: returns false for a created subscription past the grace period
- hasActiveSubscription: returns false when user not found
- getUserSubscription: returns the latest subscription
- getUserSubscription: returns null when no subscription exists
- incrementConversationCount: increments and returns the new count

> Note: two of these previously failed. The cause was the local `mockQuery` helper
> making only `.single()` awaitable, while `hasActiveSubscription` awaits the
> subscriptions query builder directly to get an array. Every "expect false" case
> was passing for the wrong reason. The chain is now thenable and the cases match
> the current status-priority logic (`active`/`authenticated` grant access;
> `created` gets a 24-hour grace period).

**`middlewares/admin.middleware.test.ts`** — Admin route gate
- Returns 401 when no user is attached to the request
- Returns 404 when the user is not an admin
- Returns 404 when is_admin is missing entirely
- Rejects a truthy-but-not-true is_admin value
- Calls next() for an admin user

**`services/adminStats.service.test.ts`** — Dashboard analytics maths
- percentile: null for empty set, single sample, odd/even medians, p95, no input mutation
- computeMrrRupees: zero, paise→rupee conversion, summing, null-plan tolerance
- computeConversionRate: zero-user guard, one-decimal rounding, 0% and 100% cases

**`services/webhook.service.test.ts`** — Razorpay webhook event handling
- Handles subscription.charged and sets last_charged_at
- Handles subscription.cancelled
- Handles subscription.authenticated and sets last_charged_at
- Ignores non-subscription events gracefully
- Handles missing subscription data in payload
- Handles subscription.activated and sets last_charged_at as fallback

**`services/song.service.test.ts`** — Song listing with pagination and search
- Returns paginated songs with correct offset
- Applies search filter when provided
- Does not apply search filter when not provided
- Throws on database error
- Calculates correct offset for first page

---

## Frontend Tests

Located in `talktojesus-frontend/test/`

### Models

**`domain/models/user_model_test.dart`** — UserModel and CreateOrGetUserResponse
- fromJson parses all fields correctly
- fromJson handles null optional fields
- toJson produces correct snake_case keys
- fromJson/toJson round-trip preserves data
- copyWith creates a new instance with updated fields
- isTester returns true for tester user ID
- isTester returns false for regular user
- CreateOrGetUserResponse fromJson parses nested user and token
- CreateOrGetUserResponse fromJson handles null token

**`domain/models/plan_model_test.dart`** — Plan model and currency helpers
- fromJson parses all fields correctly
- toJson produces correct keys
- fromJson/toJson round-trip preserves data
- priceInRupees converts paise to rupees
- priceInRupees handles fractional amounts
- formattedPrice returns rupee symbol with amount
- formattedPrice truncates decimals

**`domain/models/subscription_model_test.dart`** — Subscription, CreateSubscriptionResponse, CurrentSubscriptionResponse
- fromJson parses all fields correctly
- fromJson parses nested plan when present
- toJson produces correct keys
- toJson includes plan when present
- isActive returns true for active status
- isActive returns true for authenticated status
- isActive returns false for cancelled status
- isCancelled returns true for cancelled status
- isPaused returns true for paused status
- isPastDue returns true for past_due status
- CreateSubscriptionResponse shortUrl returns value from razorpaySubscription
- CreateSubscriptionResponse shortUrl returns null when razorpaySubscription is null
- CurrentSubscriptionResponse fromJson handles null subscription

**`domain/models/song_test.dart`** — Song model equality and copyWith
- copyWith updates specified fields only
- copyWith with no args returns equal copy
- Equality works for identical songs
- Equality fails for different songs
- hashCode is consistent for equal objects
- toString includes all fields
- Handles null optional fields

**`domain/models/conversation_response_test.dart`** — ConversationResponse serialization
- fromJson parses all fields
- fromJson handles null/missing fields with defaults
- toJson produces snake_case keys
- fromJson/toJson round-trip

**`domain/models/bible_cache_test.dart`** — BibleCacheEntry and ReadingPosition
- toMap/fromMap round-trip preserves all fields
- fromMap handles missing optional fields with defaults
- isExpired returns false for future expiry
- isExpired returns true for past expiry
- copyWithAccess increments access count
- copyWith updates only specified fields
- ReadingPosition toMap/fromMap round-trip preserves all fields
- ReadingPosition positionKey combines translationId and bookId

**`domain/models/bible_data_test.dart`** — Static Bible reference data
- Books list is not empty
- Genesis is the first book with 50 chapters
- Psalms has 150 chapters
- All books have positive chapter counts
- Versions list contains expected translations
- Versions list has 6 entries
- BibleBook can be constructed with name and totalChapters

**`domain/models/user_model_test.dart`** (admin additions)
- isAdmin defaults to false when the field is absent
- isAdmin parses true from the backend
- isAdmin survives a toJson/fromJson round-trip
- copyWith can toggle isAdmin without touching other fields

### Constants

**`core/constants/app_strings_test.dart`** — Bilingual UI copy
- Every English key has a Telugu translation (guards against drift)
- Returns the translated string for each language
- English and Telugu values actually differ
- Falls back to the key itself for an unknown key
- getAll returns a non-empty map for both languages
- Covers the screens used in the demo flow

### Providers

**`core/providers/app_state_provider_test.dart`** — AppState and AppStateNotifier
- AppState has correct default values
- AppState copyWith updates only specified fields
- AppStateNotifier initial state has default values
- setLanguage updates the language
- toggleHighContrastMode toggles the mode
- setAudioPermission sets the permission flag
- incrementCounter increases counter by 1
- resetCounter sets counter back to 0
- AppLanguage english has correct code and displayName
- AppLanguage telugu has correct code and displayName
