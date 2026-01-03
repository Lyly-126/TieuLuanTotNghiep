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
import '../../models/category_model.dart';
import '../../services/category_service.dart';
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

  // ✅ Helper để lấy gradient màu theo index
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

  // ✅ Helper để lấy icon theo index
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

  void _onItemTapped(int index) async {
    if (index == 1) {
      _showCreateBottomSheet();
      return;
    }

    final isTeacher = _currentUser?.canCreateClass ?? false;
    final libraryIndex = isTeacher ? 4 : 3;

    if (index == libraryIndex) {
      // ✅ ĐI ĐẾN LIBRARY VÀ NHẬN KẾT QUẢ
      final result = await Navigator.pushNamed(context, '/library');

      // ✅ CHỈ CẬP NHẬT NẾU RESULT LÀ INT (không null)
      if (result != null && result is int && mounted) {
        setState(() => _selectedIndex = result);
      }
      // ✅ NẾU result == null → User swipe back → KHÔNG LÀM GÌ, GIỮ NGUYÊN TAB LIBRARY
    } else {
      // ✅ CHUYỂN TAB BÌNH THƯỜNG
      setState(() => _selectedIndex = index);
    }
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
                Navigator.push(context, MaterialPageRoute(builder: (context) => const FlashcardCreationScreen()));
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
                Navigator.pushNamed(context, AppRoutes.categoryCreate, arguments: {'classId': null, 'className': null});
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
              const Text('Nâng cấp tài khoản', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
              const SizedBox(height: 12),
              Text('Bạn cần nâng cấp lên Premium để sử dụng tính năng tạo thẻ và tạo chủ đề', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5)),
              const SizedBox(height: 24),
              _buildBenefit(Icons.check_circle, 'Tạo thẻ không giới hạn'),
              const SizedBox(height: 8),
              _buildBenefit(Icons.check_circle, 'Tạo và quản lý chủ đề'),
              const SizedBox(height: 8),
              _buildBenefit(Icons.check_circle, 'Truy cập tất cả tính năng'),
              const SizedBox(height: 24),
              CustomButton(text: 'Nâng cấp ngay', onPressed: () { Navigator.pop(context); Navigator.pushNamed(context, '/upgrade_premium'); }, icon: Icons.arrow_forward_rounded),
              const SizedBox(height: 12),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Để sau', style: TextStyle(color: AppColors.textGray, fontSize: 15))),
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

  Widget _buildCreateOption({required IconData icon, required Color iconColor, required Color iconBgColor, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
        child: Row(
          children: [
            Container(width: 56, height: 56, decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor, size: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ]),
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
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    final isTeacher = _currentUser?.canCreateClass ?? false;
    if (isTeacher) {
      switch (_selectedIndex) {
        case 0: return _buildHomeTab();
        case 2: return _buildCoursesTab();
        case 3: return _buildClassesTab();
        case 4: return _buildLibraryTab();
        default: return _buildHomeTab();
      }
    } else {
      switch (_selectedIndex) {
        case 0: return _buildHomeTab();
        case 2: return _buildCoursesTab();
        case 3: return _buildLibraryTab();
        default: return _buildHomeTab();
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
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Chào nhé!', style: AppTextStyles.heading2.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Hôm nay học gì cùng Flai nhỉ?', style: AppTextStyles.hint.copyWith(color: AppColors.textSecondary, fontSize: 14)),
              ]),
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
                  width: 48, height: 48,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.inputBackground, border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1)),
                  child: ClipOval(child: Image.asset('assets/images/avatar.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 26))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: AppColors.inputBackground, borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2)),
              child: Row(children: [
                const Icon(Icons.search_outlined, color: AppColors.textGray, size: 22),
                const SizedBox(width: 10),
                Expanded(child: Text('Tìm chủ đề, lớp học, mã lớp...', style: AppTextStyles.hint.copyWith(color: AppColors.textGray, fontSize: 14))),
              ]),
            ),
          ),
          const SizedBox(height: 36),
          Text('Bộ thẻ đang học', style: AppTextStyles.heading3.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w700, fontSize: 17)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TOEIC 600+', style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Đã học 36/120 thẻ', style: AppTextStyles.hint.copyWith(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 12),
              ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: 36 / 120, minHeight: 8, backgroundColor: AppColors.textGray.withOpacity(0.15), valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary))),
              const SizedBox(height: 18),
              CustomButton(text: 'Học tiếp', onPressed: () {}, height: 46),
            ]),
          ),
          const SizedBox(height: 40),
          Text('Gợi ý cho bạn', style: AppTextStyles.heading3.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w700, fontSize: 17)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Học 5 thẻ mới hôm nay', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 15)),
                const SizedBox(height: 4),
                Text('Giúp bạn ghi nhớ từ vựng nhanh hơn', style: AppTextStyles.hint.copyWith(color: AppColors.textSecondary, fontSize: 13)),
              ])),
              const SizedBox(width: 12),
              CustomButton(text: 'Học ngay', width: 110, height: 42, onPressed: () {}),
            ]),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Widget _buildLibraryTab() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.folder_open_outlined, size: 80, color: Colors.grey[400]),
      const SizedBox(height: 16),
      const Text('Thư viện của tôi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('Danh sách chủ đề từ vựng', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
    ]));
  }

  Widget _buildCoursesTab() {
    if (_isLoadingCategories) {
      return Column(children: [_buildCoursesHeader(), const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))]);
    }
    if (_defaultCategories.isEmpty) {
      return Column(children: [
        _buildCoursesHeader(),
        Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.school_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('Chưa có khóa học nào', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Các khóa học sẽ được hiển thị ở đây', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ]))),
      ]);
    }

    // ✅ LIST VIEW DỌC - ĐẸP HƠN
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

  // ✅ CATEGORY CARD ĐẸP - DẠNG LIST DỌC
  Widget _buildCategoryCard(CategoryModel category, int index) {
    final gradientColors = _getGradientColors(index);
    final iconData = _getCategoryIcon(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: gradientColors[0].withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => CategoryDetailScreen(category: category, isOwner: category.ownerUserId == _currentUser?.userId),
            )).then((_) => _loadDefaultCategories());
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // ✅ Icon với gradient background
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
                // ✅ Content
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
                      // ✅ Badges
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
                // ✅ Arrow
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
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))]),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _buildNavItem(index: 0, icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Trang chủ'),
            _buildNavItem(index: 1, icon: Icons.add_outlined, activeIcon: Icons.add_rounded, label: 'Tạo', isCreateButton: false),
            _buildNavItem(index: 2, icon: Icons.school_outlined, activeIcon: Icons.school_rounded, label: 'Khóa học'),
            if (isTeacher) _buildNavItem(index: 3, icon: Icons.class_outlined, activeIcon: Icons.class_rounded, label: 'Lớp học'),
            _buildNavItem(index: isTeacher ? 4 : 3, icon: Icons.folder_open_outlined, activeIcon: Icons.folder_open_rounded, label: 'Thư viện'),
          ]),
        ),
      ),
    );
  }

  Widget _buildNavItem({required int index, required IconData icon, required IconData activeIcon, required String label, bool isCreateButton = false}) {
    final isSelected = !isCreateButton && _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(isSelected ? activeIcon : icon, size: isCreateButton ? 28 : 24, color: isSelected ? AppColors.primary : isCreateButton ? AppColors.primary : AppColors.textGray),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: isSelected ? AppColors.primary : isCreateButton ? AppColors.primary : AppColors.textGray)),
        ]),
      ),
    );
  }

  Future<void> _loadDefaultCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final categories = await CategoryService.getPublicCategories();
      final systemCategories = categories.where((cat) => cat.isSystem).toList();
      if (mounted) setState(() { _defaultCategories = systemCategories; _isLoadingCategories = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoadingCategories = false);
      debugPrint('❌ Error loading default categories: $e');
    }
  }
}