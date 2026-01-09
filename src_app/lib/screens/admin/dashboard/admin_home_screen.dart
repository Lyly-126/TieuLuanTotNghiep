import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../config/app_colors.dart';
import '../../../../config/app_constants.dart';
import '../../../../config/app_text_styles.dart';
import '../../../../widgets/admin_bottom_nav.dart';
import '../../../../services/admin_user_service.dart';
import '../../../../services/payment_service.dart';
import '../../../../services/category_service.dart';

/// ✅ ADMIN HOME SCREEN - DASHBOARD VỚI THỐNG KÊ REALTIME
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> with TickerProviderStateMixin {
  // Loading states
  bool _isLoading = true;
  String? _error;

  // Stats data
  AdminStats _stats = AdminStats.empty();

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadAllStats();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAllStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load tất cả data song song
      final results = await Future.wait([
        _loadUserStats(),
        _loadCategoryStats(),
      ]);

      final userStats = results[0] as UserStats;
      final categoryStats = results[1] as CategoryStats;

      if (mounted) {
        setState(() {
          _stats = AdminStats(
            userStats: userStats,
            categoryStats: categoryStats,
          );
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<UserStats> _loadUserStats() async {
    try {
      final users = await AdminUserService.getAllUsers();

      int totalUsers = users.length;
      int premiumUsers = 0;
      int normalUsers = 0;
      int teacherUsers = 0;
      int blockedUsers = 0;
      int activeToday = 0;
      int newThisMonth = 0;

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      for (var user in users) {
        // Count by role
        final role = user['role'] ?? '';
        if (role == 'PREMIUM_USER') {
          premiumUsers++;
        } else if (role == 'TEACHER') {
          teacherUsers++;
        } else if (role == 'NORMAL_USER') {
          normalUsers++;
        }

        // Count blocked
        if (user['isBlocked'] == true) {
          blockedUsers++;
        }

        // Count new this month (từ createdAt)
        final createdAt = user['createdAt'];
        if (createdAt != null) {
          try {
            final createdDate = DateTime.parse(createdAt.toString());
            if (createdDate.isAfter(startOfMonth)) {
              newThisMonth++;
            }
          } catch (_) {}
        }
      }

      return UserStats(
        total: totalUsers,
        premium: premiumUsers,
        normal: normalUsers,
        teacher: teacherUsers,
        blocked: blockedUsers,
        activeToday: activeToday,
        newThisMonth: newThisMonth,
      );
    } catch (e) {
      debugPrint('Error loading user stats: $e');
      return UserStats.empty();
    }
  }

  Future<CategoryStats> _loadCategoryStats() async {
    try {
      final categories = await CategoryService.getPublicCategories();

      int totalCategories = categories.length;
      int systemCategories = 0;
      int totalFlashcards = 0;

      for (var cat in categories) {
        if (cat.isSystem) systemCategories++;
        totalFlashcards += cat.flashcardCount!;
      }

      return CategoryStats(
        total: totalCategories,
        system: systemCategories,
        totalFlashcards: totalFlashcards,
      );
    } catch (e) {
      debugPrint('Error loading category stats: $e');
      return CategoryStats.empty();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _error != null
            ? _buildErrorState()
            : _buildDashboard(),
      ),
      bottomNavigationBar: AdminBottomNav(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) return;
          switch (index) {
            case 1:
              Navigator.pushReplacementNamed(context, '/admin_users_management');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/admin_study_packs');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/admin_policy');
              break;
          }
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Đang tải dữ liệu...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
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
              child: Icon(
                Icons.error_outline_rounded,
                size: 60,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Không thể tải dữ liệu',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Đã xảy ra lỗi không xác định',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAllStats,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadAllStats,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 24),

              // Overview Stats Grid
              _buildOverviewStats(),
              const SizedBox(height: 24),

              // User Distribution Chart
              _buildUserDistributionCard(),
              const SizedBox(height: 24),

              // Quick Actions
              _buildQuickActions(),
              const SizedBox(height: 24),

              // Recent Activity (Placeholder)
              _buildRecentActivityCard(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xin chào, Admin! 👋',
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getGreetingMessage(),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        // Refresh button
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            onPressed: _loadAllStats,
            icon: const Icon(Icons.refresh_rounded),
            color: AppColors.primary,
            tooltip: 'Làm mới dữ liệu',
          ),
        ),
      ],
    );
  }

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chúc bạn buổi sáng tốt lành!';
    if (hour < 18) return 'Chúc bạn buổi chiều năng suất!';
    return 'Chúc bạn buổi tối vui vẻ!';
  }

  Widget _buildOverviewStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tổng quan hệ thống',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1, // Giảm để card cao hơn
          children: [
            _buildStatCard(
              title: 'Tổng người dùng',
              value: _stats.userStats.total.toString(),
              icon: Icons.people_alt_rounded,
              gradient: const [Color(0xFF667eea), Color(0xFF764ba2)],
              subtitle: '+${_stats.userStats.newThisMonth} tháng này',
            ),
            _buildStatCard(
              title: 'Premium',
              value: _stats.userStats.premium.toString(),
              icon: Icons.workspace_premium_rounded,
              gradient: const [Color(0xFFf093fb), Color(0xFFf5576c)],
              subtitle: '${_stats.userStats.total > 0 ? ((_stats.userStats.premium / _stats.userStats.total) * 100).toStringAsFixed(1) : 0}% tổng số',
            ),
            _buildStatCard(
              title: 'Khóa học',
              value: _stats.categoryStats.total.toString(),
              icon: Icons.school_rounded,
              gradient: const [Color(0xFF11998e), Color(0xFF38ef7d)],
              subtitle: '${_stats.categoryStats.system} hệ thống',
            ),
            _buildStatCard(
              title: 'Flashcards',
              value: _formatNumber(_stats.categoryStats.totalFlashcards),
              icon: Icons.style_rounded,
              gradient: const [Color(0xFFfc4a1a), Color(0xFFf7b733)],
              subtitle: 'Tổng thẻ học',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradient,
    String? subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -15,
            bottom: -15,
            child: Icon(
              icon,
              size: 70,
              color: Colors.white.withOpacity(0.15),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const Spacer(),
                // Value
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                // Title
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDistributionCard() {
    final total = _stats.userStats.total;
    if (total == 0) return const SizedBox.shrink();

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Phân bố người dùng',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Tổng: $total',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Simple bar chart
          _buildDistributionBar(
            label: 'Premium',
            value: _stats.userStats.premium,
            total: total,
            color: const Color(0xFFf093fb),
            icon: Icons.workspace_premium_rounded,
          ),
          const SizedBox(height: 16),
          _buildDistributionBar(
            label: 'Giáo viên',
            value: _stats.userStats.teacher,
            total: total,
            color: const Color(0xFF667eea),
            icon: Icons.school_rounded,
          ),
          const SizedBox(height: 16),
          _buildDistributionBar(
            label: 'Người dùng thường',
            value: _stats.userStats.normal,
            total: total,
            color: const Color(0xFF11998e),
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 16),
          _buildDistributionBar(
            label: 'Bị khóa',
            value: _stats.userStats.blocked,
            total: total,
            color: const Color(0xFFef4444),
            icon: Icons.block_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionBar({
    required String label,
    required int value,
    required int total,
    required Color color,
    required IconData icon,
  }) {
    final percent = total > 0 ? (value / total) : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${(percent * 100).toStringAsFixed(1)}%)',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thao tác nhanh',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.people_alt_rounded,
                title: 'Quản lý\nngười dùng',
                color: const Color(0xFF667eea),
                onTap: () => Navigator.pushReplacementNamed(context, '/admin_users_management'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.card_giftcard_rounded,
                title: 'Gói\nPremium',
                color: const Color(0xFFf093fb),
                onTap: () => Navigator.pushReplacementNamed(context, '/admin_study_packs'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.policy_rounded,
                title: 'Chính sách\n& Điều khoản',
                color: const Color(0xFF11998e),
                onTap: () => Navigator.pushReplacementNamed(context, '/admin_policy'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thông tin hệ thống',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildInfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Ngày hiện tại',
            value: _formatDate(DateTime.now()),
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.person_add_rounded,
            label: 'Người dùng mới tháng này',
            value: '${_stats.userStats.newThisMonth} người',
            color: const Color(0xFF11998e),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.block_rounded,
            label: 'Tài khoản bị khóa',
            value: '${_stats.userStats.blocked} tài khoản',
            color: const Color(0xFFef4444),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.style_rounded,
            label: 'Tổng số flashcards',
            value: _formatNumber(_stats.categoryStats.totalFlashcards),
            color: const Color(0xFFf7b733),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppColors.primaryDark,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatDate(DateTime date) {
    const weekDays = ['Chủ nhật', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7'];
    return '${weekDays[date.weekday % 7]}, ${date.day}/${date.month}/${date.year}';
  }
}

// ==================== DATA MODELS ====================

class AdminStats {
  final UserStats userStats;
  final CategoryStats categoryStats;

  AdminStats({
    required this.userStats,
    required this.categoryStats,
  });

  factory AdminStats.empty() => AdminStats(
    userStats: UserStats.empty(),
    categoryStats: CategoryStats.empty(),
  );
}

class UserStats {
  final int total;
  final int premium;
  final int normal;
  final int teacher;
  final int blocked;
  final int activeToday;
  final int newThisMonth;

  UserStats({
    required this.total,
    required this.premium,
    required this.normal,
    required this.teacher,
    required this.blocked,
    required this.activeToday,
    required this.newThisMonth,
  });

  factory UserStats.empty() => UserStats(
    total: 0,
    premium: 0,
    normal: 0,
    teacher: 0,
    blocked: 0,
    activeToday: 0,
    newThisMonth: 0,
  );
}

class CategoryStats {
  final int total;
  final int system;
  final int totalFlashcards;

  CategoryStats({
    required this.total,
    required this.system,
    required this.totalFlashcards,
  });

  factory CategoryStats.empty() => CategoryStats(
    total: 0,
    system: 0,
    totalFlashcards: 0,
  );
}