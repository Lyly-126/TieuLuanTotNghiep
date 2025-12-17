class ClassModel {
  final int id;
  final String name;
  final String? description;
  final int? ownerId;
  final String? ownerName;        // ✅ THÊM field này
  final bool isPublic;            // ✅ Đổi thành non-nullable với default
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
    this.ownerName,               // ✅ THÊM vào constructor
    this.isPublic = false,        // ✅ Default value
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
      ownerId: json['ownerId'] as int?,
      ownerName: json['ownerName'] as String?,     // ✅ THÊM mapping
      isPublic: json['isPublic'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      inviteCode: json['inviteCode'] as String?,
      memberCount: json['studentCount'] as int?,
      categoryCount: json['categoryCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'ownerName': ownerName,                      // ✅ THÊM vào JSON
      'isPublic': isPublic,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'inviteCode': inviteCode,
      'memberCount': memberCount,
      'categoryCount': categoryCount,
    };
  }

  // ✅ Helper method
  ClassModel copyWith({
    int? id,
    String? name,
    String? description,
    int? ownerId,
    String? ownerName,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? inviteCode,
    int? memberCount,
    int? categoryCount,
  }) {
    return ClassModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      inviteCode: inviteCode ?? this.inviteCode,
      memberCount: memberCount ?? this.memberCount,
      categoryCount: categoryCount ?? this.categoryCount,
    );
  }

  @override
  String toString() {
    return 'ClassModel(id: $id, name: $name, ownerName: $ownerName, isPublic: $isPublic)';
  }
}