class ClassMemberModel {
  final int classId;
  final int userId;
  final String? userEmail;
  final String? userFullName;
  final String? userRole; // TEACHER, NORMAL_USER, PREMIUM_USER, ADMIN
  final String memberRole; // STUDENT, TEACHER, CO_TEACHER
  final String joinedAt;

  ClassMemberModel({
    required this.classId,
    required this.userId,
    this.userEmail,
    this.userFullName,
    this.userRole,
    required this.memberRole,
    required this.joinedAt,
  });

  factory ClassMemberModel.fromJson(Map<String, dynamic> json) {
    return ClassMemberModel(
      classId: json['classId'],
      userId: json['userId'],
      userEmail: json['userEmail'],
      userFullName: json['userFullName'],
      userRole: json['userRole'],
      memberRole: json['memberRole'] ?? 'STUDENT',
      joinedAt: json['joinedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'classId': classId,
      'userId': userId,
      'userEmail': userEmail,
      'userFullName': userFullName,
      'userRole': userRole,
      'memberRole': memberRole,
      'joinedAt': joinedAt,
    };
  }

  // Helper getters
  bool get isStudent => memberRole == 'STUDENT';
  bool get isTeacher => memberRole == 'TEACHER';
  bool get isCoTeacher => memberRole == 'CO_TEACHER';

  String get roleDisplayName {
    switch (memberRole) {
      case 'TEACHER':
        return 'Giáo viên';
      case 'CO_TEACHER':
        return 'Giáo viên phụ';
      case 'STUDENT':
      default:
        return 'Học sinh';
    }
  }

  @override
  String toString() {
    return 'ClassMember(userId: $userId, name: $userFullName, role: $roleDisplayName)';
  }
}