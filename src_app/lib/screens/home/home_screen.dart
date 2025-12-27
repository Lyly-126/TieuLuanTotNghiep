import 'package:flutter/material.dart';
import 'package:src_app/screens/home/search_screen.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import '../profile/profile_screen.dart';
import '../card/flashcard_creation_screen.dart';
import '../class/teacher_class_management_screen.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../models/category_model.dart';      // ✅ THÊM
import '../../services/category_service.dart';  // ✅ THÊM
import '../../routes/app_routes.dart';
import '../category/category_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();

}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  UserModel? _currentUser;
  bool _isLoadingUser = true;
  List<CategoryModel> _defaultCategories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadDefaultCategories();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await UserService.getCurrentUser();
      setState(() {
        _currentUser = user;
        _isLoadingUser = false;
      });
      print('Loaded user: ${user?.email}, role: ${user?.role}');
      print('Can create class: ${user?.canCreateClass}');
    } catch (e) {
      setState(() {
        _isLoadingUser = false;
      });
      debugPrint('Error loading user: $e');
    }
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      _showCreateBottomSheet();
    } else {
      // Check if this is Library tab
      final isTeacher = _currentUser?.canCreateClass ?? false;
      final libraryIndex = isTeacher ? 4 : 3;

      if (index == libraryIndex) {
        // Navigate to Library Screen
        Navigator.pushNamed(context, '/library');
      } else {
        setState(() => _selectedIndex = index);
      }
    }
  }

  void _showCreateBottomSheet() {
    // Check if user can create (Premium or Teacher)
    final canCreate = _currentUser?.hasPremiumAccess ?? false;

    if (!canCreate) {
      // Show upgrade dialog for normal users
      _showUpgradeDialog();
      return;
    }

    // Show create options for Premium/Teacher
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Tạo mới',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chọn loại nội dung bạn muốn tạo',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Option 1: Tạo thẻ - CHO PREMIUM/TEACHER
            _buildCreateOption(
              icon: Icons.style_outlined,
              iconColor: AppColors.primary,
              iconBgColor: AppColors.primary.withOpacity(0.1),
              title: 'Tạo thẻ',
              subtitle: 'Tạo flashcard học tập mới',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FlashcardCreationScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Option 2: Tạo chủ đề - CHO PREMIUM/TEACHER
            _buildCreateOption(
              icon: Icons.folder_outlined,
              iconColor: const Color(0xFF10B981),
              iconBgColor: const Color(0xFF10B981).withOpacity(0.1),
              title: 'Tạo chủ đề',
              subtitle: 'Tạo chủ đề để quản lý thẻ',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  AppRoutes.categoryCreate,
                  arguments: {
                    'classId': null,
                    'className': null,
                  },
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.warning,
                      AppColors.warning.withOpacity(0.7),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Nâng cấp tài khoản',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'Bạn cần nâng cấp lên Premium để sử dụng tính năng tạo thẻ và tạo chủ đề',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Benefits
              _buildBenefit(Icons.check_circle, 'Tạo thẻ không giới hạn'),
              const SizedBox(height: 8),
              _buildBenefit(Icons.check_circle, 'Tạo và quản lý chủ đề'),
              const SizedBox(height: 8),
              _buildBenefit(Icons.check_circle, 'Truy cập tất cả tính năng'),
              const SizedBox(height: 24),

              // Buttons
              CustomButton(
                text: 'Nâng cấp ngay',
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to Upgrade Premium Screen using named route
                  Navigator.pushNamed(context, '/upgrade_premium');
                },
                icon: Icons.arrow_forward_rounded,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Để sau',
                  style: TextStyle(
                    color: AppColors.textGray,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.success,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateOption({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _buildBody(),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    final isTeacher = _currentUser?.canCreateClass ?? false;

    if (isTeacher) {
      // TEACHER: 5 tabs
      switch (_selectedIndex) {
        case 0:
          return _buildHomeTab();
        case 2:
          return _buildCoursesTab();
        case 3:
          return _buildClassesTab();
        case 4:
          return _buildLibraryTab();
        default:
          return _buildHomeTab();
      }
    } else {
      // NORMAL/PREMIUM USER: 4 tabs
      switch (_selectedIndex) {
        case 0:
          return _buildHomeTab();
        case 2:
          return _buildCoursesTab();
        case 3:
          return _buildLibraryTab();
        default:
          return _buildHomeTab();
      }
    }
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: AppConstants.screenPadding.copyWith(top: 20, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chào nhé!',
                    style: AppTextStyles.heading2.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hôm nay học gì cùng Flai nhỉ?',
                    style: AppTextStyles.hint.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                      const ProfileScreen(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOut;
                        var tween = Tween(begin: begin, end: end)
                            .chain(CurveTween(curve: curve));
                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                    ),
                  );
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.inputBackground,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/avatar.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius:
                BorderRadius.circular(AppConstants.borderRadius * 1.2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_outlined,
                      color: AppColors.textGray, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tìm chủ đề, lớp học, mã lớp...',
                      style: AppTextStyles.hint.copyWith(
                        color: AppColors.textGray,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 36),

          Text(
            'Bộ thẻ đang học',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(AppConstants.borderRadius * 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOEIC 600+',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Đã học 36/120 thẻ',
                  style: AppTextStyles.hint.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: 36 / 120,
                    minHeight: 8,
                    backgroundColor:
                    AppColors.textGray.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                CustomButton(
                  text: 'Học tiếp',
                  onPressed: () {},
                  height: 46,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          Text(
            'Gợi ý cho bạn',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(AppConstants.borderRadius * 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Học 5 thẻ mới hôm nay',
                        style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Giúp bạn ghi nhớ từ vựng nhanh hơn',
                        style: AppTextStyles.hint.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                CustomButton(
                  text: 'Học ngay',
                  width: 110,
                  height: 42,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Widget _buildLibraryTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Thư viện của tôi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Danh sách chủ đề từ vựng',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesTab() {
    // Show loading indicator
    if (_isLoadingCategories) {
      return Column(
        children: [
          _buildCoursesHeader(),
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      );
    }

    // Show empty state if no categories
    if (_defaultCategories.isEmpty) {
      return Column(
        children: [
          _buildCoursesHeader(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có khóa học nào',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Các khóa học sẽ được hiển thị ở đây',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Display categories list with header
    return Column(
      children: [
        _buildCoursesHeader(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadDefaultCategories,
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppConstants.padding),
              itemCount: _defaultCategories.length,
              itemBuilder: (context, index) {
                final category = _defaultCategories[index];
                return _buildCategoryCard(category);
              },
            ),
          ),
        ),
      ],
    );
  }

  // ✅ Build category card widget
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
              builder: (context) => CategoryDetailScreen(
                category: category,
                isOwner: category.ownerUserId == _currentUser?.userId,
              ),
            ),
          ).then((_) => _loadDefaultCategories());
        },
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: AppTextStyles.heading2.copyWith(
                            color: AppColors.primaryDark,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '🌐 Khóa học mặc định',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 11,
                              color: AppColors.info,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Description
              if (category.description != null &&
                  category.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  category.description!,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              // Flashcard count
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.style,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${category.flashcardCount ?? 0} thẻ',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Header cho tab Khóa học - Tiêu đề ở giữa
  Widget _buildCoursesHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Tiêu đề ở giữa
          Center(
            child: Text(
              'Khóa học',
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Nút back ở bên trái
          Positioned(
            left: 0,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              onPressed: () {
                // Quay về tab Home
                setState(() => _selectedIndex = 0);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassesTab() {
    return const TeacherClassManagementScreen();
  }

  Widget _buildBottomNav() {
    final isTeacher = _currentUser?.canCreateClass ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Trang chủ',
              ),

              _buildNavItem(
                index: 1,
                icon: Icons.add_outlined,
                activeIcon: Icons.add_rounded,
                label: 'Tạo',
                isCreateButton: false,
              ),

              _buildNavItem(
                index: 2,
                icon: Icons.school_outlined,
                activeIcon: Icons.school_rounded,
                label: 'Khóa học',
              ),

              if (isTeacher)
                _buildNavItem(
                  index: 3,
                  icon: Icons.class_outlined,
                  activeIcon: Icons.class_rounded,
                  label: 'Lớp học',
                ),

              _buildNavItem(
                index: isTeacher ? 4 : 3,
                icon: Icons.folder_open_outlined,
                activeIcon: Icons.folder_open_rounded,
                label: 'Thư viện',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    bool isCreateButton = false,
  }) {
    final isSelected = !isCreateButton && _selectedIndex == index;

    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: isCreateButton ? 28 : 24,
              color: isSelected
                  ? AppColors.primary
                  : isCreateButton
                  ? AppColors.primary
                  : AppColors.textGray,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primary
                    : isCreateButton
                    ? AppColors.primary
                    : AppColors.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ✅ THÊM METHOD MỚI
  Future<void> _loadDefaultCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      // Lấy tất cả public categories
      final categories = await CategoryService.getPublicCategories();

      // Lọc chỉ lấy SYSTEM categories (default)
      final systemCategories = categories.where((cat) => cat.isSystem).toList();

      if (mounted) {
        setState(() {
          _defaultCategories = systemCategories;
          _isLoadingCategories = false;
        });
      }
      print('✅ Loaded ${systemCategories.length} default categories');
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
      debugPrint('❌ Error loading default categories: $e');
    }
  }
}