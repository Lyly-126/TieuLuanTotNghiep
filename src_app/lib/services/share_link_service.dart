// File: lib/services/share_link_service.dart

import 'package:share_plus/share_plus.dart';
import '../config/api_config.dart';

/// Service để chia sẻ lớp học qua link
class ShareLinkService {

  /// Tạo link chia sẻ lớp học
  ///
  /// Nếu đang dùng ngrok -> tạo link với ngrok URL
  /// Nếu không -> tạo deep link scheme
  static String generateClassShareLink(String inviteCode) {
    if (ApiConfig.isUsingNgrok) {
      // Sử dụng ngrok URL
      final ngrokUrl = ApiConfig.baseUrl;
      return '$ngrokUrl/join/$inviteCode';
    } else {
      // Sử dụng deep link scheme
      return 'flai://join/$inviteCode';
    }
  }

  /// Chia sẻ lớp học qua link
  static Future<void> shareClass({
    required String className,
    required String inviteCode,
    String? description,
  }) async {
    final shareLink = generateClassShareLink(inviteCode);

    final message = '''
🎓 Tham gia lớp "$className"

${description != null && description.isNotEmpty ? '📝 $description\n\n' : ''}🔗 Link tham gia: $shareLink

💡 Mã lớp: $inviteCode

---
Ứng dụng học tập Flai
''';

    try {
      await Share.share(
        message,
        subject: 'Mời tham gia lớp "$className"',
      );
      print('✅ ShareLinkService: Shared successfully');
    } catch (e) {
      print('❌ ShareLinkService: Error sharing - $e');
      rethrow;
    }
  }

  /// Lấy share message (không share ngay)
  static String getShareMessage({
    required String className,
    required String inviteCode,
    String? description,
  }) {
    final shareLink = generateClassShareLink(inviteCode);

    return '''
🎓 Tham gia lớp "$className"

${description != null && description.isNotEmpty ? '📝 $description\n\n' : ''}🔗 Link tham gia: $shareLink

💡 Mã lớp: $inviteCode
''';
  }

  /// Lấy chỉ link (không có message)
  static String getShareLink(String inviteCode) {
    return generateClassShareLink(inviteCode);
  }
}