// File: lib/models/order_model.dart
import 'package:intl/intl.dart';

class OrderModel {
  final int id;
  final int userId;
  final int packId;
  final String? packName;
  final double priceAtPurchase;
  final String status; // PENDING, PAID, CANCELED, REFUNDED
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.packId,
    this.packName,
    required this.priceAtPurchase,
    required this.status,
    this.startedAt,
    this.expiresAt,
    required this.createdAt,
  });

  // ✅ Sửa fromJson để hỗ trợ cả camelCase và snake_case
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? json['user_id'] ?? 0,
      packId: json['packId'] ?? json['pack_id'] ?? 0,
      packName: json['packName'] ?? json['pack_name'],
      priceAtPurchase: _parseDouble(json['priceAtPurchase'] ?? json['price_at_purchase'] ?? 0),
      status: (json['status'] ?? 'PENDING').toString().toUpperCase(),
      startedAt: _parseDateTime(json['startedAt'] ?? json['started_at']),
      expiresAt: _parseDateTime(json['expiresAt'] ?? json['expires_at']),
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']) ?? DateTime.now(),
    );
  }

  // Helper methods cho parsing
  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('❌ Error parsing date: $value - $e');
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'packId': packId,
      'packName': packName,
      'priceAtPurchase': priceAtPurchase,
      'status': status,
      'startedAt': startedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Helper methods
  String get formattedPrice {
    return '${priceAtPurchase.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    )}đ';
  }

  String get formattedCreatedDate {
    return DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
  }

  String get formattedStartDate {
    if (startedAt == null) return 'Chưa kích hoạt';
    return DateFormat('dd/MM/yyyy').format(startedAt!);
  }

  String get formattedExpiryDate {
    if (expiresAt == null) return 'Không giới hạn';
    return DateFormat('dd/MM/yyyy').format(expiresAt!);
  }

  String get statusLabel {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Chờ thanh toán';
      case 'PAID':
        return 'Đã thanh toán';
      case 'CANCELED':
        return 'Đã hủy';
      case 'REFUNDED':
        return 'Đã hoàn tiền';
      default:
        return status;
    }
  }

  bool get isPaid => status.toUpperCase() == 'PAID';
  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isActive => isPaid && expiresAt != null && expiresAt!.isAfter(DateTime.now());

  // Tính số ngày còn lại
  int get daysRemaining {
    if (expiresAt == null || !isPaid) return 0;
    final diff = expiresAt!.difference(DateTime.now());
    return diff.inDays > 0 ? diff.inDays : 0;
  }

  String get daysRemainingLabel {
    if (!isActive) return 'Đã hết hạn';
    final days = daysRemaining;
    if (days == 0) return 'Hết hạn hôm nay';
    if (days == 1) return 'Còn 1 ngày';
    return 'Còn $days ngày';
  }

  @override
  String toString() {
    return 'OrderModel(id: $id, packName: $packName, status: $status, isActive: $isActive)';
  }
}