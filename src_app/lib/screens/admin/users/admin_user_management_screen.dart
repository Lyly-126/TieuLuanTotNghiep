// File: lib/screens/admin/admin_user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_constants.dart';
import '../../../config/app_text_styles.dart';
import '../../../models/user_model.dart';
import '../../../models/study_pack_model.dart';
import '../../../services/admin_user_service.dart';
import '../../../services/study_pack_service.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  String _selectedFilter = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final usersData = await AdminUserService.getAllUsers();
      final users = usersData.map((e) => UserModel.fromJson(e)).toList();
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('❌ Lỗi khi tải người dùng: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _filteredUsers = _users.where((u) {
        final lower = query.toLowerCase();
        final matchesSearch = u.email.toLowerCase().contains(lower) ||
            u.userId.toString().contains(lower) ||
            u.displayName.toLowerCase().contains(lower) ||
            u.role.toLowerCase().contains(lower);

        if (_selectedFilter == 'Tất cả') return matchesSearch;
        if (_selectedFilter == 'Admin') return matchesSearch && u.role == 'ADMIN';
        if (_selectedFilter == 'Teacher') return matchesSearch && u.role == 'TEACHER';
        if (_selectedFilter == 'Premium') return matchesSearch && u.role == 'PREMIUM_USER';
        if (_selectedFilter == 'User') return matchesSearch && u.role == 'NORMAL_USER';
        if (_selectedFilter == 'Bị khóa') return matchesSearch && u.isBlocked;
        if (_selectedFilter == 'Hoạt động') return matchesSearch && !u.isBlocked;

        return matchesSearch;
      }).toList();
    });
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      _filterUsers('');
    });
  }

  // ✅ Helper để format role hiển thị
  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'NORMAL_USER':
        return 'Người dùng';
      case 'PREMIUM_USER':
        return 'Premium';
      case 'TEACHER':
        return 'Giáo viên';
      case 'ADMIN':
        return 'Quản trị viên';
      default:
        return role;
    }
  }

  // ✅ Helper để lấy role color
  Color _getRoleColor(String role) {
    switch (role) {
      case 'ADMIN':
        return const Color(0xFFFF9800); // Orange
      case 'TEACHER':
        return const Color(0xFF2196F3); // Blue
      case 'PREMIUM_USER':
        return AppColors.primary; // Purple
      case 'NORMAL_USER':
        return const Color(0xFF9E9E9E); // Gray
      default:
        return Colors.grey;
    }
  }

  // ✅ Helper để lấy role background color
  Color _getRoleBackgroundColor(String role) {
    switch (role) {
      case 'ADMIN':
        return const Color(0xFFFFF3E0);
      case 'TEACHER':
        return const Color(0xFFE3F2FD);
      case 'PREMIUM_USER':
        return AppColors.primary.withOpacity(0.1);
      case 'NORMAL_USER':
        return const Color(0xFFF5F5F5);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  // ✅ Hàm đăng xuất
  Future<void> _logout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Đăng xuất'),
          ],
        ),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản Admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Hủy',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
                (Route<dynamic> route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi đăng xuất: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: AppConstants.screenPadding.copyWith(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quản lý hệ thống Flai',
                    style: AppTextStyles.heading2.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  // ✅ Avatar với chức năng đăng xuất
                  GestureDetector(
                    onTap: _logout,
                    child: Container(
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
                      child: const CircleAvatar(
                        radius: 23,
                        backgroundImage: AssetImage('assets/images/avatar.png'),
                        backgroundColor: AppColors.inputBackground,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Text(
                'Quản lý tài khoản người dùng',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tổng số: ${_users.length} người dùng',
                style: AppTextStyles.hint.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 16),

              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_outlined, color: AppColors.textGray, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        onChanged: _filterUsers,
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Tìm kiếm theo tên, email hoặc ID',
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

              const SizedBox(height: 16),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Tất cả', _users.length),
                    const SizedBox(width: 8),
                    _buildFilterChip('Admin', _users.where((u) => u.role == 'ADMIN').length),
                    const SizedBox(width: 8),
                    _buildFilterChip('Teacher', _users.where((u) => u.role == 'TEACHER').length),
                    const SizedBox(width: 8),
                    _buildFilterChip('Premium', _users.where((u) => u.role == 'PREMIUM_USER').length),
                    const SizedBox(width: 8),
                    _buildFilterChip('User', _users.where((u) => u.role == 'NORMAL_USER').length),
                    const SizedBox(width: 8),
                    _buildFilterChip('Hoạt động', _users.where((u) => !u.isBlocked).length),
                    const SizedBox(width: 8),
                    _buildFilterChip('Bị khóa', _users.where((u) => u.isBlocked).length),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // User List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredUsers.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 64, color: AppColors.textGray.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'Không tìm thấy người dùng',
                        style: AppTextStyles.label.copyWith(color: AppColors.textGray),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];
                    return _buildUserCard(user);
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        currentIndex: 1,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textGray,
        iconSize: 26,
        selectedFontSize: 0,
        unselectedFontSize: 0,
        onTap: (index) {
          if (index == 1) return;
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/admin_home');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/admin_study_packs');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/admin_policy');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline_rounded), activeIcon: Icon(Icons.people_rounded), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.workspace_premium_outlined), activeIcon: Icon(Icons.workspace_premium_rounded), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.description_outlined), activeIcon: Icon(Icons.description_rounded), label: ''),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => _applyFilter(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE6E8EC),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.25) : AppColors.inputBackground,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                count.toString(),
                style: AppTextStyles.hint.copyWith(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return GestureDetector(
      onTap: () {
        debugPrint('🔹 User card tapped: ${user.displayName}');
        _showUserDetailBottomSheet(user);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
          border: Border.all(color: const Color(0xFFE6E8EC)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: const AssetImage('assets/images/avatar.png'),
                      backgroundColor: AppColors.inputBackground,
                    ),
                    if (user.hasPremiumAccess)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.verified, size: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.displayName,
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getRoleBackgroundColor(user.role),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getRoleDisplayName(user.role),
                              style: AppTextStyles.hint.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _getRoleColor(user.role),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: AppTextStyles.hint.copyWith(fontSize: 13, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textGray,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatusBadge(
                  user.isBlocked ? 'Bị khóa' : 'Hoạt động',
                  user.isBlocked ? Icons.block_rounded : Icons.check_circle_rounded,
                  user.isBlocked ? Colors.redAccent : const Color(0xFF4CAF50),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.hint.copyWith(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showUserDetailBottomSheet(UserModel user) {
    debugPrint('🔹 Opening bottom sheet for: ${user.displayName}');

    try {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: true,
        enableDrag: true,
        builder: (BuildContext context) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20,
              left: 24,
              right: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textGray.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Avatar & Info
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: const AssetImage('assets/images/avatar.png'),
                    backgroundColor: AppColors.inputBackground,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.displayName,
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
                  ),

                  const SizedBox(height: 20),

                  // Detail Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow('User ID', user.userId.toString()),
                        const Divider(height: 20),
                        _buildInfoRow('Họ tên', user.displayName),
                        const Divider(height: 20),
                        _buildInfoRow('Vai trò', _getRoleDisplayName(user.role)),
                        const Divider(height: 20),
                        _buildInfoRow('Trạng thái', user.isBlocked ? 'Bị khóa' : 'Hoạt động'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  if (user.role == 'NORMAL_USER' || user.role == 'PREMIUM_USER' || user.role == 'TEACHER') ...[
                    Column(
                      children: [
                        // Info cho Teacher
                        if (user.role == 'TEACHER') ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.school_rounded, color: Color(0xFF2196F3)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Tài khoản giáo viên - Có quyền quản lý lớp học',
                                    style: AppTextStyles.hint.copyWith(color: const Color(0xFF2196F3)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Lock/Unlock Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              user.isBlocked ? _confirmUnlock(user) : _confirmLock(user);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: user.isBlocked ? const Color(0xFF4CAF50) : Colors.orangeAccent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
                              elevation: 0,
                            ),
                            icon: Icon(
                              user.isBlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                              color: Colors.white,
                            ),
                            label: Text(
                              user.isBlocked ? 'Mở khóa tài khoản' : 'Khóa tài khoản',
                              style: AppTextStyles.button.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),

                        // Premium Toggle Button (cho NORMAL_USER, PREMIUM_USER và TEACHER)
                        if (user.role == 'NORMAL_USER' || user.role == 'PREMIUM_USER' || user.role == 'TEACHER') ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: user.role == 'PREMIUM_USER' && user.role == 'TEACHER'
                                ? OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _confirmRevoke(user);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
                                side: const BorderSide(color: Colors.redAccent, width: 1.5),
                              ),
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                              label: Text(
                                'Hạ xuống Normal User',
                                style: AppTextStyles.button.copyWith(color: Colors.redAccent, fontWeight: FontWeight.w600),
                              ),
                            )
                                : ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _confirmGrant(user);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.workspace_premium_rounded, color: Colors.white),
                              label: Text(
                                'Nâng lên Premium User',
                                style: AppTextStyles.button.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFFFF9800)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Không thể thao tác trên tài khoản Admin',
                              style: AppTextStyles.hint.copyWith(color: const Color(0xFFFF9800)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('❌ Error showing bottom sheet: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
        ),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.label.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // ✅ FIXED: Dialog Actions - Chỉ reload data
  void _confirmLock(UserModel user) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Khóa tài khoản', style: AppTextStyles.heading3),
        content: Text(
          'Bạn có chắc muốn khóa tài khoản "${user.displayName}"? Người dùng sẽ không thể truy cập hệ thống.',
          style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: AppTextStyles.button.copyWith(color: AppColors.textGray)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AdminUserService.blockUser(user.userId);
                await _loadUsers();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã khóa tài khoản thành công'),
                      backgroundColor: Colors.orangeAccent,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            child: Text('Khóa', style: AppTextStyles.button.copyWith(color: Colors.orangeAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _confirmUnlock(UserModel user) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Mở khóa tài khoản', style: AppTextStyles.heading3),
        content: Text(
          'Xác nhận mở khóa tài khoản "${user.displayName}"?',
          style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: AppTextStyles.button.copyWith(color: AppColors.textGray)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AdminUserService.unblockUser(user.userId);
                await _loadUsers();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã mở khóa tài khoản thành công'),
                      backgroundColor: Color(0xFF4CAF50),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            child: Text('Mở khóa', style: AppTextStyles.button.copyWith(color: const Color(0xFF4CAF50), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _confirmGrant(UserModel user) async {
    // Load danh sách gói Premium trước
    List<StudyPackModel> packs = [];
    bool isLoading = true;
    String? errorMessage;

    try {
      packs = await StudyPackService.getAllPacks();
      isLoading = false;
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
    }

    if (!mounted) return;

    // Nếu không có gói nào
    if (packs.isEmpty && errorMessage == null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Không có gói Premium', style: AppTextStyles.heading3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
              const SizedBox(height: 12),
              Text(
                'Chưa có gói Premium nào.\nVui lòng tạo gói trước.',
                textAlign: TextAlign.center,
                style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Đóng', style: AppTextStyles.button.copyWith(color: AppColors.primary)),
            ),
          ],
        ),
      );
      return;
    }

    // Nếu có lỗi
    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải gói: $errorMessage'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    // Hiển thị dialog chọn gói
    int selectedPackIndex = 0;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final selectedPack = packs[selectedPackIndex];

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Nâng lên Premium', style: AppTextStyles.heading3),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chọn gói Premium cho "${user.displayName}":',
                    style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // Danh sách gói dạng Radio buttons
                  ...packs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final pack = entry.value;
                    final isSelected = index == selectedPackIndex;

                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedPackIndex = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3),
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: isSelected ? AppColors.primary : Colors.grey,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pack.name,
                                    style: AppTextStyles.label.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${pack.formattedPrice} - ${pack.durationLabel}',
                                    style: AppTextStyles.hint.copyWith(
                                      fontSize: 12,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 8),

                  // Mô tả gói đã chọn
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedPack.description,
                            style: AppTextStyles.hint.copyWith(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Hủy', style: AppTextStyles.button.copyWith(color: AppColors.textGray)),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await AdminUserService.grantPremium(user.userId, selectedPack.id);
                    await _loadUsers();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã nâng "${user.displayName}" lên Premium với gói ${selectedPack.name}'),
                          backgroundColor: const Color(0xFF4CAF50),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.redAccent),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Xác nhận', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmRevoke(UserModel user) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hạ xuống Normal User', style: AppTextStyles.heading3),
        content: Text(
          'Bạn có chắc muốn hạ "${user.displayName}" xuống Normal User?',
          style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: AppTextStyles.button.copyWith(color: AppColors.textGray)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AdminUserService.revokePremium(user.userId);
                await _loadUsers();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã hạ xuống Normal User thành công'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            child: Text('Hạ xuống', style: AppTextStyles.button.copyWith(color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}