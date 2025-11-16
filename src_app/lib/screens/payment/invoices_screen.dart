// File: lib/screens/payment/invoices_screen.dart
import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final List<_Invoice> _items = const [
    _Invoice(
      id: 'INV-2025-00021',
      plan: 'Pro',
      period: '30/09–29/10',
      amount: '86.900đ',
      status: InvoiceStatus.open,
      dueOrPaidDateLabel: 'Đến hạn: 05/11/2025',
    ),
    _Invoice(
      id: 'INV-2025-00020',
      plan: 'Pro',
      period: '31/08–29/09',
      amount: '86.900đ',
      status: InvoiceStatus.paid,
      dueOrPaidDateLabel: 'Đã thanh toán: 30/09/2025',
    ),
  ];

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
          'Hoá đơn thanh toán',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(
        padding: AppConstants.screenPadding.copyWith(top: 8, bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xem tất cả các hoá đơn và trạng thái thanh toán',
              style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final inv = _items[index];
                  return _InvoiceCard(
                    invoice: inv,
                    onPay: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Thanh toán ${inv.id}')), // TODO: nối tới PaymentScreen
                      );
                    },
                    onView: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Xem chi tiết ${inv.id}')), // TODO: mở chi tiết hoá đơn
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum InvoiceStatus { open, paid }

class _Invoice {
  final String id;
  final String plan;
  final String period; // ví dụ: 30/09–29/10
  final String amount; // ví dụ: 86.900đ
  final InvoiceStatus status;
  final String dueOrPaidDateLabel; // "Đến hạn: ..." hoặc "Đã thanh toán: ..."
  const _Invoice({
    required this.id,
    required this.plan,
    required this.period,
    required this.amount,
    required this.status,
    required this.dueOrPaidDateLabel,
  });
}

class _InvoiceCard extends StatelessWidget {
  final _Invoice invoice;
  final VoidCallback onPay;
  final VoidCallback onView;
  const _InvoiceCard({
    required this.invoice,
    required this.onPay,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = invoice.status == InvoiceStatus.open;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
        border: Border.all(color: const Color(0xFFE6E8EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${invoice.id} · ${invoice.plan} · ${invoice.period}',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                invoice.amount,
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatusChip(status: invoice.status),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  invoice.dueOrPaidDateLabel,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _ActionButton(
                isPrimary: isOpen,
                label: isOpen ? 'Trả' : 'Xem',
                onPressed: isOpen ? onPay : onView,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final InvoiceStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isOpen = status == InvoiceStatus.open;
    final bg = isOpen ? const Color(0xFFEFFAF3) : const Color(0xFFEFF6FF);
    final txt = isOpen ? AppColors.primary : AppColors.textSecondary;
    final label = isOpen ? 'OPEN' : 'PAID';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(
          color: txt,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: .4,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final bool isPrimary; // true => xanh "Trả"; false => xám "Xem"
  final String label;
  final VoidCallback onPressed;
  const _ActionButton({
    required this.isPrimary,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(999));

    if (isPrimary) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          shape: shape,
        ),
        child: Text(
          label,
          style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
        ),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        shape: shape,
        side: const BorderSide(color: Color(0xFFE6E8EC)),
        backgroundColor: const Color(0xFFF3F5F7),
      ),
      child: Text(
        label,
        style: AppTextStyles.button.copyWith(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}