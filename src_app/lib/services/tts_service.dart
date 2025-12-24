import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';


class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  // ✅ BACKEND URL - Thay đổi theo môi trường
  // Web: http://localhost:8080/api/tts
  // Mobile: http://10.0.2.2:8080/api/tts (Android Emulator)
  // static const String _baseUrl = 'http://localhost:8080/api/tts';

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  // Getters
  bool get isPlaying => _isPlaying;
  bool get isConfigured => true;

  /// Phát văn bản
  Future<void> speak(String text, {String languageCode = 'en-US'}) async {
    try {
      // Dừng audio hiện tại nếu có
      if (_isPlaying) {
        await stop();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // ✅ ĐANG TEST TRÊN WEB → GỌI BACKEND LUÔN
      // Sau này deploy app mobile cũng gọi backend
      await _speakViaBackend(text, languageCode);

    } catch (e) {
      _isPlaying = false;
      if (kDebugMode) print('❌ TTS Error: $e');
      rethrow;
    }
  }

  /// Gọi backend API để tạo audio
  Future<void> _speakViaBackend(String text, String languageCode) async {
    try {
      if (kDebugMode) {
        print('🎵 Calling Backend TTS API...');
        print('   Platform: ${kIsWeb ? "WEB" : "MOBILE"}');
        print('   Text: "$text"');
      }

      // Gọi backend endpoint
      final uri = Uri.parse('${ApiConfig.ttsSynthesize}/generate-audio').replace(
        queryParameters: {
          'text': text,
          'languageCode': languageCode,
        },
      );

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true', // ✅ Bypass ngrok warning
        },
      );

      if (response.statusCode == 200) {
        // Backend trả về audio bytes
        final audioBytes = response.bodyBytes;

        if (kDebugMode) {
          print('✅ Received audio: ${audioBytes.length} bytes');
        }

        // Phát audio từ bytes
        await _playAudioFromBytes(audioBytes);
      } else {
        throw Exception('Backend TTS failed: ${response.statusCode}');
      }
    } catch (e) {
      _isPlaying = false;
      if (kDebugMode) print('❌ Backend TTS Error: $e');
      rethrow;
    }
  }

  /// Phát audio từ bytes
  Future<void> _playAudioFromBytes(List<int> audioBytes) async {
    try {
      _isPlaying = true;

      // Tạo source từ bytes
      final source = BytesSource(Uint8List.fromList(audioBytes));
      await _audioPlayer.play(source);

      // Lắng nghe khi audio kết thúc
      _audioPlayer.onPlayerComplete.listen((_) {
        _isPlaying = false;
        if (kDebugMode) print('✅ Audio playback completed');
      });
    } catch (e) {
      _isPlaying = false;
      if (kDebugMode) print('❌ Error playing audio: $e');
      rethrow;
    }
  }

  /// Phát âm từ URL có sẵn (nếu flashcard đã có ttsUrl)
  Future<void> speakFromUrl(String audioUrl) async {
    try {
      if (_isPlaying) {
        await stop();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (kDebugMode) print('🎵 Playing from URL: $audioUrl');

      _isPlaying = true;
      await _audioPlayer.play(UrlSource(audioUrl));

      _audioPlayer.onPlayerComplete.listen((_) {
        _isPlaying = false;
        if (kDebugMode) print('✅ URL audio completed');
      });
    } catch (e) {
      _isPlaying = false;
      if (kDebugMode) print('❌ Error playing from URL: $e');
      rethrow;
    }
  }

  /// Dừng phát audio
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      if (kDebugMode) print('ℹ️ Audio stopped');
    } catch (e) {
      if (kDebugMode) print('⚠️ Error stopping audio: $e');
    }
  }

  /// Giải phóng resources
  void dispose() {
    _audioPlayer.dispose();
  }
}