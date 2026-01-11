/// ✅ FIXED: Model cho lịch học của từng category
/// Tương thích với CategoryReminder API đã có trong backend
class CategoryStudyScheduleModel {
  final int? id;
  final int categoryId;
  final String? categoryName;
  final int hour;
  final int minute;
  final String daysOfWeek; // "1111111" - 7 chars, mỗi char là 1 ngày (0=CN, 1=T2, ...)
  final bool isEnabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CategoryStudyScheduleModel({
    this.id,
    required this.categoryId,
    this.categoryName,
    this.hour = 20,
    this.minute = 0,
    this.daysOfWeek = '1111111',
    this.isEnabled = false,
    this.createdAt,
    this.updatedAt,
  });

  // ==================== JSON SERIALIZATION ====================

  /// Parse từ JSON gốc (cũ)
  factory CategoryStudyScheduleModel.fromJson(Map<String, dynamic> json) {
    return CategoryStudyScheduleModel(
      id: json['id'],
      categoryId: json['categoryId'] ?? 0,
      categoryName: json['categoryName'],
      hour: json['hour'] ?? 20,
      minute: json['minute'] ?? 0,
      daysOfWeek: json['daysOfWeek'] ?? '1111111',
      isEnabled: json['isEnabled'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  /// ✅ Parse từ CategoryReminder API response
  factory CategoryStudyScheduleModel.fromCategoryReminderJson(Map<String, dynamic> json) {
    return CategoryStudyScheduleModel(
      id: json['id'],
      categoryId: json['categoryId'] ?? 0,
      categoryName: json['categoryName'],
      hour: json['hour'] ?? 20,
      minute: json['minute'] ?? 0,
      daysOfWeek: json['daysOfWeek'] ?? '1111111',
      isEnabled: json['isEnabled'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'hour': hour,
      'minute': minute,
      'daysOfWeek': daysOfWeek,
      'isEnabled': isEnabled,
    };
  }

  /// ✅ Convert to CategoryReminder API request format
  Map<String, dynamic> toCategoryReminderJson() {
    return {
      'hour': hour,
      'minute': minute,
      'daysOfWeek': daysOfWeek,
      'isEnabled': isEnabled,
    };
  }

  // ==================== HELPER METHODS ====================

  /// Kiểm tra ngày có được bật không
  bool isDayEnabled(int dayIndex) {
    if (dayIndex < 0 || dayIndex >= 7) return false;
    return daysOfWeek.length > dayIndex && daysOfWeek[dayIndex] == '1';
  }

  /// Toggle ngày
  CategoryStudyScheduleModel toggleDay(int dayIndex) {
    if (dayIndex < 0 || dayIndex >= 7) return this;

    final chars = daysOfWeek.split('');
    if (chars.length < 7) {
      // Pad to 7 chars
      while (chars.length < 7) chars.add('0');
    }
    chars[dayIndex] = chars[dayIndex] == '1' ? '0' : '1';

    return copyWith(daysOfWeek: chars.join());
  }

  /// Số ngày được bật
  int get enabledDaysCount {
    return daysOfWeek.split('').where((c) => c == '1').length;
  }

  /// Có ngày nào được bật không
  bool get hasAnyDayEnabled => enabledDaysCount > 0;

  /// Danh sách tên các ngày được bật
  List<String> get enabledDayNames {
    const dayNames = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    List<String> result = [];
    for (int i = 0; i < 7; i++) {
      if (isDayEnabled(i)) {
        result.add(dayNames[i]);
      }
    }
    return result;
  }

  /// Thời gian hiển thị
  String get displayTime {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// Copy with
  CategoryStudyScheduleModel copyWith({
    int? id,
    int? categoryId,
    String? categoryName,
    int? hour,
    int? minute,
    String? daysOfWeek,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryStudyScheduleModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ==================== SCHEDULE ITEM ====================

/// Item lịch học (dùng cho overview)
class ScheduleItem {
  final int categoryId;
  final String categoryName;
  final int hour;
  final int minute;
  final int dayOfWeek;
  final DateTime? scheduledDateTime;

  ScheduleItem({
    required this.categoryId,
    required this.categoryName,
    required this.hour,
    required this.minute,
    required this.dayOfWeek,
    this.scheduledDateTime,
  });

  String get displayTime {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  int compareTime(ScheduleItem other) {
    final thisMinutes = hour * 60 + minute;
    final otherMinutes = other.hour * 60 + other.minute;
    return thisMinutes.compareTo(otherMinutes);
  }
}

// ==================== SCHEDULE OVERVIEW ====================

/// Tổng quan lịch học (dùng cho home screen)
class StudyScheduleOverview {
  final List<ScheduleItem> todaySchedules;
  final List<ScheduleItem> upcomingSchedules;
  final List<ScheduleConflict> conflicts;
  final int totalActiveSchedules;

  StudyScheduleOverview({
    required this.todaySchedules,
    required this.upcomingSchedules,
    required this.conflicts,
    required this.totalActiveSchedules,
  });

  factory StudyScheduleOverview.empty() {
    return StudyScheduleOverview(
      todaySchedules: [],
      upcomingSchedules: [],
      conflicts: [],
      totalActiveSchedules: 0,
    );
  }

  bool get hasTodaySchedules => todaySchedules.isNotEmpty;
  bool get hasConflicts => conflicts.isNotEmpty;
}

// ==================== SCHEDULE CONFLICT ====================

/// Xung đột lịch học
class ScheduleConflict {
  final int hour;
  final int minute;
  final int dayOfWeek;
  final List<ConflictingCategory> categories;

  ScheduleConflict({
    required this.hour,
    required this.minute,
    required this.dayOfWeek,
    required this.categories,
  });

  String get displayTime {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String get dayName {
    const dayNames = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return dayNames[dayOfWeek];
  }
}

/// Category bị xung đột
class ConflictingCategory {
  final int categoryId;
  final String categoryName;

  ConflictingCategory({
    required this.categoryId,
    required this.categoryName,
  });
}