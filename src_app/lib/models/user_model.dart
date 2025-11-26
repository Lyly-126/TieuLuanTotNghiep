class UserModel {
  final int userId;
  final String email;
  final String displayName;
  final String? dob;
  final String status;
  final String role;
  final bool isBlocked;
  final String createdAt;

  UserModel({
    required this.userId,
    required this.email,
    required this.displayName,
    this.dob,
    required this.status,
    required this.role,
    required this.isBlocked,
    required this.createdAt,
  });

  // ✅ Factory constructor từ JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['id'] ?? 0,
      email: json['email'] ?? '',
      displayName: json['fullName'] ?? '',
      dob: json['dob'],
      status: json['status'] ?? 'UNVERIFIED',
      role: json['role'] ?? 'NORMAL_USER',
      isBlocked: json['isBlocked'] ?? false,
      createdAt: json['createdAt'] ?? '',
    );
  }

  // ✅ Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': userId,
      'email': email,
      'fullName': displayName,
      'dob': dob,
      'status': status,
      'role': role,
      'isBlocked': isBlocked,
      'createdAt': createdAt,
    };
  }

  // ✅ Helper methods để check role
  bool get isNormalUser => role == 'NORMAL_USER';
  bool get isPremiumUser => role == 'PREMIUM_USER';
  bool get isTeacher => role == 'TEACHER';
  bool get isAdmin => role == 'ADMIN';

  // ✅ Check user có premium features không - CHỈ DỰA VÀO ROLE
  bool get hasPremiumAccess =>
      role == 'PREMIUM_USER' || role == 'TEACHER';

  // ✅ Thêm getter để check isPremium (backward compatibility)
  bool get isPremium => role == 'PREMIUM_USER' || role == 'TEACHER';

  // ✅ Check user có thể tạo lớp học không
  bool get canCreateClass => role == 'TEACHER';

  // ✅ Display name cho role
  String get roleDisplayName {
    switch (role) {
      case 'NORMAL_USER':
        return 'User Thường';
      case 'PREMIUM_USER':
        return 'Premium User';
      case 'TEACHER':
        return 'Giáo Viên';
      case 'ADMIN':
        return 'Quản Trị Viên';
      default:
        return 'Unknown';
    }
  }

  // ✅ Icon cho role
  String get roleIcon {
    switch (role) {
      case 'NORMAL_USER':
        return '👤';
      case 'PREMIUM_USER':
        return '⭐';
      case 'TEACHER':
        return '👨‍🏫';
      case 'ADMIN':
        return '👑';
      default:
        return '❓';
    }
  }

  // ✅ Copy with method
  UserModel copyWith({
    int? userId,
    String? email,
    String? displayName,
    String? dob,
    String? status,
    String? role,
    bool? isBlocked,
    String? createdAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      dob: dob ?? this.dob,
      status: status ?? this.status,
      role: role ?? this.role,
      isBlocked: isBlocked ?? this.isBlocked,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(userId: $userId, email: $email, displayName: $displayName, role: $role)';
  }
}