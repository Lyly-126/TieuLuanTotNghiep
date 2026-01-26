import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/category_model.dart';

class CategoryService {
  static void _log(String message) {
    print('[CategoryService] $message');
  }

  /// Lấy token từ SharedPreferences
  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      throw Exception('Vui lòng đăng nhập lại');
    }
    return token;
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=utf-8',
      'ngrok-skip-browser-warning': 'true',
    };
  }

  // ==================== CATEGORY CRUD ====================

  /// ✅ Lấy tất cả categories của user hiện tại (Của tôi)
  /// Bao gồm: system categories + owned categories + saved + class categories
  static Future<List<CategoryModel>> getUserCategories() async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConfig.categoryBase}/my');

      _log('GET User Categories URL: $uri');

      final response = await http.get(uri, headers: headers);

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
        throw Exception('Không thể tải danh sách chủ đề');
      }
    } catch (e) {
      _log('❌ Error in getUserCategories: $e');
      rethrow;
    }
  }

  /// ✅ Alias method để tương thích
  static Future<List<CategoryModel>> getMyCategories() async {
    return getUserCategories();
  }

  /// ✅ NEW: Lấy CHỈ categories do user tự tạo (KHÔNG có system/default)
  /// Dùng cho:
  /// - Tạo flashcard từ Home (chọn category)
  /// - OCR/PDF chọn category
  /// - Dropdown chọn category
  static Future<List<CategoryModel>> getMyOwnedCategories() async {
    try {
      final headers = await _getHeaders();
      // ✅ GỌI ENDPOINT MỚI
      final uri = Uri.parse('${ApiConfig.categoryBase}/my/owned');

      _log('GET My Owned Categories URL: $uri');

      final response = await http.get(uri, headers: headers);

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final categories = data.map((json) => CategoryModel.fromJson(json)).toList();
        _log('✅ Found ${categories.length} owned categories');
        return categories;
      } else {
        _log('⚠️ API /my/owned failed, falling back to filter method');
        // Fallback: filter từ getMyCategories nếu endpoint chưa có
        return _getOwnedCategoriesFallback();
      }
    } catch (e) {
      _log('❌ Error in getMyOwnedCategories: $e');
      // Fallback
      return _getOwnedCategoriesFallback();
    }
  }

  /// Fallback: Lọc categories do user sở hữu từ danh sách categories
  static Future<List<CategoryModel>> _getOwnedCategoriesFallback() async {
    try {
      _log('🔄 Using fallback method to get owned categories');
      final allCategories = await getUserCategories();

      // ✅ Lọc: chỉ lấy category do user tạo
      // - isUserCategory = true (category cá nhân)
      // - isSystem = false (không phải system category)
      final ownedCategories = allCategories.where((cat) {
        return cat.isUserCategory && !cat.isSystem;
      }).toList();

      _log('✅ Fallback: Found ${ownedCategories.length} owned categories (filtered from ${allCategories.length})');
      return ownedCategories;
    } catch (e) {
      _log('❌ Error in fallback: $e');
      return [];
    }
  }

  /// ✅ Lấy danh sách categories đã lưu
  static Future<List<CategoryModel>> getSavedCategories() async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConfig.categoryBase}/saved');

      _log('GET Saved Categories URL: $uri');

      final response = await http.get(uri, headers: headers);

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
        throw Exception('Không thể tải danh sách chủ đề đã lưu');
      }
    } catch (e) {
      _log('❌ Error in getSavedCategories: $e');
      rethrow;
    }
  }

  /// ✅ Lưu một category
  static Future<void> saveCategory(int categoryId) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConfig.categoryBase}/$categoryId/save');

      _log('POST Save Category URL: $uri');

      final response = await http.post(uri, headers: headers);

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        _log('✅ Category saved successfully');
        return;
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể lưu chủ đề');
      }
    } catch (e) {
      _log('❌ Error in saveCategory: $e');
      rethrow;
    }
  }

  /// ✅ Bỏ lưu một category
  static Future<void> unsaveCategory(int categoryId) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConfig.categoryBase}/$categoryId/save');

      _log('DELETE Unsave Category URL: $uri');

      final response = await http.delete(uri, headers: headers);

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        _log('✅ Category unsaved successfully');
        return;
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể bỏ lưu chủ đề');
      }
    } catch (e) {
      _log('❌ Error in unsaveCategory: $e');
      rethrow;
    }
  }

  /// ✅ Kiểm tra xem category đã được lưu chưa
  static Future<bool> isCategorySaved(int categoryId) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConfig.categoryBase}/$categoryId/is-saved');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['isSaved'] ?? false;
      }
      return false;
    } catch (e) {
      _log('❌ Error in isCategorySaved: $e');
      return false;
    }
  }

  /// ✅ Lấy categories theo class ID
  static Future<List<CategoryModel>> getCategoriesByClassId(int classId) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(ApiConfig.classCategories(classId));

      _log('GET Categories for Class URL: $uri');

      final response = await http.get(uri, headers: headers);

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        _log('Found ${data.length} categories');
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
        throw Exception('Không thể tải danh sách học phần');
      }
    } catch (e) {
      _log('❌ Error in getCategoriesByClassId: $e');
      rethrow;
    }
  }

  /// ✅ Alias method để tương thích
  static Future<List<CategoryModel>> getCategoriesForClass(int classId) async {
    return getCategoriesByClassId(classId);
  }

  /// ✅ Lấy thông tin chi tiết category
  static Future<CategoryModel> getCategoryById(int categoryId) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConfig.categoryBase}/$categoryId');

      _log('GET Category by ID URL: $uri');

      final response = await http.get(uri, headers: headers);

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return CategoryModel.fromJson(data);
      } else {
        throw Exception('Không thể tải thông tin chủ đề');
      }
    } catch (e) {
      _log('❌ Error in getCategoryById: $e');
      rethrow;
    }
  }

  /// ✅ Lấy system categories
  static Future<List<CategoryModel>> getSystemCategories() async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConfig.categoryBase}/admin/system');

      _log('GET System Categories URL: $uri');

      final response = await http.get(uri, headers: headers);

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
        throw Exception('Không thể tải danh sách chủ đề hệ thống');
      }
    } catch (e) {
      _log('❌ Error in getSystemCategories: $e');
      rethrow;
    }
  }

  /// ✅ Tạo category cá nhân
  static Future<CategoryModel> createUserCategory(String name) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConfig.categoryBase}/user');

      _log('POST Create User Category URL: $uri');

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({'name': name}),
      );

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return CategoryModel.fromJson(data);
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể tạo chủ đề');
      }
    } catch (e) {
      _log('❌ Error in createUserCategory: $e');
      rethrow;
    }
  }

  /// ✅ Tạo category mới (generic - hỗ trợ cả class category)
  static Future<CategoryModel> createCategory({
    required String name,
    String? description,
    int? classId,
    String visibility = 'PRIVATE',
  }) async {
    try {
      final headers = await _getHeaders();

      // Nếu có classId, sử dụng endpoint /class
      // Nếu không, sử dụng endpoint /user
      final uri = classId != null
          ? Uri.parse('${ApiConfig.categoryBase}/class')
          : Uri.parse('${ApiConfig.categoryBase}/user');

      _log('POST Create Category URL: $uri');
      _log('Body: name=$name, classId=$classId, description=$description');

      final body = <String, dynamic>{'name': name};

      if (description != null) body['description'] = description;
      if (classId != null) body['classId'] = classId;
      if (visibility != 'PRIVATE') body['visibility'] = visibility;

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      _log('Response Status: ${response.statusCode}');
      _log('Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return CategoryModel.fromJson(data);
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể tạo chủ đề mới');
      }
    } catch (e) {
      _log('❌ Error in createCategory: $e');
      rethrow;
    }
  }

  /// ✅ TEACHER: Lấy tất cả categories của teacher
  static Future<List<CategoryModel>> getTeacherCategories() async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConfig.categoryBase}/teacher');

      _log('GET Teacher Categories URL: $uri');

      final response = await http.get(uri, headers: headers);

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
        throw Exception('Không thể tải categories của teacher');
      }
    } catch (e) {
      _log('❌ Error in getTeacherCategories: $e');
      rethrow;
    }
  }

  /// ✅ UPDATE category
  static Future<CategoryModel> updateCategory({
    required int categoryId,
    required String name,
    String? description,
    String? visibility,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(ApiConfig.categoryUpdate(categoryId));

      _log('PUT Update Category URL: $uri');

      final body = <String, dynamic>{'name': name};
      if (description != null) body['description'] = description;
      if (visibility != null) body['visibility'] = visibility;

      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return CategoryModel.fromJson(data);
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể cập nhật chủ đề');
      }
    } catch (e) {
      _log('❌ Error in updateCategory: $e');
      rethrow;
    }
  }

  /// ✅ Xóa category
  static Future<void> deleteCategory(int categoryId) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(ApiConfig.categoryDelete(categoryId));

      _log('DELETE Category URL: $uri');

      final response = await http.delete(uri, headers: headers);

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể xóa chủ đề');
      }
    } catch (e) {
      _log('❌ Error in deleteCategory: $e');
      rethrow;
    }
  }

  // ==================== SEARCH & PUBLIC ====================

  /// ✅ Tìm kiếm categories công khai
  static Future<List<CategoryModel>> searchPublicCategories(String query) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConfig.categoryBase}/search?keyword=${Uri.encodeComponent(query)}');

      _log('🔍 Searching categories: $query');
      _log('GET URL: $uri');

      final response = await http.get(uri, headers: headers);

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        _log('✅ Found ${data.length} categories');
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
        throw Exception('Không thể tìm kiếm chủ đề');
      }
    } catch (e) {
      _log('❌ Error in searchPublicCategories: $e');
      rethrow;
    }
  }

  /// ✅ Alias method - Search categories theo keyword
  static Future<List<CategoryModel>> searchCategories(String keyword) async {
    return searchPublicCategories(keyword);
  }

  /// ✅ Get all public categories (không cần keyword)
  static Future<List<CategoryModel>> getPublicCategories() async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConfig.categoryBase}/public');

      _log('GET Public Categories URL: $uri');

      final response = await http.get(uri, headers: headers);

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        _log('✅ Found ${data.length} public categories');
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
        throw Exception('Không thể tải public categories');
      }
    } catch (e) {
      _log('❌ Error in getPublicCategories: $e');
      rethrow;
    }
  }
  /// Lấy category bằng shareToken (public - không cần auth nhưng vẫn gửi token nếu có)
  static Future<CategoryModel> getCategoryByShareToken(String shareToken) async {
    try {
      Map<String, String> headers;
      try {
        headers = await _getHeaders();
      } catch (e) {
        // Nếu không có token, vẫn có thể gọi API public
        headers = {
          'Content-Type': 'application/json; charset=utf-8',
          'ngrok-skip-browser-warning': 'true',
        };
      }

      final uri = Uri.parse('${ApiConfig.categoryBase}/share/$shareToken');

      _log('GET Category by token URL: $uri');

      final response = await http.get(uri, headers: headers);

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return CategoryModel.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Không tìm thấy bộ thẻ');
      } else if (response.statusCode == 403) {
        throw Exception('Bộ thẻ này không được chia sẻ công khai');
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Lỗi khi tải bộ thẻ');
      }
    } catch (e) {
      _log('❌ Error in getCategoryByShareToken: $e');
      rethrow;
    }
  }

  /// Lưu category từ shareToken vào danh sách của user
  static Future<CategoryModel> saveCategoryByShareToken(String shareToken) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConfig.categoryBase}/share/$shareToken/save');

      _log('POST Save category by token URL: $uri');

      final response = await http.post(uri, headers: headers);

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return CategoryModel.fromJson(data);
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể lưu bộ thẻ');
      }
    } catch (e) {
      _log('❌ Error in saveCategoryByShareToken: $e');
      rethrow;
    }
  }

  /// Preview category bằng shareToken (public)
  static Future<Map<String, dynamic>> previewCategoryByShareToken(String shareToken) async {
    try {
      final headers = {
        'Content-Type': 'application/json; charset=utf-8',
        'ngrok-skip-browser-warning': 'true',
      };

      final uri = Uri.parse('${ApiConfig.categoryBase}/share/$shareToken/preview');

      _log('GET Preview category by token URL: $uri');

      final response = await http.get(uri, headers: headers);

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else if (response.statusCode == 404) {
        throw Exception('Không tìm thấy bộ thẻ');
      } else if (response.statusCode == 403) {
        throw Exception('Bộ thẻ này không được chia sẻ công khai');
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Lỗi khi tải bộ thẻ');
      }
    } catch (e) {
      _log('❌ Error in previewCategoryByShareToken: $e');
      rethrow;
    }
  }
}