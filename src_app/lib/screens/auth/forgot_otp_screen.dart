import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

// URL API Backend

class ForgotOtpScreen extends StatefulWidget {
  const ForgotOtpScreen({super.key});

  @override
  State<ForgotOtpScreen> createState() => _ForgotOtpScreenState();
}

class _ForgotOtpScreenState extends State<ForgotOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  bool _submitted = false;
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  String? _email;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_email == null) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _email = args?['email'];

      if (_email == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.popUntil(context, ModalRoute.withName('/login'));
        });
      }
    }
  }

  // Validate OTP
  String? _validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập mã OTP';
    }
    if (value.trim().length != 6 || !RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'Mã OTP phải có 6 chữ số';
    }
    return null;
  }

  // Xác nhận OTP
  Future<void> _callCheckOtpApi() async {
    if (_email == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await http.post(
      Uri.parse('${ApiConfig.authForgotPassword}/check-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': _email,
        'otp': _otpController.text.trim(),
      }),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xác thực thành công!')),
      );
      Navigator.pushNamed(
        context,
        '/reset_password',
        arguments: {'email': _email, 'otp': _otpController.text.trim()},
      );
    } else {
      try {
        final data = jsonDecode(response.body);
        setState(() => _errorMessage = data['message'] ?? 'Đã xảy ra lỗi.');
      } catch (_) {
        setState(() => _errorMessage = 'Đã xảy ra lỗi không xác định.');
      }
    }

    setState(() => _isLoading = false);
  }

  // Gửi lại OTP
  Future<void> _resendOtp() async {
    if (_email == null) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    final response = await http.post(
      Uri.parse('${ApiConfig.authForgotPassword}/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': _email}),
    );

    if (mounted) {
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi lại mã OTP.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể gửi lại OTP.')),
        );
      }
    }

    setState(() => _isResending = false);
  }

  void _submitOtp() {
    setState(() => _submitted = true);
    if (_formKey.currentState!.validate()) {
      _callCheckOtpApi();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_email == null) {
      return const Scaffold(body: Center(child: Text('Đang tải...')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: AppConstants.screenPadding,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              autovalidateMode:
              _submitted ? AutovalidateMode.always : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),

                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(height: 24),

                  Center(
                    child: Text(
                      'Xác nhận mã OTP',
                      style: AppTextStyles.title.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Center(
                    child: Column(
                      children: [
                        Text('Hãy kiểm tra email của bạn', style: AppTextStyles.hint),
                        Text(
                          _email!,
                          style: AppTextStyles.hint.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  CustomTextField(
                    label: 'Nhập mã OTP',
                    hintText: '••••••',
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    validator: _validateOtp,
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
                    text: 'Xác nhận OTP',
                    onPressed: _isLoading ? null : _submitOtp,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),

                  Center(
                    child: TextButton(
                      onPressed:
                      _isResending || _isLoading ? null : _resendOtp,
                      child: Text(
                        _isResending ? 'Đang gửi lại...' : 'Gửi lại mã OTP',
                        style: AppTextStyles.link.copyWith(
                          color: (_isResending || _isLoading)
                              ? AppTextStyles.hint.color
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
