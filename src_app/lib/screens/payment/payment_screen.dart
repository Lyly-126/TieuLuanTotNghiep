import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import 'pay_later_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _paymentMethodIndex = -1; // 0: Pay now, 1: Pay later

  // --- BottomSheet chọn phương thức "Thanh toán trước" (theo mẫu UI) ---
  void _showPayNowSheet({required String packageName, required String pricePerMonth}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        int selected = 0; // mặc định chọn Ví MoMo
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 12, top: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7E9EE),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Text(
                    'Chọn phương thức',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gói: $packageName — $pricePerMonth',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _MethodTile(
                    label: 'Ví MoMo',
                    selected: selected == 0,
                    onTap: () => setModalState(() => selected = 0),
                  ),
                  const SizedBox(height: 10),
                  _MethodTile(
                    label: 'ZaloPay',
                    selected: selected == 1,
                    onTap: () => setModalState(() => selected = 1),
                  ),
                  const SizedBox(height: 10),
                  _MethodTile(
                    label: 'Thẻ ATM/Napas · Visa/Mastercard',
                    selected: selected == 2,
                    onTap: () => setModalState(() => selected = 2),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        final label = selected == 0
                            ? 'Ví MoMo'
                            : selected == 1
                            ? 'ZaloPay'
                            : 'Thẻ ATM/Napas · Visa/Mastercard';
                        _showPaymentDetails(label);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(42),
                        ),
                      ),
                      child: Text(
                        'Tiếp tục',
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
            );
          },
        );
      },
    );
  }

  // Sheet chi tiết/confirm sau khi chọn phương thức cụ thể
  void _showPaymentDetails(String method) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 250,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chi tiết phương thức thanh toán: $method',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Thông tin thanh toán sẽ được thực hiện qua $method. Vui lòng kiểm tra lại thông tin trước khi thanh toán.',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                ),
                child: Text(
                  'Thanh toán qua $method',
                  style: AppTextStyles.button.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.primary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Thanh toán gói Premium',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(
        padding: AppConstants.screenPadding.copyWith(top: 16, bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- TÓM TẮT GÓI DỊCH VỤ ----------------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryRow('Gói', 'Pro'),
                  const SizedBox(height: 16),
                  _buildSummaryRow('Tổng thanh toán', '79.900đ', isPrice: true),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ---------------- 2 NÚT CHỌN PHƯƠNG THỨC ----------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPaymentOptionButton('Thanh toán trước', _paymentMethodIndex == 0, onTap: () {
                  setState(() => _paymentMethodIndex = 0);
                  _showPayNowSheet(packageName: 'Pro', pricePerMonth: '79.000đ / tháng');
                }),
                _buildPaymentOptionButton('Thanh toán sau', _paymentMethodIndex == 1, onTap: () {
                  setState(() => _paymentMethodIndex = 1);
                  // 👉 Điều hướng sang màn hình khác dành cho thanh toán sau
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PayLaterScreen()),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- COMPONENT: SUMMARY ROW ----------------
  Widget _buildSummaryRow(String label, String value, {bool isPrice = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: isPrice
              ? AppTextStyles.heading3.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          )
              : AppTextStyles.label.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // ---------------- COMPONENT: PAYMENT OPTION BUTTON ----------------
  Widget _buildPaymentOptionButton(String text, bool isSelected, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(
            color: AppColors.primary,
            width: 1.2,
          ),
        ),
        child: Text(
          text,
          style: AppTextStyles.label.copyWith(
            color: isSelected ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

// ---------------- ITEM TILE (theo UI mẫu) ----------------
class _MethodTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _MethodTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(
            color: const Color(0xFFE6E8EC),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : const Color(0xFFD1D5DB),
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}