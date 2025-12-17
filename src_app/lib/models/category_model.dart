class CategoryModel {
  final int id;
  final String name;
  final String? description;
  final int? flashcardCount;
  final int? classId;
  final String? className;
  final bool isSystem;
  final bool isUserCategory;
  final bool isClassCategory;

  // ✅ SỬ DỤNG DB CÓ SẴN
  final int? ownerUserId;     // DB field: ownerUserId (không phải creatorId)
  final String? visibility;   // DB field: visibility (PUBLIC/PRIVATE)
  final bool isSaved;         // Computed từ userSavedCategories table

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
    this.ownerUserId,           // ✅ Sử dụng ownerUserId từ DB
    this.visibility,            // ✅ Sử dụng visibility từ DB
    this.isSaved = false,
  });

  /// ✅ Type display name helper
  String get typeDisplayName {
    if (isSystem) return '🌐 Hệ thống';
    if (isClassCategory) return '🏫 Lớp học';
    if (isUserCategory) return '👤 Cá nhân';
    return 'Category';
  }

  /// ✅ Check if category is public
  bool get isPublic => visibility == 'PUBLIC';

  /// ✅ UPDATED: Parse từ JSON theo DB structure
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      flashcardCount: json['flashcard_count'] as int?,
      classId: json['class_id'] as int?,
      className: json['class_name'] as String?,
      isSystem: json['is_system'] as bool? ?? json['isSystem'] as bool? ?? false,
      isUserCategory: json['is_user_category'] as bool? ?? false,
      isClassCategory: json['is_class_category'] as bool? ?? false,
      ownerUserId: json['owner_user_id'] as int? ?? json['ownerUserId'] as int?,
      visibility: json['visibility'] as String?,
      isSaved: json['is_saved'] as bool? ?? false,
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
      'owner_user_id': ownerUserId,
      'visibility': visibility,
      'is_saved': isSaved,
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
    int? ownerUserId,
    String? visibility,
    bool? isSaved,
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
      ownerUserId: ownerUserId ?? this.ownerUserId,
      visibility: visibility ?? this.visibility,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, description: $description, '
        'isSystem: $isSystem, classId: $classId, ownerUserId: $ownerUserId, '
        'visibility: $visibility, isSaved: $isSaved)';
  }
}