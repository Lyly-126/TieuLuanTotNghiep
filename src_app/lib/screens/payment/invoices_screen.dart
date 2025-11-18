// File: lib/screens/payment/invoices_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../models/order_model.dart';
import '../../services/payment_service.dart';
import 'invoice_detail_screen.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  bool _isLoading = true;
  List<OrderModel> _orders = [];
  String? _errorMessage;
  bool _isPremium = false;
  DateTime? _premiumExpiryDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔄 Loading orders and syncing premium status...');

      // ✅ Load orders (tự động sync premium status trong service)
      final orders = await PaymentService.getMyOrders();

      // ✅ Reload premium status từ SharedPreferences SAU KHI sync
      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool('user_is_premium') ?? false;

      // Lấy expiry date từ prefs
      final expiryStr = prefs.getString('premium_expiry_date');
      if (expiryStr != null) {
        try {
          _premiumExpiryDate = DateTime.parse(expiryStr);
        } catch (e) {
          print('⚠️ Error parsing expiry date: $e');
        }
      }

      // Fallback: Tìm order PAID gần nhất nếu chưa có expiry date
      if (_premiumExpiryDate == null) {
        final paidOrders = orders.where((o) => o.isPaid && o.expiresAt != null).toList();
        if (paidOrders.isNotEmpty) {
          paidOrders.sort((a, b) => b.expiresAt!.compareTo(a.expiresAt!));
          _premiumExpiryDate = paidOrders.first.expiresAt;
        }
      }

      print('✅ Premium status: $_isPremium, Expiry: $_premiumExpiryDate');
      print('✅ Loaded ${orders.length} orders');

      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading data: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Hóa đơn & Thanh toán',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // ✅ THÊM: Nút refresh
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadData,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium Status Card
              _buildPremiumStatusCard(),
              const SizedBox(height: 24),

              // Invoices List
              Text(
                'Lịch sử đơn hàng',
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 16),

              if (_orders.isEmpty)
                _buildEmptyView()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _orders.length,
                  separatorBuilder: (context, index) =>
                  const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildOrderCard(_orders[index]);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumStatusCard() {
    final isActive = _isPremium &&
        _premiumExpiryDate != null &&
        _premiumExpiryDate!.isAfter(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [AppColors.primary, AppColors.primaryDark]
              : [Colors.grey.shade300, Colors.grey.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
        BorderRadius.circular(AppConstants.borderRadius * 1.5),
        boxShadow: [
          BoxShadow(
            color:
            (isActive ? AppColors.primary : Colors.grey).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isActive ? Icons.workspace_premium : Icons.lock_outline,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isActive ? 'Tài khoản Premium' : 'Tài khoản Free',
                  style: AppTextStyles.heading3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.check_circle_outline,
            'Trạng thái',
            isActive ? 'Đang hoạt động' : 'Chưa kích hoạt',
          ),
          if (isActive && _premiumExpiryDate != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.calendar_today,
              'Hạn sử dụng',
              _formatDate(_premiumExpiryDate!),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.timelapse,
              'Còn lại',
              _getDaysRemaining(_premiumExpiryDate!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: AppTextStyles.label.copyWith(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.label.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    Color statusColor;
    IconData statusIcon;

    switch (order.status.toUpperCase()) {
      case 'PAID':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'PENDING':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        break;
      case 'CANCELED':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InvoiceDetailScreen(order: order),
          ),
        );
        // ✅ Reload sau khi quay về
        _loadData();
      },
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Container(
        padding: const EdgeInsets.all(16),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.packName ?? 'Gói học tập #${order.packId}',
                    style: AppTextStyles.heading4.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        order.statusLabel,
                        style: AppTextStyles.label.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildOrderInfoRow('Mã đơn', '#${order.id}'),
            const SizedBox(height: 6),
            _buildOrderInfoRow('Số tiền', order.formattedPrice),
            const SizedBox(height: 6),
            _buildOrderInfoRow('Ngày tạo', order.formattedCreatedDate),
            if (order.isPaid && order.expiresAt != null) ...[
              const SizedBox(height: 6),
              _buildOrderInfoRow(
                'Hạn sử dụng',
                order.formattedExpiryDate,
                highlight: order.isActive,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoRow(String label, String value,
      {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: AppColors.textGray,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.label.copyWith(
            color: highlight ? AppColors.primary : AppColors.textPrimary,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: AppColors.textGray.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có đơn hàng nào',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.textGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy nâng cấp tài khoản để trải nghiệm Premium',
              textAlign: TextAlign.center,
              style: AppTextStyles.label.copyWith(
                color: AppColors.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Có lỗi xảy ra',
              style: AppTextStyles.heading3.copyWith(
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Không thể tải dữ liệu',
              textAlign: TextAlign.center,
              style: AppTextStyles.label,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getDaysRemaining(DateTime expiryDate) {
    final diff = expiryDate.difference(DateTime.now());
    final days = diff.inDays;

    if (days < 0) return 'Đã hết hạn';
    if (days == 0) return 'Hết hạn hôm nay';
    if (days == 1) return '1 ngày';
    return '$days ngày';
  }
}