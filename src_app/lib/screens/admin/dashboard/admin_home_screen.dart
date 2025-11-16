import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_constants.dart';
import '../../../config/app_text_styles.dart';
import '../../../widgets/admin_bottom_nav.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  final List<String> _tabs = [
    'Tổng quan',
    'Người dùng',
    'Premium',
    'Điều khoản & Chính sách',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: AppConstants.screenPadding.copyWith(bottom: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------- HEADER ----------------
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 12, right: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Tiêu đề bên trái
                    Text(
                      'Quản lý hệ thống Flai',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    // Ảnh đại diện admin
                    Container(
                      margin: const EdgeInsets.only(right: 4, top: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 23,
                        backgroundColor: AppColors.inputBackground,
                        backgroundImage: const AssetImage('assets/images/avatar.png'),
                        onBackgroundImageError: (_, __) {},
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
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Thống kê & Báo cáo hệ thống',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 16),

              // ---------------- MAIN CONTENT ----------------
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    _buildOverviewTab(),
                    _buildUserTab(),
                    _buildPremiumTab(),
                    _buildPolicyTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // ---------------- BOTTOM NAVIGATION ----------------
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

  // ---------------- TAB: TỔNG QUAN ----------------
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildStatCard(
            title: 'Tài khoản Premium',
            subtitle: 'Số lượng tài khoản Premium trong hệ thống',
            value: '850',
            icon: Icons.workspace_premium_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            title: 'Tỷ lệ hoạt động',
            subtitle: 'Tỷ lệ người dùng hoạt động hàng ngày',
            value: '75%',
            icon: Icons.insights_rounded,
            color: Colors.orangeAccent,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            title: 'Người dùng mới',
            subtitle: 'Người dùng đăng ký trong tháng này',
            value: '120',
            icon: Icons.person_add_alt_1_rounded,
            color: Colors.teal,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---------------- TAB: NGƯỜI DÙNG ----------------
  Widget _buildUserTab() {
    return const Center(
      child: Text('👥 Quản lý người dùng đang phát triển...',
          style: TextStyle(color: Colors.grey)),
    );
  }

  // ---------------- TAB: PREMIUM ----------------
  Widget _buildPremiumTab() {
    return const Center(
      child: Text('💎 Quản lý gói Premium...',
          style: TextStyle(color: Colors.grey)),
    );
  }

  // ---------------- TAB: CHÍNH SÁCH ----------------
  Widget _buildPolicyTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Điều khoản & Chính sách',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 16),
          _buildPolicyCard(
            title: 'Điều khoản sử dụng',
            desc: 'Cập nhật nội dung quy định và quyền sử dụng hệ thống.',
          ),
          const SizedBox(height: 14),
          _buildPolicyCard(
            title: 'Chính sách bảo mật',
            desc: 'Thông tin về quyền riêng tư và dữ liệu người dùng.',
          ),
          const SizedBox(height: 14),
          _buildPolicyCard(
            title: 'Hướng dẫn & hỗ trợ',
            desc: 'Tài liệu hướng dẫn dành cho người dùng mới.',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---------------- CARD: THỐNG KÊ ----------------
  Widget _buildStatCard({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (color ?? AppColors.primary).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color ?? AppColors.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.hint.copyWith(
                    color: AppColors.textGray,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: AppTextStyles.heading3.copyWith(
              color: color ?? AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- CARD: CHÍNH SÁCH ----------------
  Widget _buildPolicyCard({
    required String title,
    required String desc,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_rounded,
              color: AppColors.primary, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: AppTextStyles.hint.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: AppColors.textGray, size: 16),
        ],
      ),
    );
  }
}
