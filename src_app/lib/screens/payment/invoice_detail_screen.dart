// File: lib/screens/payment/invoice_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../models/order_model.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final OrderModel order;

  const InvoiceDetailScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Chi tiết hóa đơn',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.share_outlined,
              color: AppColors.primary,
            ),
            onPressed: () {
              _shareInvoice(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            _buildStatusBanner(),
            const SizedBox(height: 24),

            // Invoice Info Card
            _buildInfoCard(
              context,
              title: 'Thông tin đơn hàng',
              children: [
                _buildInfoRow(context, 'Mã đơn hàng', '#${order.id}', copyable: true),
                const Divider(height: 24),
                _buildInfoRow(context, 'Gói dịch vụ', order.packName ?? 'Gói học tập'),
                const Divider(height: 24),
                _buildInfoRow(context, 'Trạng thái', order.statusLabel),
                const Divider(height: 24),
                _buildInfoRow(context, 'Ngày tạo', order.formattedCreatedDate),
              ],
            ),
            const SizedBox(height: 16),

            // Payment Info Card
            _buildInfoCard(
              context,
              title: 'Thông tin thanh toán',
              children: [
                _buildInfoRow(context, 'Số tiền', order.formattedPrice,
                  valueStyle: AppTextStyles.heading3.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Divider(height: 24),
                _buildInfoRow(context, 'Phương thức', 'VNPay'),
              ],
            ),
            const SizedBox(height: 16),

            // Subscription Info Card (only for PAID orders)
            if (order.isPaid) ...[
              _buildInfoCard(
                context,
                title: 'Thông tin gói dịch vụ',
                children: [
                  _buildInfoRow(context, 'Ngày kích hoạt', order.formattedStartDate),
                  const Divider(height: 24),
                  _buildInfoRow(context, 'Ngày hết hạn', order.formattedExpiryDate),
                  const Divider(height: 24),
                  _buildInfoRow(
                    context,
                    'Thời gian còn lại',
                    order.daysRemainingLabel,
                    valueStyle: AppTextStyles.label.copyWith(
                      color: order.isActive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Usage Stats Card (only for active subscriptions)
            if (order.isActive) ...[
              _buildInfoCard(
                context,
                title: 'Trạng thái sử dụng',
                children: [
                  _buildProgressIndicator(
                    label: 'Thời gian đã sử dụng',
                    current: _calculateUsedDays(),
                    total: _calculateTotalDays(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Notes
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      order.isPaid
                          ? 'Gói dịch vụ của bạn sẽ tự động gia hạn khi hết hạn. Bạn có thể hủy bất cứ lúc nào.'
                          : 'Vui lòng hoàn tất thanh toán để kích hoạt gói dịch vụ.',
                      style: AppTextStyles.label.copyWith(
                        color: Colors.blue.shade900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String message;

    switch (order.status) {
      case 'PAID':
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        message = 'Đơn hàng đã được thanh toán thành công';
        break;
      case 'PENDING':
        backgroundColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        icon = Icons.access_time;
        message = 'Đang chờ thanh toán';
        break;
      case 'CANCELED':
        backgroundColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        icon = Icons.cancel;
        message = 'Đơn hàng đã bị hủy';
        break;
      default:
        backgroundColor = Colors.grey.shade50;
        textColor = Colors.grey.shade700;
        icon = Icons.help_outline;
        message = 'Trạng thái không xác định';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.label.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      BuildContext context, {
        required String title,
        required List<Widget> children,
      }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.heading4.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context,
      String label,
      String value, {
        TextStyle? valueStyle,
        bool copyable = false,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: AppColors.textGray,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: valueStyle ??
                      AppTextStyles.label.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                  textAlign: TextAlign.right,
                ),
              ),
              if (copyable) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    _copyToClipboard(context, value);
                  },
                  child: Icon(
                    Icons.copy,
                    size: 16,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator({
    required String label,
    required int current,
    required int total,
  }) {
    final percentage = total > 0 ? (current / total * 100).clamp(0, 100) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: AppColors.textGray,
                fontSize: 14,
              ),
            ),
            Text(
              '$current / $total ngày',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage > 80 ? Colors.red : AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${percentage.toStringAsFixed(1)}% đã sử dụng',
          style: AppTextStyles.label.copyWith(
            color: AppColors.textGray,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  int _calculateUsedDays() {
    if (order.startedAt == null) return 0;
    final diff = DateTime.now().difference(order.startedAt!);
    return diff.inDays.clamp(0, _calculateTotalDays());
  }

  int _calculateTotalDays() {
    if (order.startedAt == null || order.expiresAt == null) return 0;
    final diff = order.expiresAt!.difference(order.startedAt!);
    return diff.inDays > 0 ? diff.inDays : 0;
  }

  void _shareInvoice(BuildContext context) {
    final text = '''
🧾 HÓA ĐƠN THANH TOÁN

Mã đơn: #${order.id}
Gói dịch vụ: ${order.packName ?? 'Gói học tập'}
Trạng thái: ${order.statusLabel}
Số tiền: ${order.formattedPrice}
Ngày tạo: ${order.formattedCreatedDate}

${order.isPaid ? '''
Ngày kích hoạt: ${order.formattedStartDate}
Ngày hết hạn: ${order.formattedExpiryDate}
Còn lại: ${order.daysRemainingLabel}
''' : ''}

Cảm ơn bạn đã sử dụng dịch vụ!
    ''';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chia sẻ hóa đơn: ${text.substring(0, 50)}...'),
        action: SnackBarAction(
          label: 'Sao chép',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: text));
          },
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}