// File: lib/services/payment_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/order_model.dart';

class PaymentService {
  static const String baseUrl = 'http://localhost:8080/api/payment';
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

  /// Lấy danh sách orders của user hiện tại
  static Future<List<OrderModel>> getMyOrders() async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$baseUrl/my-orders');

      print('📡 Calling: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📦 Response body: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((e) => OrderModel.fromJson(e)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Phiên đăng nhập đã hết. Vui lòng đăng nhập lại.');
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể tải danh sách đơn hàng');
      }
    } catch (e) {
      print('❌ Error in getMyOrders: $e');
      rethrow;
    }
  }

  /// Tạo order mới
  static Future<OrderModel> createOrder(int packId) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$baseUrl/create-order');

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
      print('📦 Response body: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        return OrderModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể tạo đơn hàng');
      }
    } catch (e) {
      print('❌ Error in createOrder: $e');
      rethrow;
    }
  }

  /// Tạo URL thanh toán VNPay
  static Future<Map<String, dynamic>> createVNPayPayment(int orderId) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$baseUrl/vnpay/create?orderId=$orderId');

      print('📡 Creating VNPay payment for order $orderId');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 VNPay payment status: ${response.statusCode}');
      print('📦 Response body: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể tạo link thanh toán');
      }
    } catch (e) {
      print('❌ Error in createVNPayPayment: $e');
      rethrow;
    }
  }
}