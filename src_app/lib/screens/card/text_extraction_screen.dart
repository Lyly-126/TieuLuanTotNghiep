import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../services/text_extraction_service.dart';
import 'word_selection_screen.dart';

/// Màn hình chọn nguồn trích xuất từ vựng (OCR/PDF)
///
/// Flow:
/// 1. User chọn chụp ảnh/chọn ảnh từ thư viện/chọn PDF
/// 2. Upload và trích xuất từ vựng
/// 3. Chuyển sang WordSelectionScreen để chọn từ
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

  /// Chọn file PDF
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
        // Web: sử dụng bytes
        final bytes = await image.readAsBytes();
        result = await TextExtractionService.extractFromImageBytes(
          bytes,
          image.name,
        );
      } else {
        // Mobile: sử dụng file
        result = await TextExtractionService.extractFromImage(
          File(image.path),
        );
      }

      if (result.success && result.extractedWords.isNotEmpty) {
        _navigateToWordSelection(result);
      } else if (result.success && result.extractedWords.isEmpty) {
        _showError('Không tìm thấy từ vựng tiếng Anh trong ảnh');
      } else {
        _showError(result.message ?? 'Lỗi không xác định');
      }
    } catch (e) {
      _showError('Lỗi xử lý ảnh: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Xử lý PDF đã chọn
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

      if (result.success && result.extractedWords.isNotEmpty) {
        _navigateToWordSelection(result);
      } else if (result.success && result.extractedWords.isEmpty) {
        _showError('Không tìm thấy từ vựng tiếng Anh trong PDF');
      } else {
        _showError(result.message ?? 'Lỗi không xác định');
      }
    } catch (e) {
      _showError('Lỗi đọc PDF: $e');
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
            'OCR ảnh hoặc đọc PDF',
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
          // Animated loading indicator
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _loadingMessage,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
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
            // Header illustration
            _buildHeader(),
            const SizedBox(height: 32),

            // Error message
            if (_errorMessage != null) ...[
              _buildErrorCard(),
              const SizedBox(height: 24),
            ],

            // Options
            _buildOptionCard(
              icon: Icons.camera_alt_rounded,
              title: 'Chụp ảnh',
              subtitle: 'Chụp ảnh tài liệu, sách, bảng từ vựng',
              color: AppColors.primary,
              onTap: _captureImage,
            ),
            const SizedBox(height: 16),

            _buildOptionCard(
              icon: Icons.photo_library_rounded,
              title: 'Chọn từ thư viện',
              subtitle: 'Chọn ảnh có sẵn trong điện thoại',
              color: AppColors.success,
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.document_scanner_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tạo thẻ từ ảnh/PDF',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chụp ảnh hoặc chọn PDF để tự động nhận dạng từ vựng tiếng Anh',
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
                'Mẹo để có kết quả tốt nhất',
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
            icon: Icons.wb_sunny_outlined,
            text: 'Chụp ảnh ở nơi đủ ánh sáng',
          ),
          _buildTipItem(
            icon: Icons.crop_free,
            text: 'Đặt tài liệu thẳng, không bị nghiêng',
          ),
          _buildTipItem(
            icon: Icons.text_fields,
            text: 'Chữ trong ảnh phải rõ ràng, không bị mờ',
          ),
          _buildTipItem(
            icon: Icons.language,
            text: 'Hệ thống chỉ nhận dạng từ tiếng Anh',
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}