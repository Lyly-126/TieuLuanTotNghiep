class CategoryModel {
  final int id;
  final String name;
  final bool isSystem;
  final int? ownerUserId;
  final String? ownerEmail;
  final int? classId;
  final String? className;
  final String createdAt;
  final int? flashcardCount;

  CategoryModel({
    required this.id,
    required this.name,
    required this.isSystem,
    this.ownerUserId,
    this.ownerEmail,
    this.classId,
    this.className,
    required this.createdAt,
    this.flashcardCount,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'] ?? '',
      isSystem: json['isSystem'] ?? false,
      ownerUserId: json['ownerUserId'],
      ownerEmail: json['ownerEmail'],
      classId: json['classId'],
      className: json['className'],
      createdAt: json['createdAt'] ?? '',
      flashcardCount: json['flashcardCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isSystem': isSystem,
      'ownerUserId': ownerUserId,
      'ownerEmail': ownerEmail,
      'classId': classId,
      'className': className,
      'createdAt': createdAt,
      'flashcardCount': flashcardCount,
    };
  }

  // Helper methods
  String get typeDisplayName {
    if (isSystem) return '🌐 Hệ thống';
    if (classId != null) return '🏫 Lớp học';
    return '👤 Cá nhân';
  }

  bool get isClassCategory => classId != null;
  bool get isUserCategory => !isSystem && classId == null;

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, type: $typeDisplayName)';
  }
}