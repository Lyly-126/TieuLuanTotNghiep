class ClassModel {
  final int id;
  final String name;
  final String? description;
  final int? ownerId;
  final bool? isPublic;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? inviteCode;
  final int? memberCount;
  final int? categoryCount;

  ClassModel({
    required this.id,
    required this.name,
    this.description,
    this.ownerId,
    this.isPublic,
    this.createdAt,
    this.updatedAt,
    this.inviteCode,
    this.memberCount,
    this.categoryCount,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      ownerId: json['ownerId'] as int?,              // ✅ camelCase
      isPublic: json['isPublic'] as bool?,            // ✅ camelCase
      createdAt: json['createdAt'] != null           // ✅ camelCase
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null           // ✅ camelCase
          ? DateTime.parse(json['updatedAt'])
          : null,
      inviteCode: json['inviteCode'] as String?,     // ✅ camelCase
      memberCount: json['memberCount'] as int?,      // ✅ camelCase
      categoryCount: json['categoryCount'] as int?,  // ✅ camelCase
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ownerId': ownerId,              // ✅ camelCase for backend
      'isPublic': isPublic,            // ✅ camelCase for backend
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'inviteCode': inviteCode,
      'memberCount': memberCount,
      'categoryCount': categoryCount,
    };
  }
}