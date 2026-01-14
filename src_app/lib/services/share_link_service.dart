import 'package:share_plus/share_plus.dart';
import '../config/api_config.dart';

/// Service để chia sẻ lớp học và category qua link
class ShareLinkService {
  static const String _landingPageUrl = 'https://melodic-kitten-e659c0.netlify.app';


  /// Tạo link chia sẻ lớp học
  static String generateClassShareLink(String inviteCode) {
    return '$_landingPageUrl/join/$inviteCode';  // ✅ Không dùng backend URL nữa
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
      print('✅ ShareLinkService: Class shared successfully');
    } catch (e) {
      print('❌ ShareLinkService: Error sharing class - $e');
      rethrow;
    }
  }

  // ==================== CATEGORY SHARING ====================

  /// Tạo link chia sẻ category
  static String generateCategoryShareLink(String shareToken) {
    return '$_landingPageUrl/category/$shareToken';
  }

  /// Chia sẻ category qua link
  static Future<void> shareCategory({
    required String categoryName,
    required String shareToken,
    String? description,
    int? flashcardCount,
  }) async {
    final shareLink = generateCategoryShareLink(shareToken);

    final message = '''
📚 Bộ thẻ "$categoryName"

${description != null && description.isNotEmpty ? '📝 $description\n\n' : ''}${flashcardCount != null ? '🃏 $flashcardCount thẻ\n\n' : ''}🔗 Link học: $shareLink

---
Ứng dụng học tập Flai
''';

    try {
      await Share.share(
        message,
        subject: 'Chia sẻ bộ thẻ "$categoryName"',
      );
      print('✅ ShareLinkService: Category shared successfully');
    } catch (e) {
      print('❌ ShareLinkService: Error sharing category - $e');
      rethrow;
    }
  }

  // ==================== HELPER METHODS ====================

  /// Lấy share message cho class (không share ngay)
  static String getClassShareMessage({
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

  /// Lấy share message cho category (không share ngay)
  static String getCategoryShareMessage({
    required String categoryName,
    required String shareToken,
    String? description,
    int? flashcardCount,
  }) {
    final shareLink = generateCategoryShareLink(shareToken);

    return '''
📚 Bộ thẻ "$categoryName"

${description != null && description.isNotEmpty ? '📝 $description\n\n' : ''}${flashcardCount != null ? '🃏 $flashcardCount thẻ\n\n' : ''}🔗 Link học: $shareLink
''';
  }

  /// Lấy chỉ link class (không có message)
  static String getClassLink(String inviteCode) {
    return generateClassShareLink(inviteCode);
  }

  /// Lấy chỉ link category (không có message)
  static String getCategoryLink(String shareToken) {
    return generateCategoryShareLink(shareToken);
  }

  /// Copy link vào clipboard
  static Future<void> copyToClipboard(String text) async {
    // Import clipboard if needed
    // await Clipboard.setData(ClipboardData(text: text));
    print('📋 Copied to clipboard: $text');
  }
}