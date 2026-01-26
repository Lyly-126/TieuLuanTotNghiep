import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import '../setting/change_password_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  int? _userId;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    // Log toàn bộ keys để debug
    print('All SharedPreferences keys: ${prefs.getKeys()}');

    setState(() {
      _userId = prefs.getInt('user_id');
      _token = prefs.getString('auth_token');

      // Ưu tiên fullName, nếu không có thì lấy phần trước @ của email
      String? fullName = prefs.getString('user_fullname');
      String? email = prefs.getString('user_email');

      _fullNameController.text = fullName ??
          (email != null ? email.split('@')[0] : 'Người dùng');
      _emailController.text = email ?? '';

      // Log để debug
      print('Loaded User ID: $_userId');
      print('Loaded Token: $_token');
      print('Loaded Full Name: ${_fullNameController.text}');
      print('Loaded Email: ${_emailController.text}');
    });

    // Kiểm tra token
    if (_token == null) {
      _showErrorSnackBar('Phiên đăng nhập đã hết. Vui lòng đăng nhập lại.');
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Future<void> _saveChanges() async {
    // Lấy token và userId từ SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userId = prefs.getInt('user_id');

    // ✅ VALIDATION: Kiểm tra trước khi gọi API
    if (token == null || userId == null) {
      _showErrorSnackBar('Vui lòng đăng nhập lại');
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      return;
    }

    // ✅ Kiểm tra tên không được rỗng
    if (_fullNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Tên người dùng không được để trống');
      return;
    }

    setState(() => _isLoading = true);

    // ✅ ĐỔI URL: localhost → 10.0.2.2 (cho Android Emulator)
    // Nếu dùng iOS Simulator: dùng localhost
    // Nếu dùng thiết bị thật: dùng IP máy tính (vd: 192.168.1.5)
    final uri = Uri.parse('https://backend-52ab.onrender.com/api/users/$userId/profile');

    print('🔄 Calling API: $uri');
    print('📤 Token: $token');
    print('📤 User ID: $userId');
    print('📤 Full Name: ${_fullNameController.text.trim()}');

    try {
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fullName': _fullNameController.text.trim(),
        }),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${utf8.decode(response.bodyBytes)}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        // ✅ Parse response và cập nhật SharedPreferences
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        // Lưu fullName mới vào SharedPreferences
        await prefs.setString('user_fullname', _fullNameController.text.trim());

        _showSuccessSnackBar('Cập nhật thông tin thành công!');
      } else if (response.statusCode == 401) {
        _showErrorSnackBar('Phiên đăng nhập đã hết. Vui lòng đăng nhập lại.');
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      } else if (response.statusCode == 403) {
        _showErrorSnackBar('Bạn không có quyền thực hiện thao tác này');
      } else {
        try {
          final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
          _showErrorSnackBar(errorBody['message'] ?? 'Cập nhật thất bại');
        } catch (e) {
          _showErrorSnackBar('Cập nhật thất bại (${response.statusCode})');
        }
      }
    } catch (e) {
      print('❌ Error: $e');
      if (!mounted) return;
      _showErrorSnackBar('Lỗi kết nối: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _deleteAccount() async {
    // Lấy token một lần nữa từ SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    print('Delete Account - Token from Prefs: $token');

    if (token == null) {
      _showErrorSnackBar('Vui lòng đăng nhập lại');
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      return;
    }

    final confirmDelete = await _showConfirmDialog(
      title: 'Xóa tài khoản',
      content: 'Bạn có chắc chắn muốn xóa tài khoản? Thao tác này không thể hoàn tác.',
    );

    if (!confirmDelete) return;

    final uri = Uri.parse('https://backend-52ab.onrender.com/api/users/delete');

    try {
      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await prefs.clear();

        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          _showSuccessSnackBar('Xóa tài khoản thành công');
        }
      } else {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        _showErrorSnackBar(errorBody['message'] ?? 'Xóa tài khoản thất bại');
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi kết nối: $e');
    }
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      _showSuccessSnackBar('Đăng xuất thành công!');
    }
  }

  // Các hàm tiện ích
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String content,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Cài đặt',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0).copyWith(bottom: 30),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Container chứa thông tin người dùng
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Tên người dùng'),
                    _buildEditableInputField(
                      _fullNameController,
                      hintText: 'Nhập tên người dùng',
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Email'),
                    _buildEditableInputField(
                      _emailController,
                      hintText: 'Nhập email',
                      isEmail: true,
                      isReadOnly: true, // Không cho chỉnh sửa email
                    ),
                    const SizedBox(height: 24),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChangePasswordScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tạo mật khẩu mới',
                              style: AppTextStyles.label.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: AppColors.textGray,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: _isLoading ? 'Đang lưu...' : 'Lưu thay đổi',
                height: 54,
                onPressed: _isLoading ? null : _saveChanges,
              ),
              const SizedBox(height: 40),
            _buildMenuItem(
              'Nâng cấp gói học tập',
              onTap: () => Navigator.pushNamed(context, '/upgrade_premium'),
            ),
              const SizedBox(height: 14),
              _buildMenuItem(
                'Điều khoản - Chính sách',
                onTap: () {
                  Navigator.pushNamed(context, '/terms_privacy');
                },
              ),
              const SizedBox(height: 14),
              _buildMenuItem('Hóa đơn và thanh toán',
                  onTap: () {
                  Navigator.pushNamed(context, '/invoices');
          },
          ),
              const SizedBox(height: 48),
              _buildLogoutButton(),
              const SizedBox(height: 16),
              _buildDeleteAccountButton(),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: AppTextStyles.label.copyWith(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildEditableInputField(
      TextEditingController controller, {
        required String hintText,
        bool isEmail = false,
        bool isReadOnly = false,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: isReadOnly ? AppColors.inputBackground : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: isReadOnly
              ? Colors.transparent
              : AppColors.primary.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        readOnly: isReadOnly,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        style: AppTextStyles.label.copyWith(
          color: isReadOnly ? AppColors.textGray : AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.hint.copyWith(
            color: isReadOnly ? AppColors.textGray.withOpacity(0.7) : AppColors.textGray,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: isReadOnly
                  ? Colors.transparent
                  : AppColors.primary.withOpacity(0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          focusedBorder: isReadOnly
              ? InputBorder.none
              : OutlineInputBorder(
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1.4,
            ),
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildMenuItem(String text, {VoidCallback? onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      onTap: onTap ?? () {},
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                text,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textGray,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
            color: AppColors.primaryDark,
            width: 1.2,
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
          ),
        ),
        onPressed: _handleLogout,
        child: Text(
          'Đăng xuất',
          style: AppTextStyles.label.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.red.withOpacity(0.08),
          side: const BorderSide(color: Colors.red, width: 1.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
          ),
        ),
        onPressed: _deleteAccount,
        child: Text(
          'Xóa tài khoản',
          style: AppTextStyles.label.copyWith(
            color: Colors.red,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}