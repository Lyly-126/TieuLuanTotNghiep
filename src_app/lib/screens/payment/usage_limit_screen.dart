import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_constants.dart';
import '../../../config/app_text_styles.dart';

class UsageLimitScreen extends StatelessWidget {
  const UsageLimitScreen({super.key});

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
          'Hạn mức sử dụng',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(
        padding: AppConstants.screenPadding.copyWith(top: 8, bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 6),
            Text(
              'Quản lý gói và theo dõi hạn mức sử dụng của bạn',
              textAlign: TextAlign.center,
              style: AppTextStyles.hint.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 28),

            // ---------------- THÔNG TIN GÓI DỊCH VỤ ----------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(AppConstants.borderRadius * 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gói dịch vụ: Pro',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildRow(
                    'Thời gian sử dụng:',
                    '01/01/2025 – 31/12/2025',
                  ),
                  const SizedBox(height: 10),
                  _buildRow(
                    'Thời gian còn lại:',
                    '8 tháng 12 ngày',
                    color: AppColors.primary,
                    isBold: true,
                  ),
                  const SizedBox(height: 10),
                  _buildRow(
                    'Số flashcard đã tạo:',
                    '456 thẻ',
                    color: AppColors.primary,
                    isBold: true,
                  ),
                  const SizedBox(height: 10),
                  _buildRow(
                    'Giới hạn OCR:',
                    '1000 thẻ',
                    color: AppColors.primary,
                    isBold: true,
                  ),
                  const SizedBox(height: 10),
                  _buildRow(
                    'Số thẻ còn lại:',
                    '544 thẻ',
                    color: AppColors.primary,
                    isBold: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- COMPONENT: ROW ----------------
  Widget _buildRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Text(
            value,
            style: AppTextStyles.label.copyWith(
              color: color ?? AppColors.textPrimary,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
