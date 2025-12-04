import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../models/category_model.dart';
import '../../models/class_model.dart';
import '../../models/flashcard_model.dart';
import '../../services/flash_card_service.dart';
import '../../widgets/custom_button.dart';

class ClassCategoryFlashcardsScreen extends StatefulWidget {
  final CategoryModel category;
  final ClassModel classModel;

  const ClassCategoryFlashcardsScreen({
    Key? key,
    required this.category,
    required this.classModel,
  }) : super(key: key);

  @override
  State<ClassCategoryFlashcardsScreen> createState() =>
      _ClassCategoryFlashcardsScreenState();
}

class _ClassCategoryFlashcardsScreenState
    extends State<ClassCategoryFlashcardsScreen> {
  List<FlashcardModel> _flashcards = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadFlashcards();
  }

  /// Load flashcards của category
  Future<void> _loadFlashcards() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final flashcards =
      await FlashcardService.getFlashcardsByCategory(widget.category.id);
      setState(() {
        _flashcards = flashcards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Hiển thị dialog tạo flashcard mới
  void _showCreateFlashcardDialog() {
    final frontController = TextEditingController();
    final backController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.5),
        ),
        title: Text(
          'Tạo thẻ mới',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.primaryDark,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: frontController,
                decoration: InputDecoration(
                  labelText: 'Mặt trước *',
                  hintText: 'VD: Hello',
                  labelStyle: AppTextStyles.label,
                  hintStyle: AppTextStyles.hint,
                  border: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(AppConstants.borderRadius),
                    borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: backController,
                decoration: InputDecoration(
                  labelText: 'Mặt sau *',
                  hintText: 'VD: Xin chào',
                  labelStyle: AppTextStyles.label,
                  hintStyle: AppTextStyles.hint,
                  border: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(AppConstants.borderRadius),
                    borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          CustomButton(
            text: 'Tạo',
            width: 100,
            height: 40,
            onPressed: () async {
              if (frontController.text.trim().isEmpty ||
                  backController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚠️ Vui lòng nhập đầy đủ thông tin'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }

              try {
                await FlashcardService.createFlashcard(
                  term: frontController.text.trim(),     // ← ĐỔI TỪ question
                  meaning: backController.text.trim(),   // ← ĐỔI TỪ answer
                  categoryId: widget.category.id,
                );

                Navigator.pop(context);
                _loadFlashcards();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Tạo thẻ thành công'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// Hiển thị dialog sửa flashcard
  void _showEditFlashcardDialog(FlashcardModel flashcard) {
    final frontController = TextEditingController(text: flashcard.question); // ✅ Fixed
    final backController = TextEditingController(text: flashcard.answer);    // ✅ Fixed

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.5),
        ),
        title: Text(
          'Sửa thẻ',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.primaryDark,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: frontController,
                decoration: InputDecoration(
                  labelText: 'Mặt trước *',
                  labelStyle: AppTextStyles.label,
                  border: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(AppConstants.borderRadius),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: backController,
                decoration: InputDecoration(
                  labelText: 'Mặt sau *',
                  labelStyle: AppTextStyles.label,
                  border: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(AppConstants.borderRadius),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          CustomButton(
            text: 'Lưu',
            width: 100,
            height: 40,
            onPressed: () async {
              try {
                await FlashcardService.updateFlashcard(
                  flashcard.id,                          // ← Positional parameter
                  term: frontController.text.trim(),     // ← ĐỔI TỪ question
                  meaning: backController.text.trim(),   // ← ĐỔI TỪ answer
                );

                Navigator.pop(context);
                _loadFlashcards();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Cập nhật thành công'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// Xóa flashcard
  Future<void> _deleteFlashcard(FlashcardModel flashcard) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.5),
        ),
        title: Text(
          'Xác nhận xóa',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.primaryDark,
          ),
        ),
        content: Text(
          'Bạn có chắc muốn xóa thẻ này?',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Hủy',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          CustomButton(
            text: 'Xóa',
            backgroundColor: AppColors.error,
            width: 100,
            height: 40,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FlashcardService.deleteFlashcard(flashcard.id);
        _loadFlashcards();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã xóa thẻ'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header với gradient
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.7),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // AppBar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 22),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            widget.classModel.name,
                            style: AppTextStyles.label.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.style_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.category.name,
                                style: AppTextStyles.heading2.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_flashcards.length} thẻ học',
                                style: AppTextStyles.hint.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ✅ Fixed: Kiểm tra description có tồn tại không
                  if (widget.category.description != null &&
                      widget.category.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        widget.category.description!,
                        style: AppTextStyles.hint.copyWith(
                          color: Colors.white.withOpacity(0.85),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
                : _errorMessage.isNotEmpty
                ? Center(
              child: Padding(
                padding: AppConstants.screenPadding,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 80,
                      color: AppColors.error.withOpacity(0.5),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Không thể tải danh sách thẻ',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.hint.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Thử lại',
                      onPressed: _loadFlashcards,
                      width: 200,
                      icon: Icons.refresh_rounded,
                    ),
                  ],
                ),
              ),
            )
                : _flashcards.isEmpty
                ? Center(
              child: Padding(
                padding: AppConstants.screenPadding,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.style_outlined,
                        size: 60,
                        color: AppColors.primary.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Chưa có thẻ nào',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tạo thẻ đầu tiên để bắt đầu\nhọc tập với chủ đề này',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.hint.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: 'Tạo thẻ đầu tiên',
                      onPressed: _showCreateFlashcardDialog,
                      icon: Icons.add_rounded,
                    ),
                  ],
                ),
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadFlashcards,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _flashcards.length,
                itemBuilder: (context, index) {
                  final flashcard = _flashcards[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: AppTextStyles.label.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        flashcard.question, // ✅ Fixed: Đổi từ front
                        style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: PopupMenuButton(
                        icon: const Icon(Icons.more_vert_rounded),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppConstants.borderRadius),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined,
                                    size: 20,
                                    color: AppColors.primary),
                                const SizedBox(width: 12),
                                Text(
                                  'Sửa',
                                  style: AppTextStyles.label,
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outlined,
                                    size: 20,
                                    color: AppColors.error),
                                const SizedBox(width: 12),
                                Text(
                                  'Xóa',
                                  style: AppTextStyles.label
                                      .copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditFlashcardDialog(flashcard);
                          } else if (value == 'delete') {
                            _deleteFlashcard(flashcard);
                          }
                        },
                      ),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.inputBackground,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(
                                  AppConstants.borderRadius),
                              bottomRight: Radius.circular(
                                  AppConstants.borderRadius),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mặt sau:',
                                style: AppTextStyles.hint.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                flashcard.answer, // ✅ Fixed: Đổi từ back
                                style: AppTextStyles.body,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: !_isLoading && _flashcards.isNotEmpty
          ? FloatingActionButton(
        onPressed: _showCreateFlashcardDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, size: 28),
      )
          : null,
    );
  }
}