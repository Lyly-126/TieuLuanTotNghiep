// File: lib/screens/admin/admin_study_packs_screen.dart
import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_constants.dart';
import '../../../config/app_text_styles.dart';
import '../../../models/study_pack_model.dart';
import '../../../services/study_pack_service.dart';

class AdminStudyPacksScreen extends StatefulWidget {
  const AdminStudyPacksScreen({super.key});

  @override
  State<AdminStudyPacksScreen> createState() => _AdminStudyPacksScreenState();
}

class _AdminStudyPacksScreenState extends State<AdminStudyPacksScreen> {
  List<StudyPackModel> _packs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPacks();
  }

  Future<void> _loadPacks() async {
    setState(() => _isLoading = true);
    try {
      final packs = await StudyPackService.getAllPacks();
      setState(() {
        _packs = packs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quản lý hệ thống Flai',
                        style: AppTextStyles.heading2.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gói học tập Premium',
                        style: AppTextStyles.hint.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
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
                ],
              ),

              const SizedBox(height: 24),

              // Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Tổng gói',
                      _packs.length.toString(),
                      Icons.workspace_premium_rounded,
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Đang bán',
                      _packs.length.toString(),
                      Icons.trending_up_rounded,
                      const Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Add Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddEditDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                    elevation: 2,
                    shadowColor: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: Text(
                    'Thêm gói mới',
                    style: AppTextStyles.button.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Pack List
              Expanded(
                child: _isLoading
                    ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
                    : _packs.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: AppColors.primary.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có gói học tập nào',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
                    : RefreshIndicator(
                  onRefresh: _loadPacks,
                  color: AppColors.primary,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    itemCount: _packs.length,
                    itemBuilder: (context, index) {
                      final pack = _packs[index];
                      return _buildPackCard(pack);
                    },
                  ),
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
        currentIndex: 2,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textGray,
        iconSize: 26,
        selectedFontSize: 0,
        unselectedFontSize: 0,
        onTap: (index) {
          if (index == 2) return;
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/admin_home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/admin_users_management');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/admin_policy');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline_rounded),
            activeIcon: Icon(Icons.people_rounded),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.workspace_premium_outlined),
            activeIcon: Icon(Icons.workspace_premium_rounded),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            activeIcon: Icon(Icons.description_rounded),
            label: '',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: const Color(0xFFE6E8EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: AppTextStyles.hint.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackCard(StudyPackModel pack) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
        border: Border.all(color: const Color(0xFFE6E8EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pack.name,
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${pack.formattedPrice} ${pack.durationLabel}',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.textGray),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                onSelected: (value) {
                  if (value == 'edit') {
                    _showAddEditDialog(pack: pack);
                  } else if (value == 'delete') {
                    _confirmDelete(pack);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text('Chỉnh sửa', style: AppTextStyles.label),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                        const SizedBox(width: 12),
                        Text('Xóa', style: AppTextStyles.label.copyWith(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              pack.description,
              style: AppTextStyles.hint.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog({StudyPackModel? pack}) {
    final isEdit = pack != null;
    final nameController = TextEditingController(text: pack?.name ?? '');
    final descController = TextEditingController(text: pack?.description ?? '');
    final priceController = TextEditingController(
      text: pack != null ? pack.price.toInt().toString() : '',
    );
    final durationController = TextEditingController(
      text: pack != null ? pack.durationDays.toString() : '30',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEdit ? 'Chỉnh sửa gói' : 'Thêm gói mới', style: AppTextStyles.heading3),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Tên gói',
                  hintText: 'VD: Basic 30 ngày, Pro tháng...',
                  prefixIcon: const Icon(Icons.workspace_premium_rounded, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Mô tả',
                  hintText: 'Tính năng của gói...',
                  prefixIcon: const Icon(Icons.description_rounded, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Giá (VNĐ)',
                  hintText: '159000',
                  prefixIcon: const Icon(Icons.payments_rounded, color: AppColors.primary),
                  suffixText: 'đ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Thời lượng (ngày)',
                  hintText: '30 hoặc 365',
                  prefixIcon: const Icon(Icons.timer_rounded, color: AppColors.primary),
                  suffixText: 'ngày',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
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
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final desc = descController.text.trim();
              final price = double.tryParse(priceController.text.trim()) ?? 0;
              final duration = int.tryParse(durationController.text.trim()) ?? 30;

              try {
                StudyPackModel saved;
                if (isEdit) {
                  saved = await StudyPackService.updatePack(
                    id: pack!.id,
                    name: name,
                    description: desc,
                    price: price,
                    durationDays: duration,
                  );
                  setState(() {
                    final idx = _packs.indexWhere((p) => p.id == pack.id);
                    if (idx != -1) _packs[idx] = saved;
                  });
                } else {
                  saved = await StudyPackService.createPack(
                    name: name,
                    description: desc,
                    price: price,
                    durationDays: duration,
                  );
                  setState(() {
                    _packs.add(saved);
                  });
                }

                if (mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEdit ? 'Đã cập nhật gói' : 'Đã thêm gói mới'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: Text(
              isEdit ? 'Cập nhật' : 'Thêm',
              style: AppTextStyles.button.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(StudyPackModel pack) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Xóa gói học tập', style: AppTextStyles.heading3),
        content: Text(
          'Bạn có chắc muốn xóa gói "${pack.name}"? Hành động này không thể hoàn tác.',
          style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: AppTextStyles.button.copyWith(color: AppColors.textGray)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await StudyPackService.deletePack(pack.id);
                setState(() => _packs.removeWhere((p) => p.id == pack.id));
                if (mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Đã xóa gói học tập'),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: Text('Xóa', style: AppTextStyles.button.copyWith(color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}