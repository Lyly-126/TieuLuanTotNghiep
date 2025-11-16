class UserModel {
  final int userId;
  final String email;
  final String role;
  final String? fullName;
  final String status;
  bool isPremium;
  bool isBlocked;

  UserModel({
    required this.userId,
    required this.email,
    required this.role,
    this.fullName,
    this.status = 'UNVERIFIED',
    this.isPremium = false,
    this.isBlocked = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['id'] ?? 0,
      email: json['email'] ?? '',
      role: json['role'] ?? 'USER',
      fullName: json['fullName'],
      status: json['status'] ?? 'UNVERIFIED',
      isPremium: json['isPremium'] ?? false,
      isBlocked: json['isBlocked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': userId,
      'email': email,
      'role': role,
      'fullName': fullName,
      'status': status,
      'isPremium': isPremium,
      'isBlocked': isBlocked,
    };
  }

  // Helper methods
  bool get isAdmin => role == 'ADMIN';
  bool get isActive => !isBlocked && status != 'BANNED';

  String get displayName => fullName ?? email.split('@')[0];
}