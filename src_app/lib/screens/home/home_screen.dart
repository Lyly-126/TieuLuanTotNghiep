import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import '../profile/profile_screen.dart';
import '../card/flashcard_creation_screen.dart';
import '../class/teacher_class_management_screen.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  UserModel? _currentUser;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  /// Load thông tin user hiện tại
  Future<void> _loadCurrentUser() async {
    try {
      final user = await UserService.getCurrentUser();
      setState(() {
        _currentUser = user;
        _isLoadingUser = false;
      });
      print('✅ Loaded user: ${user?.email}, role: ${user?.role}');
      print('✅ Can create class: ${user?.canCreateClass}');
    } catch (e) {
      setState(() {
        _isLoadingUser = false;
      });
      debugPrint('❌ Lỗi load user: $e');
    }
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      // Nút "Tạo" - hiển thị bottom sheet, KHÔNG thay đổi selected index
      _showCreateBottomSheet();
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  /// Hiển thị bottom sheet với options tạo flashcard/lớp học
  void _showCreateBottomSheet() {
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
            // Handle bar
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

            // Title
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

            // Option 1: Học phần - CHO TẤT CẢ USERS
            _buildCreateOption(
              icon: Icons.style_outlined,
              iconColor: AppColors.primary,
              iconBgColor: AppColors.primary.withOpacity(0.1),
              title: 'Học phần',
              subtitle: 'Tạo bộ flashcard học tập mới',
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

            // Option 2: Lớp học - CHỈ CHO TEACHER & ADMIN
            if (_currentUser?.canCreateClass ?? false) ...[
              const SizedBox(height: 12),
              _buildCreateOption(
                icon: Icons.school_outlined,
                iconColor: const Color(0xFF10B981),
                iconBgColor: const Color(0xFF10B981).withOpacity(0.1),
                title: 'Lớp học',
                subtitle: 'Tạo lớp học cho học sinh',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TeacherClassManagementScreen(),
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
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
    // Chuyển đổi giữa các tab
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 2:
        return _buildLibraryTab();
      case 3:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  /// Tab Home (nội dung chính)
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: AppConstants.screenPadding.copyWith(top: 20, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------- HEADER ----------------
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

              // ---------------- AVATAR ----------------
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

          // ---------------- SEARCH BAR ----------------
          Container(
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
                  child: TextField(
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Tìm bộ thẻ hoặc từ vựng...',
                      hintStyle: AppTextStyles.hint.copyWith(
                        color: AppColors.textGray,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // ---------------- BỘ THẺ ĐANG HỌC ----------------
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

          // ---------------- GỢI Ý HỌC TẬP ----------------
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
                        'Giúp bạn ghi nhớ từ vựng nhanh hơn ✈️',
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

  /// Tab Thư viện (danh sách chủ đề)
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

  /// Tab Profile
  Widget _buildProfileTab() {
    return const ProfileScreen();
  }

  /// Bottom Navigation Bar mới (4 tabs)
  Widget _buildBottomNav() {
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
              // Tab 1: Trang chủ
              _buildNavItem(
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Trang chủ',
              ),

              // Tab 2: Tạo (nút +) - KHÔNG BAO GIỜ ACTIVE
              _buildNavItem(
                index: 1,
                icon: Icons.add_outlined,
                activeIcon: Icons.add_rounded,
                label: 'Tạo',
                isCreateButton: false,
              ),

              // Tab 3: Thư viện
              _buildNavItem(
                index: 2,
                icon: Icons.folder_open_outlined,
                activeIcon: Icons.folder_open_rounded,
                label: 'Thư viện',
              ),

              // Tab 4: Thư miễn phí (Profile)
              _buildNavItem(
                index: 3,
                icon: Icons.search_outlined,
                activeIcon: Icons.search_rounded,
                label: 'Thư miễn phí',
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
    // ✅ FIX: Nút Tạo không bao giờ là selected
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
}