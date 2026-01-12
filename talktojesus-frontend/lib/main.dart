import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'core/navigation/app_router.dart';
import 'core/navigation/app_routes.dart';
import 'core/navigation/navigation_service.dart';
import 'core/widgets/error_boundary.dart';
import 'core/providers/app_state_provider.dart';
import 'core/providers/analytics_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/constants/colors.dart';
import 'core/accessibility/focus_manager.dart';
import 'core/config/flavor_config.dart';
import 'data/services/in_app_review_service.dart';
import 'data/services/token_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'presentation/pages/loading_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize flavor configuration with production settings
  if (!FlavorConfig.isInitialized) {
    FlavorConfig.initialize(
      flavor: Flavor.prod,
      name: 'TalkToJesus',
      appIdSuffix: '',
      posthogApiKey: 'phc_6HuKQBC0LXXvL6nPeXsdM3JUbNexAWKBc7iyOn9YbhK',
      posthogHost: 'https://app.posthog.com',
      sentryDsn:
          'https://9a8f5dbcb014f55c7077249034fc9ce3@o4510107037728768.ingest.us.sentry.io/4510107039694848',
      enableAnalytics: true,
      enableErrorTracking: true,
      enableDebugLogging: false,
    );
  }

  final config = FlavorConfig.instance;
  config.logConfig();

  // Validate configuration for production builds
  if (config.isProduction && !config.isValid) {
    throw Exception(
      'Invalid configuration for production build. Please set POSTHOG_API_KEY and SENTRY_DSN.',
    );
  }

  // Initialize PostHog
  Posthog? posthogInstance;
  if (config.enableAnalytics && config.posthogApiKey.isNotEmpty) {
    try {
      final posthogConfig = PostHogConfig(config.posthogApiKey);
      posthogConfig.host = config.posthogHost;
      await Posthog().setup(posthogConfig);
      posthogInstance = Posthog();
      debugPrint('✅ PostHog initialized successfully');
    } catch (e) {
      debugPrint('⚠️ PostHog initialization failed: $e');
    }
  } else {
    debugPrint('⚠️ PostHog analytics disabled or API key not provided.');
  }

  // Initialize services
  final inAppReviewService = InAppReviewService();
  await inAppReviewService.init();

  // Initialize token service
  await TokenService().init();

  // Setup global error handling
  GlobalErrorHandler.setup();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Sentry only if enabled and DSN is provided
  if (config.enableErrorTracking && config.sentryDsn.isNotEmpty) {
    await SentryFlutter.init((options) {
      options.dsn = config.sentryDsn;
      options.environment = config.sentryEnvironment;
      options.sendDefaultPii = config.sentrySendPii;
      options.enableLogs = config.enableDebugLogging;

      // Flavor-based sample rates
      options.tracesSampleRate = config.sentryTracesSampleRate;
      options.profilesSampleRate = config.sentryProfilesSampleRate;

      // Session Replay configuration
      options.replay.sessionSampleRate = config.sentryReplaySessionSampleRate;
      options.replay.onErrorSampleRate = config.sentryReplayErrorSampleRate;

      // Release tracking
      options.release = 'talktojesus@1.0.0+1';
      options.dist = '1';
    }, appRunner: () => _runApp(posthogInstance, inAppReviewService));
  } else {
    debugPrint('⚠️ Sentry error tracking disabled or DSN not provided.');
    _runApp(posthogInstance, inAppReviewService);
  }
}

void _runApp(Posthog? posthogInstance, InAppReviewService inAppReviewService) {
  runApp(
    SentryWidget(
      child: ProviderScope(
        overrides: [
          // Override analytics provider with initialized PostHog instance
          analyticsProvider.overrideWithValue(posthogInstance),
        ],
        child: TalkToJesusApp(inAppReviewService: inAppReviewService),
      ),
    ),
  );
}

class TalkToJesusApp extends ConsumerStatefulWidget {
  final InAppReviewService inAppReviewService;
  const TalkToJesusApp({super.key, required this.inAppReviewService});

  @override
  ConsumerState<TalkToJesusApp> createState() => _TalkToJesusAppState();
}

class _TalkToJesusAppState extends ConsumerState<TalkToJesusApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestReview();
    _trackAppOpened();
  }

  void _requestReview() {
    // Wait 2 minutes before potentially showing review prompt
    Future.delayed(const Duration(seconds: 120), () {
      widget.inAppReviewService.requestReviewIfAppropriate();
    });
  }

  void _trackAppOpened() {
    final analytics = ref.read(analyticsServiceProvider);
    analytics.trackAppOpened();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      final analytics = ref.read(analyticsServiceProvider);
      analytics.trackAppBackgrounded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final authState = ref.watch(authProvider);
    final brightness = MediaQuery.platformBrightnessOf(context);
    final systemHighContrast = MediaQuery.highContrastOf(context);
    final isHighContrast = appState.isHighContrastMode || systemHighContrast;

    // Show loading screen while checking auth status
    if (authState.isLoading) {
      return const MaterialApp(
        title: 'TalkToJesus',
        debugShowCheckedModeBanner: false,
        home: LoadingPage(),
      );
    }

    // Determine initial route based on auth status
    // If token exists → home, if no token → login
    final initialRoute = authState.isAuthenticated
        ? AppRoutes.home
        : AppRoutes.login;

    return ErrorBoundary(
      title: 'App Error',
      message:
          'The app encountered an unexpected error. Please restart the app.',
      child: MaterialApp(
        title: 'TalkToJesus',
        debugShowCheckedModeBanner: false,
        navigatorKey: NavigationService.navigatorKey,
        theme: ThemeData(
          colorScheme: AppColors.getColorScheme(
            isHighContrast: isHighContrast,
            brightness: brightness,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.poppinsTextTheme().apply(
            bodyColor: isHighContrast
                ? (brightness == Brightness.dark ? Colors.white : Colors.black)
                : null,
            displayColor: isHighContrast
                ? (brightness == Brightness.dark ? Colors.white : Colors.black)
                : null,
          ),
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: CupertinoPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
          focusColor: isHighContrast
              ? AppColors.highContrastSecondary
              : Colors.deepPurple,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: initialRoute,
        onGenerateRoute: AppRouter.generateRoute,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: MediaQuery.of(
                context,
              ).textScaler.clamp(minScaleFactor: 0.8, maxScaleFactor: 1.4),
            ),
            child: child!,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppFocusManager.disposeAll();
    super.dispose();
  }
}
