import 'dart:convert';

/// Model cho tiến trình học của category
class CategoryProgressModel {
  final int categoryId;
  final int totalCards;
  final int studiedCards;
  final int masteredCards;
  final int learningCards;
  final int notStartedCards;
  final int correctCount;
  final int incorrectCount;
  final double progressPercent;
  final double masteryPercent;
  final double accuracyRate;
  final DateTime? lastStudiedAt;

  CategoryProgressModel({
    required this.categoryId,
    this.totalCards = 0,
    this.studiedCards = 0,
    this.masteredCards = 0,
    this.learningCards = 0,
    this.notStartedCards = 0,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.progressPercent = 0,
    this.masteryPercent = 0,
    this.accuracyRate = 0,
    this.lastStudiedAt,
  });

  factory CategoryProgressModel.fromJson(Map<String, dynamic> json) {
    return CategoryProgressModel(
      categoryId: json['categoryId'] ?? 0,
      totalCards: json['totalCards'] ?? 0,
      studiedCards: json['studiedCards'] ?? 0,
      masteredCards: json['masteredCards'] ?? 0,
      learningCards: json['learningCards'] ?? 0,
      notStartedCards: json['notStartedCards'] ?? 0,
      correctCount: json['correctCount'] ?? 0,
      incorrectCount: json['incorrectCount'] ?? 0,
      progressPercent: (json['progressPercent'] ?? 0).toDouble(),
      masteryPercent: (json['masteryPercent'] ?? 0).toDouble(),
      accuracyRate: (json['accuracyRate'] ?? 0).toDouble(),
      lastStudiedAt: json['lastStudiedAt'] != null
          ? DateTime.tryParse(json['lastStudiedAt'])
          : null,
    );
  }

  factory CategoryProgressModel.empty(int categoryId) {
    return CategoryProgressModel(categoryId: categoryId);
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'totalCards': totalCards,
      'studiedCards': studiedCards,
      'masteredCards': masteredCards,
      'learningCards': learningCards,
      'notStartedCards': notStartedCards,
      'correctCount': correctCount,
      'incorrectCount': incorrectCount,
      'progressPercent': progressPercent,
      'masteryPercent': masteryPercent,
      'accuracyRate': accuracyRate,
      'lastStudiedAt': lastStudiedAt?.toIso8601String(),
    };
  }
}

/// Model cho Study Streak
class StudyStreakModel {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastStudyDate;
  final int totalStudyDays;
  final bool hasStudiedToday;
  final bool isStreakAtRisk;
  final List<DailyStudyModel> weeklyData;

  StudyStreakModel({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastStudyDate,
    this.totalStudyDays = 0,
    this.hasStudiedToday = false,
    this.isStreakAtRisk = false,
    this.weeklyData = const [],
  });

  factory StudyStreakModel.fromJson(Map<String, dynamic> json) {
    List<DailyStudyModel> weekly = [];
    if (json['weeklyData'] != null) {
      weekly = (json['weeklyData'] as List)
          .map((e) => DailyStudyModel.fromJson(e))
          .toList();
    }

    return StudyStreakModel(
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      lastStudyDate: json['lastStudyDate'] != null
          ? DateTime.tryParse(json['lastStudyDate'])
          : null,
      totalStudyDays: json['totalStudyDays'] ?? 0,
      hasStudiedToday: json['hasStudiedToday'] ?? false,
      isStreakAtRisk: json['isStreakAtRisk'] ?? false,
      weeklyData: weekly,
    );
  }

  factory StudyStreakModel.empty() {
    return StudyStreakModel();
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastStudyDate': lastStudyDate?.toIso8601String(),
      'totalStudyDays': totalStudyDays,
      'hasStudiedToday': hasStudiedToday,
      'isStreakAtRisk': isStreakAtRisk,
      'weeklyData': weeklyData.map((e) => e.toJson()).toList(),
    };
  }
}

/// Model cho Daily Study Log
class DailyStudyModel {
  final DateTime? date;
  final int cardsStudied;
  final int minutesSpent;
  final int sessionsCount;
  final bool isStudied;

  DailyStudyModel({
    this.date,
    this.cardsStudied = 0,
    this.minutesSpent = 0,
    this.sessionsCount = 0,
    this.isStudied = false,
  });

  factory DailyStudyModel.fromJson(Map<String, dynamic> json) {
    return DailyStudyModel(
      date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
      cardsStudied: json['cardsStudied'] ?? 0,
      minutesSpent: json['minutesSpent'] ?? 0,
      sessionsCount: json['sessionsCount'] ?? 0,
      isStudied: json['isStudied'] ?? false,
    );
  }

  factory DailyStudyModel.empty() {
    return DailyStudyModel();
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date?.toIso8601String(),
      'cardsStudied': cardsStudied,
      'minutesSpent': minutesSpent,
      'sessionsCount': sessionsCount,
      'isStudied': isStudied,
    };
  }
}

/// Model cho Study Reminder
class StudyReminderModel {
  final int? id;
  final int hour;
  final int minute;
  final String daysOfWeek;
  final List<String> enabledDays;
  final bool isEnabled;
  final String? customMessage;

  StudyReminderModel({
    this.id,
    this.hour = 20,
    this.minute = 0,
    this.daysOfWeek = '1111111',
    this.enabledDays = const [],
    this.isEnabled = false,
    this.customMessage,
  });

  factory StudyReminderModel.fromJson(Map<String, dynamic> json) {
    List<String> days = [];
    if (json['enabledDays'] != null) {
      days = List<String>.from(json['enabledDays']);
    }

    // Parse reminderTime nếu là string "HH:mm"
    int hour = json['hour'] ?? 20;
    int minute = json['minute'] ?? 0;

    if (json['reminderTime'] != null && json['reminderTime'] is String) {
      final parts = (json['reminderTime'] as String).split(':');
      if (parts.length >= 2) {
        hour = int.tryParse(parts[0]) ?? 20;
        minute = int.tryParse(parts[1]) ?? 0;
      }
    }

    return StudyReminderModel(
      id: json['id'],
      hour: hour,
      minute: minute,
      daysOfWeek: json['daysOfWeek'] ?? '1111111',
      enabledDays: days,
      isEnabled: json['isEnabled'] ?? false,
      customMessage: json['customMessage'],
    );
  }

  factory StudyReminderModel.defaultSettings() {
    return StudyReminderModel(
      hour: 20,
      minute: 0,
      daysOfWeek: '1111111',
      isEnabled: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hour': hour,
      'minute': minute,
      'daysOfWeek': daysOfWeek,
      'enabledDays': enabledDays,
      'isEnabled': isEnabled,
      'customMessage': customMessage,
    };
  }

  String get displayTime {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool isDayEnabled(int dayIndex) {
    if (dayIndex < 0 || dayIndex >= daysOfWeek.length) return false;
    return daysOfWeek[dayIndex] == '1';
  }

  StudyReminderModel toggleDay(int dayIndex) {
    if (dayIndex < 0 || dayIndex >= daysOfWeek.length) return this;

    final chars = daysOfWeek.split('');
    chars[dayIndex] = chars[dayIndex] == '1' ? '0' : '1';

    return StudyReminderModel(
      id: id,
      hour: hour,
      minute: minute,
      daysOfWeek: chars.join(),
      enabledDays: enabledDays,
      isEnabled: isEnabled,
      customMessage: customMessage,
    );
  }

  StudyReminderModel copyWith({
    int? id,
    int? hour,
    int? minute,
    String? daysOfWeek,
    List<String>? enabledDays,
    bool? isEnabled,
    String? customMessage,
  }) {
    return StudyReminderModel(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      enabledDays: enabledDays ?? this.enabledDays,
      isEnabled: isEnabled ?? this.isEnabled,
      customMessage: customMessage ?? this.customMessage,
    );
  }
}