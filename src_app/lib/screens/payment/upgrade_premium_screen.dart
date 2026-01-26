import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_config.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../models/study_pack_model.dart';
import '../../services/study_pack_service.dart';

class UpgradePremiumScreen extends StatefulWidget {
  const UpgradePremiumScreen({super.key});

  @override
  State<UpgradePremiumScreen> createState() => _UpgradePremiumScreenState();
}

class _UpgradePremiumScreenState extends State<UpgradePremiumScreen> {
  int _selectedPackIndex = 0;
  bool _isLoading = true;
  List<StudyPackModel> _packs = [];
  String? _errorMessage;

  /// Chọn base URL theo môi trường chạy
  // String get _apiBase {
  //   // Android emulator truy cập host là 10.0.2.2
  //   if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
  //     return 'http://10.0.2.2:8080';
  //   }
  //   return 'http://localhost:8080';
  // }

  @override
  void initState() {
    super.initState();
    _loadPacks();
  }

  Future<void> _loadPacks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final packs = await StudyPackService.getAllPacks();

      if (packs.isEmpty) {
        setState(() {
          _errorMessage = 'Chưa có gói học tập nào';
          _isLoading = false;
        });
        return;
      }

      // Tự động chọn gói ở giữa hoặc gói đầu tiên
      final middleIndex = packs.length > 1 ? (packs.length ~/ 2) : 0;

      setState(() {
        _packs = packs;
        _selectedPackIndex = middleIndex;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $_errorMessage'),
            backgroundColor: Colors.redAccent,
          ),
        );
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
          'Nâng cấp Premium',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
          ? _buildErrorState()
          : Column(
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.primary.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mở khóa toàn bộ tính năng',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Học thông minh hơn với AI 🌟',
                          style: AppTextStyles.hint.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Plans List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadPacks,
              color: AppColors.primary,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: _packs.length,
                itemBuilder: (context, index) {
                  final pack = _packs[index];
                  final isSelected = _selectedPackIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPackIndex = index),
                    child: _buildPackCard(pack, isSelected, index),
                  );
                },
              ),
            ),
          ),

          // Bottom CTA
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: AppColors.textGray,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Giá đã bao gồm VAT • Hủy bất kỳ lúc nào',
                        style: AppTextStyles.hint.copyWith(
                          fontSize: 12,
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _handlePurchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.workspace_premium_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          // ✅ FIX: Sử dụng Flexible để tránh overflow
                          Flexible(
                            child: Text(
                              'Mua ${_packs[_selectedPackIndex].name}',
                              style: AppTextStyles.button.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _packs[_selectedPackIndex].formattedPrice,
                            style: AppTextStyles.button.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _packs[_selectedPackIndex].durationLabel,
                            style: AppTextStyles.hint.copyWith(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.redAccent.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Không thể tải gói học tập',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Đã xảy ra lỗi',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPacks,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: Text(
                'Thử lại',
                style: AppTextStyles.button.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Chỉ cần thay thế phần _buildPackCard trong file upgrade_premium_screen.dart

  Widget _buildPackCard(StudyPackModel pack, bool isSelected, int index) {
    // Xác định gói phổ biến (middle option)
    final isPopular = _packs.length > 2 && index == (_packs.length ~/ 2);

    // Parse description thành list features
    final features = pack.description
        .split('•')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.primary : const Color(0xFFE6E8EC),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.primary.withOpacity(0.15)
                : Colors.black.withOpacity(0.03),
            blurRadius: isSelected ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ FIXED: Header với proper layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start, // ← THÊM
            children: [
              // Radio button
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(top: 2), // ← THÊM để align
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.textGray,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 12),

              // ✅ FIXED: Name + Badge (với Expanded)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + Badge trên cùng 1 row
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          pack.name,
                          style: AppTextStyles.heading3.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 17, // ← Giảm từ 18 xuống 17
                          ),
                        ),
                        if (isPopular)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: Color(0xFFFF9800),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'PHỔ BIẾN',
                                  style: AppTextStyles.hint.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFFF9800),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    // ✅ FIXED: Price bên dưới name
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          pack.formattedPrice,
                          style: AppTextStyles.heading3.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 20, // ← Tăng lên để nổi bật
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          pack.durationLabel,
                          style: AppTextStyles.hint.copyWith(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Features
          if (features.isNotEmpty)
            ...features.map(
                  (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        feature,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                pack.description,
                style: AppTextStyles.label.copyWith(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handlePurchase() {
    final selectedPack = _packs[_selectedPackIndex];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Xác nhận thanh toán',
                style: AppTextStyles.heading3,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn đang mua gói ${selectedPack.name}',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Gói:',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        selectedPack.name,
                        style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tổng thanh toán:',
                        style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            selectedPack.formattedPrice,
                            style: AppTextStyles.heading3.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            selectedPack.durationLabel,
                            style: AppTextStyles.hint.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: AppTextStyles.button.copyWith(color: AppColors.textGray),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _payWithVnPay(packId: selectedPack.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Thanh toán',
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

  // ====== PAYMENT - FIXED VERSION ======

  Future<void> _payWithVnPay({required int packId}) async {
    try {
      // Show loading
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang tạo hóa đơn VNPay...'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );

      // 1. Lấy token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        throw Exception('Bạn chưa đăng nhập');
      }

      // 2. Tạo order
      print('🔵 Step 1: Creating order for pack $packId');
      final createOrderRes = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/payment/create-order'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'packId': packId}),
      );

      print('📊 Create order status: ${createOrderRes.statusCode}');
      print('📦 Create order body: ${createOrderRes.body}');

      if (createOrderRes.statusCode != 200) {
        final errMsg = _extractMessage(createOrderRes.body);
        throw Exception('Tạo đơn thất bại: $errMsg');
      }

      // ✅ FIX: Kiểm tra body trống trước khi parse
      if (createOrderRes.body.isEmpty) {
        throw Exception('Server trả về response trống khi tạo order');
      }

      final order = jsonDecode(createOrderRes.body);
      final orderId = order['id'];

      if (orderId == null) {
        throw Exception('Không nhận được orderId từ server');
      }

      print('✅ Created order: $orderId');

      // 3. Tạo URL VNPay
      print('🔵 Step 2: Creating VNPay payment URL');
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/payment/vnpay/create')
          .replace(queryParameters: {
        'orderId': orderId.toString(),
      });

      final createPayRes = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📊 Create payment status: ${createPayRes.statusCode}');
      print('📦 Create payment body: ${createPayRes.body}');

      if (createPayRes.statusCode != 200) {
        final errMsg = _extractMessage(createPayRes.body);
        throw Exception('Tạo URL thanh toán thất bại: $errMsg');
      }

      // ✅ FIX: Kiểm tra body trống trước khi parse
      if (createPayRes.body.isEmpty) {
        throw Exception('Server trả về response trống khi tạo payment URL');
      }

      final payData = jsonDecode(createPayRes.body);
      final paymentUrl = payData['paymentUrl'];

      if (paymentUrl == null || paymentUrl.toString().isEmpty) {
        throw Exception('Server không trả về paymentUrl');
      }

      print('✅ Payment URL: $paymentUrl');

      // 4. Mở trình duyệt
      final uri2 = Uri.parse(paymentUrl.toString());
      final canLaunch = await canLaunchUrl(uri2);

      if (!canLaunch) {
        throw Exception('Không thể mở trình duyệt');
      }

      final launched = await launchUrl(
        uri2,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Không mở được trang thanh toán');
      }

      print('✅ Opened payment URL in browser');

    } catch (e) {
      print('❌ Payment error: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  String _extractMessage(String body) {
    try {
      // ✅ FIX: Kiểm tra body trống
      if (body.isEmpty) {
        return 'Server không trả về thông tin lỗi';
      }

      final json = jsonDecode(body);
      return (json['message'] ?? json['error'] ?? body).toString();
    } catch (e) {
      // Nếu parse JSON fail, trả về body nguyên bản
      print('⚠️ Failed to parse error message: $e');
      return body.isNotEmpty ? body : 'Lỗi không xác định';
    }
  }
}