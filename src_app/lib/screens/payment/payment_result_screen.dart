// lib/screens/payment/payment_result_screen.dart
import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';

class PaymentResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  const PaymentResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final isSuccess = result['success'] == true;
    final order = result['order'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.primary),
            onPressed: () {
              // Về màn hình chính
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: isSuccess
                      ? AppColors.primary.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  size: 80,
                  color: isSuccess ? AppColors.primary : Colors.red,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                isSuccess ? 'Thanh toán thành công!' : 'Thanh toán thất bại',
                style: AppTextStyles.heading2.copyWith(
                  color: isSuccess ? AppColors.primary : Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 16),

              // Message
              Text(
                result['message'] ?? '',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Order info
              if (order != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE6E8EC)),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('Mã đơn hàng', '#${order['id']}'),
                      const SizedBox(height: 12),
                      _buildInfoRow('Gói dịch vụ', order['packName'] ?? 'N/A'),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Số tiền',
                        '${order['priceAtPurchase']} VNĐ',
                        valueColor: AppColors.primary,
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Về trang chủ',
                    style: AppTextStyles.button.copyWith(
                      color: Colors.white,
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

  Widget _buildInfoRow(
      String label,
      String value, {
        Color? valueColor,
        bool isBold = false,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.label.copyWith(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}