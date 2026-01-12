# Talk to Jesus

> A spiritual companion mobile application that allows users to have meaningful conversations with an AI-powered Jesus, listen to spiritual music, and access premium features through subscription plans.

---

## 📋 Table of Contents

- [Problem Statement](#-problem-statement)
- [Tech Stack](#-tech-stack)
- [Features Implemented](#-features-implemented)
- [How to Run Locally](#-how-to-run-locally)
- [API Documentation](#-api-documentation)
- [Project Structure](#-project-structure)
- [License](#-license)

---

## 🎯 Problem Statement

### The Opportunity

Simple Bible applications in Telugu have garnered **millions of downloads**, yet they only offer static content—books, scriptures, and songs. While these resources are valuable, they lack the **interactive, personalized guidance** that modern believers seek.

### The Gap

Despite the massive demand for spiritual content, existing solutions fall short:

- **One-Way Communication**: Traditional Bible apps provide information but no conversation or personalized guidance
- **Limited Accessibility**: Seeking guidance from pastors or spiritual counselors requires:
  - Physical visits to churches or religious centers
  - Scheduling appointments that may not align with urgent spiritual needs
  - Overcoming social barriers or hesitation to share personal struggles
- **No Context-Aware Guidance**: Users read scriptures but often struggle to apply them to their specific life situations
- **Language & Cultural Barriers**: Limited availability of AI-powered spiritual guidance in regional languages

### The Innovation

**What if millions of believers could have direct, meaningful conversations with an AI-powered Jesus avatar?**

Talk to Jesus bridges this gap by transforming passive scripture reading into **active spiritual dialogue**:

🎙️ **Interactive Avatar**: An AI-powered Jesus that speaks to you, not just text on a screen  
📖 **Scripture-Based Wisdom**: Every response is grounded in biblical teachings and scriptures  
🌍 **Always Available**: 24/7 spiritual guidance without appointments or waiting  
🔒 **Private & Judgment-Free**: Share your deepest concerns in complete confidentiality  
💬 **Context-Aware**: Personalized responses based on your specific situation and questions  
🌐 **Multi-Language Support**: Full support for English and Telugu languages  
🎵 **Holistic Experience**: Combines spiritual conversations with curated worship music

### The Impact

If basic Bible apps can reach millions, an **intelligent, conversational spiritual companion** has the potential to:
- Democratize access to spiritual guidance
- Provide immediate comfort during times of crisis
- Help believers apply scriptures to real-life challenges
- Reduce barriers to seeking spiritual help
- Serve as a 24/7 spiritual counselor in your pocket

---

## 🛠️ Tech Stack

### Frontend (Mobile App)
- **Framework**: Flutter (Dart)
- **State Management**: Riverpod (with app-wide language state management)
- **Authentication**: Firebase Auth, Google Sign-In
- **Database**: Cloud Firestore, SQLite (local storage)
- **Internationalization**: Multi-language support (English & Telugu)
- **UI/UX**: 
  - Material Design
  - Custom animations (Lottie)
  - Google Fonts
  - Shimmer effects
- **Audio**: 
  - Audioplayers (music playback)
  - Record (voice recording)
  - Permission Handler
- **Payment**: Razorpay Flutter
- **Analytics & Monitoring**: 
  - PostHog (product analytics)
  - Sentry (error tracking)
- **Other**: 
  - HTTP (API calls)
  - Connectivity Plus (network status)
  - In-App Review

### Backend (API Server)
- **Runtime**: Node.js
- **Framework**: Express.js
- **Language**: TypeScript
- **Database**: Supabase (PostgreSQL)
- **Authentication**: 
  - Google OAuth (google-auth-library)
  - JWT (jsonwebtoken)
- **AI Services**:
  - OpenAI API (GPT for conversations with multi-language support)
  - ElevenLabs API (text-to-speech with language-specific emotional tags)
  - Speech-to-Text service (auto-detect language)
- **Payment Processing**: Razorpay
- **File Handling**: Multer, Form-Data
- **Logging**: Winston
- **Validation**: Zod
- **Other**: Axios, CORS, dotenv

### Infrastructure & Tools
- **Version Control**: Git & GitHub
- **Database**: Supabase (PostgreSQL)
- **Cloud Services**: Firebase
- **Payment Gateway**: Razorpay
- **AI APIs**: OpenAI, ElevenLabs

---

## ✨ Features Implemented

### 🔐 Authentication & User Management
- Google OAuth 2.0 integration
- JWT-based session management
- User profile management
- Last login tracking
- Secure token-based authentication

### 💬 Conversation Features
- AI-powered conversations with contextual responses
- Voice input support (speech-to-text)
- Voice output support (text-to-speech using ElevenLabs)
- Conversation history tracking
- Real-time message processing
- Multi-language conversation support (English & Telugu)

### 🌐 Multi-Language Support
- **Bilingual Interface**: Seamless switching between English and Telugu
- **Language-Aware UI**: All UI elements update dynamically based on selected language
- **Intelligent AI Responses**: AI automatically responds in the user's selected language
- **Language-Specific Prompts**: Custom system prompts optimized for each language
- **Cultural Context**: Language-appropriate emotional expressions and addressing (e.g., "My child" in English, "నా బిడ్డ" in Telugu)
- **TTS Optimization**: Emotional tags and speech patterns tailored for each language
- **Supported Languages**:
  - 🇬🇧 **English**: Full feature support with native expressions
  - 🇮🇳 **Telugu**: Complete Telugu language support with culturally appropriate responses

### 🎵 Music & Spiritual Content
- Curated spiritual songs library
- Audio player with play/pause controls
- Music streaming functionality
- Song search and filtering
- Pagination support

### 💳 Subscription & Payments
- Multiple subscription plans (Free, Basic, Premium)
- Razorpay payment gateway integration
- Subscription status tracking
- Auto-renewal support
- Payment webhooks for real-time updates
- Transaction history

### 📱 Mobile App Features
- Beautiful, intuitive UI with custom animations
- Multi-language support (English & Telugu)
- Offline support with local database caching
- Network connectivity monitoring
- Error tracking and crash reporting (Sentry)
- Product analytics (PostHog)
- In-app review prompts
- Cross-platform support (Android & iOS)

### 🔒 Security Features
- Protected API routes with JWT middleware
- Secure webhook verification
- Environment-based configuration
- Token validation and expiry handling

---

## 🚀 How to Run Locally

### Prerequisites

Before you begin, ensure you have the following installed:
- **Node.js** (v18 or higher)
- **npm** or **yarn**
- **Flutter SDK** (v3.0 or higher)
- **Android Studio** (for Android development)
- **Xcode** (for iOS development, macOS only)
- **Git**

### Backend Setup

1. **Navigate to the backend directory**:
   ```bash
   cd TalkToJesus-backend
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Create environment file**:
   Create a `.env` file in the backend root with the following variables:
   ```env
   # Server Configuration
   PORT=3000
   NODE_ENV=development

   # Supabase Configuration
   SUPABASE_URL=your_supabase_url
   SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key

   # JWT Configuration
   JWT_SECRET=your_jwt_secret_key

   # Google OAuth
   GOOGLE_CLIENT_ID=your_google_client_id

   # OpenAI API
   OPENAI_API_KEY=your_openai_api_key

   # ElevenLabs API
   ELEVENLABS_API_KEY=your_elevenlabs_api_key

   # Razorpay Configuration
   RAZORPAY_KEY_ID=your_razorpay_key_id
   RAZORPAY_KEY_SECRET=your_razorpay_key_secret
   RAZORPAY_WEBHOOK_SECRET=your_razorpay_webhook_secret
   ```

4. **Set up the database**:
   ```bash
   # Run the SQL setup script in your Supabase dashboard
   # File location: TalkToJesus-backend/supabase-setup.sql
   ```

5. **Start the development server**:
   ```bash
   npm run dev
   ```
   The backend will run on `http://localhost:3000`

6. **For production build**:
   ```bash
   npm run build
   npm start
   ```

### Frontend Setup

1. **Navigate to the frontend directory**:
   ```bash
   cd talktojesus-frontend
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**:
   - Download `google-services.json` for Android and place it in `android/app/`
   - Download `GoogleService-Info.plist` for iOS and place it in `ios/Runner/`
   - Update `lib/firebase_options.dart` with your Firebase configuration

4. **Update API configuration**:
   - Update the backend API URL in your app configuration
   - Ensure all API endpoints point to your backend server

5. **Run the app**:
   
   **For Android**:
   ```bash
   flutter run
   # Or specify device
   flutter run -d android
   ```

   **For iOS** (macOS only):
   ```bash
   flutter run -d ios
   ```

6. **Build for production**:
   
   **Android APK**:
   ```bash
   flutter build apk --release
   ```

   **Android App Bundle**:
   ```bash
   flutter build appbundle --release
   ```

   **iOS**:
   ```bash
   flutter build ios --release
   ```

### Environment Configuration

#### Backend Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `PORT` | Server port number | Yes |
| `SUPABASE_URL` | Supabase project URL | Yes |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service role key | Yes |
| `JWT_SECRET` | Secret key for JWT signing | Yes |
| `GOOGLE_CLIENT_ID` | Google OAuth client ID | Yes |
| `OPENAI_API_KEY` | OpenAI API key for conversations | Yes |
| `ELEVENLABS_API_KEY` | ElevenLabs API key for TTS | Yes |
| `RAZORPAY_KEY_ID` | Razorpay key ID | Yes |
| `RAZORPAY_KEY_SECRET` | Razorpay secret key | Yes |
| `RAZORPAY_WEBHOOK_SECRET` | Razorpay webhook secret | Yes |

#### Frontend Configuration

- Configure Firebase through `google-services.json` and `GoogleService-Info.plist`
- Update API endpoints in the app configuration
- Configure Sentry DSN for error tracking (optional)
- Configure PostHog API key for analytics (optional)

### Testing the Application

1. **Start the backend server** (ensure it's running on `http://localhost:3000`)

2. **Launch the mobile app** on an emulator or physical device

3. **Test the flow**:
   - Sign in with Google
   - Toggle between English and Telugu languages
   - Start a conversation in English mode
   - Switch to Telugu and start another conversation
   - Try voice recording in both languages
   - Browse songs and play music
   - Test subscription flow (use Razorpay test mode)

---

## 📚 API Documentation

For detailed API documentation including all endpoints, request/response formats, and examples, please refer to:

**[Backend API Documentation →](./TalkToJesus-backend/README.md)**

### Quick API Overview

The backend provides the following API groups:

- **Authentication**: User signup/signin with Google OAuth
- **User Management**: Profile information and user data
- **Conversations**: AI-powered chat with voice support
- **Songs**: Spiritual music library management
- **Plans**: Subscription plan information
- **Subscriptions**: User subscription management
- **Payments**: Payment processing with Razorpay
- **Webhooks**: Payment status updates

All authenticated endpoints require a JWT token in the Authorization header:
```
Authorization: Bearer <jwt_token>
```

Base URL (local): `http://localhost:3000/api`

---

## 📁 Project Structure

```
rn-final-manish/
├── TalkToJesus-backend/          # Backend API (Node.js/Express)
│   ├── src/
│   │   ├── api/
│   │   │   ├── controllers/      # Request handlers
│   │   │   ├── middlewares/      # Auth & validation
│   │   │   ├── routes/           # API routes
│   │   │   └── services/         # Business logic
│   │   ├── config/               # Configuration files
│   │   ├── models/               # Data models
│   │   ├── utils/                # Utility functions
│   │   └── index.ts              # Server entry point
│   ├── logs/                     # Application logs
│   ├── package.json              # Dependencies
│   ├── tsconfig.json             # TypeScript config
│   ├── supabase-setup.sql        # Database schema
│   └── README.md                 # Backend documentation
│
└── talktojesus-frontend/         # Frontend (Flutter)
    ├── lib/
    │   ├── core/                 # Core utilities & constants
    │   ├── data/                 # Data layer (repositories, APIs)
    │   ├── domain/               # Business logic & models
    │   ├── presentation/         # UI screens & widgets
    │   ├── firebase_options.dart # Firebase configuration
    │   └── main.dart             # App entry point
    ├── android/                  # Android-specific files
    ├── ios/                      # iOS-specific files
    ├── assets/                   # Images, music, animations
    │   ├── images/
    │   ├── music/
    │   ├── svg/
    │   └── lottie/
    ├── pubspec.yaml              # Flutter dependencies
    └── README.md                 # Frontend documentation
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## 📄 License

This project is licensed under the ISC License.

---

## 👨‍💻 Developer

**Manish**  
GitHub: [@manish-gitx](https://github.com/manish-gitx)

---

## 📞 Support

For any queries or issues, please open an issue in the GitHub repository.

---

**Made with ❤️ for spiritual seekers everywhere**

