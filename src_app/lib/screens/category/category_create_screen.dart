import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../models/flashcard_model.dart';
import '../../services/category_service.dart';
import '../../services/flash_card_service.dart';

/// 🎨 Màn hình tạo chủ đề mới - PHIÊN BẢN HOÀN CHỈNH
/// ✅ Có mô tả, đồng bộ với style cũ
class CategoryCreateScreen extends StatefulWidget {
  final int? classId; // Optional: nếu tạo cho class cụ thể
  final String? className;

  const CategoryCreateScreen({
    Key? key,
    this.classId,
    this.className,
  }) : super(key: key);

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

  // Danh sách flashcards đang tạo (CHỈ CÓ TERM)
  final List<_FlashcardTermData> _flashcards = [
    _FlashcardTermData(), // Mặc định có 2 cards
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

  /// Thêm flashcard mới
  void _addFlashcard() {
    setState(() {
      _flashcards.add(_FlashcardTermData());
    });
    // Scroll to bottom sau khi thêm
    Future.delayed(const Duration(milliseconds: 100), () {
      // Scroll animation sẽ được handle bởi ListView
    });
  }

  /// Xóa flashcard
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

  /// Validate và lưu
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

    setState(() => _isLoading = true);

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

      // 2. Tạo flashcards (CHỈ CÓ TERM - meaning sẽ generate sau)
      for (var flashcardData in validFlashcards) {
        await FlashcardService.createFlashcard(
          categoryId: category.id,
          term: flashcardData.term.trim(),
          meaning: 'Đang chờ tạo tự động...', // Placeholder
        );
      }

      if (!mounted) return;

      // Show success dialog
      _showSuccessDialog(category.name, validFlashcards.length);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Không thể tạo chủ đề: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  void _showSuccessDialog(String categoryName, int cardCount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: AppColors.success, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Thành công!', style: AppTextStyles.heading3),
            ),
          ],
        ),
        content: Text(
          'Đã tạo chủ đề "$categoryName" với $cardCount thẻ.\n\nNghĩa của các thẻ sẽ được tạo tự động bằng AI.',
          style: AppTextStyles.body,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Return to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Hoàn tất'),
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.classId != null ? 'Tạo chủ đề cho lớp' : 'Tạo chủ đề mới',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            if (widget.className != null)
              Text(
                widget.className!,
                style: AppTextStyles.hint.copyWith(fontSize: 12),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveCategory,
            child: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Text(
              'Tạo',
              style: AppTextStyles.button.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Header with category info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  TextFormField(
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                    style: AppTextStyles.heading2,
                    decoration: InputDecoration(
                      hintText: 'Nhập tên chủ đề, VD: "IELTS Vocabulary"',
                      hintStyle: AppTextStyles.hint,
                      border: InputBorder.none,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên chủ đề';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: 'Thêm mô tả (tùy chọn)',
                      hintStyle: AppTextStyles.hint.copyWith(fontSize: 14),
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.description_outlined,
                        color: AppColors.textGray,
                        size: 20,
                      ),
                    ),
                    maxLines: 2,
                  ),

                  const SizedBox(height: 12),

                  // Visibility toggle
                  Row(
                    children: [
                      Icon(
                        _isPublic ? Icons.public : Icons.lock_outline,
                        size: 20,
                        color: AppColors.textGray,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isPublic ? 'Công khai' : 'Riêng tư',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textGray,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Tooltip(
                        message: _isPublic
                            ? 'Mọi người có thể xem chủ đề này'
                            : 'Chỉ bạn có thể xem chủ đề này',
                        child: Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.textGray,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _isPublic,
                        onChanged: (value) => setState(() => _isPublic = value),
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Instruction banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                border: Border.all(
                  color: AppColors.info.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.info,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Chỉ cần nhập thuật ngữ, nghĩa sẽ được AI tạo tự động',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Flashcards list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _flashcards.length + 1, // +1 for add button
                itemBuilder: (context, index) {
                  if (index == _flashcards.length) {
                    return _buildAddCardButton();
                  }
                  return _buildFlashcardItem(index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashcardItem(int index) {
    final flashcard = _flashcards[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppConstants.borderRadius),
                topRight: Radius.circular(AppConstants.borderRadius),
              ),
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
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Thẻ ${index + 1}',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                if (_flashcards.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _removeFlashcard(index),
                    color: AppColors.error,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Xóa thẻ',
                  ),
              ],
            ),
          ),

          // Term field ONLY
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.text_fields,
                      size: 16,
                      color: AppColors.textGray,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'THUẬT NGỮ',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 11,
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '*',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: flashcard.termController,
                  decoration: InputDecoration(
                    hintText: 'VD: Photosynthesis, Algorithm, Machine Learning...',
                    hintStyle: AppTextStyles.hint,
                    filled: true,
                    fillColor: AppColors.inputBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      borderSide: const BorderSide(color: AppColors.error),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập thuật ngữ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Nghĩa sẽ được tạo tự động bằng AI',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.success.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
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
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
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
              child: const Icon(
                Icons.add,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Thêm thẻ mới',
              style: AppTextStyles.button.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper class để lưu data của flashcard (CHỈ CÓ TERM)
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