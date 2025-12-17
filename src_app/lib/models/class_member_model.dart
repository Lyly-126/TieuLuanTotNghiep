class ClassMemberModel {
  final int classId;
  final int userId;
  final String userEmail;
  final String userFullName;
  final String userRole;
  final String memberRole;

  // ✅ THÊM STATUS
  final String status; // PENDING, APPROVED, REJECTED

  final String joinedAt;

  ClassMemberModel({
    required this.classId,
    required this.userId,
    required this.userEmail,
    required this.userFullName,
    required this.userRole,
    required this.memberRole,
    required this.status, // ✅
    required this.joinedAt,
  });

  factory ClassMemberModel.fromJson(Map<String, dynamic> json) {
    return ClassMemberModel(
      classId: json['classId'] ?? 0,
      userId: json['userId'] ?? 0,
      userEmail: json['userEmail'] ?? '',
      userFullName: json['userFullName'] ?? '',
      userRole: json['userRole'] ?? 'NORMAL_USER',
      memberRole: json['memberRole'] ?? 'STUDENT',
      status: json['status'] ?? 'APPROVED', // ✅
      joinedAt: json['joinedAt'] ?? '',
    );
  }

  // ✅ Helper methods
  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';
}