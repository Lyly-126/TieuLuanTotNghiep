import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'api_client.dart';
import '../models/quiz_model.dart';

/// Service quản lý Quiz
/// ✅ FIX: Đồng bộ endpoints với Backend QuizController
class QuizService {

  // ==================== CREATE QUIZ ====================

  /// Tạo bài kiểm tra mới
  /// ✅ FIX: Đổi từ /api/quiz/create sang /api/quiz/generate
  static Future<QuizSessionModel> createQuiz(CreateQuizRequest request) async {
    try {
      final response = await ApiClient.authenticatedPost(
        Uri.parse('${ApiConfig.baseUrl}/api/quiz/generate'),  // ✅ FIX
        body: request.toJson(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return QuizSessionModel.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Không thể tạo bài kiểm tra');
      }
    } catch (e) {
      debugPrint('❌ [QuizService] createQuiz error: $e');
      rethrow;
    }
  }

  /// Tạo bài kiểm tra nhanh (shortcut)
  /// ✅ FIX: Đổi từ /api/quiz/quick sang /api/quiz/generate/quick
  static Future<QuizSessionModel> createQuickQuiz(int categoryId) async {
    try {
      final response = await ApiClient.authenticatedGet(  // ✅ FIX: Đổi sang GET
        Uri.parse('${ApiConfig.baseUrl}/api/quiz/generate/quick/$categoryId'),  // ✅ FIX
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return QuizSessionModel.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Không thể tạo bài kiểm tra');
      }
    } catch (e) {
      debugPrint('❌ [QuizService] createQuickQuiz error: $e');
      rethrow;
    }
  }

  // ==================== SUBMIT ANSWERS ====================

  /// Nộp một câu trả lời
  static Future<AnswerResultModel> submitAnswer({
    required int quizResultId,
    required int flashcardId,
    required String questionType,
    String? userAnswer,
    int? selectedOptionIndex,
    int timeSpentSeconds = 0,
  }) async {
    try {
      final response = await ApiClient.authenticatedPost(
        Uri.parse('${ApiConfig.baseUrl}/api/quiz/answer'),
        body: {
          'quizResultId': quizResultId,
          'flashcardId': flashcardId,
          'questionType': questionType,
          'userAnswer': userAnswer,
          'selectedOptionIndex': selectedOptionIndex,
          'timeSpentSeconds': timeSpentSeconds,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AnswerResultModel.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Không thể nộp câu trả lời');
      }
    } catch (e) {
      debugPrint('❌ [QuizService] submitAnswer error: $e');
      rethrow;
    }
  }

  /// Nộp tất cả câu trả lời và hoàn thành quiz
  static Future<QuizResultModel> submitAllAnswers({
    required int quizResultId,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      final response = await ApiClient.authenticatedPost(
        Uri.parse('${ApiConfig.baseUrl}/api/quiz/submit'),  // ✅ FIX
        body: {
          'quizResultId': quizResultId,
          'answers': answers,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return QuizResultModel.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Không thể hoàn thành bài kiểm tra');
      }
    } catch (e) {
      debugPrint('❌ [QuizService] submitAllAnswers error: $e');
      rethrow;
    }
  }

  /// Hoàn thành bài kiểm tra
  static Future<QuizResultModel> completeQuiz(int quizResultId) async {
    try {
      final response = await ApiClient.authenticatedPost(
        Uri.parse('${ApiConfig.baseUrl}/api/quiz/complete/$quizResultId'),
        body: {},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return QuizResultModel.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Không thể hoàn thành bài kiểm tra');
      }
    } catch (e) {
      debugPrint('❌ [QuizService] completeQuiz error: $e');
      rethrow;
    }
  }

  // ==================== HISTORY & STATS ====================

  /// ✅ Alias for submitNewQuiz (for compatibility)
  static Future<QuizResultModel> submitQuiz({
    required int categoryId,
    required String quizType,
    required String difficulty,
    required List<Map<String, dynamic>> answers,
    int? totalTimeSeconds,
  }) => submitNewQuiz(
    categoryId: categoryId,
    quizType: quizType,
    difficulty: difficulty,
    answers: answers,
    totalTimeSeconds: totalTimeSeconds,
  );

  /// ✅ NEW: Submit quiz mới (không cần quizResultId)
  /// Dùng khi quiz được generate mà không tạo record trước
  static Future<QuizResultModel> submitNewQuiz({
    required int categoryId,
    required String quizType,
    required String difficulty,
    required List<Map<String, dynamic>> answers,
    int? totalTimeSeconds,
  }) async {
    try {
      final response = await ApiClient.authenticatedPost(
        Uri.parse('${ApiConfig.baseUrl}/api/quiz/submit'),
        body: {
          'categoryId': categoryId,
          'quizType': quizType,
          'difficulty': difficulty,
          'answers': answers,
          'totalTimeSeconds': totalTimeSeconds,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return QuizResultModel.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Không thể hoàn thành bài kiểm tra');
      }
    } catch (e) {
      debugPrint('❌ [QuizService] submitNewQuiz error: $e');
      rethrow;
    }
  }

  // ==================== HISTORY & STATS (continued) ====================

  /// Lấy lịch sử kiểm tra
  static Future<List<QuizResultModel>> getQuizHistory({int? categoryId, int? limit}) async {
    try {
      String url = '${ApiConfig.baseUrl}/api/quiz/history';
      List<String> params = [];
      if (categoryId != null) params.add('categoryId=$categoryId');
      if (limit != null) params.add('limit=$limit');
      if (params.isNotEmpty) url += '?${params.join('&')}';

      final response = await ApiClient.authenticatedGet(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final history = data['history'] as List? ?? [];
        return history.map((r) => QuizResultModel.fromJson(r)).toList();
      } else {
        debugPrint('❌ [QuizService] getQuizHistory error: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ [QuizService] getQuizHistory error: $e');
      return [];
    }
  }

  /// Lấy thống kê quiz tổng quan
  static Future<QuizStatsModel?> getQuizStats() async {
    try {
      final response = await ApiClient.authenticatedGet(
        Uri.parse('${ApiConfig.baseUrl}/api/quiz/stats'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return QuizStatsModel.fromJson(data);
      } else {
        debugPrint('❌ [QuizService] getQuizStats error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [QuizService] getQuizStats error: $e');
      return null;
    }
  }

  /// Lấy thống kê quiz cho category
  static Future<Map<String, dynamic>?> getCategoryQuizStats(int categoryId) async {
    try {
      final response = await ApiClient.authenticatedGet(
        Uri.parse('${ApiConfig.baseUrl}/api/quiz/stats/$categoryId'),  // ✅ FIX
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('❌ [QuizService] getCategoryQuizStats error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [QuizService] getCategoryQuizStats error: $e');
      return null;
    }
  }

  /// Lấy danh sách loại quiz
  static Future<Map<String, dynamic>?> getQuizTypes() async {
    try {
      final response = await ApiClient.authenticatedGet(
        Uri.parse('${ApiConfig.baseUrl}/api/quiz/types'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('❌ [QuizService] getQuizTypes error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [QuizService] getQuizTypes error: $e');
      return null;
    }
  }
}