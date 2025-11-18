// lib/screens/payment/payment_waiting_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import 'payment_result_screen.dart';

class PaymentWaitingScreen extends StatefulWidget {
  final int orderId;
  final String ngrokUrl; // URL ngrok của bạn

  const PaymentWaitingScreen({
    super.key,
    required this.orderId,
    required this.ngrokUrl,
  });

  @override
  State<PaymentWaitingScreen> createState() => _PaymentWaitingScreenState();
}

class _PaymentWaitingScreenState extends State<PaymentWaitingScreen> {
  Timer? _pollTimer;
  int _pollCount = 0;
  static const int MAX_POLL = 60; // Poll 60 lần (5 phút)
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    // Check ngay lập tức
    _checkPaymentStatus();

    // Sau đó check mỗi 5 giây
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      _pollCount++;

      if (_pollCount > MAX_POLL) {
        timer.cancel();
        _showTimeout();
        return;
      }

      await _checkPaymentStatus();
    });
  }

  Future<void> _checkPaymentStatus() async {
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        _showError('Phiên đăng nhập hết hạn');
        return;
      }

      print('🔍 Checking payment status... (attempt $_pollCount)');

      // Gọi API lấy danh sách orders
      final response = await http.get(
        Uri.parse('${widget.ngrokUrl}/api/payment/my-orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> orders = jsonDecode(response.body);

        // Tìm order hiện tại
        final order = orders.firstWhere(
              (o) => o['id'] == widget.orderId,
          orElse: () => null,
        );

        if (order != null) {
          final status = order['status'] as String;
          print('📦 Order status: $status');

          if (status != 'PENDING') {
            // Đã có kết quả
            _pollTimer?.cancel();
            _navigateToResult(order);
          }
        }
      } else if (response.statusCode == 401) {
        _pollTimer?.cancel();
        _showError('Phiên đăng nhập hết hạn');
      }
    } catch (e) {
      print('❌ Error checking payment: $e');
      // Không show error, tiếp tục polling
    }
  }

  void _navigateToResult(Map<String, dynamic> order) {
    if (!mounted) return;

    final bool isSuccess = order['status'] == 'PAID';

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PaymentResultScreen(
          result: {
            'success': isSuccess,
            'message': isSuccess
                ? 'Thanh toán thành công'
                : 'Thanh toán thất bại',
            'order': order,
          },
        ),
      ),
    );
  }

  void _showTimeout() {
    if (!mounted) return;

    setState(() {
      _isChecking = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.access_time, color: Colors.orange[700]),
            const SizedBox(width: 12),
            const Text('Hết thời gian chờ'),
          ],
        ),
        content: const Text(
          'Chúng tôi chưa nhận được kết quả thanh toán. '
              'Vui lòng kiểm tra lại trong mục "Đơn hàng của tôi".\n\n'
              'Nếu bạn đã thanh toán thành công, đơn hàng sẽ được cập nhật trong vài phút.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Check 1 lần cuối
              await _checkPaymentStatus();
              if (mounted) {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close waiting screen
              }
            },
            child: const Text('Kiểm tra lại'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close waiting screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Đóng',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Hỏi xác nhận trước khi thoát
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xác nhận'),
            content: const Text(
              'Bạn có chắc muốn hủy kiểm tra thanh toán?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Không'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Có'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animation
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: _isChecking
                      ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                      : const Icon(
                    Icons.access_time,
                    size: 60,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  _isChecking
                      ? 'Đang chờ kết quả thanh toán...'
                      : 'Hết thời gian chờ',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                Text(
                  _isChecking
                      ? 'Vui lòng hoàn tất thanh toán trong cửa sổ trình duyệt.\n'
                      'Chúng tôi sẽ tự động cập nhật kết quả.'
                      : 'Không nhận được kết quả thanh toán.\n'
                      'Vui lòng kiểm tra lại trong Đơn hàng của tôi.',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Progress indicator
                if (_isChecking) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.refresh,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Đang kiểm tra... (${_pollCount}/$MAX_POLL)',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Nút hủy
                TextButton(
                  onPressed: () {
                    _pollTimer?.cancel();
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Hủy và quay lại',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}