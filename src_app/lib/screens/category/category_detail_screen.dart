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
/// ✅ CẬP NHẬT: Thêm search, cải thiện typography, bỏ định nghĩa EN
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
  List<FlashcardModel> _filteredFlashcards = [];  // ✅ NEW
  String? _errorMessage;
  CategoryModel? _category;
  UserModel? _currentUser;

  // ✅ Search
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // ✅ TTS
  final TTSService _ttsService = TTSService();
  int? _playingIndex;

  // Animation
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  // Preview card
  int _previewIndex = 0;
  late PageController _previewController;

  // Permissions
  bool get _isOwner => widget.isOwner || (_category?.ownerUserId == _currentUser?.userId);
  bool get _canEdit => _isOwner && !(_category?.isSystem ?? true);
  bool get _canQuiz => true; // ✅ TẤT CẢ người dùng đều có thể kiểm tra
  bool get _canStudy => true;
  bool get _canSave => !_isOwner;

  CategoryModel get category => _category ?? widget.category;

  @override
  void initState() {
    super.initState();
    _category = widget.category;
    _isSaved = widget.category.isSaved;

    _fabController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _fabAnimation = CurvedAnimation(parent: _fabController, curve: Curves.easeOut);
    _previewController = PageController(viewportFraction: 0.85);
    _searchController.addListener(_onSearchChanged);

    print('📱 [SCREEN] $runtimeType');
    _loadCurrentUser();
    _loadCategoryDetails();
  }

  @override
  void dispose() {
    _fabController.dispose();
    _previewController.dispose();
    _searchController.dispose();
    _ttsService.stop();
    super.dispose();
  }

  // ✅ Search filter - chỉ theo word
  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredFlashcards = _flashcards;
      } else {
        _filteredFlashcards = _flashcards.where((card) => card.word.toLowerCase().contains(query)).toList();
      }
    });
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await UserService.getCurrentUser();
      if (mounted) setState(() => _currentUser = user);
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
  }

  Future<void> _loadCategoryDetails() async {
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final flashcards = await FlashcardService.getFlashcardsByCategory(_category!.id);
      if (!mounted) return;
      setState(() {
        _flashcards = flashcards;
        _filteredFlashcards = flashcards;
        _isLoading = false;
      });
      _fabController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() { _errorMessage = e.toString(); _isLoading = false; });
    }
  }

  // ✅ TTS
  Future<void> _playPronunciation(FlashcardModel card, int index) async {
    if (_playingIndex == index) {
      await _ttsService.stop();
      setState(() => _playingIndex = null);
      return;
    }
    setState(() => _playingIndex = index);
    try {
      await _ttsService.speak(card.word, languageCode: 'en-US');
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) setState(() => _playingIndex = null);
    } catch (e) {
      if (mounted) {
        setState(() => _playingIndex = null);
        _showSnackBar('Không thể phát âm', Icons.error, isError: true);
      }
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
    Navigator.push(context, MaterialPageRoute(builder: (context) => FlashcardScreen(categoryId: _category!.id, categoryName: _category!.name)));
  }

  void _startQuiz() {
    if (_flashcards.isEmpty) {
      _showSnackBar('Chưa có thẻ nào để kiểm tra', Icons.warning, isError: true);
      return;
    }
    // ✅ TẤT CẢ người dùng đều có thể kiểm tra
    _showSnackBar('Tính năng kiểm tra đang phát triển', Icons.quiz);
  }

  Future<void> _shareCategory() async {
    await Share.share('📚 ${_category!.name}\n${_flashcards.length} thuật ngữ\n\nHọc cùng tôi trên FlashLearn!\nhttps://flashlearn.vn/set/${_category!.id}', subject: _category!.name);
  }

  // ==================== OWNER ACTIONS ====================

  void _addFlashcard() {
    if (!_canEdit) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) => FlashcardCreationScreen(initialCategoryId: _category!.id, initialCategoryName: _category!.name))).then((created) { if (created != null) _loadCategoryDetails(); });
  }

  void _editFlashcard(FlashcardModel flashcard) {
    if (!_canEdit) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) => FlashcardEditScreen(flashcard: flashcard, categoryId: _category!.id))).then((updated) { if (updated == true) _loadCategoryDetails(); });
  }

  Future<void> _deleteFlashcard(FlashcardModel flashcard) async {
    if (!_canEdit) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.delete_forever, color: AppColors.error)), const SizedBox(width: 12), const Text('Xóa thẻ?')]),
        content: Text('Bạn có chắc muốn xóa thẻ "${flashcard.word}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await FlashcardService.deleteFlashcard(flashcard.id);
        _loadCategoryDetails();
        _showSnackBar('Đã xóa thẻ', Icons.check_circle);
      } catch (e) { _showSnackBar('Lỗi: $e', Icons.error, isError: true); }
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
        builder: (context, setDialogState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ Handle bar
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ✅ Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Chỉnh sửa học phần', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                            SizedBox(height: 4),
                            Text('Cập nhật thông tin học phần của bạn', style: TextStyle(fontSize: 13, color: AppColors.textGray)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ✅ Tên học phần
                  const Text('Tên học phần', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Nhập tên học phần',
                      hintStyle: TextStyle(color: AppColors.textGray),
                      prefixIcon: Icon(Icons.title, color: AppColors.primary, size: 22),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary, width: 2)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ✅ Mô tả
                  const Text('Mô tả (tùy chọn)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descController,
                    style: const TextStyle(fontSize: 16),
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Thêm mô tả cho học phần...',
                      hintStyle: TextStyle(color: AppColors.textGray),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(bottom: 48),
                        child: Icon(Icons.description_outlined, color: AppColors.primary, size: 22),
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary, width: 2)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ✅ Quyền riêng tư
                  const Text('Quyền riêng tư', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildVisibilityCard(
                          icon: Icons.lock_outline,
                          label: 'Riêng tư',
                          description: 'Chỉ bạn xem được',
                          isSelected: visibility == 'PRIVATE',
                          onTap: () => setDialogState(() => visibility = 'PRIVATE'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildVisibilityCard(
                          icon: Icons.public,
                          label: 'Công khai',
                          description: 'Mọi người xem được',
                          isSelected: visibility == 'PUBLIC',
                          onTap: () => setDialogState(() => visibility = 'PUBLIC'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ✅ Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Hủy', style: TextStyle(color: AppColors.textGray, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _updateCategory(nameController.text, descController.text, visibility);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Lưu thay đổi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Visibility Card đẹp hơn
  Widget _buildVisibilityCard({
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
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))] : null,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.white : AppColors.textGray, size: 22),
            ),
            const SizedBox(height: 10),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isSelected ? AppColors.primary : AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(description, style: TextStyle(fontSize: 11, color: AppColors.textGray), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Future<void> _updateCategory(String name, String description, String visibility) async {
    try {
      _showLoadingDialog();
      final updated = await CategoryService.updateCategory(categoryId: _category!.id, name: name, description: description.isEmpty ? null : description, visibility: visibility);
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
        title: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.delete_forever, color: AppColors.error)), const SizedBox(width: 12), const Text('Xóa học phần?')]),
        content: Text('Bạn có chắc muốn xóa "${_category!.name}"?\n\nTất cả ${_flashcards.length} thẻ sẽ bị xóa vĩnh viễn.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: () { Navigator.pop(context); _deleteCategory(); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white), child: const Text('Xóa')),
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

  void _showLoadingDialog() => showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)));

  void _showSnackBar(String message, IconData icon, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 12), Expanded(child: Text(message))]),
      backgroundColor: isError ? AppColors.error : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  /// Lấy nghĩa chính (bỏ định nghĩa EN)
  String _getMainMeaning(String meaning) {
    if (meaning.isEmpty) return 'Không có nghĩa';
    if (meaning.contains('\n\n')) {
      for (var part in meaning.split('\n\n')) {
        final t = part.trim();
        if (!t.startsWith('📖') && !t.startsWith('📝') && !t.toLowerCase().startsWith('example')) return t;
      }
    }
    if (meaning.contains('📖') || meaning.contains('📝')) {
      final i1 = meaning.indexOf('📖'), i2 = meaning.indexOf('📝');
      final min = i1 == -1 ? i2 : (i2 == -1 ? i1 : (i1 < i2 ? i1 : i2));
      if (min > 0) return meaning.substring(0, min).trim();
    }
    return meaning.trim();
  }

  // ==================== BUILD UI ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading ? _buildLoadingState() : _errorMessage != null ? _buildErrorState() : _buildContent(),
      floatingActionButton: _canEdit && !_isLoading && _errorMessage == null
          ? ScaleTransition(scale: _fabAnimation, child: FloatingActionButton.extended(onPressed: _addFlashcard, backgroundColor: AppColors.primary, elevation: 4, icon: const Icon(Icons.add_rounded, color: Colors.white), label: const Text('Thêm thẻ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))
          : null,
    );
  }

  Widget _buildLoadingState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(color: AppColors.primary), const SizedBox(height: 16), Text('Đang tải học phần...', style: TextStyle(color: AppColors.textGray))]));

  Widget _buildErrorState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.error_outline, size: 64, color: AppColors.error), const SizedBox(height: 16), const Text('Có lỗi xảy ra', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(_errorMessage ?? '', style: TextStyle(color: AppColors.textGray)), const SizedBox(height: 24), ElevatedButton(onPressed: _loadCategoryDetails, child: const Text('Thử lại'))]));

  Widget _buildContent() {
    return CustomScrollView(slivers: [
      _buildAppBar(),
      SliverToBoxAdapter(child: Column(children: [
        _buildPreviewCards(),  // ✅ GIỮ NGUYÊN
        _buildActionButtons(),
        _buildStudyModes(),
        _buildFlashcardSection(),
        const SizedBox(height: 100),
      ])),
    ]);
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180, pinned: true, backgroundColor: AppColors.primary,
      leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/library',
                  (route) => route.isFirst,
            );
          }
      ),
      actions: [
        if (_canSave) IconButton(icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border, color: Colors.white), onPressed: _toggleSave),
        IconButton(icon: const Icon(Icons.share_outlined, color: Colors.white), onPressed: _shareCategory),
        if (_canEdit) PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) { if (value == 'edit') _showEditCategoryDialog(); if (value == 'delete') _showDeleteCategoryConfirmation(); },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 12), Text('Chỉnh sửa')])),
            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 20, color: AppColors.error), SizedBox(width: 12), Text('Xóa', style: TextStyle(color: AppColors.error))])),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primary, AppColors.primary.withOpacity(0.85), AppColors.accent])),
          child: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 56, 20, 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(_category!.isPublic ? Icons.public : Icons.lock_outline, size: 14, color: Colors.white), const SizedBox(width: 6), Text(_category!.isPublic ? 'Công khai' : 'Riêng tư', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500))])),
            const SizedBox(height: 12),
            Text(_category!.name, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
            if (_category!.description != null && _category!.description!.isNotEmpty) ...[const SizedBox(height: 8), Text(_category!.description!, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)],
          ]))),
        ),
      ),
    );
  }

  // ✅ PREVIEW CARDS - Kích thước đồng nhất
  Widget _buildPreviewCards() {
    if (_flashcards.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 220, margin: const EdgeInsets.only(top: 20),
      child: PageView.builder(
        controller: _previewController,
        itemCount: math.min(_flashcards.length, 5),
        onPageChanged: (index) => setState(() => _previewIndex = index),
        itemBuilder: (context, index) {
          return AnimatedBuilder(animation: _previewController, builder: (context, child) {
            double value = 1.0;
            if (_previewController.position.haveDimensions) { value = _previewController.page! - index; value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0); }
            return Center(child: Transform.scale(scale: value, child: _buildPreviewCard(_flashcards[index])));
          });
        },
      ),
    );
  }

  Widget _buildPreviewCard(FlashcardModel card) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      // ✅ Fixed width & height cho tất cả cards
      width: double.infinity,
      height: 200,
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ✅ Từ vựng - Fixed height area
                  SizedBox(
                    height: 56,
                    child: Center(
                      child: Text(
                        card.word,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryDark, height: 1.2),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Divider
                  Container(height: 2, width: 40, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.3), borderRadius: BorderRadius.circular(1))),
                  const SizedBox(height: 12),
                  // ✅ Nghĩa - Fixed height area
                  SizedBox(
                    height: 48,
                    child: Center(
                      child: Text(
                        _getMainMeaning(card.meaning),
                        style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.4),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  // ✅ Phiên âm (nếu có)
                  if (card.phonetic != null && card.phonetic!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        card.phonetic!,
                        style: TextStyle(fontSize: 13, color: AppColors.textGray, fontStyle: FontStyle.italic),
                      ),
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
    return Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 0), child: Row(children: [
      Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]), child: Row(children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.style, color: AppColors.primary, size: 24)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${_flashcards.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryDark)), Text('thuật ngữ', style: TextStyle(fontSize: 13, color: AppColors.textGray))]),
      ]))),
      const SizedBox(width: 12),
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]), child: Column(children: [
        Icon(_isOwner ? Icons.edit : _category!.isClassCategory ? Icons.school_outlined : _category!.isSystem ? Icons.public : Icons.person_outline, color: _isOwner ? AppColors.success : AppColors.secondary, size: 28),
        const SizedBox(height: 4),
        Text(_isOwner ? 'Tác giả' : _category!.isClassCategory ? 'Lớp học' : _category!.isSystem ? 'Hệ thống' : 'Cá nhân', style: TextStyle(fontSize: 12, color: AppColors.textGray)),
      ])),
    ]));
  }

  Widget _buildStudyModes() {
    return Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Chế độ học', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: _buildStudyModeCard(icon: Icons.style_outlined, label: 'Thẻ ghi nhớ', color: AppColors.primary, onTap: _startStudy, isEnabled: true)),
        const SizedBox(width: 12),
        Expanded(child: _buildStudyModeCard(icon: Icons.quiz_outlined, label: 'Kiểm tra', color: AppColors.secondary, onTap: _startQuiz, isEnabled: true)),
      ]),
      const SizedBox(height: 12),
    ]));
  }

  Widget _buildStudyModeCard({required IconData icon, required String label, required Color color, required VoidCallback onTap, bool isEnabled = true}) {
    return Material(color: Colors.white, borderRadius: BorderRadius.circular(16), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: (isEnabled ? color : AppColors.textGray).withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: isEnabled ? color : AppColors.textGray, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isEnabled ? AppColors.primaryDark : AppColors.textGray))),
      ]),
    )));
  }

  // ✅ FLASHCARD SECTION VỚI SEARCH
  Widget _buildFlashcardSection() {
    return Padding(padding: const EdgeInsets.fromLTRB(20, 28, 20, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header + Search
      Row(children: [
        const Expanded(child: Text('Thuật ngữ trong học phần', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark))),
        Text('${_filteredFlashcards.length} thẻ', style: TextStyle(fontSize: 14, color: AppColors.textGray)),
        const SizedBox(width: 8),
        // ✅ NÚT SEARCH
        GestureDetector(
          onTap: () { setState(() => _isSearching = !_isSearching); if (!_isSearching) _searchController.clear(); },
          child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _isSearching ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: Icon(_isSearching ? Icons.close : Icons.search, color: _isSearching ? AppColors.primary : AppColors.textGray, size: 20)),
        ),
      ]),

      // ✅ Search field
      AnimatedContainer(
        duration: const Duration(milliseconds: 300), height: _isSearching ? 56 : 0,
        child: _isSearching ? Padding(padding: const EdgeInsets.only(top: 12), child: TextField(
          controller: _searchController, autofocus: true,
          decoration: InputDecoration(hintText: 'Tìm từ vựng...', hintStyle: TextStyle(color: AppColors.textGray, fontSize: 14), prefixIcon: Icon(Icons.search, color: AppColors.textGray, size: 20), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary, width: 2))),
        )) : const SizedBox.shrink(),
      ),

      const SizedBox(height: 16),
      if (_filteredFlashcards.isEmpty) _buildEmptyFlashcards()
      else ..._filteredFlashcards.asMap().entries.map((entry) => _buildFlashcardItem(entry.value, entry.key)),
    ]));
  }

  Widget _buildEmptyFlashcards() {
    final isFiltered = _searchController.text.isNotEmpty;
    return Container(padding: const EdgeInsets.all(40), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)), child: Column(children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle), child: Icon(isFiltered ? Icons.search_off : Icons.style_outlined, size: 48, color: AppColors.textGray)),
      const SizedBox(height: 20),
      Text(isFiltered ? 'Không tìm thấy' : 'Chưa có thẻ nào', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
      const SizedBox(height: 8),
      Text(isFiltered ? 'Thử từ khóa khác' : (_canEdit ? 'Thêm thẻ đầu tiên để bắt đầu học' : 'Học phần này chưa có thẻ nào'), style: TextStyle(color: AppColors.textGray)),
      if (_canEdit && !isFiltered) ...[const SizedBox(height: 20), ElevatedButton.icon(onPressed: _addFlashcard, icon: const Icon(Icons.add, color: Colors.white), label: const Text('Thêm thẻ', style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))],
    ]));
  }

  // ✅ FLASHCARD ITEM - Typography cải thiện, KHÔNG có định nghĩa EN
  Widget _buildFlashcardItem(FlashcardModel flashcard, int index) {
    final isPlaying = _playingIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Padding(padding: const EdgeInsets.all(16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Index
        Container(width: 36, height: 36, decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.accent]), borderRadius: BorderRadius.circular(10)), child: Center(child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)))),
        const SizedBox(width: 16),
        // Content
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Từ vựng (17px, bold)
          Text(flashcard.word, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.primaryDark)),
          const SizedBox(height: 6),
          // Loại từ + Phiên âm
          Row(children: [
            if (flashcard.partOfSpeech != null && flashcard.partOfSpeech!.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(flashcard.partOfSpeech!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary))),
            if (flashcard.phonetic != null && flashcard.phonetic!.isNotEmpty) Expanded(child: Text(flashcard.phonetic!, style: TextStyle(fontSize: 13, color: AppColors.textGray, fontStyle: FontStyle.italic))),
          ]),
          const SizedBox(height: 8),
          // Nghĩa VN (không có định nghĩa EN)
          Text(_getMainMeaning(flashcard.meaning), style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
          if (flashcard.partOfSpeechVi != null && flashcard.partOfSpeechVi!.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text('(${flashcard.partOfSpeechVi})', style: TextStyle(fontSize: 12, color: AppColors.textGray))),
        ])),
        // Actions
        Column(children: [
          // TTS
          GestureDetector(onTap: () => _playPronunciation(flashcard, index), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: isPlaying ? AppColors.primary.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: isPlaying ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.primary))) : Icon(Icons.volume_up_outlined, color: AppColors.primary, size: 22))),
          if (_canEdit) ...[
            IconButton(icon: Icon(Icons.edit_outlined, color: AppColors.textGray, size: 20), onPressed: () => _editFlashcard(flashcard), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
            IconButton(icon: Icon(Icons.delete_outline, color: AppColors.error, size: 20), onPressed: () => _deleteFlashcard(flashcard), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
          ],
        ]),
      ])),
    );
  }
}

// AnimatedBuilder helper
class AnimatedBuilder extends StatelessWidget {
  final Listenable animation;
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;
  const AnimatedBuilder({Key? key, required this.animation, required this.builder, this.child}) : super(key: key);
  @override
  Widget build(BuildContext context) => AnimatedBuilder2(animation: animation, builder: builder, child: child);
}

class AnimatedBuilder2 extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;
  const AnimatedBuilder2({Key? key, required Listenable animation, required this.builder, this.child}) : super(key: key, listenable: animation);
  @override
  Widget build(BuildContext context) => builder(context, child);
}