import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math' as math;
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../models/category_model.dart';
import '../../models/flashcard_model.dart';
import '../../models/user_model.dart';
import '../../services/category_service.dart';
import '../../services/flash_card_service.dart';
import '../../services/user_service.dart';
import '../../services/tts_service.dart';
import '../card/flashcard_creation_screen.dart';
import '../card/flashcard_screen.dart';
import '../card/flashcard_edit_screen.dart';
import '../payment/upgrade_premium_screen.dart';

/// 🎨 Màn hình chi tiết chủ đề - Unified Screen
///
/// PHÂN QUYỀN:
/// - Owner (Tác giả): Toàn quyền - Xem, Học, Kiểm tra, Thêm/Sửa/Xóa flashcard, Sửa/Xóa category
/// - NORMAL_USER: Chỉ xem, học, lưu chủ đề (KHÔNG có kiểm tra)
/// - PREMIUM_USER/TEACHER: Xem, học, kiểm tra, lưu chủ đề
class CategoryDetailScreen extends StatefulWidget {
  final CategoryModel category;
  final bool isOwner;

  const CategoryDetailScreen({
    Key? key,
    required this.category,
    this.isOwner = false,
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
  CategoryModel? _category;
  UserModel? _currentUser;

  // Animation
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  // Preview card
  int _previewIndex = 0;
  late PageController _previewController;

  // ✅ PHÂN QUYỀN
  bool get _isOwner => widget.isOwner || (_category?.ownerUserId == _currentUser?.userId);
  bool get _canEdit => _isOwner && !(_category?.isSystem ?? true);
  bool get _canQuiz => _isOwner || (_currentUser?.hasPremiumAccess ?? false); // Premium/Teacher có thể kiểm tra
  bool get _canStudy => true; // Ai cũng có thể học
  bool get _canSave => !_isOwner; // Chỉ save nếu không phải owner

  CategoryModel get category => _category ?? widget.category;

  @override
  void initState() {
    super.initState();
    _category = widget.category;
    _isSaved = widget.category.isSaved;

    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeOut,
    );

    _previewController = PageController(viewportFraction: 0.85);
    _loadCurrentUser();
    _loadCategoryDetails();
  }

  @override
  void dispose() {
    _fabController.dispose();
    _previewController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await UserService.getCurrentUser();
      if (mounted) {
        setState(() => _currentUser = user);
        print('📱 [CategoryDetail] User: ${user?.email}, Role: ${user?.role}');
        print('   ├── isOwner: $_isOwner');
        print('   ├── canEdit: $_canEdit');
        print('   ├── canQuiz: $_canQuiz');
        print('   └── canSave: $_canSave');
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
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
    if (!_canSave) return;

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

    // ✅ CHECK QUYỀN KIỂM TRA
    if (!_canQuiz) {
      _showUpgradeDialog();
      return;
    }

    _showSnackBar('Tính năng kiểm tra đang phát triển', Icons.quiz);
  }

  // ✅ DIALOG NÂNG CẤP PREMIUM
  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.warning, AppColors.warning.withOpacity(0.7)],
                  ),
                ),
                child: const Icon(Icons.workspace_premium_rounded, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'Nâng cấp Premium',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
              ),
              const SizedBox(height: 12),
              Text(
                'Tính năng Kiểm tra chỉ dành cho người dùng Premium',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
              ),
              const SizedBox(height: 24),
              _buildUpgradeBenefit(Icons.quiz_outlined, 'Kiểm tra kiến thức'),
              const SizedBox(height: 8),
              _buildUpgradeBenefit(Icons.insights, 'Theo dõi tiến độ'),
              const SizedBox(height: 8),
              _buildUpgradeBenefit(Icons.stars, 'Truy cập đầy đủ tính năng'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const UpgradePremiumScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Nâng cấp ngay', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Để sau', style: TextStyle(color: AppColors.textGray)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpgradeBenefit(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.success),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
      ],
    );
  }

  Future<void> _shareCategory() async {
    final shareUrl = 'https://flashlearn.vn/set/${_category!.id}';
    await Share.share(
      '📚 ${_category!.name}\n${_flashcards.length} thuật ngữ\n\nHọc cùng tôi trên FlashLearn!\n$shareUrl',
      subject: _category!.name,
    );
  }

  // ==================== OWNER ACTIONS ====================

  void _addFlashcard() {
    if (!_canEdit) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardCreationScreen(
          initialCategoryId: _category!.id,
        ),
      ),
    ).then((created) {
      if (created != null) _loadCategoryDetails();
    });
  }

  void _editFlashcard(FlashcardModel flashcard) {
    if (!_canEdit) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardEditScreen(
          flashcard: flashcard,
          categoryId: _category!.id,
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
        content: Text('Bạn có chắc muốn xóa thẻ "${flashcard.question}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Chỉnh sửa học phần'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên học phần',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả (tùy chọn)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Text('Quyền riêng tư', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildVisibilityOption(
                        icon: Icons.lock_outline,
                        label: 'Riêng tư',
                        isSelected: visibility == 'PRIVATE',
                        onTap: () => setDialogState(() => visibility = 'PRIVATE'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildVisibilityOption(
                        icon: Icons.public,
                        label: 'Công khai',
                        isSelected: visibility == 'PUBLIC',
                        onTap: () => setDialogState(() => visibility = 'PUBLIC'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateCategory(nameController.text, descController.text, visibility);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textGray),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? AppColors.primary : AppColors.textPrimary)),
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
      Navigator.pop(context);

      setState(() => _category = updated);
      _showSnackBar('Đã cập nhật học phần', Icons.check_circle);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
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
              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.delete_forever, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            const Text('Xóa học phần?'),
          ],
        ),
        content: Text('Bạn có chắc muốn xóa "${_category!.name}"?\n\nTất cả ${_flashcards.length} thẻ sẽ bị xóa vĩnh viễn.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCategory();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
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
      Navigator.pop(context);
      Navigator.pop(context, true);

      _showSnackBar('Đã xóa học phần', Icons.check_circle);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar('Lỗi: $e', Icons.error, isError: true);
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }

  void _showSnackBar(String message, IconData icon, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ]),
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
          Text('Đang tải học phần...', style: TextStyle(color: AppColors.textGray)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Có lỗi xảy ra', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_errorMessage ?? '', style: TextStyle(color: AppColors.textGray)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _loadCategoryDetails, child: const Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildPreviewCards(),
              _buildActionButtons(),
              _buildStudyModes(),
              _buildFlashcardSection(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // ✅ NÚT LƯU - CHỈ HIỆN NẾU KHÔNG PHẢI OWNER
        if (_canSave)
          IconButton(
            icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border, color: Colors.white),
            onPressed: _toggleSave,
          ),
        IconButton(icon: const Icon(Icons.share_outlined, color: Colors.white), onPressed: _shareCategory),
        // ✅ MENU - CHỈ HIỆN NẾU LÀ OWNER
        if (_canEdit)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'edit') _showEditCategoryDialog();
              if (value == 'delete') _showDeleteCategoryConfirmation();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 12), Text('Chỉnh sửa')])),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 20, color: AppColors.error), SizedBox(width: 12), Text('Xóa', style: TextStyle(color: AppColors.error))])),
            ],
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.85), AppColors.accent],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_category!.isPublic ? Icons.public : Icons.lock_outline, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(_category!.isPublic ? 'Công khai' : 'Riêng tư', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(_category!.name, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (_category!.description != null && _category!.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(_category!.description!, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
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
              return Center(child: Transform.scale(scale: value, child: _buildPreviewCard(_flashcards[index])));
            },
          );
        },
      ),
    );
  }

  Widget _buildPreviewCard(FlashcardModel card) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))],
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
                  Text(card.question, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDark), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 16),
                  Container(height: 2, width: 40, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.3), borderRadius: BorderRadius.circular(1))),
                  const SizedBox(height: 16),
                  Text(card.answer, style: TextStyle(fontSize: 16, color: AppColors.textSecondary), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
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
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.style, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_flashcards.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                      Text('thuật ngữ', style: TextStyle(fontSize: 13, color: AppColors.textGray)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                Icon(
                  _isOwner ? Icons.edit : _category!.isClassCategory ? Icons.school_outlined : _category!.isSystem ? Icons.public : Icons.person_outline,
                  color: _isOwner ? AppColors.success : AppColors.secondary,
                  size: 28,
                ),
                const SizedBox(height: 4),
                Text(
                  _isOwner ? 'Tác giả' : _category!.isClassCategory ? 'Lớp học' : _category!.isSystem ? 'Hệ thống' : 'Cá nhân',
                  style: TextStyle(fontSize: 12, color: AppColors.textGray),
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
          const Text('Chế độ học', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
          const SizedBox(height: 16),
          Row(
            children: [
              // ✅ HỌC - AI CŨNG ĐƯỢC
              Expanded(
                child: _buildStudyModeCard(
                  icon: Icons.style_outlined,
                  label: 'Thẻ ghi nhớ',
                  color: AppColors.primary,
                  onTap: _startStudy,
                  isEnabled: true,
                ),
              ),
              const SizedBox(width: 12),
              // ✅ KIỂM TRA - CHỈ PREMIUM/OWNER
              Expanded(
                child: _buildStudyModeCard(
                  icon: Icons.quiz_outlined,
                  label: 'Kiểm tra',
                  color: AppColors.secondary,
                  onTap: _startQuiz,
                  isEnabled: _canQuiz,
                  isPremium: !_canQuiz,
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
                  isEnabled: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStudyModeCard(
                  icon: Icons.sports_esports_outlined,
                  label: 'Ghép thẻ',
                  color: AppColors.error,
                  onTap: () => _showSnackBar('Đang phát triển', Icons.construction),
                  isEnabled: true,
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
    bool isEnabled = true,
    bool isPremium = false,
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: (isEnabled ? color : AppColors.textGray).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: isEnabled ? color : AppColors.textGray, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isEnabled ? AppColors.primaryDark : AppColors.textGray)),
              ),
              // ✅ BADGE PREMIUM
              if (isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: const Text('PRO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.warning)),
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
              const Text('Thuật ngữ trong học phần', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
              Text('${_flashcards.length} thẻ', style: TextStyle(fontSize: 14, color: AppColors.textGray)),
            ],
          ),
          const SizedBox(height: 16),
          if (_flashcards.isEmpty)
            _buildEmptyFlashcards()
          else
            ..._flashcards.asMap().entries.map((entry) => _buildFlashcardItem(entry.value, entry.key)),
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
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
            child: Icon(Icons.style_outlined, size: 48, color: AppColors.textGray),
          ),
          const SizedBox(height: 20),
          const Text('Chưa có thẻ nào', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
          const SizedBox(height: 8),
          Text(_canEdit ? 'Thêm thẻ đầu tiên để bắt đầu học' : 'Học phần này chưa có thẻ nào', style: TextStyle(color: AppColors.textGray)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(flashcard.question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.primaryDark)),
                      const SizedBox(height: 8),
                      Text(flashcard.answer, style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4)),
                      if (flashcard.phonetic != null) ...[
                        const SizedBox(height: 6),
                        Text(flashcard.phonetic!, style: TextStyle(fontSize: 13, color: AppColors.textGray, fontStyle: FontStyle.italic)),
                      ],
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(icon: Icon(Icons.volume_up_outlined, color: AppColors.primary, size: 22), onPressed: () {}, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
                    // ✅ CHỈ HIỆN NÚT SỬA/XÓA NẾU LÀ OWNER
                    if (_canEdit) ...[
                      IconButton(icon: Icon(Icons.edit_outlined, color: AppColors.textGray, size: 20), onPressed: () => _editFlashcard(flashcard), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
                      IconButton(icon: Icon(Icons.delete_outline, color: AppColors.error, size: 20), onPressed: () => _deleteFlashcard(flashcard), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
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

class AnimatedBuilder extends StatelessWidget {
  final Listenable animation;
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({Key? key, required this.animation, required this.builder, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder2(animation: animation, builder: builder, child: child);
  }
}

class AnimatedBuilder2 extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder2({Key? key, required Listenable animation, required this.builder, this.child}) : super(key: key, listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}