/// 🎯 Quiz Models - Phù hợp với Backend QuizDTO
/// ✅ FIX: Sửa để match với response từ /api/quiz/generate

// ==================== ENUMS ====================

enum QuizType {
  quickTest,
  fullTest,
  listeningTest,
  writingTest,
  mixedTest,
}

enum DifficultyLevel {
  kids,
  teen,
  adult,
  auto,
}

// ==================== REQUEST MODELS ====================

/// Request tạo quiz
class CreateQuizRequest {
  final int categoryId;
  final String quizType;
  final bool includeListening;
  final bool includeWriting;
  final bool onlyStudiedCards;
  final bool focusWeakCards;

  CreateQuizRequest({
    required this.categoryId,
    required this.quizType,
    this.includeListening = true,
    this.includeWriting = true,
    this.onlyStudiedCards = false,
    this.focusWeakCards = false,
  });

  Map<String, dynamic> toJson() => {
    'categoryId': categoryId,
    'quizType': quizType,
    'includeListening': includeListening,
    'includeWriting': includeWriting,
    'onlyStudiedCards': onlyStudiedCards,
    'focusWeakCards': focusWeakCards,
  };
}

// ==================== RESPONSE MODELS ====================

/// Model cho phiên quiz (response từ /api/quiz/generate)
/// ✅ FIX: Không có quizResultId vì quiz chưa được submit
class QuizSessionModel {
  final int categoryId;
  final String categoryName;
  final String quizType;
  final String difficulty;
  final int totalQuestions;
  final int timeLimitSeconds;
  final List<QuizQuestionModel> questions;
  final String? userAgeGroup;

  QuizSessionModel({
    required this.categoryId,
    required this.categoryName,
    required this.quizType,
    required this.difficulty,
    required this.totalQuestions,
    required this.timeLimitSeconds,
    required this.questions,
    this.userAgeGroup,
  });

  factory QuizSessionModel.fromJson(Map<String, dynamic> json) {
    return QuizSessionModel(
      categoryId: (json['categoryId'] as num?)?.toInt() ?? 0,
      categoryName: json['categoryName']?.toString() ?? '',
      quizType: json['quizType']?.toString() ?? 'MIXED',
      difficulty: json['difficulty']?.toString() ?? 'AUTO',
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      timeLimitSeconds: (json['timeLimitSeconds'] as num?)?.toInt() ?? 0,
      questions: (json['questions'] as List<dynamic>?)
          ?.map((q) => QuizQuestionModel.fromJson(q as Map<String, dynamic>))
          .toList() ?? [],
      userAgeGroup: json['userAgeGroup']?.toString(),
    );
  }

  // Helper getter for difficulty label
  String get difficultyLabel {
    switch (difficulty) {
      case 'KIDS': return 'Trẻ em';
      case 'TEEN': return 'Thiếu niên';
      case 'ADULT': return 'Người lớn';
      case 'AUTO': return 'Tự động';
      default: return difficulty;
    }
  }
}

/// Model cho một câu hỏi quiz
class QuizQuestionModel {
  final int index;
  final int flashcardId;
  final String questionType;
  final String skillType;     // ✅ Non-nullable
  final String question;
  final String hint;          // ✅ Non-nullable với default
  final List<String>? options;
  final String correctAnswer; // ✅ Non-nullable với default
  final String? audioUrl;
  final String? imageUrl;
  final String phonetic;      // ✅ Non-nullable với default
  final int points;
  final String word;          // ✅ Non-nullable với default
  final String meaning;       // ✅ Non-nullable với default

  // State cho user answer
  String? userAnswer;
  int? selectedOptionIndex;
  int timeSpentSeconds;
  bool isCorrect;

  QuizQuestionModel({
    required this.index,
    required this.flashcardId,
    required this.questionType,
    this.skillType = 'READING',
    required this.question,
    this.hint = '',
    this.options,
    this.correctAnswer = '',
    this.audioUrl,
    this.imageUrl,
    this.phonetic = '',
    required this.points,
    this.word = '',
    this.meaning = '',
    this.userAnswer,
    this.selectedOptionIndex,
    this.timeSpentSeconds = 0,
    this.isCorrect = false,
  });

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    return QuizQuestionModel(
      index: (json['index'] as num?)?.toInt() ?? 0,
      flashcardId: (json['flashcardId'] as num?)?.toInt() ?? 0,
      questionType: json['questionType']?.toString() ?? '',
      skillType: json['skillType']?.toString() ?? 'READING',
      question: json['question']?.toString() ?? '',
      hint: json['hint']?.toString() ?? '',
      options: (json['options'] as List<dynamic>?)?.map((e) => e?.toString() ?? '').toList(),
      correctAnswer: json['correctAnswer']?.toString() ?? '',
      audioUrl: json['audioUrl']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      phonetic: json['phonetic']?.toString() ?? '',
      points: (json['points'] as num?)?.toInt() ?? 10,
      word: json['word']?.toString() ?? '',
      meaning: json['meaning']?.toString() ?? '',
      isCorrect: json['isCorrect'] == true,
    );
  }

  // Helper getters
  bool get isMultipleChoice =>
      questionType.contains('MULTIPLE_CHOICE') || (options != null && options!.isNotEmpty);

  bool get isListeningQuestion =>
      questionType.contains('LISTENING') || audioUrl != null;

  bool get isFillBlank => questionType.contains('FILL_BLANK');

  bool get isAnswered => userAnswer != null || selectedOptionIndex != null;

  String get questionText => question;  // Alias for compatibility

  String? get ttsUrl => audioUrl;  // Alias for compatibility

  int? get correctOptionIndex {
    if (options == null || correctAnswer.isEmpty) return null;
    return options!.indexOf(correctAnswer);
  }
}

/// Model kết quả trả lời một câu
class AnswerResultModel {
  final bool isCorrect;
  final String? correctAnswer;
  final String? explanation;
  final int pointsEarned;

  AnswerResultModel({
    required this.isCorrect,
    this.correctAnswer,
    this.explanation,
    this.pointsEarned = 0,
  });

  factory AnswerResultModel.fromJson(Map<String, dynamic> json) {
    return AnswerResultModel(
      isCorrect: json['isCorrect'] ?? false,
      correctAnswer: json['correctAnswer'],
      explanation: json['explanation'],
      pointsEarned: json['pointsEarned'] ?? 0,
    );
  }
}

/// Model kết quả quiz (sau khi submit)
class QuizResultModel {
  final int? resultId;
  final int categoryId;
  final String categoryName;  // ✅ Non-nullable với default
  final String quizType;
  final String difficulty;    // ✅ Non-nullable với default
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final int skippedQuestions;
  final double score;
  final int? totalTimeSeconds;
  final bool passed;
  final String grade;         // ✅ Non-nullable với default
  final SkillScoreModel? skillScores;
  final List<QuestionResultModel>? questionResults;
  final double? previousScore;
  final double? improvement;
  final List<String>? recommendations;
  final DateTime? completedAt;

  QuizResultModel({
    this.resultId,
    required this.categoryId,
    this.categoryName = '',
    required this.quizType,
    this.difficulty = 'AUTO',
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    this.skippedQuestions = 0,
    required this.score,
    this.totalTimeSeconds,
    required this.passed,
    this.grade = '-',
    this.skillScores,
    this.questionResults,
    this.previousScore,
    this.improvement,
    this.recommendations,
    this.completedAt,
  });

  factory QuizResultModel.fromJson(Map<String, dynamic> json) {
    return QuizResultModel(
      resultId: (json['resultId'] as num?)?.toInt(),
      categoryId: (json['categoryId'] as num?)?.toInt() ?? 0,
      categoryName: json['categoryName']?.toString() ?? '',
      quizType: json['quizType']?.toString() ?? 'MIXED',
      difficulty: json['difficulty']?.toString() ?? 'AUTO',
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
      wrongAnswers: (json['wrongAnswers'] as num?)?.toInt() ?? 0,
      skippedQuestions: (json['skippedQuestions'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      totalTimeSeconds: (json['totalTimeSeconds'] as num?)?.toInt(),
      passed: json['passed'] == true,
      grade: json['grade']?.toString() ?? '-',
      skillScores: json['skillScores'] != null
          ? SkillScoreModel.fromJson(json['skillScores'] as Map<String, dynamic>)
          : null,
      questionResults: (json['questionResults'] as List<dynamic>?)
          ?.map((q) => QuestionResultModel.fromJson(q as Map<String, dynamic>))
          .toList(),
      previousScore: (json['previousScore'] as num?)?.toDouble(),
      improvement: (json['improvement'] as num?)?.toDouble(),
      recommendations: (json['recommendations'] as List<dynamic>?)
          ?.map((e) => e?.toString() ?? '')
          .toList(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
    );
  }

  // Helper getters
  double get accuracyRate => totalQuestions > 0
      ? correctAnswers / totalQuestions * 100
      : 0;

  // ✅ Thêm các alias/computed properties
  int get incorrectAnswers => wrongAnswers;

  int get timeSpentSeconds => totalTimeSeconds ?? 0;

  double? get scoreImprovement => improvement;

  String get timeFormatted {
    final seconds = timeSpentSeconds;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String get scoreMessage {
    if (score >= 90) return 'Xuất sắc! 🌟';
    if (score >= 80) return 'Giỏi lắm! 👏';
    if (score >= 70) return 'Khá tốt! 👍';
    if (score >= 60) return 'Đạt yêu cầu ✓';
    return 'Cần cố gắng hơn 💪';
  }
}

/// Model điểm theo kỹ năng
class SkillScoreModel {
  final double? listeningScore;
  final int? listeningCorrect;
  final int? listeningTotal;
  final double? readingScore;
  final int? readingCorrect;
  final int? readingTotal;
  final double? writingScore;
  final int? writingCorrect;
  final int? writingTotal;

  SkillScoreModel({
    this.listeningScore,
    this.listeningCorrect,
    this.listeningTotal,
    this.readingScore,
    this.readingCorrect,
    this.readingTotal,
    this.writingScore,
    this.writingCorrect,
    this.writingTotal,
  });

  factory SkillScoreModel.fromJson(Map<String, dynamic> json) {
    return SkillScoreModel(
      listeningScore: (json['listeningScore'] as num?)?.toDouble(),
      listeningCorrect: (json['listeningCorrect'] as num?)?.toInt(),
      listeningTotal: (json['listeningTotal'] as num?)?.toInt(),
      readingScore: (json['readingScore'] as num?)?.toDouble(),
      readingCorrect: (json['readingCorrect'] as num?)?.toInt(),
      readingTotal: (json['readingTotal'] as num?)?.toInt(),
      writingScore: (json['writingScore'] as num?)?.toDouble(),
      writingCorrect: (json['writingCorrect'] as num?)?.toInt(),
      writingTotal: (json['writingTotal'] as num?)?.toInt(),
    );
  }
}

/// Model kết quả từng câu hỏi
class QuestionResultModel {
  final int index;
  final int flashcardId;
  final String questionType;
  final String skillType;      // ✅ Non-nullable
  final String question;       // ✅ Non-nullable
  final String userAnswer;     // ✅ Non-nullable
  final String correctAnswer;  // ✅ Non-nullable
  final bool isCorrect;
  final int timeSpent;         // ✅ Non-nullable
  final String word;           // ✅ Non-nullable
  final String meaning;        // ✅ Non-nullable
  final String explanation;    // ✅ Non-nullable

  QuestionResultModel({
    required this.index,
    required this.flashcardId,
    required this.questionType,
    this.skillType = 'READING',
    this.question = '',
    this.userAnswer = '',
    this.correctAnswer = '',
    required this.isCorrect,
    this.timeSpent = 0,
    this.word = '',
    this.meaning = '',
    this.explanation = '',
  });

  factory QuestionResultModel.fromJson(Map<String, dynamic> json) {
    return QuestionResultModel(
      index: (json['index'] as num?)?.toInt() ?? 0,
      flashcardId: (json['flashcardId'] as num?)?.toInt() ?? 0,
      questionType: json['questionType']?.toString() ?? '',
      skillType: json['skillType']?.toString() ?? 'READING',
      question: json['question']?.toString() ?? '',
      userAnswer: json['userAnswer']?.toString() ?? '',
      correctAnswer: json['correctAnswer']?.toString() ?? '',
      isCorrect: json['isCorrect'] == true,
      timeSpent: (json['timeSpent'] as num?)?.toInt() ?? 0,
      word: json['word']?.toString() ?? '',
      meaning: json['meaning']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
    );
  }
}

/// Model thống kê quiz
class QuizStatsModel {
  final int totalQuizzes;
  final int totalQuestions;
  final int totalCorrect;
  final double overallAccuracy;
  final double averageScore;
  final int passedQuizzes;
  final int failedQuizzes;
  final double? avgListeningScore;
  final double? avgReadingScore;
  final double? avgWritingScore;
  final int quizzesToday;
  final int quizzesThisWeek;

  QuizStatsModel({
    required this.totalQuizzes,
    required this.totalQuestions,
    required this.totalCorrect,
    required this.overallAccuracy,
    required this.averageScore,
    required this.passedQuizzes,
    required this.failedQuizzes,
    this.avgListeningScore,
    this.avgReadingScore,
    this.avgWritingScore,
    required this.quizzesToday,
    required this.quizzesThisWeek,
  });

  factory QuizStatsModel.fromJson(Map<String, dynamic> json) {
    return QuizStatsModel(
      totalQuizzes: (json['totalQuizzes'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      totalCorrect: (json['totalCorrect'] as num?)?.toInt() ?? 0,
      overallAccuracy: (json['overallAccuracy'] as num?)?.toDouble() ?? 0.0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
      passedQuizzes: (json['passedQuizzes'] as num?)?.toInt() ?? 0,
      failedQuizzes: (json['failedQuizzes'] as num?)?.toInt() ?? 0,
      avgListeningScore: (json['avgListeningScore'] as num?)?.toDouble(),
      avgReadingScore: (json['avgReadingScore'] as num?)?.toDouble(),
      avgWritingScore: (json['avgWritingScore'] as num?)?.toDouble(),
      quizzesToday: (json['quizzesToday'] as num?)?.toInt() ?? 0,
      quizzesThisWeek: (json['quizzesThisWeek'] as num?)?.toInt() ?? 0,
    );
  }

  // ✅ Thêm computed property
  double get passRate => totalQuizzes > 0
      ? passedQuizzes / totalQuizzes * 100
      : 0;
}