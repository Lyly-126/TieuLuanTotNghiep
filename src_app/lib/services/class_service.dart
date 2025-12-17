// File: lib/services/class_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_constants.dart';
import '../models/class_model.dart';
import '../models/class_member_model.dart';

class ClassService {
  static const String baseUrl = '${AppConstants.baseUrl}/api/classes';

  // ==================== LOGGING & HELPERS ====================

  static void _log(String message) {
    print('[ClassService] $message');
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    _log('Checking token...');
    if (token != null) {
      _log('✅ Token found: ${token.substring(0, 20)}...');
    } else {
      _log('❌ Token not found');
    }

    return token;
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      _log('❌ No token - User needs to login');
      throw Exception('Vui lòng đăng nhập lại');
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=utf-8',
    };
  }

  // ==================== CLASS CRUD =================

  static Future<List<ClassModel>> getMyClasses() async {
    try {
      _log('========== GET MY CLASSES ==========');

      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/my-classes');

      _log('GET URL: $url');

      final response = await http.get(url, headers: headers);

      _log('Response Status: ${response.statusCode}');
      _log('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        _log('✅ Classes loaded successfully');
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        _log('Found ${data.length} classes');
        return data.map((json) => ClassModel.fromJson(json)).toList();
      } else {
        _log('❌ Failed to load classes');

        try {
          final error = json.decode(utf8.decode(response.bodyBytes));
          throw Exception(error['message'] ?? 'Không thể tải danh sách lớp');
        } catch (e) {
          throw Exception('Không thể tải danh sách lớp. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      _log('❌ Exception in getMyClasses: $e');
      rethrow;
    }
  }

  static Future<ClassDetailModel> getClassDetail(int classId) async {
    try {
      _log('========== GET CLASS DETAIL ==========');
      _log('Class ID: $classId');

      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/$classId');

      _log('GET URL: $url');

      final response = await http.get(url, headers: headers);

      _log('Response Status: ${response.statusCode}');
      _log('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        _log('✅ Class detail loaded successfully');
        final data = json.decode(utf8.decode(response.bodyBytes));
        return ClassDetailModel.fromJson(data);
      } else {
        _log('❌ Failed to load class detail');

        try {
          final errorBody = json.decode(utf8.decode(response.bodyBytes));
          final errorMessage = errorBody['message'] ??
              'Không thể tải thông tin lớp. Status: ${response.statusCode}';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('Không thể tải thông tin lớp. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      _log('❌ Exception in getClassDetail: $e');
      rethrow;
    }
  }

  static Future<ClassModel> getClassById(int classId) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/$classId');

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return ClassModel.fromJson(data);
      } else {
        throw Exception('Không thể tải thông tin lớp học');
      }
    } catch (e) {
      _log('❌ Exception in getClassById: $e');
      rethrow;
    }
  }

  static Future<bool> isUserMemberOfClass(int classId) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/$classId/is-member');

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['isMember'] ?? false;
      }
      return false;
    } catch (e) {
      _log('❌ Exception in isUserMemberOfClass: $e');
      return false;
    }
  }

  static Future<void> deleteClass(int classId) async {
    try {
      _log('========== DELETE CLASS ==========');
      _log('Class ID: $classId');

      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/$classId/delete');

      _log('DELETE URL: $url');

      final response = await http.delete(url, headers: headers);

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        _log('✅ Class deleted successfully');
        return;
      } else {
        _log('❌ Delete class failed');

        try {
          final error = json.decode(utf8.decode(response.bodyBytes));
          throw Exception(error['message'] ?? 'Không thể xóa lớp');
        } catch (e) {
          throw Exception('Không thể xóa lớp. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      _log('❌ Exception in deleteClass: $e');
      rethrow;
    }
  }

  // ==================== CLASS MEMBERS ====================

  static Future<List<ClassMemberModel>> getClassMembers(int classId) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/$classId/members');

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => ClassMemberModel.fromJson(json)).toList();
      } else {
        throw Exception('Không thể tải danh sách thành viên');
      }
    } catch (e) {
      _log('❌ Exception in getClassMembers: $e');
      rethrow;
    }
  }

  static Future<void> removeMember(int classId, int userId) async {
    try {
      _log('========== REMOVE MEMBER ==========');
      _log('Class ID: $classId, User ID: $userId');

      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/$classId/members/$userId');

      _log('DELETE URL: $url');

      final response = await http.delete(url, headers: headers);

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        _log('✅ Member removed successfully');
      } else {
        _log('❌ Remove member failed');

        try {
          final error = json.decode(utf8.decode(response.bodyBytes));
          throw Exception(error['message'] ?? 'Không thể xóa thành viên');
        } catch (e) {
          throw Exception('Không thể xóa thành viên');
        }
      }
    } catch (e) {
      _log('❌ Exception in removeMember: $e');
      rethrow;
    }
  }

  static Future<void> addMemberToClass({
    required int classId,
    required int userId,
    String role = 'STUDENT',
  }) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/$classId/members');

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          'userId': userId,
          'role': role,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Không thể thêm thành viên');
      }
    } catch (e) {
      _log('❌ Exception in addMemberToClass: $e');
      rethrow;
    }
  }

  // ==================== PENDING MEMBERS (APPROVAL SYSTEM) ====================

  /// ✅ Lấy danh sách thành viên chờ duyệt
  static Future<List<ClassMemberModel>> getPendingMembers(int classId) async {
    try {
      _log('========== GET PENDING MEMBERS ==========');
      _log('Class ID: $classId');

      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/$classId/members/pending');

      _log('GET URL: $url');

      final response = await http.get(url, headers: headers);

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        _log('✅ Pending members loaded successfully');
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => ClassMemberModel.fromJson(json)).toList();
      } else {
        _log('❌ Failed to load pending members');
        throw Exception('Không thể tải danh sách chờ duyệt');
      }
    } catch (e) {
      _log('❌ Exception in getPendingMembers: $e');
      rethrow;
    }
  }

  /// ✅ Duyệt thành viên
  static Future<void> approveMember(int classId, int userId) async {
    try {
      _log('========== APPROVE MEMBER ==========');
      _log('Class ID: $classId, User ID: $userId');

      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/$classId/members/$userId/approve');

      _log('POST URL: $url');

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({}),
      );

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        _log('✅ Member approved successfully');
      } else {
        _log('❌ Approve member failed');
        throw Exception('Không thể duyệt thành viên');
      }
    } catch (e) {
      _log('❌ Exception in approveMember: $e');
      rethrow;
    }
  }

  /// ✅ Từ chối thành viên
  static Future<void> rejectMember(int classId, int userId) async {
    try {
      _log('========== REJECT MEMBER ==========');
      _log('Class ID: $classId, User ID: $userId');

      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/$classId/members/$userId/reject');

      _log('POST URL: $url');

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({}),
      );

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        _log('✅ Member rejected successfully');
      } else {
        _log('❌ Reject member failed');
        throw Exception('Không thể từ chối thành viên');
      }
    } catch (e) {
      _log('❌ Exception in rejectMember: $e');
      rethrow;
    }
  }

  // ==================== CREATE/UPDATE CLASS ====================

  static Future<ClassModel> createClass({
    required String name,
    required String description,
    bool isPublic = false,
  }) async {
    try {
      _log('========== CREATE CLASS ==========');
      _log('Name: $name');
      _log('Description: $description');
      _log('IsPublic: $isPublic');

      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/create');

      _log('POST URL: $url');

      final body = json.encode({
        'name': name,
        'description': description,
        'isPublic': isPublic,
      });

      _log('Request Body: $body');

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      _log('Response Status: ${response.statusCode}');
      _log('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        _log('✅ Class created successfully');
        final data = json.decode(utf8.decode(response.bodyBytes));
        return ClassModel.fromJson(data);
      } else {
        _log('❌ Create class failed');

        try {
          final error = json.decode(utf8.decode(response.bodyBytes));
          final errorMessage = error['message'] ?? 'Không thể tạo lớp';
          _log('Error message: $errorMessage');
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('Không thể tạo lớp. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      _log('❌ Exception in createClass: $e');
      rethrow;
    }
  }

  static Future<ClassModel> updateClass({
    required int classId,
    required String name,
    required String description,
    bool? isPublic,
  }) async {
    try {
      _log('========== UPDATE CLASS ==========');
      _log('Class ID: $classId');
      _log('Name: $name');
      _log('IsPublic: $isPublic');

      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/$classId/update');

      _log('PUT URL: $url');

      final body = <String, dynamic>{
        'name': name,
        'description': description,
      };

      if (isPublic != null) {
        body['isPublic'] = isPublic;
      }

      final response = await http.put(
        url,
        headers: headers,
        body: json.encode(body),
      );

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        _log('✅ Class updated successfully');
        final data = json.decode(utf8.decode(response.bodyBytes));
        return ClassModel.fromJson(data);
      } else {
        _log('❌ Update class failed');

        try {
          final error = json.decode(utf8.decode(response.bodyBytes));
          throw Exception(error['message'] ?? 'Không thể cập nhật lớp');
        } catch (e) {
          throw Exception('Không thể cập nhật lớp. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      _log('❌ Exception in updateClass: $e');
      rethrow;
    }
  }

  // ==================== REGENERATE INVITE CODE ====================

  static Future<String> regenerateInviteCode(int classId) async {
    try {
      _log('========== REGENERATE INVITE CODE ==========');
      _log('Class ID: $classId');

      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/$classId/regenerate-invite-code');

      _log('POST URL: $url');

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({}),
      );

      _log('Response Status: ${response.statusCode}');
      _log('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final newCode = data['inviteCode'] as String;

        _log('✅ Invite code regenerated successfully: $newCode');
        return newCode;
      } else {
        _log('❌ Regenerate invite code failed');

        try {
          final error = json.decode(utf8.decode(response.bodyBytes));
          throw Exception(error['message'] ?? 'Không thể tạo mã mời mới');
        } catch (e) {
          throw Exception('Không thể tạo mã mời mới. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      _log('❌ Exception in regenerateInviteCode: $e');
      rethrow;
    }
  }

  // ==================== JOIN/LEAVE CLASS ====================

  static Future<void> joinClass(int classId) async {
    try {
      _log('========== JOIN CLASS ==========');
      _log('Class ID: $classId');

      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/$classId/join');

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể tham gia lớp học');
      }
    } catch (e) {
      _log('❌ Exception in joinClass: $e');
      rethrow;
    }
  }

  static Future<ClassMemberModel> joinByInviteCode(String inviteCode) async {
    try {
      _log('========== JOIN CLASS BY CODE ==========');
      _log('Invite Code: $inviteCode');

      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/join');

      _log('POST URL: $url');

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({'inviteCode': inviteCode.toUpperCase()}),
      );

      _log('Response Status: ${response.statusCode}');
      _log('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        _log('✅ Joined class successfully');
        final data = json.decode(utf8.decode(response.bodyBytes));
        return ClassMemberModel.fromJson(data);
      } else {
        _log('❌ Join class failed');

        try {
          final error = json.decode(utf8.decode(response.bodyBytes));
          throw Exception(error['message'] ?? 'Không thể tham gia lớp');
        } catch (e) {
          throw Exception('Không thể tham gia lớp. Mã lớp không hợp lệ.');
        }
      }
    } catch (e) {
      _log('❌ Exception in joinByInviteCode: $e');
      rethrow;
    }
  }

  static Future<void> leaveClass(int classId) async {
    try {
      _log('========== LEAVE CLASS ==========');
      _log('Class ID: $classId');

      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/$classId/leave');

      _log('DELETE URL: $url');

      final response = await http.delete(url, headers: headers);

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        _log('✅ Left class successfully');
        return;
      } else {
        _log('❌ Leave class failed');

        try {
          final error = json.decode(utf8.decode(response.bodyBytes));
          throw Exception(error['message'] ?? 'Không thể rời lớp');
        } catch (e) {
          throw Exception('Không thể rời lớp. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      _log('❌ Exception in leaveClass: $e');
      rethrow;
    }
  }

  static Future<List<ClassModel>> getJoinedClasses() async {
    try {
      _log('========== GET JOINED CLASSES ==========');

      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/joined');

      _log('GET URL: $url');

      final response = await http.get(url, headers: headers);

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        _log('✅ Joined classes loaded successfully');
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        _log('Found ${data.length} joined classes');
        return data.map((json) => ClassModel.fromJson(json)).toList();
      } else {
        _log('❌ Failed to load joined classes');
        throw Exception('Không thể tải danh sách lớp đã tham gia');
      }
    } catch (e) {
      _log('❌ Exception in getJoinedClasses: $e');
      rethrow;
    }
  }

  // ==================== SEARCH ====================

  static Future<List<ClassModel>> searchClasses(String keyword) async {
    try {
      _log('========== SEARCH CLASSES ==========');
      _log('Keyword: $keyword');

      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/search?keyword=$keyword');

      _log('GET URL: $url');

      final response = await http.get(url, headers: headers);

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        _log('✅ Search completed successfully');
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        _log('Found ${data.length} classes');
        return data.map((json) => ClassModel.fromJson(json)).toList();
      } else {
        _log('❌ Search failed');
        throw Exception('Không thể tìm kiếm lớp');
      }
    } catch (e) {
      _log('❌ Exception in searchClasses: $e');
      rethrow;
    }
  }

  static Future<List<ClassModel>> getPublicClasses() async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/public');

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => ClassModel.fromJson(json)).toList();
      } else {
        throw Exception('Không thể tải danh sách lớp học công khai');
      }
    } catch (e) {
      _log('❌ Exception in getPublicClasses: $e');
      rethrow;
    }
  }
}

// ==================== CLASS DETAIL MODEL ====================

class ClassDetailModel {
  final int id;
  final String name;
  final String? description;
  final String? inviteCode;
  final int ownerId;
  final bool? isPublic;
  final String? createdAt;
  final String? updatedAt;
  final int? memberCount;
  final int? categoryCount;
  final List<ClassMemberModel>? members;
  final List<dynamic>? categories;

  ClassDetailModel({
    required this.id,
    required this.name,
    this.description,
    this.inviteCode,
    required this.ownerId,
    this.isPublic,
    this.createdAt,
    this.updatedAt,
    this.memberCount,
    this.categoryCount,
    this.members,
    this.categories,
  });

  factory ClassDetailModel.fromJson(Map<String, dynamic> json) {
    return ClassDetailModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      inviteCode: json['inviteCode'] as String?,
      ownerId: json['ownerId'] as int,
      isPublic: json['isPublic'] as bool?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      memberCount: json['memberCount'] as int?,
      categoryCount: json['categoryCount'] as int?,
      members: json['members'] != null
          ? (json['members'] as List)
          .map((m) => ClassMemberModel.fromJson(m))
          .toList()
          : null,
      categories: json['categories'] as List<dynamic>?,
    );
  }
}