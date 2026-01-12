/// ✅ CategoryModel - UPDATED với shareToken
///
/// Fix: Thêm field shareToken để nhận dữ liệu từ backend
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

  // ✅ THÊM MỚI: shareToken để chia sẻ category
  final String? shareToken;

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
    this.ownerUserId,
    this.visibility,
    this.isSaved = false,
    this.shareToken,  // ✅ THÊM
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

  /// ✅ Check if category can be shared (has shareToken)
  bool get canShare => shareToken != null && shareToken!.isNotEmpty;

  /// ✅ Get share link
  String? get shareLink {
    if (shareToken == null) return null;
    return 'https://flashlearn.vn/share/$shareToken';
  }

  /// ✅ UPDATED: Parse từ JSON - hỗ trợ cả camelCase và snake_case
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      // ✅ FIX: Hỗ trợ cả camelCase (từ backend) và snake_case
      flashcardCount: json['flashcardCount'] as int? ?? json['flashcard_count'] as int?,
      classId: json['classId'] as int? ?? json['class_id'] as int?,
      className: json['className'] as String? ?? json['class_name'] as String?,
      isSystem: json['isSystem'] as bool? ?? json['is_system'] as bool? ?? false,
      isUserCategory: json['isUserCategory'] as bool? ?? json['is_user_category'] as bool? ?? false,
      isClassCategory: json['isClassCategory'] as bool? ?? json['is_class_category'] as bool? ?? false,
      ownerUserId: json['ownerUserId'] as int? ?? json['owner_user_id'] as int?,
      visibility: json['visibility'] as String?,
      isSaved: json['isSaved'] as bool? ?? json['is_saved'] as bool? ?? false,
      shareToken: json['shareToken'] as String? ?? json['share_token'] as String?,  // ✅ THÊM
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'flashcardCount': flashcardCount,
      'classId': classId,
      'className': className,
      'isSystem': isSystem,
      'isUserCategory': isUserCategory,
      'isClassCategory': isClassCategory,
      'ownerUserId': ownerUserId,
      'visibility': visibility,
      'isSaved': isSaved,
      'shareToken': shareToken,  // ✅ THÊM
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
    String? shareToken,  // ✅ THÊM
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
      shareToken: shareToken ?? this.shareToken,  // ✅ THÊM
    );
  }

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, flashcardCount: $flashcardCount, '
        'isSystem: $isSystem, classId: $classId, ownerUserId: $ownerUserId, '
        'visibility: $visibility, isSaved: $isSaved, shareToken: $shareToken)';
  }
}