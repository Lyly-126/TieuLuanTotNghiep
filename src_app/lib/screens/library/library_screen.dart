// File: lib/screens/library/library_screen.dart
import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../routes/app_routes.dart';
import '../../models/category_model.dart';
import '../../models/class_model.dart';
import '../../models/user_model.dart';
import '../../services/category_service.dart';
import '../../services/class_service.dart';
import '../../services/user_service.dart';
import '../category/category_detail_screen.dart';
import '../class/class_detail_screen.dart';
import '../payment/upgrade_premium_screen.dart';
import '../card/flashcard_creation_screen.dart';

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

  List<CategoryModel> _myCategories = [];
  List<ClassModel> _myClasses = [];
  List<CategoryModel> _savedCategories = [];

  // ✅ Gradients cho category cards
  List<Color> _getGradientColors(int index) {
    final gradients = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)],
      [const Color(0xFF11998e), const Color(0xFF38ef7d)],
      [const Color(0xFFfc4a1a), const Color(0xFFf7b733)],
      [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
      [const Color(0xFFf093fb), const Color(0xFFf5576c)],
      [const Color(0xFF30cfd0), const Color(0xFF330867)],
      [const Color(0xFFa8edea), const Color(0xFFfed6e3)],
      [const Color(0xFF5ee7df), const Color(0xFFb490ca)],
    ];
    return gradients[index % gradients.length];
  }

  IconData _getCategoryIcon(int index) {
    final icons = [
      Icons.auto_stories_rounded,
      Icons.psychology_rounded,
      Icons.rocket_launch_rounded,
      Icons.lightbulb_rounded,
      Icons.school_rounded,
      Icons.emoji_objects_rounded,
      Icons.workspace_premium_rounded,
      Icons.stars_rounded,
    ];
    return icons[index % icons.length];
  }

  @override
  void initState() {
    super.initState();
    // ✅ KHỞI TẠO VỚI INDEX MẶC ĐỊNH
    _tabController = TabController(length: 3, vsync: this);
    _loadUserAndData();
  }

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
      final userCreatedOnly = categories.where((cat) =>
      !cat.isSystem && cat.ownerUserId == _currentUser?.userId
      ).toList();
      if (mounted) setState(() => _myCategories = userCreatedOnly);
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
        case 0: await _loadMyCategories(); break;
        case 1: await _loadJoinedClasses(); break;
        case 2: await _loadSavedCategories(); break;
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
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
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text('Thư viện', style: AppTextStyles.heading2.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          tabs: const [Tab(text: 'Của tôi'), Tab(text: 'Lớp học'), Tab(text: 'Đã lưu')],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(controller: _tabController, children: [_buildMyTab(), _buildClassesTab(), _buildSavedTab()]),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildMyTab() {
    if (_currentUser?.role == 'NORMAL_USER') return _buildUpgradePrompt();

    if (_myCategories.isEmpty) {
      return _buildEmptyState(icon: Icons.collections_bookmark, title: 'Chưa có chủ đề nào', subtitle: 'Tạo chủ đề mới để bắt đầu học!');
    }
    return RefreshIndicator(
      onRefresh: _refreshCurrentTab,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _myCategories.length,
        itemBuilder: (context, index) => _buildCategoryCard(_myCategories[index], index),
      ),
    );
  }

  Widget _buildClassesTab() {
    if (_myClasses.isEmpty) {
      return _buildEmptyState(icon: Icons.school, title: 'Chưa tham gia lớp học nào', subtitle: 'Tham gia hoặc tạo lớp học để học cùng nhau!');
    }
    return RefreshIndicator(
      onRefresh: _refreshCurrentTab,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _myClasses.length,
        itemBuilder: (context, index) => _buildClassCard(_myClasses[index], index),
      ),
    );
  }

  Widget _buildSavedTab() {
    if (_savedCategories.isEmpty) {
      return _buildEmptyState(icon: Icons.bookmark_border, title: 'Chưa có chủ đề nào được lưu', subtitle: 'Lưu các chủ đề yêu thích để học lại!');
    }
    return RefreshIndicator(
      onRefresh: _refreshCurrentTab,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _savedCategories.length,
        itemBuilder: (context, index) => _buildCategoryCard(_savedCategories[index], index),
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category, int index) {
    final gradientColors = _getGradientColors(index);
    final iconData = _getCategoryIcon(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: gradientColors[0].withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => CategoryDetailScreen(category: category, isOwner: category.ownerUserId == _currentUser?.userId),
            )).then((_) => _refreshCurrentTab());
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradientColors),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: gradientColors[0].withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Icon(iconData, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (category.description != null && category.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(category.description!, style: TextStyle(fontSize: 13, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildBadge('${category.flashcardCount} thẻ', gradientColors[0]),
                          const SizedBox(width: 8),
                          _buildBadge(category.typeDisplayName, Colors.grey),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClassCard(ClassModel classModel, int index) {
    final gradientColors = _getGradientColors(index + 3);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: gradientColors[0].withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => ClassDetailScreen(classId: classModel.id, isOwner: false),
            )).then((_) => _refreshCurrentTab());
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradientColors),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: gradientColors[0].withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(classModel.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (classModel.description != null && classModel.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(classModel.description!, style: TextStyle(fontSize: 13, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildBadge('${classModel.memberCount ?? 0} thành viên', gradientColors[0]),
                          const SizedBox(width: 8),
                          _buildBadge('🏫 Lớp học', Colors.blue),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: AppColors.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.heading2.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary.withOpacity(0.7)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradePrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.workspace_premium, size: 60, color: AppColors.warning),
            ),
            const SizedBox(height: 24),
            Text('Nâng cấp Premium', style: AppTextStyles.heading1.copyWith(color: AppColors.primaryDark), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text('Chức năng này chỉ dành cho người dùng Premium', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UpgradePremiumScreen())),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Nâng cấp ngay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            const Text('Tạo mới', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Chọn loại nội dung bạn muốn tạo', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 24),
            _buildCreateOption(
              icon: Icons.style_outlined,
              iconColor: AppColors.primary,
              iconBgColor: AppColors.primary.withOpacity(0.1),
              title: 'Tạo thẻ',
              subtitle: 'Tạo flashcard học tập mới',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const FlashcardCreationScreen())).then((_) => _refreshCurrentTab());
              },
            ),
            const SizedBox(height: 12),
            _buildCreateOption(
              icon: Icons.folder_outlined,
              iconColor: const Color(0xFF10B981),
              iconBgColor: const Color(0xFF10B981).withOpacity(0.1),
              title: 'Tạo chủ đề',
              subtitle: 'Tạo chủ đề để quản lý thẻ',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.categoryCreate, arguments: {'classId': null, 'className': null}).then((_) => _refreshCurrentTab());
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateOption({required IconData icon, required Color iconColor, required Color iconBgColor, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: iconColor, size: 24)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ])),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  // ✅ SỬA LẠI HÀM NÀY - XỬ LÝ NAVIGATION ĐÚNG
  void _onBottomNavTapped(int index) {
    final isTeacher = _currentUser?.canCreateClass ?? false;
    final libraryIndex = isTeacher ? 4 : 3;

    // Nếu đang ở màn Library và bấm vào Library → không làm gì
    if (index == libraryIndex) return;

    if (index == 1) {
      // Nút tạo
      final canCreate = _currentUser?.hasPremiumAccess ?? false;
      if (!canCreate) {
        _showUpgradeDialog();
      } else {
        _showCreateBottomSheet();
      }
      return;
    }

    // ✅ XỬ LÝ NAVIGATION
    if (index == 0) {
      // Trang chủ - pop về với index 0
      Navigator.pop(context, 0);
    } else if (index == 2) {
      // Khóa học - pop về với index 2
      Navigator.pop(context, 2);
    } else if (isTeacher && index == 3) {
      // Lớp học (teacher) - pop về với index 3
      Navigator.pop(context, 3);
    }
  }

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
              Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.warning, AppColors.warning.withOpacity(0.7)])), child: const Icon(Icons.workspace_premium_rounded, size: 40, color: Colors.white)),
              const SizedBox(height: 20),
              const Text('Nâng cấp tài khoản', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
              const SizedBox(height: 12),
              Text('Bạn cần nâng cấp lên Premium để sử dụng tính năng tạo thẻ và tạo chủ đề', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const UpgradePremiumScreen())); },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                child: const Text('Nâng cấp ngay'),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Để sau', style: TextStyle(color: AppColors.textGray, fontSize: 15))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final isTeacher = _currentUser?.canCreateClass ?? false;

    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))]),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(index: 0, icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Trang chủ'),
              _buildBottomNavItem(index: 1, icon: Icons.add_outlined, activeIcon: Icons.add_rounded, label: 'Tạo', isCreateButton: false),
              _buildBottomNavItem(index: 2, icon: Icons.school_outlined, activeIcon: Icons.school_rounded, label: 'Khóa học'),
              if (isTeacher) _buildBottomNavItem(index: 3, icon: Icons.class_outlined, activeIcon: Icons.class_rounded, label: 'Lớp học'),
              _buildBottomNavItem(index: isTeacher ? 4 : 3, icon: Icons.folder_open_outlined, activeIcon: Icons.folder_open_rounded, label: 'Thư viện', isSelected: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({required int index, required IconData icon, required IconData activeIcon, required String label, bool isCreateButton = false, bool isSelected = false}) {
    return InkWell(
      onTap: () => _onBottomNavTapped(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : icon, size: isCreateButton ? 28 : 24, color: isSelected ? AppColors.primary : isCreateButton ? AppColors.primary : AppColors.textGray),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: isSelected ? AppColors.primary : isCreateButton ? AppColors.primary : AppColors.textGray)),
          ],
        ),
      ),
    );
  }
}