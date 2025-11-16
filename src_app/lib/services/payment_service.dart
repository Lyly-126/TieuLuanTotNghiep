import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  /// Tạo order mới
  static Future<Map<String, dynamic>> createOrder(int packId) async {
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
  static Future<List<Map<String, dynamic>>> getMyOrders() async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$baseUrl/my-orders');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        throw Exception('Không thể tải danh sách đơn hàng');
      }
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }
}