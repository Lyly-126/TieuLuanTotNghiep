// File: lib/screens/payment/pay_later_screen.dart
import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';

class PayLaterScreen extends StatefulWidget {
  const PayLaterScreen({super.key, this.packageName = 'Pro'});
  final String packageName;

  @override
  State<PayLaterScreen> createState() => _PayLaterScreenState();
}

class _PayLaterScreenState extends State<PayLaterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _taxCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _taxCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputStyle(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFFE6E8EC)),
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: AppColors.primary),
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
    ),
  );

  void _submit() {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    String? error;
    if (name.isEmpty) error = 'Vui lòng nhập tên/đơn vị';
    else if (!email.contains('@')) error = 'Email nhận hoá đơn chưa hợp lệ';

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Đã gửi yêu cầu', style: AppTextStyles.heading3),
        content: Text(
          'Yêu cầu thanh toán sau cho gói ${widget.packageName} đã được ghi nhận. Vui lòng kiểm tra email để nhận hoá đơn khi được xử lý.',
          style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng', style: AppTextStyles.button.copyWith(color: AppColors.primary)),
          ),
        ],
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Thanh toán sau',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(
        padding: AppConstants.screenPadding.copyWith(top: 16, bottom: 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ======= Tiêu đề & mô tả như ảnh mẫu =======
              Text(
                'Thanh toán sau cho gói ${widget.packageName}',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Nhập thông tin xuất hoá đơn để gửi yêu cầu',
                style: AppTextStyles.label.copyWith(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // ======= Card: Thông tin hoá đơn =======
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
                  border: Border.all(color: const Color(0xFFE6E8EC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin hoá đơn',
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameCtrl,
                      decoration: _inputStyle('Tên/đơn vị'),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputStyle('Email nhận hoá đơn'),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _taxCtrl,
                      decoration: _inputStyle('Mã số thuế (nếu có)'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(42), // nút pill như mẫu
                    ),
                  ),
                  child: Text(
                    'Gửi yêu cầu thanh toán sau',
                    style: AppTextStyles.button.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
