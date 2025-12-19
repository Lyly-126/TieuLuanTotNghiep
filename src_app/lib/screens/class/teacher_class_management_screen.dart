import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../models/class_model.dart';
import '../../models/class_member_model.dart';
import '../../services/class_service.dart';
import '../../widgets/custom_button.dart';
import 'class_detail_screen.dart';

class TeacherClassManagementScreen extends StatefulWidget {
  const TeacherClassManagementScreen({Key? key}) : super(key: key);

  @override
  State<TeacherClassManagementScreen> createState() =>
      _TeacherClassManagementScreenState();
}

class _TeacherClassManagementScreenState
    extends State<TeacherClassManagementScreen> {
  List<ClassModel> _ownedClasses = [];
  bool _isLoading = false;

  Map<int, int> _pendingCountMap = {};
  int _totalPendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final owned = await ClassService.getMyClasses();

      _pendingCountMap.clear();
      _totalPendingCount = 0;

      for (var cls in owned) {
        try {
          final pendingMembers = await ClassService.getPendingMembers(cls.id);
          _pendingCountMap[cls.id] = pendingMembers.length;
          _totalPendingCount += pendingMembers.length;
        } catch (e) {
          print('Error loading pending count for class ${cls.id}: $e');
          _pendingCountMap[cls.id] = 0;
        }
      }

      setState(() {
        _ownedClasses = owned;
        _isLoading = false;
      });

      if (_totalPendingCount > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '🔔 Bạn có $_totalPendingCount yêu cầu tham gia chờ duyệt',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Xem',
              textColor: Colors.white,
              onPressed: () {
                final firstClassWithPending = _ownedClasses.firstWhere(
                      (c) => (_pendingCountMap[c.id] ?? 0) > 0,
                  orElse: () => _ownedClasses.first,
                );
                _navigateToClassDetail(firstClassWithPending);
              },
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showCreateClassDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isPublic = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tạo lớp học mới',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Tên lớp *',
                  hintText: 'Nhập tên lớp học',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Mô tả',
                  hintText: 'Nhập mô tả về lớp học',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: isPublic,
                onChanged: (value) {
                  setModalState(() {
                    isPublic = value;
                  });
                },
                title: Text('Công khai', style: AppTextStyles.body),
                subtitle: Text(
                  isPublic
                      ? 'Mọi người có thể tìm kiếm và tham gia'
                      : 'Chỉ tham gia bằng mã mời',
                  style: AppTextStyles.hint,
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Tạo lớp',
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng nhập tên lớp'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  try {
                    await ClassService.createClass(
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim(),
                      isPublic: isPublic,
                    );

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Tạo lớp thành công'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      _loadClasses();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClassOptions(ClassModel cls) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: AppColors.primary),
              title: const Text('Chỉnh sửa'),
              onTap: () {
                Navigator.pop(context);
                _showEditClassDialog(cls);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: AppColors.error),
              title: const Text('Xóa lớp', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                _deleteClass(cls);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showEditClassDialog(ClassModel cls) {
    final nameController = TextEditingController(text: cls.name);
    final descriptionController = TextEditingController(text: cls.description);
    bool isPublic = cls.isPublic;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chỉnh sửa lớp học',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Tên lớp *',
                  hintText: 'Nhập tên lớp học',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Mô tả',
                  hintText: 'Nhập mô tả về lớp học',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: isPublic,
                onChanged: (value) {
                  setModalState(() {
                    isPublic = value;
                  });
                },
                title: Text('Công khai', style: AppTextStyles.body),
                subtitle: Text(
                  isPublic
                      ? 'Mọi người có thể tìm kiếm và tham gia'
                      : 'Chỉ tham gia bằng mã mời',
                  style: AppTextStyles.hint,
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Lưu thay đổi',
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng nhập tên lớp'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  try {
                    await ClassService.updateClass(
                      classId: cls.id,
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim(),
                      isPublic: isPublic,
                    );

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Cập nhật thành công'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      _loadClasses();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteClass(ClassModel cls) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Xóa lớp học?',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.error,
          ),
        ),
        content: Text(
          'Tất cả học phần và thành viên sẽ bị xóa. Hành động này không thể hoàn tác.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Hủy',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          CustomButton(
            text: 'Xóa',
            backgroundColor: AppColors.error,
            width: 100,
            height: 40,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ClassService.deleteClass(cls.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Đã xóa lớp học'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadClasses();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _navigateToClassDetail(ClassModel cls) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassDetailScreen(
          classId: cls.id,
          isOwner: true,
        ),
      ),
    ).then((_) {
      _loadClasses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.primary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Lớp học của tôi',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      )
          : _ownedClasses.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _loadClasses,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _ownedClasses.length,
          itemBuilder: (context, index) {
            return _buildClassCard(_ownedClasses[index]);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateClassDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text('Tạo lớp'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: AppConstants.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.school_rounded,
                size: 60,
                color: AppColors.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa có lớp học nào',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tạo lớp học đầu tiên của bạn\nđể bắt đầu quản lý học sinh',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Tạo lớp ngay',
              onPressed: _showCreateClassDialog,
              width: 160,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassCard(ClassModel cls) {
    final pendingCount = _pendingCountMap[cls.id] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: InkWell(
        onTap: () => _navigateToClassDetail(cls),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                cls.name,
                                style: AppTextStyles.heading3.copyWith(
                                  color: AppColors.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (pendingCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.notification_important_rounded,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$pendingCount',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (cls.description == null || cls.description!.isEmpty)
                              ? 'Không có mô tả'
                              : cls.description!,
                          style: AppTextStyles.hint,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded,
                        color: AppColors.textSecondary),
                    onPressed: () => _showClassOptions(cls),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.vpn_key_rounded,
                    label: cls.inviteCode ?? 'N/A',
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    icon: Icons.people_outline_rounded,
                    label: '${cls.memberCount ?? 0} thành viên',
                    color: AppColors.primary,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cls.isPublic
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cls.isPublic
                              ? Icons.public_rounded
                              : Icons.lock_outline_rounded,
                          size: 14,
                          color: cls.isPublic
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          cls.isPublic ? 'Công khai' : 'Riêng tư',
                          style: AppTextStyles.hint.copyWith(
                            color: cls.isPublic
                                ? AppColors.success
                                : AppColors.warning,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
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

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.hint.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}