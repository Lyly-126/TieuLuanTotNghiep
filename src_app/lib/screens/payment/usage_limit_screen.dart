// File: lib/screens/payment/usage_limit_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../models/order_model.dart';
import '../../services/payment_service.dart';

class UsageLimitScreen extends StatefulWidget {
  const UsageLimitScreen({super.key});

  @override
  State<UsageLimitScreen> createState() => _UsageLimitScreenState();
}

class _UsageLimitScreenState extends State<UsageLimitScreen> {
  bool _isLoading = true;
  bool _isPremium = false;
  String _planName = 'Free';
  DateTime? _startDate;
  DateTime? _expiryDate;
  String? _errorMessage;

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
      print('🔄 Loading usage limit data...');

      // ✅ Load orders (tự động sync premium status)
      final orders = await PaymentService.getMyOrders();

      // ✅ Reload từ SharedPreferences SAU KHI sync
      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool('user_is_premium') ?? false;

      if (_isPremium) {
        final activeOrders = orders.where((o) => o.isActive).toList();

        if (activeOrders.isNotEmpty) {
          activeOrders.sort((a, b) => b.expiresAt!.compareTo(a.expiresAt!));
          final activeOrder = activeOrders.first;

          _planName = activeOrder.packName ?? 'Premium';
          _startDate = activeOrder.startedAt;
          _expiryDate = activeOrder.expiresAt;
        }
      }

      print('✅ Usage limit loaded: isPremium=$_isPremium, plan=$_planName');

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error: $e');
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
          'Hạn mức sử dụng',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : SingleChildScrollView(
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

            // Thông tin gói dịch vụ
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
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
                  Row(
                    children: [
                      Icon(
                        _isPremium ? Icons.workspace_premium : Icons.lock_outline,
                        color: _isPremium ? AppColors.primary : AppColors.textGray,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Gói dịch vụ: $_planName',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_isPremium && _startDate != null && _expiryDate != null) ...[
                    _buildRow(
                      'Thời gian sử dụng:',
                      '${_formatDate(_startDate!)} – ${_formatDate(_expiryDate!)}',
                    ),
                    const SizedBox(height: 10),
                    _buildRow(
                      'Thời gian còn lại:',
                      _getDaysRemaining(),
                      color: AppColors.primary,
                      isBold: true,
                    ),
                  ] else ...[
                    _buildRow(
                      'Trạng thái:',
                      'Chưa kích hoạt Premium',
                      color: AppColors.textGray,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Nâng cấp lên Premium để mở khóa tất cả tính năng!',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Thông tin tính năng Premium
            if (_isPremium) ...[
              _buildFeatureCard(
                icon: Icons.auto_awesome,
                title: 'Tính năng Premium',
                items: [
                  'Tạo flashcard không giới hạn',
                  'OCR nhận diện văn bản',
                  'Tạo flashcard từ AI',
                  'Thống kê chi tiết',
                  'Backup dữ liệu',
                ],
              ),
            ] else ...[
              _buildUpgradeCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, Color? color}) {
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

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required List<String> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
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
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildUpgradeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.1), AppColors.primary.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.workspace_premium, color: AppColors.primary, size: 48),
          const SizedBox(height: 16),
          Text(
            'Nâng cấp lên Premium',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mở khóa tất cả tính năng cao cấp và trải nghiệm học tập tốt nhất!',
            textAlign: TextAlign.center,
            style: AppTextStyles.label.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/upgrade_premium');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
            ),
            child: Text(
              'Xem gói Premium',
              style: AppTextStyles.button.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Có lỗi xảy ra',
              style: AppTextStyles.heading3.copyWith(color: Colors.red),
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
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _getDaysRemaining() {
    if (_expiryDate == null) return 'Không xác định';

    final now = DateTime.now();
    final diff = _expiryDate!.difference(now);

    if (diff.isNegative) return 'Đã hết hạn';

    final days = diff.inDays;
    final months = (days / 30).floor();
    final remainingDays = days % 30;

    if (months > 0) {
      return '$months tháng ${remainingDays > 0 ? '$remainingDays ngày' : ''}';
    } else if (days > 0) {
      return '$days ngày';
    } else {
      return 'Hết hạn hôm nay';
    }
  }
}