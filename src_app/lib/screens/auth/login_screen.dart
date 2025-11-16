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

    // ✅ ENDPOINT ĐÚNG
    // Localhost: http://localhost:8080/api/users/login
    // Android Emulator: http://10.0.2.2:8080/api/users/login
    // Thiết bị thật: http://YOUR_IP:8080/api/users/login
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
        final String token = data['token'];
        final Map<String, dynamic> user = data['user'];

        final prefs = await SharedPreferences.getInstance();

        // Lưu token
        await prefs.setString('auth_token', token);

        // Lưu thông tin user
        await prefs.setInt('user_id', user['id']);
        await prefs.setString('user_email', user['email']);
        await prefs.setString('user_role', user['role']);
        await prefs.setString('user_status', user['status']);

        // Lưu fullName, nếu không có thì dùng email
        await prefs.setString('user_fullname',
            user['fullName'] ?? user['email'].split('@')[0]
        );

        // ✅ PHÂN LUỒNG USER/ADMIN DỰA TRÊN ROLE
        final String userRole = user['role'];

        if (!mounted) return;

        if (userRole == 'ADMIN') {
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

      } catch (e) {
        // Xử lý lỗi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xử lý dữ liệu: $e'),
            backgroundColor: Colors.red,
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