import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

// API Base URL
const String _baseUrl = 'http://localhost:8080/api/auth';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _submitted = false;
  bool _isLoading = false;
  String? _errorMessage;

  String? _email;
  String? _otp;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_email == null || _otp == null) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _email = args?['email'];
      _otp = args?['otp'];

      if (_email == null || _otp == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thiếu thông tin. Vui lòng thử lại.')),
          );
          Navigator.popUntil(context, ModalRoute.withName('/login'));
        });
      }
    }
  }

  // Validate
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu mới';
    if (value.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự';
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(value)) {
      return 'Mật khẩu phải gồm chữ và số';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng xác nhận mật khẩu';
    if (value != _passwordController.text) return 'Mật khẩu không khớp';
    return null;
  }

  // API
  Future<void> _callResetPasswordApi() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await http.post(
      Uri.parse('$_baseUrl/forgot-password/reset'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': _email,
        'otp': _otp,
        'newPassword': _passwordController.text.trim(),
      }),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đặt lại mật khẩu thành công!')),
      );
      Navigator.popUntil(context, ModalRoute.withName('/login'));
    } else {
      try {
        final data = jsonDecode(response.body);
        setState(() => _errorMessage = data['message'] ?? 'Đã xảy ra lỗi.');
      } catch (_) {
        setState(() => _errorMessage = 'Lỗi không xác định.');
      }
    }

    setState(() => _isLoading = false);
  }

  void _submit() {
    setState(() => _submitted = true);
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      _callResetPasswordApi();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_email == null || _otp == null) {
      return const Scaffold(body: Center(child: Text('Đang tải...')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: AppConstants.screenPadding,
                child: Form(
                  key: _formKey,
                  autovalidateMode:
                  _submitted ? AutovalidateMode.always : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Text('Đặt mật khẩu mới', style: AppTextStyles.title)),
                      const SizedBox(height: 40),

                      CustomTextField(
                        label: 'Mật khẩu mới',
                        hintText: 'Nhập mật khẩu mới',
                        controller: _passwordController,
                        validator: _validatePassword,
                        isPassword: true,
                      ),
                      const SizedBox(height: 24),

                      CustomTextField(
                        label: 'Xác nhận mật khẩu',
                        hintText: 'Nhập lại mật khẩu',
                        controller: _confirmPasswordController,
                        validator: _validateConfirm,
                        isPassword: true,
                      ),

                      const SizedBox(height: 12),
                      Text(
                        '*Mật khẩu tối thiểu 8 ký tự và có cả chữ + số.',
                        style: AppTextStyles.hint.copyWith(fontSize: 13),
                      ),

                      const SizedBox(height: 16),

                      if (_errorMessage != null)
                        Center(
                          child: Text(
                            _errorMessage!,
                            style: AppTextStyles.error,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 20),

                      CustomButton(
                        text: 'Lưu mật khẩu mới',
                        onPressed: _isLoading ? null : _submit,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              top: 12,
              left: 4,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.primary, size: 22),
              ),
            )
          ],
        ),
      ),
    );
  }
}
