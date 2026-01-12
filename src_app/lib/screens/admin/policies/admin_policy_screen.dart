// File: lib/screens/admin/policy/admin_policy_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_constants.dart';
import '../../../config/app_text_styles.dart';
import '../../../services/policy_service.dart';
import 'admin_policy_editor_screen.dart';
import 'admin_policy_create_screen.dart';

class AdminPolicyScreen extends StatefulWidget {
  const AdminPolicyScreen({super.key});

  @override
  State<AdminPolicyScreen> createState() => _AdminPolicyScreenState();
}

class _AdminPolicyScreenState extends State<AdminPolicyScreen> {
  List<Map<String, dynamic>> _policies = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPolicies();
  }

  Future<void> _loadPolicies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final policies = await PolicyService.getAllPolicies();
      setState(() {
        _policies = policies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _openEditor(int policyId) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AdminPolicyEditorScreen(policyId: policyId)));
    if (result == true) _loadPolicies();
  }

  void _openCreate() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPolicyCreateScreen()));
    if (result == true) _loadPolicies();
  }

  void _confirmDelete(int index) async {
    final policy = _policies[index];
    final policyId = policy['id'] as int;
    final policyTitle = policy['title'] as String;

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Xoá "$policyTitle"?', style: AppTextStyles.heading3),
        content: Text('Hành động này sẽ xoá điều khoản vĩnh viễn. Bạn có chắc chắn?', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Huỷ', style: AppTextStyles.button.copyWith(color: AppColors.primary))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Xoá', style: AppTextStyles.button.copyWith(color: Colors.redAccent))),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await PolicyService.deletePolicy(policyId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã xoá: $policyTitle'), backgroundColor: Colors.green));
      _loadPolicies();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi xóa: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _logout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0x1AFF0000), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.logout_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Đăng xuất'),
          ],
        ),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản Admin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Hủy', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi đăng xuất: $e'), backgroundColor: Colors.red));
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Quản lý hệ thống Flai', style: AppTextStyles.heading2.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  GestureDetector(
                    onTap: _logout,
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Color(0x407B46E4), blurRadius: 6, offset: Offset(0, 3))],
                      ),
                      child: const CircleAvatar(radius: 23, backgroundImage: AssetImage('assets/images/avatar.png'), backgroundColor: AppColors.inputBackground),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Quản lý điều khoản và chính sách', style: AppTextStyles.heading3.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _error != null
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Lỗi tải dữ liệu', style: AppTextStyles.heading3),
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: _loadPolicies, child: const Text('Thử lại')),
                    ],
                  ),
                )
                    : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _policies.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    if (i == _policies.length) return _buildAddNewButton();
                    return _buildPolicyItem(index: i, policy: _policies[i]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        currentIndex: 3,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textGray,
        iconSize: 26,
        selectedFontSize: 0,
        unselectedFontSize: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/admin_home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/admin_users_management');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/admin_study_packs');
              break;
            case 3:
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

  Widget _buildPolicyItem({required int index, required Map<String, dynamic> policy}) {
    final title = policy['title'] as String;
    final status = policy['status'] as String;
    final policyId = policy['id'] as int;

    Color statusColor;
    String statusText;
    switch (status) {
      case 'ACTIVE':
        statusColor = Colors.green;
        statusText = 'Công khai';
        break;
      case 'INACTIVE':
        statusColor = Colors.orange;
        statusText = 'Ẩn';
        break;
      case 'DRAFT':
        statusColor = Colors.grey;
        statusText = 'Nháp';
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
      onTap: () => _openEditor(policyId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1), // ✅ FIXED
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Text(
                      statusText,
                      style: AppTextStyles.hint.copyWith(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                TextButton(
                  onPressed: () => _openEditor(policyId),
                  child: Text(
                    'Sửa',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _confirmDelete(index),
                  child: Text(
                    'Xoá',
                    style: AppTextStyles.label.copyWith(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
      onTap: _openCreate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
          border: Border.all(color: AppColors.primary, width: 1.2),
        ),
        child: Center(child: Text('+ Thêm điều khoản mới', style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700))),
      ),
    );
  }
}