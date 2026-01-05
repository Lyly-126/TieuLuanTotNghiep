/// Models cho Study Progress, Streak, và Reminder

// ==================== CATEGORY PROGRESS ====================

class CategoryProgressModel {
  final int categoryId;
  final int totalCards;
  final int masteredCards;
  final int learningCards;
  final int notStartedCards;
  final int studiedCards;
  final int correctCount;
  final int incorrectCount;
  final double progressPercent;
  final double masteryPercent;
  final double accuracyRate;
  final DateTime? lastStudiedAt;

  CategoryProgressModel({
    required this.categoryId,
    required this.totalCards,
    this.masteredCards = 0,
    this.learningCards = 0,
    this.notStartedCards = 0,
    this.studiedCards = 0,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.progressPercent = 0.0,
    this.masteryPercent = 0.0,
    this.accuracyRate = 0.0,
    this.lastStudiedAt,
  });

  factory CategoryProgressModel.fromJson(Map<String, dynamic> json) {
    return CategoryProgressModel(
      categoryId: json['categoryId'] ?? 0,
      totalCards: json['totalCards'] ?? 0,
      masteredCards: json['masteredCards'] ?? 0,
      learningCards: json['learningCards'] ?? 0,
      notStartedCards: json['notStartedCards'] ?? 0,
      studiedCards: json['studiedCards'] ?? 0,
      correctCount: json['correctCount'] ?? 0,
      incorrectCount: json['incorrectCount'] ?? 0,
      progressPercent: (json['progressPercent'] ?? 0.0).toDouble(),
      masteryPercent: (json['masteryPercent'] ?? 0.0).toDouble(),
      accuracyRate: (json['accuracyRate'] ?? 0.0).toDouble(),
      lastStudiedAt: json['lastStudiedAt'] != null
          ? DateTime.tryParse(json['lastStudiedAt'])
          : null,
    );
  }

  factory CategoryProgressModel.empty(int categoryId) {
    return CategoryProgressModel(
      categoryId: categoryId,
      totalCards: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'totalCards': totalCards,
      'masteredCards': masteredCards,
      'learningCards': learningCards,
      'notStartedCards': notStartedCards,
      'studiedCards': studiedCards,
      'correctCount': correctCount,
      'incorrectCount': incorrectCount,
      'progressPercent': progressPercent,
      'masteryPercent': masteryPercent,
      'accuracyRate': accuracyRate,
      'lastStudiedAt': lastStudiedAt?.toIso8601String(),
    };
  }
}


// ==================== DAILY STUDY ====================

class DailyStudyModel {
  final DateTime date;
  final bool isStudied;
  final int cardsStudied;
  final int minutesSpent;
  final int sessionsCount;

  DailyStudyModel({
    required this.date,
    this.isStudied = false,
    this.cardsStudied = 0,
    this.minutesSpent = 0,
    this.sessionsCount = 0,
  });

  factory DailyStudyModel.fromJson(Map<String, dynamic> json) {
    return DailyStudyModel(
      date: json['date'] != null
          ? DateTime.tryParse(json['date']) ?? DateTime.now()
          : DateTime.now(),
      isStudied: json['isStudied'] ?? json['studied'] ?? false,
      cardsStudied: json['cardsStudied'] ?? 0,
      minutesSpent: json['minutesSpent'] ?? 0,
      sessionsCount: json['sessionsCount'] ?? 0,
    );
  }

  // ✅ Factory constructor cho empty
  factory DailyStudyModel.empty() {
    return DailyStudyModel(
      date: DateTime.now(),
      isStudied: false,
      cardsStudied: 0,
      minutesSpent: 0,
      sessionsCount: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'isStudied': isStudied,
      'cardsStudied': cardsStudied,
      'minutesSpent': minutesSpent,
      'sessionsCount': sessionsCount,
    };
  }
}


// ==================== STUDY STREAK ====================

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
    return StudyStreakModel(
      currentStreak: 0,
      longestStreak: 0,
      totalStudyDays: 0,
      hasStudiedToday: false,
      isStreakAtRisk: false,
      weeklyData: List.generate(7, (_) => DailyStudyModel.empty()),
    );
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


// ==================== STUDY REMINDER ====================

class StudyReminderModel {
  final int? id;
  final int hour;
  final int minute;
  final String daysOfWeek; // "1111111" = all days enabled
  final bool isEnabled;
  final String? customMessage;

  StudyReminderModel({
    this.id,
    this.hour = 20,
    this.minute = 0,
    this.daysOfWeek = '1111111',
    this.isEnabled = true,
    this.customMessage,
  });

  factory StudyReminderModel.fromJson(Map<String, dynamic> json) {
    // Parse reminderTime from "HH:mm:ss" format
    int h = 20, m = 0;
    if (json['reminderTime'] != null) {
      final parts = json['reminderTime'].toString().split(':');
      if (parts.length >= 2) {
        h = int.tryParse(parts[0]) ?? 20;
        m = int.tryParse(parts[1]) ?? 0;
      }
    }

    return StudyReminderModel(
      id: json['id'],
      hour: json['hour'] ?? h,
      minute: json['minute'] ?? m,
      daysOfWeek: json['daysOfWeek'] ?? '1111111',
      isEnabled: json['isEnabled'] ?? true,
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
    if (dayIndex < 0 || dayIndex >= 7) return false;
    if (daysOfWeek.length != 7) return true;
    return daysOfWeek[dayIndex] == '1';
  }

  StudyReminderModel toggleDay(int dayIndex) {
    if (dayIndex < 0 || dayIndex >= 7) return this;

    final chars = daysOfWeek.padRight(7, '1').split('');
    chars[dayIndex] = chars[dayIndex] == '1' ? '0' : '1';

    return copyWith(daysOfWeek: chars.join());
  }

  StudyReminderModel copyWith({
    int? id,
    int? hour,
    int? minute,
    String? daysOfWeek,
    bool? isEnabled,
    String? customMessage,
  }) {
    return StudyReminderModel(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isEnabled: isEnabled ?? this.isEnabled,
      customMessage: customMessage ?? this.customMessage,
    );
  }
}