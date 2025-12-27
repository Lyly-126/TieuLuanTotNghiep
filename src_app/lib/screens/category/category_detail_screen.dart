import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math' as math;
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../models/category_model.dart';
import '../../models/flashcard_model.dart';
import '../../services/category_service.dart';
import '../../services/flash_card_service.dart';
import '../../services/tts_service.dart';
import '../card/flashcard_screen.dart';
import '../card/flashcard_creation_screen.dart';
import '../card/flashcard_edit_screen.dart';

/// 🎨 Màn hình chi tiết chủ đề - Unified Screen
/// Dùng chung cho tất cả: Category cá nhân, Category trong Class, Category public
///
/// PHÂN QUYỀN:
/// - isOwner = true: Thêm/Sửa/Xóa category + flashcard
/// - isOwner = false: Chỉ xem, học, kiểm tra, lưu
class CategoryDetailScreen extends StatefulWidget {
  final CategoryModel category;
  final bool isOwner; // ✅ THÊM: Phân quyền chủ sở hữu

  const CategoryDetailScreen({
    Key? key,
    required this.category,
    this.isOwner = false, // Mặc định là viewer
  }) : super(key: key);

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen>
    with TickerProviderStateMixin {
  // State
  bool _isLoading = true;
  bool _isSaved = false;
  List<FlashcardModel> _flashcards = [];
  String? _errorMessage;
  CategoryModel? _category; // ✅ SỬA: Bỏ late, dùng nullable

  // Animation
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  // Preview card
  int _previewIndex = 0;
  late PageController _previewController;

  /// ✅ CHECK QUYỀN EDIT - Chỉ owner mới được edit
  bool get _canEdit => widget.isOwner && !(_category?.isSystem ?? true);

  /// ✅ Helper getter để truy cập category an toàn
  CategoryModel get category => _category ?? widget.category;

  @override
  void initState() {
    super.initState();
    // ✅ KHỞI TẠO _category TRƯỚC
    _category = widget.category;
    _isSaved = widget.category.isSaved;

    // ✅ LOG ĐỂ DEBUG (sau khi khởi tạo)
    print('📱 [SCREEN] CategoryDetailScreen');
    print('   ├── Category: ${widget.category.name} (ID: ${widget.category.id})');
    print('   ├── isOwner: ${widget.isOwner}');
    print('   └── canEdit: $_canEdit');

    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeOut,
    );

    _previewController = PageController(viewportFraction: 0.85);
    _loadCategoryDetails();
  }

  @override
  void dispose() {
    _fabController.dispose();
    _previewController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoryDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final flashcards = await FlashcardService.getFlashcardsByCategory(_category!.id);

      if (!mounted) return;

      setState(() {
        _flashcards = flashcards;
        _isLoading = false;
      });

      _fabController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // ==================== ACTIONS ====================

  Future<void> _toggleSave() async {
    try {
      if (_isSaved) {
        await CategoryService.unsaveCategory(_category!.id);
        setState(() => _isSaved = false);
        _showSnackBar('Đã bỏ lưu học phần', Icons.bookmark_border);
      } else {
        await CategoryService.saveCategory(_category!.id);
        setState(() => _isSaved = true);
        _showSnackBar('Đã lưu học phần', Icons.bookmark);
      }
    } catch (e) {
      _showSnackBar('Không thể thực hiện: $e', Icons.error, isError: true);
    }
  }

  void _startStudy() {
    if (_flashcards.isEmpty) {
      _showSnackBar('Chưa có thẻ nào để học', Icons.warning, isError: true);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardScreen(categoryId: _category!.id),
      ),
    );
  }

  void _startQuiz() {
    if (_flashcards.isEmpty) {
      _showSnackBar('Chưa có thẻ nào để kiểm tra', Icons.warning, isError: true);
      return;
    }
    // TODO: Navigate to Quiz screen
    _showSnackBar('Tính năng kiểm tra đang phát triển', Icons.quiz);
  }

  Future<void> _shareCategory() async {
    final shareUrl = 'https://flashlearn.vn/set/${_category!.id}';
    await Share.share(
      '📚 ${_category!.name}\n${_flashcards.length} thuật ngữ\n\nHọc cùng tôi trên FlashLearn!\n$shareUrl',
      subject: _category!.name,
    );
  }

  // ==================== OWNER ACTIONS (Chỉ hiển thị khi _canEdit = true) ====================

  void _addFlashcard() {
    if (!_canEdit) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardCreationScreen(categoryId: _category!.id),
      ),
    ).then((created) {
      if (created == true) _loadCategoryDetails();
    });
  }

  void _editFlashcard(FlashcardModel flashcard) {
    if (!_canEdit) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardEditScreen(
          flashcard: flashcard,
          categoryId: _category!.id, // ✅ THÊM DÒNG NÀY
        ),
      ),
    ).then((updated) {
      if (updated == true) _loadCategoryDetails();
    });
  }

  Future<void> _deleteFlashcard(FlashcardModel flashcard) async {
    if (!_canEdit) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            const Text('Xóa thẻ?'),
          ],
        ),
        content: Text(
          'Bạn có chắc muốn xóa thẻ "${flashcard.question}"?',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FlashcardService.deleteFlashcard(flashcard.id);
        _loadCategoryDetails();
        _showSnackBar('Đã xóa thẻ', Icons.check_circle);
      } catch (e) {
        _showSnackBar('Lỗi: $e', Icons.error, isError: true);
      }
    }
  }

  void _showEditCategoryDialog() {
    if (!_canEdit) return;

    final nameController = TextEditingController(text: _category!.name);
    final descController = TextEditingController(text: _category!.description ?? '');
    String visibility = _category!.visibility ?? 'PRIVATE';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Chỉnh sửa học phần',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Name field
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên học phần',
                    hintText: 'VD: Từ vựng IELTS',
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
                  ),
                ),
                const SizedBox(height: 16),

                // Description field
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Mô tả (tùy chọn)',
                    hintText: 'Thêm mô tả cho học phần...',
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
                  ),
                ),
                const SizedBox(height: 20),

                // Visibility toggle
                const Text(
                  'Quyền riêng tư',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildVisibilityOption(
                        icon: Icons.lock_outline,
                        label: 'Riêng tư',
                        description: 'Chỉ mình tôi',
                        isSelected: visibility == 'PRIVATE',
                        onTap: () => setModalState(() => visibility = 'PRIVATE'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildVisibilityOption(
                        icon: Icons.public,
                        label: 'Công khai',
                        description: 'Mọi người',
                        isSelected: visibility == 'PUBLIC',
                        onTap: () => setModalState(() => visibility = 'PUBLIC'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) {
                        _showSnackBar('Vui lòng nhập tên học phần', Icons.warning, isError: true);
                        return;
                      }

                      Navigator.pop(context);
                      await _updateCategory(
                        nameController.text.trim(),
                        descController.text.trim(),
                        visibility,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Lưu thay đổi',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisibilityOption({
    required IconData icon,
    required String label,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textGray,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateCategory(String name, String description, String visibility) async {
    try {
      _showLoadingDialog();

      final updated = await CategoryService.updateCategory(
        categoryId: _category!.id,
        name: name,
        description: description.isEmpty ? null : description,
        visibility: visibility,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      setState(() {
        _category = updated;
      });

      _showSnackBar('Đã cập nhật học phần', Icons.check_circle);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      _showSnackBar('Lỗi: $e', Icons.error, isError: true);
    }
  }

  void _showDeleteCategoryConfirmation() {
    if (!_canEdit) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            const Text('Xóa học phần?'),
          ],
        ),
        content: Text(
          'Bạn có chắc muốn xóa "${_category!.name}"?\n\nTất cả ${_flashcards.length} thẻ sẽ bị xóa vĩnh viễn.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCategory();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory() async {
    try {
      _showLoadingDialog();
      await CategoryService.deleteCategory(_category!.id);

      if (!mounted) return;
      Navigator.pop(context); // Close loading
      Navigator.pop(context, true); // Return to previous screen

      _showSnackBar('Đã xóa học phần', Icons.check_circle);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      _showSnackBar('Lỗi: $e', Icons.error, isError: true);
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  void _showSnackBar(String message, IconData icon, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ==================== BUILD UI ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
          ? _buildErrorState()
          : _buildContent(),
      // ✅ FAB chỉ hiện khi _canEdit = true
      floatingActionButton: _canEdit && !_isLoading && _errorMessage == null
          ? ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: _addFlashcard,
          backgroundColor: AppColors.primary,
          elevation: 4,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Thêm thẻ', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      )
          : null,
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Đang tải học phần...',
            style: TextStyle(color: AppColors.textGray),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            ),
            const SizedBox(height: 24),
            const Text(
              'Đã có lỗi xảy ra',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(color: AppColors.textGray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCategoryDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(),
        SliverToBoxAdapter(child: _buildOwnerBadge()), // ✅ Badge hiển thị quyền
        SliverToBoxAdapter(child: _buildPreviewCards()),
        SliverToBoxAdapter(child: _buildActionButtons()),
        SliverToBoxAdapter(child: _buildStudyModes()),
        SliverToBoxAdapter(child: _buildFlashcardSection()),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  /// ✅ BADGE HIỂN THỊ QUYỀN (Owner/Viewer)
  Widget _buildOwnerBadge() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _canEdit
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _canEdit ? AppColors.success : AppColors.secondary,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _canEdit ? Icons.edit : Icons.visibility,
                  size: 16,
                  color: _canEdit ? AppColors.success : AppColors.secondary,
                ),
                const SizedBox(width: 6),
                Text(
                  _canEdit ? 'Chủ sở hữu' : 'Chế độ xem',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _canEdit ? AppColors.success : AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!_canEdit)
            Text(
              'Bạn chỉ có thể xem và học',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textGray,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // Save button - AI AI CŨNG CÓ THỂ LƯU
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: Colors.white,
              size: 20,
            ),
          ),
          onPressed: _toggleSave,
        ),
        // Share button - AI AI CŨNG CÓ THỂ SHARE
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share, color: Colors.white, size: 20),
          ),
          onPressed: _shareCategory,
        ),
        // ✅ More options - CHỈ OWNER MỚI THẤY
        if (_canEdit)
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _showEditCategoryDialog();
                  break;
                case 'delete':
                  _showDeleteCategoryConfirmation();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                    SizedBox(width: 12),
                    Text('Chỉnh sửa'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppColors.error),
                    SizedBox(width: 12),
                    Text('Xóa học phần', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.85),
                AppColors.accent,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Visibility badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _category!.isPublic ? Icons.public : Icons.lock_outline,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _category!.isPublic ? 'Công khai' : 'Riêng tư',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    _category!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_category!.description != null && _category!.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _category!.description!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCards() {
    if (_flashcards.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 200,
      margin: const EdgeInsets.only(top: 20),
      child: PageView.builder(
        controller: _previewController,
        itemCount: math.min(_flashcards.length, 5),
        onPageChanged: (index) => setState(() => _previewIndex = index),
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _previewController,
            builder: (context, child) {
              double value = 1.0;
              if (_previewController.position.haveDimensions) {
                value = _previewController.page! - index;
                value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
              }
              return Center(
                child: Transform.scale(
                  scale: value,
                  child: _buildPreviewCard(_flashcards[index], index),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPreviewCard(FlashcardModel card, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _startStudy,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    card.question,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 2,
                    width: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    card.answer,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        children: [
          // Stats card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.style, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_flashcards.length}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      Text(
                        'thuật ngữ',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Type badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  _category!.isClassCategory
                      ? Icons.school_outlined
                      : _category!.isSystem
                      ? Icons.public
                      : Icons.person_outline,
                  color: AppColors.secondary,
                  size: 28,
                ),
                const SizedBox(height: 4),
                Text(
                  _category!.isClassCategory
                      ? 'Lớp học'
                      : _category!.isSystem
                      ? 'Hệ thống'
                      : 'Cá nhân',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyModes() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chế độ học',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStudyModeCard(
                  icon: Icons.style_outlined,
                  label: 'Thẻ ghi nhớ',
                  color: AppColors.primary,
                  onTap: _startStudy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStudyModeCard(
                  icon: Icons.quiz_outlined,
                  label: 'Kiểm tra',
                  color: AppColors.secondary,
                  onTap: _startQuiz,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStudyModeCard(
                  icon: Icons.edit_note,
                  label: 'Ghi nhớ',
                  color: AppColors.warning,
                  onTap: () => _showSnackBar('Đang phát triển', Icons.construction),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStudyModeCard(
                  icon: Icons.sports_esports_outlined,
                  label: 'Ghép thẻ',
                  color: AppColors.error,
                  onTap: () => _showSnackBar('Đang phát triển', Icons.construction),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudyModeCard({
    required IconData icon,
    required String label,
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
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlashcardSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thuật ngữ trong học phần',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              Text(
                '${_flashcards.length} thẻ',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_flashcards.isEmpty)
            _buildEmptyFlashcards()
          else
            ..._flashcards.asMap().entries.map((entry) =>
                _buildFlashcardItem(entry.value, entry.key)
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyFlashcards() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.style_outlined, size: 48, color: AppColors.textGray),
          ),
          const SizedBox(height: 20),
          const Text(
            'Chưa có thẻ nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _canEdit
                ? 'Thêm thẻ đầu tiên để bắt đầu học'
                : 'Học phần này chưa có thẻ nào',
            style: TextStyle(color: AppColors.textGray),
          ),
          // ✅ Chỉ owner mới thấy nút thêm
          if (_canEdit) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _addFlashcard,
              icon: const Icon(Icons.add),
              label: const Text('Thêm thẻ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFlashcardItem(FlashcardModel flashcard, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            // TODO: Show flashcard detail or flip
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Index badge
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        flashcard.question,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        flashcard.answer,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      if (flashcard.phonetic != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          flashcard.phonetic!,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textGray,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Actions
                Column(
                  children: [
                    // TTS button - AI AI CŨNG THẤY
                    IconButton(
                      icon: Icon(Icons.volume_up_outlined, color: AppColors.primary, size: 22),
                      onPressed: () {
                        // TODO: TTSService.speak(flashcard.question);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    // ✅ Edit/Delete - CHỈ OWNER THẤY
                    if (_canEdit) ...[
                      IconButton(
                        icon: Icon(Icons.edit_outlined, color: AppColors.textGray, size: 20),
                        onPressed: () => _editFlashcard(flashcard),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                        onPressed: () => _deleteFlashcard(flashcard),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Animation builder widget
class AnimatedBuilder extends StatelessWidget {
  final Listenable animation;
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    Key? key,
    required this.animation,
    required this.builder,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder2(
      animation: animation,
      builder: builder,
      child: child,
    );
  }
}

class AnimatedBuilder2 extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder2({
    Key? key,
    required Listenable animation,
    required this.builder,
    this.child,
  }) : super(key: key, listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}