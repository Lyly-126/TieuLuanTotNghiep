import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dobController = TextEditingController();

  final bool _submitted = false;
  bool _obscurePassword = true;
  bool _isLoading = false; // ⭐ Thêm loading state

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  // ---------- Validators ----------
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }
    final emailRegex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.trim().length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  String? _validateDob(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // ⭐ Ngày sinh là optional
    }
    final dateRegex = RegExp(r'^\d{2}/\d{2}/\d{4}$'); // dd/MM/yyyy
    if (!dateRegex.hasMatch(value.trim())) {
      return 'Định dạng phải là dd/mm/yyyy';
    }
    return null;
  }

  // ⭐ Hàm convert dd/MM/yyyy sang yyyy-MM-dd (format backend yêu cầu)
  String? _convertDateFormat(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;

    try {
      final parts = dateStr.trim().split('/');
      if (parts.length == 3) {
        final day = parts[0];
        final month = parts[1];
        final year = parts[2];
        return '$year-$month-$day'; // yyyy-MM-dd
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // ---------- Submit ----------
  Future<void> _submitForm() async {
    // Validate form
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final dobInput = _dobController.text.trim();
    final dobFormatted = _convertDateFormat(dobInput); // yyyy-MM-dd hoặc null

    // ✅ CHÍNH XÁC ENDPOINT
    final uri = Uri.parse('https://backend-52ab.onrender.com/api/users/register');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          if (dobFormatted != null) 'dob': dobFormatted,
        }),
      );

      print('📡 Register Response Status: ${response.statusCode}');
      print('📦 Register Response Body: ${response.body}');

      setState(() => _isLoading = false);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        // Chuyển sang màn OTP
        Navigator.pushNamed(
            context,
            '/otp',
            arguments: {
              'userId': data['id'],
              'email': data['email']
            }
        );
      } else {
        // Xử lý lỗi từ server
        final errorBody = jsonDecode(response.body);
        _showErrorDialog(errorBody['error'] ?? 'Đăng ký không thành công');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Lỗi kết nối: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Lỗi', style: AppTextStyles.heading3),
          content: Text(message, style: AppTextStyles.hint),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Đóng')
            )
          ],
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppConstants.screenPadding,
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              autovalidateMode:
              _submitted ? AutovalidateMode.always : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Đăng ký', style: AppTextStyles.title, textAlign: TextAlign.center),
                  const SizedBox(height: 48),

                  CustomTextField(
                    label: 'Email',
                    hintText: 'Nhập email của bạn',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 20),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Mật khẩu', style: AppTextStyles.label),
                  ),
                  const SizedBox(height: AppConstants.labelSpacing),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: AppTextStyles.label.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Nhập mật khẩu',
                      hintStyle: AppTextStyles.hint,
                      filled: true,
                      fillColor: AppColors.inputBackground,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textGray,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.inputPadding,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                        borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.2),
                      ),
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 20),

                  CustomTextField(
                    label: 'Ngày sinh (Không bắt buộc)',
                    hintText: 'Nhập ngày sinh (dd/mm/yyyy)',
                    controller: _dobController,
                    keyboardType: TextInputType.datetime,
                    validator: _validateDob,
                  ),

                  const SizedBox(height: 28),

                  Center(
                    child: Text(
                      'Bằng việc đăng ký, bạn chấp nhận Điều khoản Dịch vụ và Chính sách Quyền riêng tư',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.hint.copyWith(fontSize: 13, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 36),

                  CustomButton(
                    text: _isLoading ? 'Đang đăng ký...' : 'Tạo tài khoản',
                    onPressed: _isLoading ? () {} : _submitForm,
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Đã có tài khoản?', style: AppTextStyles.hint),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        child: Text('Đăng nhập', style: AppTextStyles.link),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}