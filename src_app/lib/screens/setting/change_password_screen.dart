import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../widgets/custom_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _submitted = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ---------------- VALIDATION ----------------
  String? _validateCurrentPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập mật khẩu hiện tại';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập mật khẩu mới';
    }
    if (value.trim().length < 8) {
      return 'Mật khẩu phải có ít nhất 8 ký tự';
    }
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$')
        .hasMatch(value.trim())) {
      return 'Mật khẩu phải gồm chữ và số';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng xác nhận mật khẩu mới';
    }
    if (value != _newPasswordController.text) {
      return 'Mật khẩu không khớp';
    }
    return null;
  }

  void _handleSave() async {
    // Đặt trạng thái loading
    setState(() {
      _submitted = true;
      _isLoading = true;
    });

    // Kiểm tra form
    if (!_formKey.currentState!.validate()) {
      setState(() => _isLoading = false);
      return;
    }

    // Lấy token từ SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    // Kiểm tra token
    if (token == null) {
      _showErrorSnackBar('Vui lòng đăng nhập lại');
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      return;
    }

    try {
      final uri = Uri.parse('http://localhost:8080/api/users/change-password');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': _currentPasswordController.text.trim(),
          'newPassword': _newPasswordController.text.trim(),
        }),
      );

      // In log để debug
      print('📡 Change Password Status: ${response.statusCode}');
      print('📦 Change Password Body: ${response.body}');

      // Xử lý response
      if (response.statusCode == 200) {
        _showSuccessSnackBar('Đổi mật khẩu thành công');

        // Chỉ quay lại màn hình trước đó
        Navigator.pop(context);
      } else {
        // Xử lý lỗi từ server
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        _showErrorSnackBar(errorBody['message'] ?? 'Đổi mật khẩu thất bại');
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi kết nối: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Hàm hiển thị Snackbar lỗi
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Hàm hiển thị Snackbar thành công
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
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
          'Tạo mật khẩu mới',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: AppConstants.screenPadding.copyWith(top: 10, bottom: 40),
          child: Form(
            key: _formKey,
            autovalidateMode:
            _submitted ? AutovalidateMode.always : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Đặt lại mật khẩu để bảo mật tài khoản',
                  style: AppTextStyles.hint.copyWith(
                    fontSize: 13,
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 28),

                // ---------------- FORM CONTAINER ----------------
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(
                        AppConstants.borderRadius * 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPasswordField(
                        label: 'Mật khẩu hiện tại',
                        controller: _currentPasswordController,
                        obscure: _obscureCurrent,
                        validator: _validateCurrentPassword,
                        onToggle: () =>
                            setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                      const SizedBox(height: 20),
                      _buildPasswordField(
                        label: 'Mật khẩu mới',
                        controller: _newPasswordController,
                        obscure: _obscureNew,
                        validator: _validateNewPassword,
                        onToggle: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                      const SizedBox(height: 20),
                      _buildPasswordField(
                        label: 'Nhập lại mật khẩu mới',
                        controller: _confirmPasswordController,
                        obscure: _obscureConfirm,
                        validator: _validateConfirmPassword,
                        onToggle: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '*Mật khẩu nên dài tối thiểu 8 ký tự, gồm chữ và số.',
                        style: AppTextStyles.hint.copyWith(
                          fontSize: 13,
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // ---------------- NÚT LƯU ----------------
                CustomButton(
                  text: _isLoading ? 'Đang lưu...' : 'Lưu mật khẩu mới',
                  onPressed: _isLoading ? null : _handleSave,
                  height: 52,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Ô NHẬP MẬT KHẨU ----------------
  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    bool obscure = true,
    String? Function(String?)? validator,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: AppConstants.labelSpacing),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          style: AppTextStyles.label.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          validator: validator,
          decoration: InputDecoration(
            hintText: 'Nhập $label'.toLowerCase(),
            hintStyle: AppTextStyles.hint,
            filled: true,
            fillColor: Colors.white,
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textGray,
              ),
              onPressed: onToggle,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppConstants.inputPadding,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(AppConstants.borderRadius),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(AppConstants.borderRadius),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}