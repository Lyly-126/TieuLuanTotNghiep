import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitted = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ----------- VALIDATION -----------
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    return null;
  }

  // ----------- LOGIN LOGIC -----------
  Future<void> _handleLogin() async {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      FocusScope.of(context).unfocus();
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final uri = Uri.parse('http://localhost:8080/api/users/login');
    late http.Response response;

    try {
      response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('📡 Login Response Status: ${response.statusCode}');
      print('📦 Login Response Body: ${response.body}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không kết nối được server: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    if (!mounted) return;

    // ✅ XỬ LÝ RESPONSE TỪ BACKEND
    if (response.statusCode == 200) {
      try {
        // Parse response JSON
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        // ✅ NULL-SAFE: Kiểm tra structure của response
        if (data == null) {
          throw Exception('Response data is null');
        }

        print('📦 Parsed data: $data');

        // ✅ NULL-SAFE: Kiểm tra token
        final String? token = data['token'] as String?;
        if (token == null || token.isEmpty) {
          throw Exception('Token không hợp lệ hoặc không tồn tại');
        }

        print('✅ Token: $token');

        // ✅ NULL-SAFE: Kiểm tra user object
        final Map<String, dynamic>? user = data['user'] as Map<String, dynamic>?;
        if (user == null) {
          throw Exception('Thông tin người dùng không hợp lệ');
        }

        print('✅ User data: $user');

        final prefs = await SharedPreferences.getInstance();

        // Lưu token
        await prefs.setString('auth_token', token);

        // ✅ NULL-SAFE: Lưu thông tin user với kiểm tra null từng trường
        final int? userIdRaw = user['id'] as int?;
        final int userId = userIdRaw ?? 0;

        final String? userEmail = user['email'] as String?;
        final String? userRole = user['role'] as String?;
        final String? userStatus = user['status'] as String?;
        final String? userFullName = user['fullName'] as String?;

        print('✅ userId: $userId');
        print('✅ userEmail: $userEmail');
        print('✅ userRole: $userRole');
        print('✅ userStatus: $userStatus');
        print('✅ userFullName: $userFullName');

        // ✅ VALIDATE dữ liệu bắt buộc
        if (userId == 0) {
          throw Exception('User ID không hợp lệ');
        }
        if (userEmail == null || userEmail.isEmpty) {
          throw Exception('Email không hợp lệ');
        }

        await prefs.setInt('user_id', userId);
        await prefs.setString('user_email', userEmail);
        await prefs.setString('user_role', userRole ?? 'NORMAL_USER');
        await prefs.setString('user_status', userStatus ?? 'VERIFIED');

        // Lưu fullName, nếu không có thì dùng email
        await prefs.setString('user_fullname',
            userFullName ?? userEmail.split('@')[0]
        );

        if (!mounted) return;

        // ✅ PHÂN LUỒNG USER/ADMIN DỰA TRÊN ROLE
        final String finalUserRole = userRole ?? 'NORMAL_USER';

        if (finalUserRole == 'ADMIN') {
          // ✅ ADMIN → Chuyển đến Admin Dashboard
          Navigator.pushReplacementNamed(context, '/admin_home');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chào mừng Admin! 👋'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // ✅ USER → Chuyển đến Home Screen
          Navigator.pushReplacementNamed(context, '/home');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng nhập thành công! 🎉'),
              backgroundColor: Colors.green,
            ),
          );
        }

      } catch (e, stackTrace) {
        // Xử lý lỗi với stack trace để debug
        print('❌ Login Error: $e');
        print('❌ Stack trace: $stackTrace');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xử lý dữ liệu: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } else {
      // ✅ XỬ LÝ LỖI ĐĂNG NHẬP
      String msg = 'Email hoặc mật khẩu không đúng';

      try {
        // Backend trả về plain text khi lỗi
        final responseBody = utf8.decode(response.bodyBytes);
        if (responseBody.isNotEmpty) {
          msg = responseBody;
        }
      } catch (e) {
        // Dùng thông báo mặc định
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppConstants.screenPadding,
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              autovalidateMode: _submitted
                  ? AutovalidateMode.always
                  : AutovalidateMode.disabled,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text('Đăng nhập', style: AppTextStyles.title),
                  ),
                  const SizedBox(height: 48),

                  // EMAIL
                  CustomTextField(
                    label: 'Email',
                    hintText: 'Nhập email',
                    controller: _emailController,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 24),

                  // PASSWORD
                  Text('Mật khẩu', style: AppTextStyles.label),
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
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 40),

                  // LOGIN BUTTON
                  CustomButton(
                    text: _isLoading ? 'Đang đăng nhập...' : 'Đăng nhập',
                    onPressed: _isLoading ? () {} : _handleLogin,
                  ),
                  const SizedBox(height: 20),

                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/forgot');
                      },
                      child: Text(
                        'Quên mật khẩu',
                        style: AppTextStyles.link.copyWith(fontSize: 14),
                      ),
                    ),
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