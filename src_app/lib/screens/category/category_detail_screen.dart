import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math' as math;
import '../../config/app_colors.dart';
import '../../models/category_study_schedule_model.dart';
import '../../screens/quiz/quiz_setup_screen.dart';
import '../../models/category_model.dart';
import '../../models/flashcard_model.dart';
import '../../models/user_model.dart';
import '../../services/category_service.dart';
import '../../services/category_study_schedule_service.dart';
import '../../services/flash_card_service.dart';
import '../../services/user_service.dart';
import '../../services/tts_service.dart';
import '../../widgets/study_schedule_widgets.dart';
import '../card/flashcard_creation_screen.dart';
import '../card/flashcard_screen.dart';
import '../card/flashcard_edit_screen.dart';
import '../../models/study_progress_model.dart';
import '../../services/study_progress_service.dart';

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
  CategoryProgressModel? _progress;
  StudyReminderModel? _reminder;
  StudyStreakModel? _streak;
  bool _isLoadingProgress = true;

  CategoryStudyScheduleModel? _schedule;
  List<ScheduleConflict>? _conflicts;
  bool _isLoadingSchedule = false;

  // ✅ Search
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // ✅ TTS
  final TTSService _ttsService = TTSService();
  int? _playingIndex;

  // Animation
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

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
    _loadStudyProgress();
    _fabController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _fabAnimation = CurvedAnimation(parent: _fabController, curve: Curves.easeOut);
    _searchController.addListener(_onSearchChanged);

    print('📱 [SCREEN] $runtimeType');
    _loadCurrentUser();
    _loadCategoryDetails();
    _loadSchedule();  // ✅ THÊM DÒNG NÀY!
  }

  @override
  void dispose() {
    _fabController.dispose();
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardScreen(
          categoryId: _category!.id,
          categoryName: _category!.name,
        ),
      ),
    ).then((_) {
      // ✅ REFRESH sau khi học xong
      _loadCategoryDetails();
      _loadStudyProgress();
    });
  }
  void _startQuiz() {
    if (_flashcards.isEmpty) {
      _showSnackBar('Chưa có thẻ nào để kiểm tra', Icons.warning, isError: true);
      return;
    }

    // ✅ Navigate đến QuizSetupScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizSetupScreen(category: _category!),
      ),
    );
  }

  Future<void> _shareCategory() async {
    await Share.share('📚 ${_category!.name}\n${_flashcards.length} thuật ngữ\n\nHọc cùng tôi trên FlashLearn!\nhttps://flashlearn.vn/set/${_category!.id}', subject: _category!.name);
  }

  Future<void> _loadSchedule() async {
    if (!mounted) return;

    setState(() => _isLoadingSchedule = true);

    try {
      // Lấy schedule của category này
      final schedule = await CategoryStudyScheduleService.getSchedule(widget.category.id);

      if (schedule != null && mounted) {
        // Kiểm tra xung đột
        final conflicts = await CategoryStudyScheduleService.checkNewScheduleConflicts(
          schedule,
          null, // Sẽ tự lấy existing schedules
        );

        setState(() {
          _schedule = schedule.copyWith(categoryName: widget.category.name);
          _conflicts = conflicts.where((c) =>
              c.categories.any((cat) => cat.categoryId == widget.category.id)
          ).toList();
          _isLoadingSchedule = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [CategoryDetail] _loadSchedule error: $e');
      setState(() => _isLoadingSchedule = false);
    }
  }

// --- Update Schedule ---
  Future<void> _updateSchedule(CategoryStudyScheduleModel newSchedule) async {
    // Cập nhật UI ngay lập tức
    setState(() => _schedule = newSchedule);

    // Kiểm tra xung đột
    final conflicts = await CategoryStudyScheduleService.checkNewScheduleConflicts(
      newSchedule,
      null,
    );

    if (mounted) {
      setState(() {
        _conflicts = conflicts.where((c) =>
          c.categories.any((cat) => cat.categoryId == widget.category.id)
        ).toList();
      });
    }

    // Gọi API cập nhật
    final updated = await CategoryStudyScheduleService.updateSchedule(newSchedule);

    if (updated != null && mounted) {
      setState(() => _schedule = updated);

      // Hiện thông báo nếu có xung đột
      if (_conflicts != null && _conflicts!.isNotEmpty) {
        _showConflictSnackBar();
      }
    }
  }

// --- Show Conflict Dialog ---
  void _showConflictDialog() {
    if (_conflicts == null || _conflicts!.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => ScheduleConflictDialog(
        conflicts: _conflicts!,
        onGoToCategory: (categoryId) {
          // Navigate to conflicting category
          // Implement navigation logic here
        },
      ),
    );
  }

  void _showConflictSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Phát hiện ${_conflicts!.length} xung đột lịch học'),
            ),
          ],
        ),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Xem',
          textColor: Colors.white,
          onPressed: _showConflictDialog,
        ),
      ),
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
          initialCategoryName: _category!.name,
        ),
      ),
    ).then((created) {
      _loadCategoryDetails();
      _loadStudyProgress();
    });
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

  Future<void> _loadStudyProgress() async {
    setState(() => _isLoadingProgress = true);
    try {
      final results = await Future.wait([
        StudyProgressService.getCategoryProgress(_category!.id),
        StudyProgressService.getStreakInfo(),
        StudyProgressService.getReminderSettings(),
      ]);

      if (mounted) {
        setState(() {
          _progress = results[0] as CategoryProgressModel;
          _streak = results[1] as StudyStreakModel;
          _reminder = results[2] as StudyReminderModel;
          _isLoadingProgress = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading progress: $e');
      if (mounted) setState(() => _isLoadingProgress = false);
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
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(
          child: Column(
            children: [
              // if (_progress != null && !_isLoadingProgress)
                StudyProgressCard(
                  progress: _progress!,
                  onResetProgress: _showResetProgressDialog,
                ),

              // ✅ MỚI: Schedule Setting Card
              if (_schedule != null && !_isLoadingSchedule)
                CategoryScheduleSettingCard(
                  schedule: _schedule!,
                  onUpdate: _updateSchedule,
                  conflicts: _conflicts,
                  onShowConflictDetail: _showConflictDialog,
                ),

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

  Future<void> _updateReminder(StudyReminderModel newReminder) async {
    setState(() => _reminder = newReminder);

    // Gọi API cập nhật
    final updated = await StudyProgressService.updateReminderSettings(newReminder);
    if (updated != null && mounted) {
      setState(() => _reminder = updated);
    }
  }

  void _showResetProgressDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.refresh, color: AppColors.warning),
            ),
            const SizedBox(width: 12),
            const Text('Reset tiến trình?'),
          ],
        ),
        content: const Text(
          'Bạn có chắc muốn xóa toàn bộ tiến trình học của học phần này?\n\n'
              'Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await StudyProgressService.resetCategoryProgress(_category!.id);
              _loadStudyProgress();
              _showSnackBar('Đã reset tiến trình', Icons.check_circle);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180, pinned: true, backgroundColor: AppColors.primary,
      leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
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
// ==================== PROGRESS CARD ====================

/// Widget hiển thị phần trăm đã học
class StudyProgressCard extends StatelessWidget {
  final CategoryProgressModel progress;
  final VoidCallback? onResetProgress;

  const StudyProgressCard({
    Key? key,
    required this.progress,
    this.onResetProgress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Tiến trình học',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              if (onResetProgress != null && progress.studiedCards > 0)
                IconButton(
                  icon: Icon(Icons.refresh, color: AppColors.textGray, size: 20),
                  onPressed: onResetProgress,
                  tooltip: 'Reset tiến trình',
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress Bar
          _buildProgressBar(),
          const SizedBox(height: 16),

          // Stats Grid
          _buildStatsGrid(),

          // Last studied
          if (progress.lastStudiedAt != null) ...[
            const SizedBox(height: 16),
            _buildLastStudied(),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final percent = progress.progressPercent / 100;
    final masteryPercent = progress.masteryPercent / 100;

    return Column(
      children: [
        // Percentage Text
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${progress.progressPercent.toStringAsFixed(0)}% đã học',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getProgressColor(progress.progressPercent).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${progress.studiedCards}/${progress.totalCards} thẻ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _getProgressColor(progress.progressPercent),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Progress Bar with gradient
        // ✅ FIX: Progress Bar căn trái bằng LayoutBuilder
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final progressWidth = maxWidth * percent.clamp(0.0, 1.0);

            return Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Stack(
                children: [
                  // ✅ Progress bar căn trái
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: progressWidth,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),

        // Legend
        Row(
          children: [
            _buildLegendItem(AppColors.primary, 'Đang học'),
            const SizedBox(width: 16),
            _buildLegendItem(AppColors.background, 'Chưa học'),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.textGray),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(child: _buildStatItem(
          icon: Icons.pending,
          color: AppColors.warning,
          value: '${progress.learningCards}',
          label: 'Đang học',
        )),
        Expanded(child: _buildStatItem(
          icon: Icons.schedule,
          color: AppColors.textGray,
          value: '${progress.notStartedCards}',
          label: 'Chưa học',
        )),
        Expanded(child: _buildStatItem(
          icon: Icons.track_changes,
          color: progress.accuracyRate >= 70 ? AppColors.success : AppColors.warning,
          value: '${progress.accuracyRate.toStringAsFixed(0)}%',
          label: 'Độ chính xác',
        )),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: AppColors.textGray),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLastStudied() {
    final lastStudied = progress.lastStudiedAt!;
    final now = DateTime.now();
    final diff = now.difference(lastStudied);

    String timeAgo;
    if (diff.inMinutes < 1) {
      timeAgo = 'Vừa xong';
    } else if (diff.inMinutes < 60) {
      timeAgo = '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      timeAgo = '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      timeAgo = '${diff.inDays} ngày trước';
    } else {
      timeAgo = '${lastStudied.day}/${lastStudied.month}/${lastStudied.year}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: 14, color: AppColors.textGray),
          const SizedBox(width: 6),
          Text(
            'Học lần cuối: $timeAgo',
            style: TextStyle(fontSize: 12, color: AppColors.textGray),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double percent) {
    if (percent >= 80) return AppColors.success;
    if (percent >= 50) return AppColors.primary;
    if (percent >= 25) return AppColors.warning;
    return AppColors.textGray;
  }
}


// ==================== STUDY REMINDER CARD ====================

/// Widget cài đặt thời gian học tập
class StudyReminderCard extends StatelessWidget {
  final StudyReminderModel reminder;
  final Function(StudyReminderModel) onUpdate;
  final VoidCallback? onPickTime;

  const StudyReminderCard({
    Key? key,
    required this.reminder,
    required this.onUpdate,
    this.onPickTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with toggle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),  // ✅ Đổi thành success
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.notifications_active,
                  color: reminder.isEnabled ? AppColors.success : AppColors.textGray,  // ✅ Đổi thành success
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nhắc nhở học tập',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      'Duy trì thói quen học mỗi ngày',
                      style: TextStyle(fontSize: 12, color: AppColors.textGray),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: reminder.isEnabled,
                onChanged: (value) {
                  onUpdate(reminder.copyWith(isEnabled: value));
                },
                activeColor: AppColors.success,  // ✅ Đổi thành success
              ),
            ],
          ),

          if (reminder.isEnabled) ...[
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 20),

            // Time Picker
            _buildTimePicker(context),
            const SizedBox(height: 16),

            // Days of week
            _buildDaysSelector(),
          ],
        ],
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context) {
    return GestureDetector(
      onTap: () => _showTimePicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: AppColors.success, size: 22),  // ✅ Đổi thành success
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thời gian nhắc nhở',
                  style: TextStyle(fontSize: 12, color: AppColors.textGray),
                ),
                Text(
                  reminder.displayTime,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.edit, color: AppColors.textGray, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: reminder.hour, minute: reminder.minute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.success,  // ✅ Đổi thành success
              secondary: AppColors.success,  // ✅ Đổi thành success
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onUpdate(reminder.copyWith(hour: picked.hour, minute: picked.minute));
    }
  }

  Widget _buildDaysSelector() {
    const dayLabels = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nhắc nhở vào các ngày',
          style: TextStyle(fontSize: 13, color: AppColors.textGray),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final isEnabled = reminder.isDayEnabled(index);
            return GestureDetector(
              onTap: () => onUpdate(reminder.toggleDay(index)),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isEnabled ? AppColors.success : Colors.transparent,  // ✅ Đổi thành success
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isEnabled ? AppColors.success : AppColors.border,  // ✅ Đổi thành success
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    dayLabels[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isEnabled ? Colors.white : AppColors.textGray,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ==================== STREAK MINI CARD ====================

/// Widget hiển thị streak nhỏ gọn
class StreakMiniCard extends StatelessWidget {
  final StudyStreakModel streak;
  final VoidCallback? onTap;

  const StreakMiniCard({
    Key? key,
    required this.streak,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: streak.hasStudiedToday
                ? [AppColors.success, AppColors.success.withOpacity(0.8)]
                : streak.isStreakAtRisk
                ? [AppColors.warning, AppColors.warning.withOpacity(0.8)]
                : [AppColors.primary, AppColors.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (streak.hasStudiedToday ? AppColors.success : AppColors
                  .primary)
                  .withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Streak fire icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '🔥',
                style: TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 14),

            // Streak info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${streak.currentStreak}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'ngày streak',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    streak.hasStudiedToday
                        ? '✓ Đã học hôm nay'
                        : streak.isStreakAtRisk
                        ? '⚠ Học ngay để giữ streak!'
                        : 'Kỷ lục: ${streak.longestStreak} ngày',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Weekly dots
            _buildWeeklyDots(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyDots() {
    return Row(
      children: streak.weeklyData.take(7).map((day) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: day.isStudied ? Colors.white : Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        );
      }).toList(),
    );
  }
}
