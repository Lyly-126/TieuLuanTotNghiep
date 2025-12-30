import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// API Configuration - Quản lý tập trung tất cả API URLs
///
/// Cách sử dụng:
/// 1. Trong development: Chỉnh sửa _developmentHost
/// 2. Trong production: Set ApiConfig.setProductionMode(true) và chỉnh sửa _productionHost
/// 3. Khi dùng ngrok: Set ApiConfig.setNgrokUrl('https://your-ngrok-url.ngrok-free.app')
class ApiConfig {
  // ==================== CONFIGURATION ====================

  /// Base host cho development (localhost)
  static const String _developmentHost = 'http://localhost:8080';

  /// Base host cho production (domain thật của bạn)
  static const String _productionHost = 'https://your-production-domain.com';

  /// Ngrok URL (dùng khi test trên thiết bị thật)
  static String? _ngrokUrl;

  /// Production mode flag
  static bool _isProduction = false;

  // ==================== GETTERS ====================

  /// Lấy base URL phù hợp với môi trường hiện tại
  static String get baseUrl {
    // Ưu tiên 1: Ngrok (nếu đã set)
    if (_ngrokUrl != null && _ngrokUrl!.isNotEmpty) {
      return _ngrokUrl!;
    }

    // Ưu tiên 2: Production mode
    if (_isProduction) {
      return _productionHost;
    }

    // Ưu tiên 3: Development mode
    // Android emulator: 10.0.2.2
    // iOS simulator & Web: localhost
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }

    return _developmentHost;
  }

  // ==================== API ENDPOINTS ====================

  /// Auth endpoints
  static String get authBase => '$baseUrl/api/users';
  static String get authLogin => '$authBase/login';
  static String get authRegister => '$authBase/register';
  static String get authForgotPassword => '$authBase/forgot-password';
  static String get authResetPassword => '$authBase/reset-password';
  static String get authVerifyOtp => '$authBase/verify-otp';
  static String get authResendOtp => '$authBase/resend-otp';

  /// User endpoints
  static String get userBase => '$baseUrl/api/users';
  static String get userProfile => '$userBase/profile';
  static String get userChangePassword => '$userBase/change-password';
  static String get userUpdate => '$userBase/update';
  static String get userDelete => '$userBase/delete';

  /// Class endpoints
  static String get classBase => '$baseUrl/api/classes';
  static String get classMyClasses => '$classBase/my-classes';
  static String get classJoined => '$classBase/joined';
  static String get classPublic => '$classBase/public';
  static String get classSearch => '$classBase/search';
  static String get classCreate => '$classBase/create';
  static String get classJoin => '$classBase/join';

  /// Category endpoints
  static String get categoryBase => '$baseUrl/api/categories';

  /// Flashcard endpoints
  static String get flashcardBase => '$baseUrl/api/flashcards';
  static String get flashcardRandom => '$flashcardBase/random';
  static String get flashcardSearch => '$flashcardBase/search';

  /// AI Flashcard endpoints (cũ - giữ lại để tương thích)
  static String get aiFlashcardBase => '$baseUrl/api/flashcards/ai';
  static String get aiFlashcardGenerate => '$aiFlashcardBase/generate';
  static String get aiFlashcardGenerateWithImage => '$aiFlashcardBase/generate-with-image';

  // ==================== NEW: FLASHCARD CREATION ENDPOINTS ====================

  /// Dictionary endpoints - Tra từ điển offline
  static String get dictionaryBase => '$baseUrl/api/dictionary';
  static String get dictionaryLookup => '$dictionaryBase/lookup';
  static String get dictionarySuggest => '$dictionaryBase/suggest';
  static String get dictionarySearch => '$dictionaryBase/search';
  static String get dictionaryExists => '$dictionaryBase/exists';
  static String get dictionaryStats => '$dictionaryBase/stats';
  static String get dictionaryBatchLookup => '$dictionaryBase/batch-lookup';

  /// Image Suggestion endpoints - Gợi ý hình ảnh từ Pexels
  static String get imageBase => '$baseUrl/api/images';
  static String get imageSuggest => '$imageBase/suggest';
  static String get imageStatus => '$imageBase/status';

  /// Category Suggestion endpoints - AI gợi ý category
  static String get categorySuggest => '$categoryBase/suggest';

  /// Flashcard Creation endpoints - Flow tạo flashcard mới
  static String get flashcardCreationBase => '$baseUrl/api/flashcard-creation';
  static String get flashcardCreationPreview => '$flashcardCreationBase/preview';
  static String get flashcardCreationSuggestCategory => '$flashcardCreationBase/suggest-category';
  static String get flashcardCreationCreate => '$flashcardCreationBase/create';
  static String get flashcardCreationBatch => '$flashcardCreationBase/batch';
  static String get flashcardCreationBatchPreview => '$flashcardCreationBase/batch-preview';

  // ==================== END NEW ENDPOINTS ====================

  /// Payment endpoints
  static String get paymentBase => '$baseUrl/api/payment';
  static String get paymentVnpay => '$paymentBase/vnpay';
  static String get paymentVnpayReturn => '$paymentVnpay/return';

  /// Study Pack endpoints
  static String get studyPackBase => '$baseUrl/api/study-packs';

  /// Policy endpoints
  static String get policyBase => '$baseUrl/api/policies';

  /// TTS endpoints
  static String get ttsBase => '$baseUrl/api/tts';
  static String get ttsSynthesize => '$ttsBase/synthesize';

  /// Admin endpoints
  static String get adminBase => '$baseUrl/api/admin';
  static String get adminUsers => '$userBase/admin';
  static String get adminPolicies => '$policyBase/admin';
  static String get adminStudyPacks => '$studyPackBase/admin';

  // ==================== SETTER METHODS ====================

  /// Set ngrok URL để test trên thiết bị thật
  ///
  /// Ví dụ:
  /// ```dart
  /// ApiConfig.setNgrokUrl('https://abc123.ngrok-free.app');
  /// ```
  static void setNgrokUrl(String url) {
    // Remove trailing slash nếu có
    _ngrokUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    print('🔧 ApiConfig: Ngrok URL set to $_ngrokUrl');
  }

  /// Clear ngrok URL (quay về localhost)
  static void clearNgrokUrl() {
    _ngrokUrl = null;
    print('🔧 ApiConfig: Ngrok URL cleared, using default');
  }

  /// Bật production mode
  static void setProductionMode(bool isProduction) {
    _isProduction = isProduction;
    print('🔧 ApiConfig: Production mode: $isProduction');
  }

  // ==================== HELPER METHODS ====================

  /// Kiểm tra xem có đang dùng ngrok không
  static bool get isUsingNgrok => _ngrokUrl != null && _ngrokUrl!.isNotEmpty;

  /// Kiểm tra xem có đang ở production mode không
  static bool get isProduction => _isProduction;

  /// Lấy thông tin môi trường hiện tại
  static String get environmentInfo {
    if (isUsingNgrok) {
      return 'Ngrok: $_ngrokUrl';
    } else if (isProduction) {
      return 'Production: $_productionHost';
    } else {
      return 'Development: $baseUrl';
    }
  }

  /// Debug info
  static void printConfig() {
    print('╔════════════════════════════════════════════════════╗');
    print('║           API CONFIGURATION                         ║');
    print('╠════════════════════════════════════════════════════╣');
    print('║ Environment: $environmentInfo');
    print('║ Base URL: $baseUrl');
    print('║ Is Production: $isProduction');
    print('║ Is Using Ngrok: $isUsingNgrok');
    print('╚════════════════════════════════════════════════════╝');
  }

  // ==================== URL BUILDERS ====================

  /// Build URL cho class detail
  static String classDetail(int classId) => '$classBase/$classId';

  /// Build URL cho class update
  static String classUpdate(int classId) => '$classBase/$classId/update';

  /// Build URL cho class delete
  static String classDelete(int classId) => '$classBase/$classId/delete';

  /// Build URL cho class members
  static String classMembers(int classId) => '$classBase/$classId/members';

  /// Build URL cho pending members
  static String classPendingMembers(int classId) => '$classBase/$classId/members/pending';

  /// Build URL cho approve member
  static String classApproveMember(int classId, int userId) =>
      '$classBase/$classId/members/$userId/approve';

  /// Build URL cho reject member
  static String classRejectMember(int classId, int userId) =>
      '$classBase/$classId/members/$userId/reject';

  /// Build URL cho remove member
  static String classRemoveMember(int classId, int userId) =>
      '$classBase/$classId/members/$userId';

  /// Build URL cho regenerate invite code
  static String classRegenerateCode(int classId) =>
      '$classBase/$classId/regenerate-invite-code';

  /// Build URL cho leave class
  static String classLeave(int classId) => '$classBase/$classId/leave';

  /// Build URL cho check is member
  static String classIsMember(int classId) => '$classBase/$classId/is-member';

  /// Build URL cho class categories
  static String classCategories(int classId) =>
      '$baseUrl/api/categories/class/$classId';

  /// Build URL cho category detail
  static String categoryDetail(int categoryId) => '$categoryBase/$categoryId';
  static String categoryUpdate(int categoryId) => '$categoryBase/$categoryId';
  static String categoryDelete(int categoryId) => '$categoryBase/$categoryId';

  /// Build URL cho flashcard by category
  static String flashcardByCategory(int categoryId) =>
      '$flashcardBase/category/$categoryId';

  /// Build URL cho flashcard detail
  static String flashcardDetail(int flashcardId) => '$flashcardBase/$flashcardId';

  /// Build URL cho flashcard update
  static String flashcardUpdate(int flashcardId) => '$flashcardBase/$flashcardId/update';

  /// Build URL cho flashcard delete
  static String flashcardDelete(int flashcardId) => '$flashcardBase/$flashcardId/delete';

  /// Build URL cho user detail
  static String userDetail(int userId) => '$userBase/$userId';

  /// Build URL cho study pack detail
  static String studyPackDetail(int packId) => '$studyPackBase/$packId';

  /// Build URL cho policy detail
  static String policyDetail(int policyId) => '$policyBase/$policyId';

  // ==================== NEW URL BUILDERS ====================

  /// Build URL cho dictionary lookup với word
  static String dictionaryLookupWord(String word) => '$dictionaryLookup?word=$word';

  /// Build URL cho dictionary suggest với prefix
  static String dictionarySuggestPrefix(String prefix) => '$dictionarySuggest?prefix=$prefix';

  /// Build URL cho image suggest với word và count
  static String imageSuggestWord(String word, {int count = 5}) =>
      '$imageSuggest?word=$word&count=$count';

  /// Build URL cho flashcard creation preview với term
  static String flashcardCreationPreviewTerm(String term) =>
      '$flashcardCreationPreview?term=$term';
}