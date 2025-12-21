import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/flashcard_model.dart';

class AIFlashcardService {
  // static const String baseUrl = 'http://localhost:8080/api/flashcards/ai';  // ← ĐÃ COMMENT

  /// Generate flashcard từ một từ vựng
  static Future<GenerationResponse> generateFlashcard({
    required String term,
    int? categoryId,
    bool generateImage = true,
    bool generateAudio = true,
  }) async {
    try {
      print('🚀 Starting flashcard generation for: $term');

      // Build URL
      final uri = Uri.parse(ApiConfig.aiFlashcardGenerate);
      print('🌐 Calling: POST $uri');

      // Build request body
      final requestBody = {
        'term': term,
        'categoryId': categoryId,
        'generateImage': generateImage,
        'generateAudio': generateAudio,
      };
      print('📦 Request body: $requestBody');

      // Make POST request
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response headers: ${response.headers}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return GenerationResponse.fromJson(data);
      } else if (response.statusCode == 403) {
        throw Exception('Access denied (403). Check backend security config.');
      } else if (response.statusCode == 404) {
        throw Exception('Endpoint not found (404). URL: $uri');
      } else if (response.statusCode == 405) {
        throw Exception('Method not allowed (405). Backend expects POST but got something else.');
      } else {
        throw Exception('Failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error generating flashcard: $e');
      rethrow;
    }
  }

  /// Check service status (public endpoint)
  static Future<Map<String, dynamic>> checkStatus() async {
    try {
      final uri = Uri.parse('${ApiConfig.aiFlashcardBase}/status');  // ← ĐÃ SỬA
      print('🔍 Checking status: GET $uri');

      final response = await http.get(uri);

      print('📥 Status check response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Service unavailable: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error checking status: $e');
      rethrow;
    }
  }

  /// Test connection to backend
  static Future<bool> testConnection() async {
    try {
      print('🔌 Testing connection to backend...');

      final status = await checkStatus();

      print('✅ Backend is reachable!');
      print('📊 Status: $status');

      return true;
    } catch (e) {
      print('❌ Cannot connect to backend: $e');
      return false;
    }
  }
}

/// Generation Response Model
class GenerationResponse {
  final bool success;
  final String message;
  final FlashcardModel? flashcard;
  final GenerationSteps steps;

  GenerationResponse({
    required this.success,
    required this.message,
    this.flashcard,
    required this.steps,
  });

  factory GenerationResponse.fromJson(Map<String, dynamic> json) {
    return GenerationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      flashcard: json['flashcard'] != null
          ? FlashcardModel.fromJson(json['flashcard'])
          : null,
      steps: GenerationSteps.fromJson(json['steps'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'flashcard': flashcard?.toJson(),
      'steps': steps.toJson(),
    };
  }
}

/// Generation Steps Model
class GenerationSteps {
  final bool aiContentGenerated;
  final bool audioGenerated;
  final bool imageFound;
  final bool savedToDatabase;
  final String? aiError;
  final String? audioError;
  final String? imageError;
  final String? databaseError;

  GenerationSteps({
    this.aiContentGenerated = false,
    this.audioGenerated = false,
    this.imageFound = false,
    this.savedToDatabase = false,
    this.aiError,
    this.audioError,
    this.imageError,
    this.databaseError,
  });

  factory GenerationSteps.fromJson(Map<String, dynamic> json) {
    return GenerationSteps(
      aiContentGenerated: json['aiContentGenerated'] ?? false,
      audioGenerated: json['audioGenerated'] ?? false,
      imageFound: json['imageFound'] ?? false,
      savedToDatabase: json['savedToDatabase'] ?? false,
      aiError: json['aiError'],
      audioError: json['audioError'],
      imageError: json['imageError'],
      databaseError: json['databaseError'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aiContentGenerated': aiContentGenerated,
      'audioGenerated': audioGenerated,
      'imageFound': imageFound,
      'savedToDatabase': savedToDatabase,
      'aiError': aiError,
      'audioError': audioError,
      'imageError': imageError,
      'databaseError': databaseError,
    };
  }

  /// Calculate overall progress (0.0 to 1.0)
  double get progress {
    int completed = 0;
    int total = 4;

    if (aiContentGenerated) completed++;
    if (audioGenerated) completed++;
    if (imageFound) completed++;
    if (savedToDatabase) completed++;

    return completed / total;
  }

  /// Check if all steps completed
  bool get isComplete {
    return aiContentGenerated &&
        audioGenerated &&
        imageFound &&
        savedToDatabase;
  }

  /// Check if any errors occurred
  bool get hasErrors {
    return aiError != null ||
        audioError != null ||
        imageError != null ||
        databaseError != null;
  }

  /// Get list of error messages
  List<String> get errors {
    final errorList = <String>[];
    if (aiError != null) errorList.add('AI: $aiError');
    if (audioError != null) errorList.add('Audio: $audioError');
    if (imageError != null) errorList.add('Image: $imageError');
    if (databaseError != null) errorList.add('Database: $databaseError');
    return errorList;
  }
}