import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

// ✅ Conditional import for web
import 'tts_web_stub.dart' if (dart.library.html) 'tts_web_impl.dart' as tts_web;

import '../config/api_config.dart';


class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  // Getters
  bool get isPlaying => _isPlaying;
  bool get isConfigured => true;

  /// ✅ Headers - không cần authentication (TTS endpoint là public)
  static Map<String, String> _getHeaders() {
    return {
      'Accept': 'audio/mpeg, application/json',
      'ngrok-skip-browser-warning': 'true',
    };
  }

  /// Phát văn bản
  Future<void> speak(String text, {String languageCode = 'en-US'}) async {
    try {
      // Dừng audio hiện tại nếu có
      if (_isPlaying) {
        await stop();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // ✅ GỌI BACKEND
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
        print('🎵 TTS Request: "$text" ($languageCode)');
      }

      // ✅ Gọi backend endpoint
      final uri = Uri.parse(ApiConfig.ttsGenerateAudio).replace(
        queryParameters: {
          'text': text,
          'languageCode': languageCode,
        },
      );

      final headers = _getHeaders();

      final response = await http.post(
        uri,
        headers: headers,
      );

      if (kDebugMode) {
        print('📨 Response Status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final audioBytes = response.bodyBytes;
        if (kDebugMode) print('✅ TTS received: ${audioBytes.length} bytes');

        // ✅ Phát audio tùy theo platform
        if (kIsWeb) {
          _isPlaying = true;
          await tts_web.playAudioBytes(
            audioBytes,
            onComplete: () {
              _isPlaying = false;
              if (kDebugMode) print('✅ Web audio completed');
            },
            onError: (e) {
              _isPlaying = false;
              if (kDebugMode) print('❌ Web audio error: $e');
            },
          );
        } else {
          await _playAudioOnMobile(audioBytes);
        }
      } else {
        if (kDebugMode) print('❌ TTS Error ${response.statusCode}: ${response.body}');
        throw Exception('Lỗi phát âm: ${response.statusCode}');
      }
    } catch (e) {
      _isPlaying = false;
      if (kDebugMode) print('❌ Backend TTS Error: $e');
      rethrow;
    }
  }

  /// ✅ Phát audio trên MOBILE sử dụng audioplayers
  Future<void> _playAudioOnMobile(List<int> audioBytes) async {
    try {
      _isPlaying = true;

      // Tạo source từ bytes
      final source = BytesSource(Uint8List.fromList(audioBytes));
      await _audioPlayer.play(source);

      // Lắng nghe khi audio kết thúc
      _audioPlayer.onPlayerComplete.listen((_) {
        _isPlaying = false;
        if (kDebugMode) print('✅ Mobile audio completed');
      });
    } catch (e) {
      _isPlaying = false;
      if (kDebugMode) print('❌ Error playing mobile audio: $e');
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

      if (kIsWeb) {
        await tts_web.playAudioUrl(
          audioUrl,
          onComplete: () {
            _isPlaying = false;
            if (kDebugMode) print('✅ URL audio completed');
          },
          onError: (e) {
            _isPlaying = false;
            if (kDebugMode) print('❌ URL audio error: $e');
          },
        );
      } else {
        // Mobile: dùng audioplayers
        await _audioPlayer.play(UrlSource(audioUrl));

        _audioPlayer.onPlayerComplete.listen((_) {
          _isPlaying = false;
          if (kDebugMode) print('✅ URL audio completed');
        });
      }
    } catch (e) {
      _isPlaying = false;
      if (kDebugMode) print('❌ Error playing from URL: $e');
      rethrow;
    }
  }

  /// Dừng phát audio
  Future<void> stop() async {
    try {
      if (kIsWeb) {
        tts_web.stopAudio();
      } else {
        await _audioPlayer.stop();
      }
      _isPlaying = false;
      if (kDebugMode) print('ℹ️ Audio stopped');
    } catch (e) {
      if (kDebugMode) print('⚠️ Error stopping audio: $e');
    }
  }

  /// Giải phóng resources
  void dispose() {
    stop();
    _audioPlayer.dispose();
  }
}