import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../services/class_service.dart';
import '../../widgets/custom_button.dart';

class JoinClassScreen extends StatefulWidget {
  final String? prefilledCode;

  const JoinClassScreen({Key? key, this.prefilledCode}) : super(key: key);

  @override
  State<JoinClassScreen> createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends State<JoinClassScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledCode != null) {
      _codeController.text = widget.prefilledCode!;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinClass() async {
    if (_codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng nhập mã lớp'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ClassService.joinByInviteCode(_codeController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã tham gia lớp thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.primary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Tham gia lớp',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppConstants.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            // Icon circle
            Center(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 70,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Title
            Text(
              'Nhập mã lớp',
              textAlign: TextAlign.center,
              style: AppTextStyles.heading2.copyWith(
                fontSize: 26,
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Nhập mã lớp mà giáo viên đã cung cấp\nđể tham gia lớp học',
              textAlign: TextAlign.center,
              style: AppTextStyles.hint.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 40),

            // Input field
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                  color: AppColors.primary,
                ),
                decoration: InputDecoration(
                  hintText: 'ABC123',
                  hintStyle: AppTextStyles.hint.copyWith(
                    fontSize: 20,
                    letterSpacing: 2,
                  ),
                  prefixIcon: Icon(
                    Icons.vpn_key_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
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
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) {
                  final upperValue = value.toUpperCase();
                  if (upperValue != value) {
                    _codeController.value = _codeController.value.copyWith(
                      text: upperValue,
                      selection: TextSelection.collapsed(
                        offset: upperValue.length,
                      ),
                    );
                  }
                },
                onSubmitted: (_) => _joinClass(),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Join button
            CustomButton(
              text: 'Tham gia lớp',
              onPressed: _isLoading ? null : _joinClass,
              isLoading: _isLoading,
              height: 54,
              icon: Icons.login_rounded,
            ),

            const SizedBox(height: 32),

            // Info cards
            _buildInfoCard(
              icon: Icons.info_outline_rounded,
              title: 'Mã lớp có dạng gì?',
              description:
              'Mã lớp thường có 6-8 ký tự, bao gồm chữ cái và số (VD: ABC123)',
              color: AppColors.info,
            ),

            const SizedBox(height: 12),

            _buildInfoCard(
              icon: Icons.help_outline_rounded,
              title: 'Lấy mã lớp ở đâu?',
              description:
              'Hỏi giáo viên của bạn để nhận mã lớp hoặc kiểm tra email/tin nhắn mời',
              color: AppColors.warning,
            ),

            const SizedBox(height: 12),

            _buildInfoCard(
              icon: Icons.school_outlined,
              title: 'Sau khi tham gia',
              description:
              'Bạn sẽ có thể truy cập tất cả học phần và tài liệu của lớp',
              color: AppColors.success,
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.hint.copyWith(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}