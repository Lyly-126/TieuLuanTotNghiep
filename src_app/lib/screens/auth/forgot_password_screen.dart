import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Cần import http
import 'dart:convert'; // Cần import json
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

// URL API của Spring Boot Backend
const String _baseUrl = 'http://localhost:8080/api/auth';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitted = false;
  bool _isLoading = false; // Trạng thái loading
  String? _errorMessage; // Thông báo lỗi

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // ----------- VALIDATE EMAIL -----------
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

  // ----------- XỬ LÝ GỬI OTP (TÍCH HỢP API) -----------
  Future<void> _callSendOtpApi() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final url = Uri.parse('http://localhost:8080/api/auth/forgot-password/send-otp');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'email': _emailController.text.trim(),
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      print('📡 Forgot Password Response Status: ${response.statusCode}');
      print('📦 Forgot Password Response Body: ${response.body}');

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        // Gửi thành công, chuyển sang màn OTP
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mã OTP đã được gửi. Kiểm tra email của bạn!'),
            ),
          );
          Navigator.pushNamed(
            context,
            '/forgot_otp',
            arguments: {'email': _emailController.text.trim()},
          );
        }
      } else {
        // Xử lý lỗi từ Backend
        final errorBody = jsonDecode(response.body);
        setState(() {
          _errorMessage = errorBody['error'] ?? 'Đã xảy ra lỗi.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi kết nối: $e';
      });
    }
  }

  void _submitEmail() {
    setState(() => _submitted = true);
    if (_formKey.currentState!.validate()) {
      _callSendOtpApi();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppConstants.screenPadding,
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            autovalidateMode: _submitted
                ? AutovalidateMode.always
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                // ---------------- Nút quay lại ----------------
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 24),

                // ---------------- Tiêu đề ----------------
                Center(
                  child: Text(
                    'Cài lại mật khẩu',
                    style: AppTextStyles.title.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ---------------- Mô tả ----------------
                Center(
                  child: Text(
                    'Chúng tôi sẽ email cho bạn mã OTP để đặt lại mật khẩu.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.hint.copyWith(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 36),

                // ---------------- Nhập email ----------------
                CustomTextField(
                  label: 'Nhập email của bạn',
                  hintText: 'example@email.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),

                // ---------------- Hiển thị Lỗi ----------------
                if (_errorMessage != null)
                  Center(
                    child: Text(
                      _errorMessage!,
                      style: AppTextStyles.error,
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 20),

                // ---------------- Nút nhận mã OTP ----------------
                CustomButton(
                  text: 'Nhận mã OTP',
                  onPressed: _isLoading ? null : _submitEmail, // Vô hiệu hóa khi đang loading
                  isLoading: _isLoading, // Hiển thị spinner khi loading
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
