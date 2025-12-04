// lib/models/category_model.dart

class CategoryModel {
  final int id;
  final String name;
  final String? description;
  final int? flashcardCount;
  final int? classId;
  final String? className;        // ← THÊM
  final bool isSystem;            // ← THÊM
  final bool isUserCategory;      // ← THÊM
  final bool isClassCategory;     // ← THÊM
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.flashcardCount,
    this.classId,
    this.className,
    this.isSystem = false,
    this.isUserCategory = false,
    this.isClassCategory = false,
    this.createdAt,
    this.updatedAt,
  });

  /// ✅ Type display name helper
  String get typeDisplayName {
    if (isSystem) return '🌐 Hệ thống';
    if (isClassCategory) return '🏫 Lớp học';
    if (isUserCategory) return '👤 Cá nhân';
    return 'Category';
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      flashcardCount: json['flashcard_count'] as int?,
      classId: json['class_id'] as int?,
      className: json['class_name'] as String?,
      isSystem: json['is_system'] as bool? ?? false,
      isUserCategory: json['is_user_category'] as bool? ?? false,
      isClassCategory: json['is_class_category'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'flashcard_count': flashcardCount,
      'class_id': classId,
      'class_name': className,
      'is_system': isSystem,
      'is_user_category': isUserCategory,
      'is_class_category': isClassCategory,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Copy with method for easy updates
  CategoryModel copyWith({
    int? id,
    String? name,
    String? description,
    int? flashcardCount,
    int? classId,
    String? className,
    bool? isSystem,
    bool? isUserCategory,
    bool? isClassCategory,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      flashcardCount: flashcardCount ?? this.flashcardCount,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      isSystem: isSystem ?? this.isSystem,
      isUserCategory: isUserCategory ?? this.isUserCategory,
      isClassCategory: isClassCategory ?? this.isClassCategory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}