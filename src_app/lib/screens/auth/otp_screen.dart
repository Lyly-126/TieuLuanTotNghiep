import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _submitted = false;
  bool _isLoading = false; // Thêm trạng thái loading

  // Biến để lưu userId một cách an toàn
  int? _userId;
  String? _userEmail;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // LẤY ARGUMENTS AN TOÀN
    final arguments = ModalRoute.of(context)!.settings.arguments;

    // --- START FIX: Chuyển đổi userId an toàn hơn ---
    if (arguments is Map<String, dynamic>) {
      final idValue = arguments['userId'];
      final emailValue = arguments['email'];

      // FIX: Luôn cố gắng phân tích giá trị thành số nguyên
      if (idValue != null) {
        _userId = int.tryParse(idValue.toString());
      }

      _userEmail = emailValue;
    }
    // --- END FIX ---

    // Nếu _userId vẫn là null, ta xử lý lỗi
    if (_userId == null) {
      debugPrint('Lỗi: Không tìm thấy userId hợp lệ');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi định tuyến: Không tìm thấy ID người dùng.')),
        );
      });
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  String? _validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập mã OTP';
    }
    if (value.trim().length != 6) {
      return 'Mã OTP phải có 6 chữ số';
    }
    return null;
  }

  void _submitOtp() async {
    // Kiểm tra userId một cách chắc chắn
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Lỗi: Không có ID người dùng'),
            backgroundColor: Colors.red
        ),
      );
      return;
    }

    // Validate form
    setState(() {
      _submitted = true;
      _isLoading = true;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() => _isLoading = false);
      return;
    }

    final otp = _otpController.text.trim();

    try {
      final response = await http.post(
        Uri.parse('https://backend-52ab.onrender.com/api/otp/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': _userId,
          'otpCode': otp
        }),
      );

      print('📡 OTP Verify Status: ${response.statusCode}');
      print('📦 OTP Verify Body: ${response.body}');

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        // Xác thực thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xác thực thành công!'),
            backgroundColor: Colors.green,
          ),
        );

        // Chuyển đến màn hình đăng nhập
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      } else {
        // Xử lý lỗi từ server
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        final errorMessage = errorBody['error'] ?? 'Mã OTP không hợp lệ';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi kết nối: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resendOtp() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi: Không có ID người dùng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://backend-52ab.onrender.com/api/otp/resend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': _userId}),
      );

      setState(() => _isLoading = false);

      print('📡 Resend OTP Status: ${response.statusCode}');
      print('📦 Resend OTP Body: ${response.body}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi lại mã OTP'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        final errorMessage = errorBody['error'] ?? 'Không thể gửi lại mã OTP';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi kết nối: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Thêm kiểm tra ở đây để tránh crash nếu pop xảy ra
    if (_userId == null) {
      return const SizedBox.shrink(); // Không hiển thị gì nếu không có userId
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
              autovalidateMode: _submitted
                  ? AutovalidateMode.always
                  : AutovalidateMode.disabled,
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
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Hãy kiểm tra hộp thư để nhập mã OTP',
                      style: AppTextStyles.hint.copyWith(fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),

                  CustomTextField(
                    label: 'Nhập mã OTP',
                    hintText: '••••••',
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    validator: _validateOtp,
                  ),
                  const SizedBox(height: 36),

                  CustomButton(
                    text: _isLoading ? 'Đang xác nhận...' : 'Xác nhận',
                    onPressed: _isLoading ? null : _submitOtp,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),

                  Center(
                    child: TextButton(
                      onPressed: _resendOtp,
                      child: Text(
                        'Gửi lại mã OTP',
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