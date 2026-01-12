import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/top_bar_widget.dart';
import '../widgets/bottom_section_widget.dart';
import '../../core/enums/app_language.dart';
import '../../core/constants/app_strings.dart';
import '../../core/navigation/navigation_service.dart';
import '../../core/providers/audio_provider.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/providers/analytics_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/network_aware_widget.dart';
import '../../core/widgets/custom_toast.dart';
import '../../core/accessibility/accessibility_utils.dart';
import '../../core/accessibility/focus_manager.dart';
import '../widgets/user_sidebar.dart';
import '../widgets/plans_bottom_sheet.dart';
import '../../data/services/conversation_service.dart';

class JesusPage extends ConsumerStatefulWidget {
  const JesusPage({super.key});

  @override
  ConsumerState<JesusPage> createState() => _JesusPageState();
}

class _JesusPageState extends ConsumerState<JesusPage> with RouteAware {
  final TextEditingController _inputController = TextEditingController();
  final RouteObserver<PageRoute> _routeObserver = RouteObserver<PageRoute>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ConversationService _conversationService = ConversationService();
  bool _isRecording = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppFocusManager.setFocusTraversalOrder('jesus_page', [
        // TODO: Input field and Jesus Songs temporarily commented out
        // 'input_field',
        // 'jesus_songs_button',
        'bible_button',
        'language_selector',
      ]);

      // Initialize and auto-play audio
      ref.read(audioPlayerProvider.notifier).fadeInAndResume();

      // Track screen view
      ref.read(analyticsServiceProvider).trackScreenView('Jesus Page');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void didPopNext() {
    // Called when returning to this page from another page
    ref.read(audioPlayerProvider.notifier).fadeInAndResume();
  }

  @override
  void dispose() {
    _routeObserver.unsubscribe(this);
    _inputController.dispose();
    // Cancel any ongoing recording
    _conversationService.cancelRecording();
    _conversationService.stopPlaying();
    super.dispose();
  }

  Future<void> _fadeOutAndNavigate(
    Future<void> Function() navigationFunction,
  ) async {
    final audioNotifier = ref.read(audioPlayerProvider.notifier);
    await audioNotifier.fadeOutAndPause();

    if (mounted) {
      await navigationFunction();
    }
  }

  // TODO: Jesus Songs navigation temporarily commented out
  // void _navigateToAudioSongs() {
  //   ref
  //       .read(analyticsServiceProvider)
  //       .trackNavigation('Jesus Page', 'Audio Songs');
  //   _fadeOutAndNavigate(() => NavigationService.navigateToAudioSongs());
  // }

  void _navigateToBible() {
    ref.read(analyticsServiceProvider).trackNavigation('Jesus Page', 'Bible');
    _fadeOutAndNavigate(() => NavigationService.navigateToBible());
  }

  // TODO: Input submit handler temporarily commented out - will be replaced with voice input
  // void _handleInputSubmit(String value) {
  //   if (value.trim().isEmpty) return;

  //   // Track question asked
  //   final questionLength = value.length <= 50
  //       ? 'short'
  //       : value.length <= 150
  //       ? 'medium'
  //       : 'long';
  //   ref.read(analyticsServiceProvider).trackQuestionAsked(questionLength);

  //   // Provide accessibility feedback (includes haptic feedback)
  //   AccessibilityUtils.provideFeedback();
  //   AccessibilityUtils.announceMessage('Question submitted: $value');

  //   // Update app state
  //   ref.read(appStateProvider.notifier).incrementCounter();

  //   // Handle input submission
  //   // TODO: Implement actual logic to handle user questions
  //   // For now, just clear the input
  //   _inputController.clear();
  // }

  void _handleLanguageChange(AppLanguage language) {
    ref.read(appStateProvider.notifier).setLanguage(language);
    AccessibilityUtils.announceMessage(
      'Language changed to: ${AppStrings.get('language', language)}',
    );
    debugPrint('Language changed to: ${AppStrings.get('language', language)}');
  }

  Future<void> _showPermissionDialog(MicrophonePermissionStatus status) async {
    if (!mounted) return;

    String title;
    String message;
    bool showSettings = false;

    switch (status) {
      case MicrophonePermissionStatus.denied:
        title = 'Microphone Permission Required';
        message =
            'We need access to your microphone to record your voice messages to Jesus. Please grant permission in the next dialog.';
        break;
      case MicrophonePermissionStatus.permanentlyDenied:
        title = 'Microphone Permission Denied';
        message =
            'Microphone permission has been permanently denied. To use voice messaging, please enable microphone access in your device settings.';
        showSettings = true;
        break;
      case MicrophonePermissionStatus.restricted:
        title = 'Microphone Access Restricted';
        message =
            'Microphone access is restricted on this device. This may be due to parental controls or device management policies.';
        break;
      case MicrophonePermissionStatus.granted:
        return; // No dialog needed
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (showSettings)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(showSettings ? 'Cancel' : 'OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleVoiceTap() async {
    if (_isProcessing) return;

    if (_isRecording) {
      // Stop recording and send
      await _stopRecordingAndSend();
    } else {
      // Start recording
      await _startRecording();
    }
  }

  Future<void> _handleCancelRecording() async {
    if (!_isRecording) return;

    try {
      // Cancel the recording
      await _conversationService.cancelRecording();

      if (mounted) {
        setState(() {
          _isRecording = false;
        });
        AccessibilityUtils.announceMessage('Recording cancelled');
      }
    } catch (e) {
      debugPrint('[JesusPage] Error cancelling recording: $e');
    }
  }

  Future<void> _startRecording() async {
    try {
      // Check current permission status
      final permissionStatus = await _conversationService
          .getMicrophonePermissionStatus();

      // If permission not granted, show explanation dialog first
      if (permissionStatus != MicrophonePermissionStatus.granted) {
        await _showPermissionDialog(permissionStatus);

        // If permanently denied or restricted, don't proceed
        if (permissionStatus == MicrophonePermissionStatus.permanentlyDenied ||
            permissionStatus == MicrophonePermissionStatus.restricted) {
          return;
        }

        // Request permission after showing explanation
        final newStatus = await _conversationService
            .requestMicrophonePermission();

        // If still not granted, show appropriate dialog
        if (newStatus != MicrophonePermissionStatus.granted) {
          await _showPermissionDialog(newStatus);
          return;
        }
      }

      // Permission granted, start recording
      final started = await _conversationService.startRecording();
      if (started && mounted) {
        setState(() {
          _isRecording = true;
        });
        AccessibilityUtils.provideFeedback();
        AccessibilityUtils.announceMessage('Recording started');
      } else if (mounted) {
        CustomToast.show(
          context,
          message: 'Failed to start recording. Please try again.',
          type: ToastType.error,
        );
      }
    } catch (e) {
      debugPrint('[JesusPage] Error starting recording: $e');
      if (mounted) {
        CustomToast.show(
          context,
          message: 'Error: ${e.toString()}',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _stopRecordingAndSend() async {
    try {
      setState(() {
        _isRecording = false;
        _isProcessing = true;
      });

      // Stop recording
      final audioFile = await _conversationService.stopRecording();

      if (audioFile == null) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          CustomToast.show(
            context,
            message: 'Recording failed. Please try again.',
            type: ToastType.error,
          );
        }
        return;
      }

      // Send to API with current language
      final currentLanguage = ref.read(appStateProvider).currentLanguage;
      final languageCode = currentLanguage == AppLanguage.english ? 'en' : 'te';
      final response = await _conversationService.sendVoiceMessage(
        audioFile,
        language: languageCode,
      );

      if (!response.isSuccess || response.data == null) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });

          // Handle 402 Payment Required - show subscription bottom sheet
          if (response.statusCode == 402) {
            CustomToast.show(
              context,
              message: response.error ?? 'Subscription required',
              type: ToastType.info,
            );
            // Show plans bottom sheet after a brief delay
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                PlansBottomSheet.show(context);
              }
            });
          } else {
            CustomToast.show(
              context,
              message: response.error ?? 'Failed to send message',
              type: ToastType.error,
            );
          }
        }
        return;
      }

      final conversationResponse = response.data!;

      // Refresh auth status
      await ref.read(authProvider.notifier).refreshAuthStatus();

      // Play response audio
      if (conversationResponse.assistantAudio.isNotEmpty) {
        await _conversationService.playResponseAudio(
          conversationResponse.assistantAudio,
        );
      }

      // Show success message with assistant text
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        // Show assistant response in toast
        CustomToast.show(
          context,
          message: conversationResponse.assistantText,
          type: ToastType.success,
          duration: const Duration(seconds: 5),
        );

        AccessibilityUtils.announceMessage(conversationResponse.assistantText);
      }
    } catch (e, stackTrace) {
      debugPrint('[JesusPage] Error in stopRecordingAndSend: $e');
      debugPrint('[JesusPage] Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        CustomToast.show(
          context,
          message: 'Error: ${e.toString()}',
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NetworkAwareWidget(
      child: AppFocusTraversalGroup(
        groupKey: 'jesus_page',
        focusOrder: const [
          // TODO: Input field and Jesus Songs temporarily commented out
          // 'input_field',
          // 'jesus_songs_button',
          'bible_button',
          'language_selector',
        ],
        child: Scaffold(
          key: _scaffoldKey,
          drawer: Drawer(child: const UserSidebar()),
          body: Semantics(
            label: 'Jesus page - Main screen with background image of Jesus',
            child: Stack(
              children: [
                // Background image
                Semantics(
                  image: true,
                  label: 'Background image of Jesus Christ',
                  child: Transform.translate(
                    offset: const Offset(0, 60),
                    child: Transform.scale(
                      scale: 1.3,
                      child: Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/jesus.jpg'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Top bar
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TopBarWidget(
                      onLanguageChanged: _handleLanguageChange,
                      onMenuTap: () {
                        _scaffoldKey.currentState?.openDrawer();
                      },
                    ),
                  ),
                ),
                // Bottom section
                BottomSectionWidget(
                  // TODO: Jesus Songs navigation temporarily disabled
                  onJesusSongsTap:
                      () {}, // Placeholder - feature temporarily disabled
                  onBibleTap: _navigateToBible,
                  // TODO: Input handling temporarily disabled - will be replaced with voice
                  onInputSubmitted: null,
                  inputController: _inputController,
                  isVoiceEnabled: !_isProcessing,
                  onVoiceTap: _handleVoiceTap,
                  onCancelRecording: _handleCancelRecording,
                  isRecording: _isRecording,
                  isProcessing: _isProcessing,
                  currentLanguage: ref.watch(appStateProvider).currentLanguage,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
