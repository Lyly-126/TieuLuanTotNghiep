import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

// Import có điều kiện
import 'dart:html' as html show window, SpeechSynthesis, SpeechSynthesisUtterance, Event;
import 'dart:io' show File;

class GoogleTTSService {
  static final GoogleTTSService _instance = GoogleTTSService._internal();
  factory GoogleTTSService() => _instance;
  GoogleTTSService._internal() {
    // Khởi tạo web speech synthesis nếu đang chạy trên web
    if (kIsWeb) {
      _webSpeechSynthesis = html.window.speechSynthesis;
    }
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  html.SpeechSynthesis? _webSpeechSynthesis;

  // Getter để kiểm tra trạng thái
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

      if (kIsWeb) {
        // Sử dụng Web Speech API cho web
        _speakOnWeb(text, languageCode);
      } else {
        // Sử dụng Google TTS API cho mobile
        await _speakOnMobile(text, languageCode);
      }
    } catch (e) {
      _isPlaying = false;
      print('❌ TTS Error: $e');
      rethrow;
    }
  }

  /// Phát âm trên web
  void _speakOnWeb(String text, String languageCode) {
    if (_webSpeechSynthesis == null) return;

    final utterance = html.SpeechSynthesisUtterance();
    utterance.text = text;
    utterance.lang = languageCode;

    // Sử dụng addEventListener thay vì setter
    utterance.addEventListener('start', (html.Event event) {
      _isPlaying = true;
      print('🔊 Web TTS Started');
    });

    utterance.addEventListener('end', (html.Event event) {
      _isPlaying = false;
      print('✅ Web TTS Completed');
    });

    utterance.addEventListener('error', (html.Event event) {
      _isPlaying = false;
      print('❌ Web TTS Error');
    });

    _webSpeechSynthesis!.speak(utterance);
  }

  /// Phát âm trên mobile (cần thêm Google Cloud API key)
  Future<void> _speakOnMobile(String text, String languageCode) async {
    try {
      // TODO: Thêm API key của bạn
      const String apiKey = 'AIzaSyByuLpzz3HjcL4NZO-H4_kSdtq0BThA6n8';

      final url = Uri.parse('https://texttospeech.googleapis.com/v1/text:synthesize?key=$apiKey');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'input': {'text': text},
          'voice': {
            'languageCode': languageCode,
            'ssmlGender': 'NEUTRAL'
          },
          'audioConfig': {'audioEncoding': 'MP3'}
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final audioContent = jsonResponse['audioContent'];

        // Lưu file tạm
        final bytes = base64.decode(audioContent);
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/tts_audio.mp3');
        await file.writeAsBytes(bytes);

        // Phát audio
        _isPlaying = true;
        await _audioPlayer.play(DeviceFileSource(file.path));

        // Lắng nghe khi audio kết thúc
        _audioPlayer.onPlayerComplete.listen((_) {
          _isPlaying = false;
          print('✅ Mobile TTS Completed');
        });

      } else {
        throw Exception('Failed to synthesize speech: ${response.statusCode}');
      }
    } catch (e) {
      _isPlaying = false;
      print('❌ Mobile TTS Error: $e');
      rethrow;
    }
  }

  /// Phát âm từ URL có sẵn
  Future<void> speakFromUrl(String audioUrl) async {
    if (kIsWeb) {
      print('⚠️ URL audio không hỗ trợ trên web');
      return;
    }

    try {
      if (_isPlaying) {
        await stop();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      _isPlaying = true;
      await _audioPlayer.play(UrlSource(audioUrl));

      _audioPlayer.onPlayerComplete.listen((_) {
        _isPlaying = false;
      });

    } catch (e) {
      _isPlaying = false;
      print('❌ Error playing from URL: $e');
      rethrow;
    }
  }

  /// Dừng phát audio
  Future<void> stop() async {
    try {
      if (kIsWeb && _webSpeechSynthesis != null) {
        _webSpeechSynthesis!.cancel();
        _isPlaying = false;
        print('⏹️ Web TTS stopped');
      } else {
        await _audioPlayer.stop();
        _isPlaying = false;
        print('⏹️ Audio stopped');
      }
    } catch (e) {
      print('⚠️ Error stopping audio: $e');
    }
  }

  /// Giải phóng resources
  void dispose() {
    _audioPlayer.dispose();
  }
}