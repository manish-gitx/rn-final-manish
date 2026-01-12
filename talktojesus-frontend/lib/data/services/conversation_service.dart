import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart' as path;
import 'api_client.dart';
import '../../domain/models/conversation_response_model.dart';

enum MicrophonePermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
}

class ConversationService {
  static final ConversationService _instance = ConversationService._internal();
  factory ConversationService() => _instance;
  ConversationService._internal();

  final AudioRecorder _audioRecorder = AudioRecorder();
  final ApiClient _apiClient = ApiClient();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentRecordingPath;
  bool _isRecording = false;
  bool _isPlaying = false;

  /// Get detailed microphone permission status
  Future<MicrophonePermissionStatus> getMicrophonePermissionStatus() async {
    final status = await Permission.microphone.status;

    if (status.isGranted) {
      return MicrophonePermissionStatus.granted;
    } else if (status.isPermanentlyDenied) {
      return MicrophonePermissionStatus.permanentlyDenied;
    } else if (status.isRestricted) {
      return MicrophonePermissionStatus.restricted;
    } else {
      return MicrophonePermissionStatus.denied;
    }
  }

  /// Request microphone permission
  Future<MicrophonePermissionStatus> requestMicrophonePermission() async {
    final currentStatus = await getMicrophonePermissionStatus();

    // If already granted, return immediately
    if (currentStatus == MicrophonePermissionStatus.granted) {
      return MicrophonePermissionStatus.granted;
    }

    // If permanently denied or restricted, return without requesting
    if (currentStatus == MicrophonePermissionStatus.permanentlyDenied ||
        currentStatus == MicrophonePermissionStatus.restricted) {
      return currentStatus;
    }

    // Request permission
    final result = await Permission.microphone.request();

    if (result.isGranted) {
      return MicrophonePermissionStatus.granted;
    } else if (result.isPermanentlyDenied) {
      return MicrophonePermissionStatus.permanentlyDenied;
    } else if (result.isRestricted) {
      return MicrophonePermissionStatus.restricted;
    } else {
      return MicrophonePermissionStatus.denied;
    }
  }

  /// Check and request microphone permission (legacy method for backward compatibility)
  Future<bool> checkMicrophonePermission() async {
    final status = await requestMicrophonePermission();
    return status == MicrophonePermissionStatus.granted;
  }

  /// Start recording audio
  Future<bool> startRecording() async {
    try {
      // Check permission
      final hasPermission = await checkMicrophonePermission();
      if (!hasPermission) {
        debugPrint('[ConversationService] Microphone permission not granted');
        return false;
      }

      if (_isRecording) {
        debugPrint('[ConversationService] Already recording');
        return false;
      }

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = path.join(
        directory.path,
        'voice_message_$timestamp.m4a', // Use m4a format (AAC codec)
      );

      debugPrint(
        '[ConversationService] Starting recording to: $_currentRecordingPath',
      );

      // Configure recorder for good quality audio
      // m4a format with AAC codec is widely supported
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1, // Mono for voice
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      return true;
    } catch (e, stackTrace) {
      debugPrint('[ConversationService] Error starting recording: $e');
      debugPrint('[ConversationService] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Stop recording and return the audio file
  Future<File?> stopRecording() async {
    try {
      if (!_isRecording || _currentRecordingPath == null) {
        debugPrint('[ConversationService] Not recording');
        return null;
      }

      debugPrint('[ConversationService] Stopping recording...');
      final path = await _audioRecorder.stop();

      _isRecording = false;

      if (path == null || path.isEmpty) {
        debugPrint('[ConversationService] Recording path is null or empty');
        _currentRecordingPath = null;
        return null;
      }

      final file = File(path);
      if (!await file.exists()) {
        debugPrint('[ConversationService] Recorded file does not exist');
        _currentRecordingPath = null;
        return null;
      }

      final fileSize = await file.length();
      debugPrint(
        '[ConversationService] Recording stopped. File size: $fileSize bytes',
      );

      _currentRecordingPath = null;
      return file;
    } catch (e, stackTrace) {
      debugPrint('[ConversationService] Error stopping recording: $e');
      debugPrint('[ConversationService] Stack trace: $stackTrace');
      _isRecording = false;
      _currentRecordingPath = null;
      return null;
    }
  }

  /// Send voice message to API
  Future<ApiResponse<ConversationResponse>> sendVoiceMessage(
    File audioFile,
  ) async {
    try {
      debugPrint('[ConversationService] Sending voice message...');

      // Verify file exists and has content
      if (!await audioFile.exists()) {
        return ApiResponse<ConversationResponse>(
          isSuccess: false,
          error: 'Audio file does not exist',
        );
      }

      final fileSize = await audioFile.length();
      if (fileSize == 0) {
        return ApiResponse<ConversationResponse>(
          isSuccess: false,
          error: 'Audio file is empty',
        );
      }

      debugPrint('[ConversationService] Audio file size: $fileSize bytes');

      // Send to API
      final response = await _apiClient.sendMessage(audioFile);

      // Clean up the temporary file after sending
      try {
        await audioFile.delete();
        debugPrint('[ConversationService] Temporary audio file deleted');
      } catch (e) {
        debugPrint('[ConversationService] Failed to delete temp file: $e');
      }

      return response;
    } catch (e, stackTrace) {
      debugPrint('[ConversationService] Error sending voice message: $e');
      debugPrint('[ConversationService] Stack trace: $stackTrace');
      return ApiResponse<ConversationResponse>(
        isSuccess: false,
        error: e.toString(),
      );
    }
  }

  /// Play the response audio from base64 string
  Future<void> playResponseAudio(String base64Audio) async {
    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
      }

      // Decode base64 audio
      // Remove data URI prefix if present (data:audio/mpeg;base64,...)
      String base64Data = base64Audio;
      if (base64Audio.contains(',')) {
        base64Data = base64Audio.split(',').last;
      }

      final audioBytes = Uint8List.fromList(base64Decode(base64Data));

      debugPrint(
        '[ConversationService] Playing audio response (${audioBytes.length} bytes)',
      );

      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final tempPath = path.join(
        directory.path,
        'response_audio_${DateTime.now().millisecondsSinceEpoch}.mp3',
      );
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(audioBytes);

      // Play audio
      await _audioPlayer.play(DeviceFileSource(tempPath));
      _isPlaying = true;

      // Clean up after playback
      _audioPlayer.onPlayerComplete.listen((_) async {
        _isPlaying = false;
        try {
          await tempFile.delete();
          debugPrint(
            '[ConversationService] Temporary response audio file deleted',
          );
        } catch (e) {
          debugPrint(
            '[ConversationService] Failed to delete temp response file: $e',
          );
        }
      });
    } catch (e, stackTrace) {
      debugPrint('[ConversationService] Error playing response audio: $e');
      debugPrint('[ConversationService] Stack trace: $stackTrace');
      _isPlaying = false;
    }
  }

  /// Cancel current recording
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _audioRecorder.stop();
        _isRecording = false;

        if (_currentRecordingPath != null) {
          final file = File(_currentRecordingPath!);
          if (await file.exists()) {
            await file.delete();
            debugPrint(
              '[ConversationService] Cancelled recording file deleted',
            );
          }
          _currentRecordingPath = null;
        }
      }
    } catch (e) {
      debugPrint('[ConversationService] Error cancelling recording: $e');
    }
  }

  /// Stop playing audio
  Future<void> stopPlaying() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
        _isPlaying = false;
      }
    } catch (e) {
      debugPrint('[ConversationService] Error stopping audio: $e');
    }
  }

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;

  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
  }
}
