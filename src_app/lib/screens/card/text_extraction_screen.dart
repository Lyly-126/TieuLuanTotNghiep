import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/app_colors.dart';
import '../../services/text_extraction_service.dart';
import 'word_selection_screen.dart';
import 'vocabulary_input_screen.dart';

/// Màn hình chọn nguồn trích xuất từ vựng (OCR/PDF)
///
/// ✅ UPDATED v2:
/// - Thêm option "Nhập thủ công" - dùng grid 100 ô
/// - PDF export có marker để hệ thống nhận diện
/// - Giới hạn 100 từ
/// - UI đẹp hơn với flow rõ ràng
///
/// Flow mới:
/// 1. User có thể:
///    - Nhập thủ công qua grid → Xuất PDF → Quét trực tiếp
///    - Chụp ảnh → OCR
///    - Chọn ảnh từ thư viện → OCR
/// 2. Chuyển sang WordSelectionScreen để chọn từ
class TextExtractionScreen extends StatefulWidget {
  final int? initialCategoryId;
  final String? initialCategoryName;

  const TextExtractionScreen({
    super.key,
    this.initialCategoryId,
    this.initialCategoryName,
  });

  @override
  State<TextExtractionScreen> createState() => _TextExtractionScreenState();
}

class _TextExtractionScreenState extends State<TextExtractionScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  String? _errorMessage;
  String _loadingMessage = '';

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ==================== ACTIONS ====================

  /// Mở màn hình nhập từ thủ công
  Future<void> _openManualInput() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => VocabularyInputScreen(
          initialCategoryId: widget.initialCategoryId,
          initialCategoryName: widget.initialCategoryName,
        ),
      ),
    );

    // Nếu user chọn "Quét ngay" từ màn hình nhập
    if (result != null && result['words'] != null) {
      final words = result['words'] as List<String>;
      _processManualWords(words);
    }
  }

  Future<void> _processManualWords(List<String> words) async {
    if (words.isEmpty) {
      _showError('Không có từ vựng nào để tạo flashcard');
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Đang tra cứu từ điển...';
      _errorMessage = null;
    });

    try {
      // Gọi API để lookup từ điển cho tất cả từ
      final previewResult = await TextExtractionService.previewSelectedWords(words);

      if (previewResult.success && previewResult.words.isNotEmpty) {
        // Tạo TextExtractionResult từ kết quả preview (đã có nghĩa)
        final result = TextExtractionResult(
          success: true,
          message: 'Đã tra cứu ${previewResult.words.length} từ vựng',
          sourceType: 'MANUAL',
          extractedWords: previewResult.words,
          totalWordsFound: previewResult.words.length,
        );

        if (mounted) {
          setState(() => _isLoading = false);
          _navigateToWordSelection(result);
        }
      } else {
        // Fallback: Nếu API không trả về kết quả
        _fallbackManualWords(words);
      }
    } catch (e) {
      debugPrint('Error looking up words: $e');
      // Fallback: Nếu API lỗi
      _fallbackManualWords(words);
    }
  }

  /// Fallback khi API lookup lỗi - tạo từ không có nghĩa
  void _fallbackManualWords(List<String> words) {
    final extractedWords = words.map((word) => ExtractedWord(
      word: word.toLowerCase().trim(),
      foundInDictionary: false,
      selected: true,
    )).toList();

    final result = TextExtractionResult(
      success: true,
      message: 'Đã nhập ${words.length} từ vựng',
      sourceType: 'MANUAL',
      extractedWords: extractedWords,
      totalWordsFound: words.length,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      _navigateToWordSelection(result);
    }
  }

  /// Chụp ảnh từ camera
  Future<void> _captureImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 2000,
        maxHeight: 2000,
      );

      if (image != null) {
        await _processImage(image);
      }
    } catch (e) {
      _showError('Không thể mở camera: $e');
    }
  }

  /// Chọn ảnh từ thư viện
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2000,
        maxHeight: 2000,
      );

      if (image != null) {
        await _processImage(image);
      }
    } catch (e) {
      _showError('Không thể chọn ảnh: $e');
    }
  }

  Future<void> _pickPDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: kIsWeb, // Cần data cho web
      );

      if (result != null && result.files.isNotEmpty) {
        await _processPDF(result.files.first);
      }
    } catch (e) {
      _showError('Không thể chọn PDF: $e');
    }
  }

  Future<void> _processPDF(PlatformFile file) async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Đang đọc PDF...';
      _errorMessage = null;
    });

    try {
      TextExtractionResult result;

      if (kIsWeb && file.bytes != null) {
        // Web: sử dụng bytes
        result = await TextExtractionService.extractFromPDFBytes(
          file.bytes!,
          file.name,
        );
      } else if (file.path != null) {
        // Mobile: sử dụng file path
        result = await TextExtractionService.extractFromPDF(
          File(file.path!),
        );
      } else {
        throw Exception('Không thể đọc file PDF');
      }

      _handleExtractionResult(result);
    } catch (e) {
      _showError('Lỗi đọc PDF: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Xử lý kết quả extraction
  void _handleExtractionResult(TextExtractionResult result) {
    if (result.success && result.extractedWords.isNotEmpty) {
      _navigateToWordSelection(result);
    } else if (result.success && result.extractedWords.isEmpty) {
      _showError('Không tìm thấy từ vựng tiếng Anh');
    } else {
      // Hiển thị lỗi từ server (bao gồm lỗi PDF không hợp lệ, vượt limit)
      _showError(result.message ?? 'Lỗi không xác định');
    }
  }

  /// Xử lý ảnh đã chọn
  Future<void> _processImage(XFile image) async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Đang nhận dạng văn bản...';
      _errorMessage = null;
    });

    try {
      TextExtractionResult result;

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        result = await TextExtractionService.extractFromImageBytes(
          bytes,
          image.name,
        );
      } else {
        result = await TextExtractionService.extractFromImage(
          File(image.path),
        );
      }

      _handleExtractionResult(result);
    } catch (e) {
      _showError('Lỗi xử lý ảnh: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Chuyển sang màn hình chọn từ
  void _navigateToWordSelection(TextExtractionResult result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WordSelectionScreen(
          extractionResult: result,
          initialCategoryId: widget.initialCategoryId,
          initialCategoryName: widget.initialCategoryName,
        ),
      ),
    );
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoading() : _buildContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trích xuất từ vựng',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            'Tối đa 100 từ mỗi lần',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      centerTitle: false,
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _loadingMessage,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vui lòng đợi...',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 24),

            // Error card nếu có
            if (_errorMessage != null) ...[
              _buildErrorCard(),
              const SizedBox(height: 24),
            ],

            // ⭐ OPTION 1: Nhập thủ công (RECOMMENDED)
            _buildPrimaryOption(),

            const SizedBox(height: 20),

            // Divider với text
            Row(
              children: [
                Expanded(child: Divider(color: AppColors.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'HOẶC',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textGray,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: AppColors.border)),
              ],
            ),

            const SizedBox(height: 20),

            // Secondary options title
            Text(
              'Quét từ ảnh',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            // OPTION 2: Chụp ảnh
            _buildSecondaryOption(
              icon: Icons.camera_alt_rounded,
              title: 'Chụp ảnh',
              subtitle: 'Chụp ảnh tài liệu, sách, bảng từ vựng',
              color: AppColors.info,
              onTap: _captureImage,
            ),
            const SizedBox(height: 12),

            // OPTION 3: Chọn ảnh
            _buildSecondaryOption(
              icon: Icons.photo_library_rounded,
              title: 'Chọn từ thư viện',
              subtitle: 'Chọn ảnh có sẵn trong điện thoại',
              color: AppColors.secondary,
              onTap: _pickImage,
            ),
            const SizedBox(height: 16),

            _buildOptionCard(
              icon: Icons.picture_as_pdf_rounded,
              title: 'Đọc file PDF',
              subtitle: 'Trích xuất từ vựng từ tài liệu PDF',
              color: AppColors.warning,
              onTap: _pickPDF,
            ),
            const SizedBox(height: 32),
            // Tips
            _buildTipsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tạo Flashcard nhanh',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nhập từ vựng hoặc quét từ ảnh để tạo flashcard tự động',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: AppColors.error,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: AppColors.error, size: 20),
            onPressed: () => setState(() => _errorMessage = null),
          ),
        ],
      ),
    );
  }

  /// Option chính: Nhập thủ công
  Widget _buildPrimaryOption() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: AppColors.primary.withOpacity(0.2),
      child: InkWell(
        onTap: _openManualInput,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.grid_view_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Tạo PDF',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              // decoration: BoxDecoration(
                              //   color: AppColors.success,
                              //   borderRadius: BorderRadius.circular(10),
                              // ),
                              // child: const Text(
                              //   'Khuyên dùng',
                              //   style: TextStyle(
                              //     color: Colors.white,
                              //     fontSize: 10,
                              //     fontWeight: FontWeight.bold,
                              //   ),
                              // ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gõ từ vựng vào ô, hệ thống tự động tra nghĩa',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Features list
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildFeatureChip(Icons.grid_on, '100 ô nhập'),
                    _buildFeatureChip(Icons.picture_as_pdf, 'Xuất PDF'),
                    _buildFeatureChip(Icons.flash_on, 'Tạo nhanh'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  /// Options phụ: Chụp/Chọn ảnh
  Widget _buildSecondaryOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textGray,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textGray,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Mẹo sử dụng',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipItem(
            icon: Icons.keyboard,
            text: 'Dùng "Nhập từ vựng" để gõ nhanh và chính xác nhất',
            highlight: true,
          ),
          _buildTipItem(
            icon: Icons.format_list_numbered,
            text: 'Mỗi lần nhập tối đa 100 từ vựng',
          ),
          _buildTipItem(
            icon: Icons.wb_sunny_outlined,
            text: 'Nếu chụp ảnh, đảm bảo đủ ánh sáng và chữ rõ ràng',
          ),
          _buildTipItem(
            icon: Icons.wb_sunny_outlined,
            text: 'Nếu tải lên PDF, phải dùng mẫu có sẵn của Flai',
          ),
          _buildTipItem(
            icon: Icons.language,
            text: 'Hệ thống tự động tra nghĩa tiếng Việt',
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem({
    required IconData icon,
    required String text,
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: highlight ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: highlight ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
                fontWeight: highlight ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}