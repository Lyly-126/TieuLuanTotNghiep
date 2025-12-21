// File: lib/services/payment_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/order_model.dart';

class PaymentService {
  // static const String baseUrl = 'http://localhost:8080/api/payment';
  // Android Emulator: 'http://10.0.2.2:8080/api/payment'
  // Production: 'https://yourdomain.com/api/payment'

  /// Lấy token từ SharedPreferences
  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      throw Exception('Vui lòng đăng nhập lại');
    }
    return token;
  }

  /// ✅ THÊM: Tự động sync premium status dựa vào orders
  static Future<void> _syncPremiumStatus(List<OrderModel> orders) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Kiểm tra xem có order nào đang active không
      final hasActivePremium = orders.any((order) => order.isActive);

      // Tìm ngày hết hạn xa nhất
      DateTime? latestExpiry;
      String? latestPackName;

      if (hasActivePremium) {
        final activeOrders = orders.where((o) => o.isActive).toList();
        if (activeOrders.isNotEmpty) {
          // Sort theo expiry date giảm dần
          activeOrders.sort((a, b) => b.expiresAt!.compareTo(a.expiresAt!));
          latestExpiry = activeOrders.first.expiresAt;
          latestPackName = activeOrders.first.packName;
        }
      }

      // Cập nhật SharedPreferences
      await prefs.setBool('user_is_premium', hasActivePremium);

      if (latestExpiry != null) {
        await prefs.setString('premium_expiry_date', latestExpiry.toIso8601String());
      } else {
        await prefs.remove('premium_expiry_date');
      }

      if (latestPackName != null) {
        await prefs.setString('premium_pack_name', latestPackName);
      } else {
        await prefs.remove('premium_pack_name');
      }

      print('✅ Premium status synced: isPremium=$hasActivePremium, expiry=$latestExpiry, pack=$latestPackName');
    } catch (e) {
      print('⚠️ Error syncing premium status: $e');
    }
  }

  /// Tạo order mới
  static Future<Map<String, dynamic>> createOrder(int packId) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${ApiConfig.paymentBase}/create-order');

      print('📡 Creating order for pack $packId');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'packId': packId}),
      );

      print('📡 Create order status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể tạo đơn hàng');
      }
    } catch (e) {
      print('❌ Error in createOrder: $e');
      throw Exception('Lỗi: $e');
    }
  }

  /// Tạo VNPay payment URL
  static Future<Map<String, dynamic>> createVNPayPayment(int orderId) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${ApiConfig.paymentVnpay}/create?orderId=$orderId');

      print('📡 Creating VNPay payment for order $orderId');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 VNPay payment status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể tạo thanh toán');
      }
    } catch (e) {
      print('❌ Error in createVNPayPayment: $e');
      throw Exception('Lỗi: $e');
    }
  }

  /// Lấy danh sách orders của user
  /// ✅ Tự động sync premium status sau khi load orders
  static Future<List<OrderModel>> getMyOrders() async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${ApiConfig.paymentBase}/my-orders');

      print('📡 Fetching my orders');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Get orders status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

        // Convert sang List<OrderModel>
        final orders = data.map((json) {
          try {
            return OrderModel.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            print('❌ Error parsing order: $json');
            print('   Error details: $e');
            rethrow;
          }
        }).toList();

        print('✅ Loaded ${orders.length} orders');
        for (var order in orders) {
          print('   Order #${order.id}: ${order.status} - Active: ${order.isActive} - Pack: ${order.packName}');
        }

        // ✅ Tự động sync premium status
        await _syncPremiumStatus(orders);

        return orders;
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể tải danh sách đơn hàng');
      }
    } catch (e) {
      print('❌ Error in getMyOrders: $e');
      rethrow;
    }
  }

  /// ✅ THÊM: Method để force refresh premium status
  static Future<bool> checkPremiumStatus() async {
    try {
      final orders = await getMyOrders();
      return orders.any((order) => order.isActive);
    } catch (e) {
      print('❌ Error checking premium status: $e');
      return false;
    }
  }
}