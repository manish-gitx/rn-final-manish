| ID | Suite | Case | Result |
|---|---|---|---|
| BE-001 | `admin.middleware.test.ts` | Admin Middleware - should return 401 when no user is attached to the request | Pass |
| BE-002 | `admin.middleware.test.ts` | Admin Middleware - should return 404 when the user is not an admin | Pass |
| BE-003 | `admin.middleware.test.ts` | Admin Middleware - should return 404 when is_admin is missing entirely | Pass |
| BE-004 | `admin.middleware.test.ts` | Admin Middleware - should reject a truthy-but-not-true is_admin value | Pass |
| BE-005 | `admin.middleware.test.ts` | Admin Middleware - should call next() for an admin user | Pass |
| BE-006 | `consoleAdmin.auth.test.ts` | Console admin authentication - authenticates a console token without reading the users table | Pass |
| BE-007 | `consoleAdmin.auth.test.ts` | Console admin authentication - passes the admin gate once authenticated | Pass |
| BE-008 | `consoleAdmin.auth.test.ts` | Console admin authentication - rejects a console token once ADMIN_EMAIL is removed | Pass |
| BE-009 | `consoleAdmin.auth.test.ts` | Console admin authentication - does not let a forged claim through without a valid signature | Pass |
| BE-010 | `jwt.test.ts` | JWT Utility - signToken - should return a valid JWT string | Pass |
| BE-011 | `jwt.test.ts` | JWT Utility - signToken - should embed the payload in the token | Pass |
| BE-012 | `jwt.test.ts` | JWT Utility - signToken - should set expiration to 70 days | Pass |
| BE-013 | `jwt.test.ts` | JWT Utility - verifyToken - should return decoded payload for a valid token | Pass |
| BE-014 | `jwt.test.ts` | JWT Utility - verifyToken - should return null for an invalid token | Pass |
| BE-015 | `jwt.test.ts` | JWT Utility - verifyToken - should return null for a token signed with a different secret | Pass |
| BE-016 | `jwt.test.ts` | JWT Utility - verifyToken - should return null for an expired token | Pass |
| BE-017 | `webhook.service.test.ts` | Webhook Service - should handle subscription.charged and set last_charged_at | Pass |
| BE-018 | `webhook.service.test.ts` | Webhook Service - should handle subscription.cancelled | Pass |
| BE-019 | `webhook.service.test.ts` | Webhook Service - should handle subscription.authenticated and set last_charged_at from current_start | Pass |
| BE-020 | `webhook.service.test.ts` | Webhook Service - should ignore non-subscription events gracefully | Pass |
| BE-021 | `webhook.service.test.ts` | Webhook Service - should handle missing subscription data in payload | Pass |
| BE-022 | `webhook.service.test.ts` | Webhook Service - should handle subscription.activated and set last_charged_at as fallback | Pass |
| BE-023 | `adminStats.service.test.ts` | Admin Stats Service - percentile - returns null for an empty set | Pass |
| BE-024 | `adminStats.service.test.ts` | Admin Stats Service - percentile - returns the only value for a single sample | Pass |
| BE-025 | `adminStats.service.test.ts` | Admin Stats Service - percentile - computes the median of an odd-length set | Pass |
| BE-026 | `adminStats.service.test.ts` | Admin Stats Service - percentile - interpolates the median of an even-length set | Pass |
| BE-027 | `adminStats.service.test.ts` | Admin Stats Service - percentile - computes p95 near the top of the range | Pass |
| BE-028 | `adminStats.service.test.ts` | Admin Stats Service - percentile - does not mutate the input array | Pass |
| BE-029 | `adminStats.service.test.ts` | Admin Stats Service - computeMrrRupees - returns 0 with no subscriptions | Pass |
| BE-030 | `adminStats.service.test.ts` | Admin Stats Service - computeMrrRupees - converts paise to rupees | Pass |
| BE-031 | `adminStats.service.test.ts` | Admin Stats Service - computeMrrRupees - sums across subscriptions | Pass |
| BE-032 | `adminStats.service.test.ts` | Admin Stats Service - computeMrrRupees - treats a missing or null plan as zero rather than throwing | Pass |
| BE-033 | `adminStats.service.test.ts` | Admin Stats Service - computeConversionRate - returns 0 when there are no users, without dividing by zero | Pass |
| BE-034 | `adminStats.service.test.ts` | Admin Stats Service - computeConversionRate - computes a percentage to one decimal place | Pass |
| BE-035 | `adminStats.service.test.ts` | Admin Stats Service - computeConversionRate - returns 100 when every user pays | Pass |
| BE-036 | `adminStats.service.test.ts` | Admin Stats Service - computeConversionRate - returns 0 when nobody pays | Pass |
| BE-037 | `auth.middleware.test.ts` | Auth Middleware - should return 401 when no authorization header | Pass |
| BE-038 | `auth.middleware.test.ts` | Auth Middleware - should return 401 when authorization header is not Bearer | Pass |
| BE-039 | `auth.middleware.test.ts` | Auth Middleware - should return 401 when JWT token is invalid | Pass |
| BE-040 | `auth.middleware.test.ts` | Auth Middleware - should return 401 when user is not found in database | Pass |
| BE-041 | `auth.middleware.test.ts` | Auth Middleware - should set req.user and call next() on valid auth | Pass |
| BE-042 | `auth.middleware.test.ts` | Auth Middleware - should return 500 on unexpected error | Pass |
| BE-043 | `song.service.test.ts` | Song Service - should return paginated songs with correct offset | Pass |
| BE-044 | `song.service.test.ts` | Song Service - should apply search filter when provided | Pass |
| BE-045 | `song.service.test.ts` | Song Service - should not apply search filter when not provided | Pass |
| BE-046 | `song.service.test.ts` | Song Service - should throw on database error | Pass |
| BE-047 | `song.service.test.ts` | Song Service - should calculate correct offset for first page | Pass |
| BE-048 | `razorpay.test.ts` | Razorpay Utility - verifyWebhookSignature - should return true for a valid signature | Pass |
| BE-049 | `razorpay.test.ts` | Razorpay Utility - verifyWebhookSignature - should return false for an invalid signature | Pass |
| BE-050 | `razorpay.test.ts` | Razorpay Utility - verifyWebhookSignature - should return false for a signature with wrong length | Pass |
| BE-051 | `razorpay.test.ts` | Razorpay Utility - verifyWebhookSignature - should return false for tampered body | Pass |
| BE-052 | `subscription.service.test.ts` | Subscription Service - hasActiveSubscription - should return true when user is within free tier (count < 3) | Pass |
| BE-053 | `subscription.service.test.ts` | Subscription Service - hasActiveSubscription - should respect a custom free tier limit | Pass |
| BE-054 | `subscription.service.test.ts` | Subscription Service - hasActiveSubscription - should return false when user exceeds free tier and has no subscription | Pass |
| BE-055 | `subscription.service.test.ts` | Subscription Service - hasActiveSubscription - should return true for an active subscription | Pass |
| BE-056 | `subscription.service.test.ts` | Subscription Service - hasActiveSubscription - should prefer an active subscription over a stale created one | Pass |
| BE-057 | `subscription.service.test.ts` | Subscription Service - hasActiveSubscription - should return true for an authenticated subscription | Pass |
| BE-058 | `subscription.service.test.ts` | Subscription Service - hasActiveSubscription - should return true for a created subscription inside the 24h grace period | Pass |
| BE-059 | `subscription.service.test.ts` | Subscription Service - hasActiveSubscription - should return false for a created subscription past the 24h grace period | Pass |
| BE-060 | `subscription.service.test.ts` | Subscription Service - hasActiveSubscription - should return false when user not found | Pass |
| BE-061 | `subscription.service.test.ts` | Subscription Service - getUserSubscription - should return the latest subscription | Pass |
| BE-062 | `subscription.service.test.ts` | Subscription Service - getUserSubscription - should return null when no subscription exists | Pass |
| BE-063 | `subscription.service.test.ts` | Subscription Service - incrementConversationCount - should increment and return the new count | Pass |
| BE-064 | `auth.service.test.ts` | Auth Service - should create a new user when not found in DB | Pass |
| BE-065 | `auth.service.test.ts` | Auth Service - should return existing user and update last_login_at | Pass |
| BE-066 | `auth.service.test.ts` | Auth Service - should throw on invalid Google token | Pass |
| FE-001 | `app_strings_test.dart` | AppStrings every English key has a Telugu translation | Pass |
| FE-002 | `conversation_response_test.dart` | ConversationResponse fromJson parses all fields | Pass |
| FE-003 | `app_strings_test.dart` | AppStrings returns the translated string for each language | Pass |
| FE-004 | `conversation_response_test.dart` | ConversationResponse fromJson handles null/missing fields with defaults | Pass |
| FE-005 | `app_strings_test.dart` | AppStrings English and Telugu values actually differ | Pass |
| FE-006 | `conversation_response_test.dart` | ConversationResponse toJson produces snake_case keys | Pass |
| FE-007 | `app_strings_test.dart` | AppStrings falls back to the key itself for an unknown key | Pass |
| FE-008 | `conversation_response_test.dart` | ConversationResponse fromJson/toJson round-trip | Pass |
| FE-009 | `app_strings_test.dart` | AppStrings getAll returns a non-empty map for both languages | Pass |
| FE-010 | `app_strings_test.dart` | AppStrings covers the screens used in the demo flow | Pass |
| FE-011 | `app_state_provider_test.dart` | AppState has correct default values | Pass |
| FE-012 | `app_state_provider_test.dart` | AppState copyWith updates only specified fields | Pass |
| FE-013 | `app_state_provider_test.dart` | AppStateNotifier initial state has default values | Pass |
| FE-014 | `app_state_provider_test.dart` | AppStateNotifier setLanguage updates the language | Pass |
| FE-015 | `app_state_provider_test.dart` | AppStateNotifier toggleHighContrastMode toggles the mode | Pass |
| FE-016 | `app_state_provider_test.dart` | AppStateNotifier setAudioPermission sets the permission flag | Pass |
| FE-017 | `app_state_provider_test.dart` | AppStateNotifier incrementCounter increases counter by 1 | Pass |
| FE-018 | `app_state_provider_test.dart` | AppStateNotifier resetCounter sets counter back to 0 | Pass |
| FE-019 | `app_state_provider_test.dart` | AppLanguage english has correct code and displayName | Pass |
| FE-020 | `app_state_provider_test.dart` | AppLanguage telugu has correct code and displayName | Pass |
| FE-021 | `bible_cache_test.dart` | BibleCacheEntry toMap/fromMap round-trip preserves all fields | Pass |
| FE-022 | `subscription_model_test.dart` | Subscription fromJson parses all fields correctly | Pass |
| FE-023 | `bible_cache_test.dart` | BibleCacheEntry fromMap handles missing optional fields with defaults | Pass |
| FE-024 | `bible_cache_test.dart` | BibleCacheEntry isExpired returns false for future expiry | Pass |
| FE-025 | `bible_cache_test.dart` | BibleCacheEntry isExpired returns true for past expiry | Pass |
| FE-026 | `bible_cache_test.dart` | BibleCacheEntry copyWithAccess increments access count | Pass |
| FE-027 | `bible_cache_test.dart` | BibleCacheEntry copyWith updates only specified fields | Pass |
| FE-028 | `subscription_model_test.dart` | Subscription fromJson parses nested plan when present | Pass |
| FE-029 | `bible_cache_test.dart` | ReadingPosition toMap/fromMap round-trip preserves all fields | Pass |
| FE-030 | `bible_cache_test.dart` | ReadingPosition positionKey combines translationId and bookId | Pass |
| FE-031 | `subscription_model_test.dart` | Subscription toJson produces correct keys | Pass |
| FE-032 | `subscription_model_test.dart` | Subscription toJson includes plan when present | Pass |
| FE-033 | `subscription_model_test.dart` | Subscription isActive returns true for active status | Pass |
| FE-034 | `subscription_model_test.dart` | Subscription isActive returns true for authenticated status | Pass |
| FE-035 | `subscription_model_test.dart` | Subscription isActive returns false for cancelled status | Pass |
| FE-036 | `subscription_model_test.dart` | Subscription isCancelled returns true for cancelled status | Pass |
| FE-037 | `subscription_model_test.dart` | Subscription isPaused returns true for paused status | Pass |
| FE-038 | `subscription_model_test.dart` | Subscription isPastDue returns true for past_due status | Pass |
| FE-039 | `subscription_model_test.dart` | CreateSubscriptionResponse shortUrl returns value from razorpaySubscription | Pass |
| FE-040 | `subscription_model_test.dart` | CreateSubscriptionResponse shortUrl returns null when razorpaySubscription is null | Pass |
| FE-041 | `subscription_model_test.dart` | CurrentSubscriptionResponse fromJson handles null subscription | Pass |
| FE-042 | `user_model_test.dart` | UserModel fromJson parses all fields correctly | Pass |
| FE-043 | `user_model_test.dart` | UserModel fromJson handles null optional fields | Pass |
| FE-044 | `user_model_test.dart` | UserModel toJson produces correct snake_case keys | Pass |
| FE-045 | `user_model_test.dart` | UserModel fromJson/toJson round-trip preserves data | Pass |
| FE-046 | `user_model_test.dart` | UserModel copyWith creates a new instance with updated fields | Pass |
| FE-047 | `user_model_test.dart` | UserModel isAdmin defaults to false when the field is absent | Pass |
| FE-048 | `user_model_test.dart` | UserModel isAdmin parses true from the backend | Pass |
| FE-049 | `user_model_test.dart` | UserModel isAdmin survives a toJson/fromJson round-trip | Pass |
| FE-050 | `user_model_test.dart` | UserModel copyWith can toggle isAdmin without touching other fields | Pass |
| FE-051 | `user_model_test.dart` | UserModel isTester returns true for tester user ID | Pass |
| FE-052 | `user_model_test.dart` | UserModel isTester returns false for regular user | Pass |
| FE-053 | `user_model_test.dart` | CreateOrGetUserResponse fromJson parses nested user and token | Pass |
| FE-054 | `user_model_test.dart` | CreateOrGetUserResponse fromJson handles null token | Pass |
| FE-055 | `bible_data_test.dart` | BibleData books list is not empty | Pass |
| FE-056 | `bible_data_test.dart` | BibleData Genesis is the first book with 50 chapters | Pass |
| FE-057 | `bible_data_test.dart` | BibleData Psalms has 150 chapters | Pass |
| FE-058 | `bible_data_test.dart` | BibleData all books have positive chapter counts | Pass |
| FE-059 | `bible_data_test.dart` | BibleData versions list contains expected translations | Pass |
| FE-060 | `bible_data_test.dart` | BibleData versions list has 6 entries | Pass |
| FE-061 | `bible_data_test.dart` | BibleBook can be constructed with name and totalChapters | Pass |
| FE-062 | `song_test.dart` | Song copyWith updates specified fields only | Pass |
| FE-063 | `song_test.dart` | Song copyWith with no args returns equal copy | Pass |
| FE-064 | `song_test.dart` | Song equality works for identical songs | Pass |
| FE-065 | `song_test.dart` | Song equality fails for different songs | Pass |
| FE-066 | `song_test.dart` | Song hashCode is consistent for equal objects | Pass |
| FE-067 | `song_test.dart` | Song toString includes all fields | Pass |
| FE-068 | `song_test.dart` | Song handles null optional fields | Pass |
| FE-069 | `plan_model_test.dart` | Plan fromJson parses all fields correctly | Pass |
| FE-070 | `plan_model_test.dart` | Plan toJson produces correct keys | Pass |
| FE-071 | `plan_model_test.dart` | Plan fromJson/toJson round-trip preserves data | Pass |
| FE-072 | `plan_model_test.dart` | Plan priceInRupees converts paise to rupees | Pass |
| FE-073 | `plan_model_test.dart` | Plan priceInRupees handles fractional amounts | Pass |
| FE-074 | `plan_model_test.dart` | Plan formattedPrice returns rupee symbol with amount | Pass |
| FE-075 | `plan_model_test.dart` | Plan formattedPrice truncates decimals | Pass |
