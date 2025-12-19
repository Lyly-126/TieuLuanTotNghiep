// File: lib/screens/library/library_screen.dart
import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../models/category_model.dart';
import '../../models/class_model.dart';
import '../../models/user_model.dart';
import '../../services/category_service.dart';
import '../../services/class_service.dart';
import '../../services/user_service.dart';
import '../card/flashcard_screen.dart';
import '../class/class_detail_screen.dart';
import '../payment/upgrade_premium_screen.dart';

/// ✅ Màn hình thư viện với 3 tabs: Của tôi, Lớp học, Đã lưu
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isRefreshing = false;

  // Dữ liệu cho từng tab
  List<CategoryModel> _myCategories = [];
  List<ClassModel> _myClasses = [];
  List<CategoryModel> _savedCategories = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserAndData();

    // ✅ BỎ listener tự động chuyển hướng
    // _tabController.addListener(_handleTabChange);
  }

  // ✅ BỎ method _handleTabChange - không tự động redirect nữa

  Future<void> _loadUserAndData() async {
    setState(() => _isLoading = true);
    try {
      final user = await UserService.getCurrentUser();
      if (!mounted) return;
      setState(() => _currentUser = user);
      await Future.wait([
        _loadMyCategories(),
        _loadJoinedClasses(),
        _loadSavedCategories(),
      ]);
    } catch (e) {
      if (mounted) _showErrorSnackBar('Không thể tải dữ liệu: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMyCategories() async {
    try {
      final categories = await CategoryService.getUserCategories();
      if (mounted) setState(() => _myCategories = categories);
    } catch (e) {
      debugPrint('Error loading my categories: $e');
    }
  }

  Future<void> _loadJoinedClasses() async {
    try {
      final classes = await ClassService.getJoinedClasses();
      if (mounted) setState(() => _myClasses = classes);
    } catch (e) {
      debugPrint('Error loading joined classes: $e');
    }
  }

  Future<void> _loadSavedCategories() async {
    try {
      final categories = await CategoryService.getSavedCategories();
      if (mounted) setState(() => _savedCategories = categories);
    } catch (e) {
      debugPrint('Error loading saved categories: $e');
    }
  }

  Future<void> _refreshCurrentTab() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      switch (_tabController.index) {
        case 0:
          await _loadMyCategories();
          break;
        case 1:
          await _loadJoinedClasses();
          break;
        case 2:
          await _loadSavedCategories();
          break;
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    // ✅ Không cần remove listener nữa
    // _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.primary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Thư viện',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Của tôi'),
            Tab(text: 'Lớp học'),
            Tab(text: 'Đã lưu'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
        controller: _tabController,
        children: [_buildMyTab(), _buildClassesTab(), _buildSavedTab()],
      ),
    );
  }

  Widget _buildMyTab() {
    // ✅ CHỈ hiển thị upgrade prompt - KHÔNG tự động chuyển hướng
    if (_currentUser?.role == 'NORMAL_USER') return _buildUpgradePrompt();

    if (_myCategories.isEmpty) {
      return _buildEmptyState(
        icon: Icons.collections_bookmark,
        title: 'Chưa có chủ đề nào',
        subtitle: 'Tạo chủ đề mới để bắt đầu học!',
      );
    }
    return RefreshIndicator(
      onRefresh: _refreshCurrentTab,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.padding),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _myCategories.length,
        itemBuilder: (context, index) => _buildCategoryCard(_myCategories[index]),
      ),
    );
  }

  Widget _buildClassesTab() {
    if (_myClasses.isEmpty) {
      return _buildEmptyState(
        icon: Icons.school,
        title: 'Chưa tham gia lớp học nào',
        subtitle: 'Tham gia hoặc tạo lớp học để học cùng nhau!',
      );
    }
    return RefreshIndicator(
      onRefresh: _refreshCurrentTab,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.padding),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _myClasses.length,
        itemBuilder: (context, index) => _buildClassCard(_myClasses[index]),
      ),
    );
  }

  Widget _buildSavedTab() {
    if (_savedCategories.isEmpty) {
      return _buildEmptyState(
        icon: Icons.bookmark_border,
        title: 'Chưa có chủ đề nào được lưu',
        subtitle: 'Lưu các chủ đề yêu thích để học lại!',
      );
    }
    return RefreshIndicator(
      onRefresh: _refreshCurrentTab,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.padding),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _savedCategories.length,
        itemBuilder: (context, index) =>
            _buildCategoryCard(_savedCategories[index]),
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.padding),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => FlashcardScreen(categoryId: category.id)),
          ).then((_) => _refreshCurrentTab());
        },
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.style,
                        color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category.name,
                      style: AppTextStyles.heading2
                          .copyWith(color: AppColors.primaryDark),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (category.description != null &&
                  category.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  category.description!,
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    icon: Icons.style,
                    label: '${category.flashcardCount ?? 0} thẻ',
                    color: AppColors.primary,
                  ),
                  _buildInfoChip(
                    icon: Icons.category,
                    label: category.typeDisplayName,
                    color: AppColors.secondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassCard(ClassModel classModel) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.padding),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ClassDetailScreen(classId: classModel.id, isOwner: false),
            ),
          ).then((_) => _refreshCurrentTab());
        },
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.school,
                        color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          classModel.name,
                          style: AppTextStyles.heading2
                              .copyWith(color: AppColors.primaryDark),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (classModel.description != null &&
                            classModel.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            classModel.description!,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    icon: Icons.person,
                    label: classModel.ownerName ?? 'Giáo viên',
                    color: AppColors.secondary,
                  ),
                  _buildInfoChip(
                    icon: Icons.people,
                    label: '${classModel.memberCount ?? 0} thành viên',
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.padding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 80, color: AppColors.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              title,
              style:
              AppTextStyles.heading2.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradePrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.padding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium,
                  size: 60, color: AppColors.warning),
            ),
            const SizedBox(height: 24),
            Text(
              'Nâng cấp Premium',
              style:
              AppTextStyles.heading1.copyWith(color: AppColors.primaryDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Chức năng này chỉ dành cho người dùng Premium',
              style:
              AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const UpgradePremiumScreen()),
                );
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Nâng cấp ngay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(AppConstants.borderRadius),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}