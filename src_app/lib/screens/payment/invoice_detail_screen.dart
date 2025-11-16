// File: lib/screens/payment/invoice_detail_screen.dart
import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';

class InvoiceDetailScreen extends StatelessWidget {
  const InvoiceDetailScreen({super.key});

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
          'Chi tiết hoá đơn',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(
        padding: AppConstants.screenPadding.copyWith(top: 8, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xem thông tin và thanh toán hoá đơn của bạn',
              style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
                border: Border.all(color: const Color(0xFFE6E8EC)),
              ),
              child: Column(
                children: [
                  _infoRow('Mã hoá đơn:', 'INV-2025-00021'),
                  const SizedBox(height: 10),
                  _infoRow('Gói dịch vụ:', 'Pro - 79.000đ/tháng', isEmphasis: true),
                  const SizedBox(height: 10),
                  _infoRow('Thời gian sử dụng:', '30/09 – 29/10/2025', isEmphasis: true),
                  const SizedBox(height: 10),
                  _infoRow('Tổng tiền:', '79.900đ', valueColor: AppColors.primary, isEmphasis: true),
                  const SizedBox(height: 10),
                  _infoRow('Trạng thái:', 'Chưa thanh toán', valueColor: AppColors.primary, isEmphasis: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor, bool isEmphasis = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: (isEmphasis ? AppTextStyles.label.copyWith(fontWeight: FontWeight.w700) : AppTextStyles.label).copyWith(
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}