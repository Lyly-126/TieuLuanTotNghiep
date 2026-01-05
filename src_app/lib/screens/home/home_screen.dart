import 'package:flutter/material.dart';
import 'package:src_app/screens/home/search_screen.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../models/class_model.dart';
import '../../services/class_service.dart';
import '../../widgets/custom_button.dart';
import '../class/class_detail_screen.dart';
import '../profile/profile_screen.dart';
import '../card/flashcard_creation_screen.dart';
import '../class/teacher_class_management_screen.dart';
import '../library/library_screen.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';
import '../../routes/app_routes.dart';
import '../category/category_detail_screen.dart';
import '../payment/upgrade_premium_screen.dart';
import '../../services/study_progress_service.dart';
import '../../models/study_progress_model.dart';

/// ✅ HOME SCREEN - FIX NAVIGATION
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

  // ✅ Streak variables - PHẢI ở trong _HomeScreenState
  StudyStreakModel? _streakInfo;
  bool _isLoadingStreak = true;

  final GlobalKey<_LibraryTabState> _libraryTabKey = GlobalKey<_LibraryTabState>();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadDefaultCategories();
    _loadStreakInfo();
  }

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

  Future<void> _loadCurrentUser() async {
    try {
      final user = await UserService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingUser = false);
      debugPrint('Error loading user: $e');
    }
  }

  Future<void> _loadStreakInfo() async {
    try {
      final streak = await StudyProgressService.getStreakInfo();
      if (mounted) {
        setState(() {
          _streakInfo = streak;
          _isLoadingStreak = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStreak = false);
      debugPrint('Error loading streak: $e');
    }
  }

  Future<void> _loadDefaultCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final categories = await CategoryService.getPublicCategories();
      final systemCategories = categories.where((cat) => cat.isSystem).toList();
      if (mounted) {
        setState(() {
          _defaultCategories = systemCategories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCategories = false);
      debugPrint('❌ Error loading default categories: $e');
    }
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      _showCreateBottomSheet();
      return;
    }
    setState(() => _selectedIndex = index);
  }

  void _showCreateBottomSheet() {
    final canCreate = _currentUser?.hasPremiumAccess ?? false;

    if (!canCreate) {
      _showUpgradeDialog();
      return;
    }

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
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => const FlashcardCreationScreen(),
                )).then((_) {
                  _loadDefaultCategories();
                });
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
                Navigator.pushNamed(
                  context,
                  AppRoutes.categoryCreate,
                  arguments: {'classId': null, 'className': null},
                ).then((_) {
                  _loadDefaultCategories();
                });
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
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.warning, AppColors.warning.withOpacity(0.7)],
                  ),
                ),
                child: const Icon(Icons.workspace_premium_rounded, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'Nâng cấp tài khoản',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
              ),
              const SizedBox(height: 12),
              Text(
                'Bạn cần nâng cấp lên Premium để sử dụng tính năng tạo thẻ và tạo chủ đề',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
              ),
              const SizedBox(height: 24),
              _buildBenefit(Icons.check_circle, 'Tạo thẻ không giới hạn'),
              const SizedBox(height: 8),
              _buildBenefit(Icons.check_circle, 'Tạo và quản lý chủ đề'),
              const SizedBox(height: 8),
              _buildBenefit(Icons.check_circle, 'Truy cập tất cả tính năng'),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Nâng cấp ngay',
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const UpgradePremiumScreen(),
                  ));
                },
                icon: Icons.arrow_forward_rounded,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Để sau', style: TextStyle(color: AppColors.textGray, fontSize: 15)),
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
        Icon(icon, size: 20, color: AppColors.success),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary))),
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
              decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ✅ _buildStreakSection PHẢI ở trong _HomeScreenState
  Widget _buildStreakSection() {
    if (_isLoadingStreak) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_streakInfo == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _streakInfo!.hasStudiedToday
              ? [const Color(0xFF4CAF50), const Color(0xFF81C784)]
              : _streakInfo!.isStreakAtRisk
              ? [const Color(0xFFFF9800), const Color(0xFFFFB74D)]
              : [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_streakInfo!.hasStudiedToday
                ? const Color(0xFF4CAF50)
                : AppColors.primary)
                .withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Fire icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('🔥', style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 16),

          // Streak info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_streakInfo!.currentStreak}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        'ngày streak',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _streakInfo!.hasStudiedToday
                      ? '✓ Đã học hôm nay'
                      : _streakInfo!.isStreakAtRisk
                      ? '⚠ Học ngay để giữ streak!'
                      : 'Kỷ lục: ${_streakInfo!.longestStreak} ngày',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          // Weekly dots
          Column(
            children: [
              Row(
                children: List.generate(7, (index) {
                  final isStudied = index < _streakInfo!.weeklyData.length
                      ? _streakInfo!.weeklyData[index].isStudied
                      : false;
                  return Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isStudied ? Colors.white : Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '7 ngày qua',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    final isTeacher = _currentUser?.canCreateClass ?? false;

    if (isTeacher) {
      return IndexedStack(
        index: _getActualIndex(_selectedIndex, isTeacher),
        children: [
          _buildHomeTab(),
          _buildCoursesTab(),
          _buildClassesTab(),
          _LibraryTab(
            key: _libraryTabKey,
            currentUser: _currentUser,
            onRefreshNeeded: _loadDefaultCategories,
          ),
        ],
      );
    } else {
      return IndexedStack(
        index: _getActualIndex(_selectedIndex, isTeacher),
        children: [
          _buildHomeTab(),
          _buildCoursesTab(),
          _LibraryTab(
            key: _libraryTabKey,
            currentUser: _currentUser,
            onRefreshNeeded: _loadDefaultCategories,
          ),
        ],
      );
    }
  }

  int _getActualIndex(int selectedIndex, bool isTeacher) {
    if (isTeacher) {
      switch (selectedIndex) {
        case 0: return 0;
        case 2: return 1;
        case 3: return 2;
        case 4: return 3;
        default: return 0;
      }
    } else {
      switch (selectedIndex) {
        case 0: return 0;
        case 2: return 1;
        case 3: return 2;
        default: return 0;
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
                    style: AppTextStyles.heading2.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hôm nay học gì cùng Flai nhỉ?',
                    style: AppTextStyles.hint.copyWith(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
              InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: () => Navigator.of(context).push(PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const ProfileScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    var tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(CurveTween(curve: Curves.easeInOut));
                    return SlideTransition(position: animation.drive(tween), child: child);
                  },
                )),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.inputBackground,
                    border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/avatar.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 26),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ✅ STREAK WIDGET
          _buildStreakSection(),

          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_outlined, color: AppColors.textGray, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tìm chủ đề, lớp học, mã lớp...',
                      style: AppTextStyles.hint.copyWith(color: AppColors.textGray, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 36),
          Text(
            'Bộ thẻ đang học',
            style: AppTextStyles.heading3.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w700, fontSize: 17),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOEIC 600+',
                  style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Đã học 36/120 thẻ',
                  style: AppTextStyles.hint.copyWith(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: 36 / 120,
                    minHeight: 8,
                    backgroundColor: AppColors.textGray.withOpacity(0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 18),
                CustomButton(text: 'Học tiếp', onPressed: () {}, height: 46),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Gợi ý cho bạn',
            style: AppTextStyles.heading3.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w700, fontSize: 17),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Học 5 thẻ mới hôm nay',
                        style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Giúp bạn ghi nhớ từ vựng nhanh hơn',
                        style: AppTextStyles.hint.copyWith(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                CustomButton(text: 'Học ngay', width: 110, height: 42, onPressed: () {}),
              ],
            ),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Widget _buildCoursesTab() {
    if (_isLoadingCategories) {
      return Column(
        children: [
          _buildCoursesHeader(),
          const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
        ],
      );
    }

    if (_defaultCategories.isEmpty) {
      return Column(
        children: [
          _buildCoursesHeader(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('Chưa có khóa học nào', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Các khóa học sẽ được hiển thị ở đây', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildCoursesHeader(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadDefaultCategories,
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _defaultCategories.length,
              itemBuilder: (context, index) => _buildCategoryCard(_defaultCategories[index], index),
            ),
          ),
        ),
      ],
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
              builder: (context) => CategoryDetailScreen(
                category: category,
                isOwner: category.ownerUserId == _currentUser?.userId,
              ),
            )).then((_) => _loadDefaultCategories());
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
                      const SizedBox(height: 4),
                      if (category.description != null && category.description!.isNotEmpty)
                        Text(
                          category.description!,
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildBadge('${category.flashcardCount} thẻ', gradientColors[0]),
                          const SizedBox(width: 8),
                          _buildBadge('🌐 Khóa học', Colors.blue),
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

  Widget _buildCoursesHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Center(
        child: Text('Khóa học', style: AppTextStyles.heading2.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildClassesTab() => const TeacherClassManagementScreen();

  Widget _buildBottomNav() {
    final isTeacher = _currentUser?.canCreateClass ?? false;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(index: 0, icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Trang chủ'),
              _buildNavItem(index: 1, icon: Icons.add_outlined, activeIcon: Icons.add_rounded, label: 'Tạo', isCreateButton: false),
              _buildNavItem(index: 2, icon: Icons.school_outlined, activeIcon: Icons.school_rounded, label: 'Khóa học'),
              if (isTeacher)
                _buildNavItem(index: 3, icon: Icons.class_outlined, activeIcon: Icons.class_rounded, label: 'Lớp học'),
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
              color: isSelected ? AppColors.primary : (isCreateButton ? AppColors.primary : AppColors.textGray),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : (isCreateButton ? AppColors.primary : AppColors.textGray),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== LIBRARY TAB WIDGET ====================
class _LibraryTab extends StatefulWidget {
  final UserModel? currentUser;
  final VoidCallback? onRefreshNeeded;

  const _LibraryTab({
    super.key,
    this.currentUser,
    this.onRefreshNeeded,
  });

  @override
  State<_LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<_LibraryTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  bool _isRefreshing = false;

  List<CategoryModel> _myCategories = [];
  List<ClassModel> _myClasses = [];
  List<CategoryModel> _savedCategories = [];

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
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadMyCategories(),
        _loadJoinedClasses(),
        _loadSavedCategories(),
      ]);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMyCategories() async {
    try {
      final categories = await CategoryService.getUserCategories();
      final userCreatedOnly = categories.where((cat) =>
      !cat.isSystem && cat.ownerUserId == widget.currentUser?.userId
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Thư viện',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Của tôi'),
                  Tab(text: 'Lớp học'),
                  Tab(text: 'Đã lưu'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : TabBarView(
            controller: _tabController,
            children: [
              _buildMyTab(),
              _buildClassesTab(),
              _buildSavedTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMyTab() {
    if (widget.currentUser?.role == 'NORMAL_USER') {
      return _buildUpgradePrompt();
    }

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
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _myCategories.length,
        itemBuilder: (context, index) => _buildCategoryCard(_myCategories[index], index),
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
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _myClasses.length,
        itemBuilder: (context, index) => _buildClassCard(_myClasses[index], index),
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
              builder: (context) => CategoryDetailScreen(
                category: category,
                isOwner: category.ownerUserId == widget.currentUser?.userId,
              ),
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
                        Text(
                          category.description!,
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                      Text(
                        classModel.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (classModel.description != null && classModel.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          classModel.description!,
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(fontSize: 14, color: AppColors.textSecondary.withOpacity(0.7)), textAlign: TextAlign.center),
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
            const Text(
              'Nâng cấp Premium',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Chức năng này chỉ dành cho người dùng Premium',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UpgradePremiumScreen())),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Nâng cấp ngay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}