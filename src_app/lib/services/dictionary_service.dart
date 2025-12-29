import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Service tra cứu từ điển offline
class DictionaryService {
  /// Tra cứu từ vựng
  static Future<DictionaryLookupResult> lookup(String word) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/dictionary/lookup')
          .replace(queryParameters: {'word': word});

      print('📖 Looking up: $word');

      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DictionaryLookupResult.fromJson(data);
      } else {
        throw Exception('Failed to lookup word: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Dictionary lookup error: $e');
      rethrow;
    }
  }

  /// Gợi ý từ khi đang gõ (autocomplete)
  static Future<List<String>> suggest(String prefix) async {
    try {
      if (prefix.length < 2) return [];

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/dictionary/suggest')
          .replace(queryParameters: {'prefix': prefix});

      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<String>();
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Dictionary suggest error: $e');
      return [];
    }
  }

  /// Tìm kiếm từ chứa keyword
  static Future<List<DictionaryLookupResult>> search(String keyword) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/dictionary/search')
          .replace(queryParameters: {'keyword': keyword});

      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => DictionaryLookupResult.fromJson(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Dictionary search error: $e');
      return [];
    }
  }

  /// Kiểm tra từ có tồn tại không
  static Future<bool> exists(String word) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/dictionary/exists')
          .replace(queryParameters: {'word': word});

      final response = await http.get(uri, headers: {
        'ngrok-skip-browser-warning': 'true',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Lấy thống kê từ điển
  static Future<DictionaryStats> getStats() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/dictionary/stats');

      final response = await http.get(uri, headers: {
        'ngrok-skip-browser-warning': 'true',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DictionaryStats.fromJson(data);
      } else {
        throw Exception('Failed to get stats');
      }
    } catch (e) {
      print('❌ Dictionary stats error: $e');
      rethrow;
    }
  }
}

/// Kết quả tra từ điển
class DictionaryLookupResult {
  final bool found;
  final String? word;
  final String? partOfSpeech;
  final String? partOfSpeechVi;
  final String? phonetic;
  final String? definitions;
  final String? meanings;
  final String? source;
  final String? errorMessage;

  DictionaryLookupResult({
    required this.found,
    this.word,
    this.partOfSpeech,
    this.partOfSpeechVi,
    this.phonetic,
    this.definitions,
    this.meanings,
    this.source,
    this.errorMessage,
  });

  factory DictionaryLookupResult.fromJson(Map<String, dynamic> json) {
    return DictionaryLookupResult(
      found: json['found'] ?? false,
      word: json['word'],
      partOfSpeech: json['partOfSpeech'],
      partOfSpeechVi: json['partOfSpeechVi'],
      phonetic: json['phonetic'],
      definitions: json['definitions'],
      meanings: json['meanings'],
      source: json['source'],
      errorMessage: json['errorMessage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'found': found,
      'word': word,
      'partOfSpeech': partOfSpeech,
      'partOfSpeechVi': partOfSpeechVi,
      'phonetic': phonetic,
      'definitions': definitions,
      'meanings': meanings,
      'source': source,
      'errorMessage': errorMessage,
    };
  }
}

/// Thống kê từ điển
class DictionaryStats {
  final int totalWords;

  DictionaryStats({required this.totalWords});

  factory DictionaryStats.fromJson(Map<String, dynamic> json) {
    return DictionaryStats(
      totalWords: json['totalWords'] ?? 0,
    );
  }
}