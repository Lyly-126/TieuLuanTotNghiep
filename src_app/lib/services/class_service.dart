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

  /// ✅ Lấy token từ SharedPreferences (khớp với cách LoginScreen lưu)
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

    // ✅ FIX: Đảm bảo Authorization header đúng format
    return {
      'Authorization': 'Bearer $token', // ⚠️ Phải có "Bearer " ở đầu
      'Content-Type': 'application/json; charset=utf-8',
    };
  }

  // ==================== CLASS CRUD ====================

  /// ✅ Tạo lớp học mới
  static Future<ClassModel> createClass({
    required String name,
    required String description,
  }) async {
    try {
      _log('========== CREATE CLASS ==========');
      _log('Name: $name');
      _log('Description: $description');

      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/create');

      _log('POST URL: $url');
      _log('Headers: $headers');

      final body = json.encode({
        'name': name,
        'description': description,
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
          // Nếu không parse được error
          throw Exception('Không thể tạo lớp. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      _log('❌ Exception in createClass: $e');
      rethrow;
    }
  }

  /// ✅ Lấy danh sách lớp của teacher
  static Future<List<ClassModel>> getMyClasses() async {
    try {
      _log('========== GET MY CLASSES ==========');

      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/my-classes');

      _log('GET URL: $url');
      _log('Headers: $headers'); // ✅ LOG HEADERS ĐỂ KIỂM TRA

      final response = await http.get(url, headers: headers);

      _log('Response Status: ${response.statusCode}');
      _log('Response Body: ${response.body}'); // ✅ LOG BODY ĐỂ XEM LỖI CHI TIẾT

      if (response.statusCode == 200) {
        _log('✅ Classes loaded successfully');
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        _log('Found ${data.length} classes');
        return data.map((json) => ClassModel.fromJson(json)).toList();
      } else {
        _log('❌ Failed to load classes');

        // ✅ PARSE ERROR BODY TỪ BACKEND
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

  /// ✅ Lấy chi tiết lớp học (với members)
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

  /// ✅ Cập nhật lớp học
  static Future<ClassModel> updateClass({
    required int classId,
    required String name,
    required String description,
  }) async {
    try {
      _log('========== UPDATE CLASS ==========');
      _log('Class ID: $classId');
      _log('Name: $name');

      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/$classId/update');

      _log('PUT URL: $url');

      final response = await http.put(
        url,
        headers: headers,
        body: json.encode({
          'name': name,
          'description': description,
        }),
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

  /// ✅ Xóa lớp học
  static Future<void> deleteClass(int classId) async {
    try {
      _log('========== DELETE CLASS ==========');
      _log('Class ID: $classId');

      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/$classId/delete');

      _log('DELETE URL: $url');

      final response = await http.delete(url, headers: headers);

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
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

  /// ✅ Xóa member khỏi lớp (by teacher)
  static Future<void> removeMember(int classId, int userId) async {
    try {
      _log('========== REMOVE MEMBER ==========');
      _log('Class ID: $classId, User ID: $userId');

      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/$classId/members/$userId');

      _log('DELETE URL: $url');

      final response = await http.delete(url, headers: headers);

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
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

  // ==================== JOIN/LEAVE CLASS ====================

  /// ✅ Tham gia lớp qua invite code
  static Future<ClassMemberModel> joinByInviteCode(String inviteCode) async {
    try {
      _log('========== JOIN CLASS ==========');
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

  /// ✅ Lấy danh sách lớp đã tham gia (for students)
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

  /// ✅ Tìm kiếm lớp học
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
}

class ClassDetailModel {
  final int id;
  final String name;
  final String? description;
  final String? inviteCode;
  final int ownerId;
  final int? memberCount;
  final int? categoryCount;
  final List<ClassMemberModel>? members;

  ClassDetailModel({
    required this.id,
    required this.name,
    this.description,
    this.inviteCode,
    required this.ownerId,
    this.memberCount,
    this.categoryCount,
    this.members,
  });

  factory ClassDetailModel.fromJson(Map<String, dynamic> json) {
    return ClassDetailModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      inviteCode: json['inviteCode'] as String?,
      ownerId: json['ownerId'] as int,
      memberCount: json['memberCount'] as int?,
      categoryCount: json['categoryCount'] as int?,
      members: json['members'] != null
          ? (json['members'] as List)
          .map((m) => ClassMemberModel.fromJson(m))
          .toList()
          : null,
    );
  }
}