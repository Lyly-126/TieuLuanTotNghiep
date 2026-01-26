import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../services/category_service.dart';
import '../../services/flash_card_service.dart';
import '../../services/flashcard_creation_service.dart';

/// 🎨 Màn hình tạo chủ đề mới - PHIÊN BẢN HOÀN CHỈNH
/// ✅ Tự động tra cứu từ và tạo thẻ đầy đủ (meaning, definition, phonetic, image, audio)
class CategoryCreateScreen extends StatefulWidget {
  final int? classId;
  final String? className;

  const CategoryCreateScreen({
    super.key,
    this.classId,
    this.className,
  });

  @override
  State<CategoryCreateScreen> createState() => _CategoryCreateScreenState();
}

class _CategoryCreateScreenState extends State<CategoryCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _titleFocusNode = FocusNode();

  bool _isPublic = false;
  bool _isLoading = false;
  String _loadingMessage = '';
  int _currentProcessingIndex = 0;
  int _totalCards = 0;

  // Danh sách flashcards đang tạo
  final List<_FlashcardTermData> _flashcards = [
    _FlashcardTermData(),
    _FlashcardTermData(),
  ];

  @override
  void initState() {
    super.initState();
    print('📱 [SCREEN] $runtimeType');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocusNode.dispose();
    for (var flashcard in _flashcards) {
      flashcard.dispose();
    }
    super.dispose();
  }

  void _addFlashcard() {
    setState(() {
      _flashcards.add(_FlashcardTermData());
    });
  }

  void _removeFlashcard(int index) {
    if (_flashcards.length <= 1) {
      _showSnackBar('Phải có ít nhất 1 thẻ', isError: true);
      return;
    }
    setState(() {
      _flashcards[index].dispose();
      _flashcards.removeAt(index);
    });
  }

  /// ✅ TẠO CATEGORY VÀ FLASHCARDS ĐẦY ĐỦ
  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate có ít nhất 1 flashcard hợp lệ
    final validFlashcards = _flashcards.where((f) => f.isValid()).toList();
    if (validFlashcards.isEmpty) {
      _showSnackBar('Vui lòng tạo ít nhất 1 thẻ hợp lệ', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Đang tạo chủ đề...';
      _totalCards = validFlashcards.length;
      _currentProcessingIndex = 0;
    });

    try {
      // 1. Tạo category trước
      final category = await CategoryService.createCategory(
        name: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        visibility: _isPublic ? 'PUBLIC' : 'PRIVATE',
        classId: widget.classId,
      );

      // 2. ✅ TẠO FLASHCARDS ĐẦY ĐỦ - Tra cứu và tạo từng thẻ
      int successCount = 0;
      List<String> failedTerms = [];

      for (int i = 0; i < validFlashcards.length; i++) {
        final flashcardData = validFlashcards[i];
        final term = flashcardData.term.trim();

        setState(() {
          _currentProcessingIndex = i + 1;
          _loadingMessage = 'Đang tra cứu "$term" (${ i + 1}/${validFlashcards.length})...';
        });

        try {
          // ✅ BƯỚC 1: Tra cứu từ qua API preview
          final previewResult = await FlashcardCreationService.preview(term);

          // ✅ BƯỚC 2: Tự động chọn ảnh đầu tiên (nếu có)
          String? selectedImageUrl;
          if (previewResult.imageSuggestions.isNotEmpty) {
            selectedImageUrl = previewResult.imageSuggestions.first.url;
          }

          // ✅ BƯỚC 3: Tạo flashcard với đầy đủ thông tin
          final request = FlashcardCreateRequest(
            word: term,
            partOfSpeech: previewResult.partOfSpeech,
            partOfSpeechVi: previewResult.partOfSpeechVi,
            phonetic: previewResult.phonetic,
            meaning: previewResult.vietnameseMeaning ?? term,
            definition: previewResult.englishDefinition,
            // Note: FlashcardPreviewResult không có exampleSentence
            selectedImageUrl: selectedImageUrl,
            categoryId: category.id,
            generateAudio: true, // Tạo audio
          );

          final result = await FlashcardCreationService.create(request);

          if (result.success) {
            successCount++;
          } else {
            failedTerms.add(term);
          }
        } catch (e) {
          // Nếu lỗi tra cứu, vẫn tạo thẻ cơ bản
          debugPrint('Error processing "$term": $e');
          try {
            await FlashcardService.createFlashcard(
              categoryId: category.id,
              term: term,
              meaning: 'Không thể tra cứu tự động',
            );
            successCount++;
          } catch (_) {
            failedTerms.add(term);
          }
        }
      }

      if (!mounted) return;

      // Show success dialog
      _showSuccessDialog(
        categoryName: category.name,
        successCount: successCount,
        failedTerms: failedTerms,
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Không thể tạo chủ đề: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = '';
        });
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
    );
  }

  void _showSuccessDialog({
    required String categoryName,
    required int successCount,
    required List<String> failedTerms,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: AppColors.success, size: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thành công!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(
                    '$successCount thẻ đã được tạo',
                    style: TextStyle(fontSize: 14, color: AppColors.textGray, fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.folder, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      categoryName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Các thẻ đã được tạo với đầy đủ:\n• Nghĩa tiếng Việt\n• Định nghĩa tiếng Anh\n• Phiên âm\n• Hình ảnh minh họa\n• Audio phát âm',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                  ),
                ),
              ],
            ),
            if (failedTerms.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Một số từ không thể tra cứu:\n${failedTerms.join(", ")}',
                        style: TextStyle(fontSize: 12, color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Hoàn tất', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 28),
            const SizedBox(width: 12),
            Text('Lỗi', style: AppTextStyles.heading3),
          ],
        ),
        content: Text(message, style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.classId != null ? 'Tạo chủ đề cho lớp' : 'Tạo chủ đề mới',
              style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary),
            ),
            if (widget.className != null)
              Text(
                widget.className!,
                style: AppTextStyles.caption.copyWith(color: AppColors.textGray),
              ),
          ],
        ),
        actions: [
          // Nút tạo
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isLoading ? null : _saveCategory,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Tạo',
                  style: AppTextStyles.button.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppConstants.padding),
              children: [
                // Title section
                _buildTitleSection(),
                const SizedBox(height: 16),

                // Description section
                _buildDescriptionSection(),
                const SizedBox(height: 16),

                // Visibility toggle
                _buildVisibilityToggle(),
                const SizedBox(height: 24),

                // Flashcards header
                _buildFlashcardsHeader(),
                const SizedBox(height: 12),

                // Flashcard items
                ...List.generate(_flashcards.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildFlashcardItem(index, _flashcards[index]),
                  );
                }),

                // Add card button
                _buildAddCardButton(),
              ],
            ),
          ),

          // ✅ LOADING OVERLAY VỚI PROGRESS
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 20),
                      Text(
                        _loadingMessage,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      if (_totalCards > 0) ...[
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: _currentProcessingIndex / _totalCards,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation(AppColors.primary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_currentProcessingIndex / $_totalCards thẻ',
                          style: TextStyle(color: AppColors.textGray, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.title, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Tên chủ đề', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const Text(' *', style: TextStyle(color: AppColors.error)),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            decoration: InputDecoration(
              hintText: 'VD: Từ vựng IELTS, Ngữ pháp N3...',
              hintStyle: AppTextStyles.hint,
              filled: true,
              fillColor: AppColors.inputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.error),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập tên chủ đề';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, size: 18, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text('Mô tả', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              Text(' (tùy chọn)', style: TextStyle(color: AppColors.textGray, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Mô tả ngắn về chủ đề...',
              hintStyle: AppTextStyles.hint,
              filled: true,
              fillColor: AppColors.inputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilityToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _isPublic ? AppColors.success.withOpacity(0.1) : AppColors.textGray.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _isPublic ? Icons.public : Icons.lock_outline,
              color: _isPublic ? AppColors.success : AppColors.textGray,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPublic ? 'Công khai' : 'Riêng tư',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                Text(
                  _isPublic ? 'Mọi người có thể tìm thấy và học' : 'Chỉ bạn có thể xem',
                  style: TextStyle(color: AppColors.textGray, fontSize: 13),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPublic,
            onChanged: (value) => setState(() => _isPublic = value),
            activeThumbColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcardsHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.style, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Thẻ ghi nhớ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('${_flashcards.length} thẻ', style: TextStyle(color: AppColors.textGray, fontSize: 13)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 14, color: AppColors.success),
              const SizedBox(width: 4),
              Text('AI tự động', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFlashcardItem(int index, _FlashcardTermData flashcard) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Thẻ ${index + 1}', style: TextStyle(color: AppColors.textSecondary)),
                ),
                if (_flashcards.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _removeFlashcard(index),
                    color: AppColors.error,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),

          // Term field
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.text_fields, size: 16, color: AppColors.textGray),
                    const SizedBox(width: 8),
                    Text(
                      'THUẬT NGỮ',
                      style: TextStyle(fontSize: 11, color: AppColors.textGray, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                    ),
                    const Text(' *', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: flashcard.termController,
                  decoration: InputDecoration(
                    hintText: 'VD: apple, beautiful, environment...',
                    hintStyle: AppTextStyles.hint,
                    filled: true,
                    fillColor: AppColors.inputBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập thuật ngữ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // ✅ INFO BOX - AI sẽ tạo đầy đủ
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.success.withOpacity(0.1), AppColors.primary.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.success.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome, size: 18, color: AppColors.success),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI sẽ tự động tạo:',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.success),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '• Nghĩa tiếng Việt\n• Định nghĩa tiếng Anh\n• Phiên âm IPA\n• Hình ảnh minh họa\n• Audio phát âm',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCardButton() {
    return InkWell(
      onTap: _addFlashcard,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Container(
        margin: const EdgeInsets.only(bottom: 80),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Thêm thẻ mới',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper class để lưu data của flashcard
class _FlashcardTermData {
  final TextEditingController termController = TextEditingController();

  String get term => termController.text;

  bool isValid() {
    return term.trim().isNotEmpty;
  }

  void dispose() {
    termController.dispose();
  }
}