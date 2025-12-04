  import 'package:flutter/material.dart';
  import '../../config/app_colors.dart';
  import '../../config/app_constants.dart';
  import '../../config/app_text_styles.dart';
  import '../../models/class_model.dart';
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

        setState(() {
          _ownedClasses = owned;
          _isLoading = false;
        });
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

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
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
          child: SingleChildScrollView(
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
                      color: AppColors.textGray.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'Tạo lớp học mới',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nhập thông tin lớp học của bạn',
                  style: AppTextStyles.hint.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Tên lớp
                Text('Tên lớp *', style: AppTextStyles.label),
                const SizedBox(height: AppConstants.labelSpacing),
                TextFormField(
                  controller: nameController,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'VD: Lớp Toán 12A1',
                    hintStyle: AppTextStyles.hint,
                    filled: true,
                    fillColor: AppColors.inputBackground,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.inputPadding,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Mô tả
                Text('Mô tả', style: AppTextStyles.label),
                const SizedBox(height: AppConstants.labelSpacing),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'VD: Lớp học toán nâng cao',
                    hintStyle: AppTextStyles.hint,
                    filled: true,
                    fillColor: AppColors.inputBackground,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.inputPadding,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Hủy',
                        outlined: true,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: 'Tạo lớp',
                        onPressed: () async {
                          if (nameController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('⚠️ Vui lòng nhập tên lớp'),
                                backgroundColor: AppColors.warning,
                              ),
                            );
                            return;
                          }

                          try {
                            await ClassService.createClass(
                              name: nameController.text.trim(),
                              description: descriptionController.text.trim(),
                            );

                            Navigator.pop(context);
                            _loadClasses();

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Tạo lớp thành công'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
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
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    void _showEditDialog(ClassModel classModel) {
      final nameController = TextEditingController(text: classModel.name);
      final descriptionController =
      TextEditingController(text: classModel.description);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
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
          child: SingleChildScrollView(
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
                      color: AppColors.textGray.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Sửa thông tin lớp',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),

                Text('Tên lớp *', style: AppTextStyles.label),
                const SizedBox(height: AppConstants.labelSpacing),
                TextFormField(
                  controller: nameController,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'VD: Lớp Toán 12A1',
                    hintStyle: AppTextStyles.hint,
                    filled: true,
                    fillColor: AppColors.inputBackground,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.inputPadding,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text('Mô tả', style: AppTextStyles.label),
                const SizedBox(height: AppConstants.labelSpacing),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'VD: Lớp học toán nâng cao',
                    hintStyle: AppTextStyles.hint,
                    filled: true,
                    fillColor: AppColors.inputBackground,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.inputPadding,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Hủy',
                        outlined: true,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: 'Lưu',
                        onPressed: () async {
                          try {
                            await ClassService.updateClass(
                              classId: classModel.id,
                              name: nameController.text.trim(),
                              description: descriptionController.text.trim(),
                            );

                            Navigator.pop(context);
                            _loadClasses();

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Cập nhật thành công'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
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
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    Future<void> _deleteClass(ClassModel classModel) async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.5),
          ),
          title: Text(
            'Xác nhận xóa',
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.primaryDark,
            ),
          ),
          content: Text(
            'Bạn có chắc muốn xóa lớp "${classModel.name}"?\n\n⚠️ Hành động này không thể hoàn tác.',
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

      if (confirm == true) {
        try {
          await ClassService.deleteClass(classModel.id);
          _loadClasses();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Đã xóa lớp'),
                backgroundColor: AppColors.success,
              ),
            );
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

    void _navigateToClassDetail(ClassModel classModel) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClassDetailScreen(classId: classModel.id),
        ),
      ).then((_) => _loadClasses());
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
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        )
            : _buildOwnedClassesTab(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showCreateClassDialog,
          backgroundColor: AppColors.primary,
          elevation: 4,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'Tạo lớp',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    Widget _buildOwnedClassesTab() {
      if (_ownedClasses.isEmpty) {
        return _buildEmptyState(
          icon: Icons.school_outlined,
          title: 'Chưa có lớp học nào',
          subtitle: 'Tạo lớp đầu tiên để bắt đầu',
          buttonText: 'Tạo lớp học',
          onPressed: _showCreateClassDialog,
        );
      }

      return RefreshIndicator(
        onRefresh: _loadClasses,
        color: AppColors.primary,
        child: ListView.builder(
          padding: AppConstants.screenPadding.copyWith(top: 16, bottom: 100),
          physics: const BouncingScrollPhysics(),
          itemCount: _ownedClasses.length,
          itemBuilder: (context, index) {
            final classModel = _ownedClasses[index];
            return _buildClassCard(classModel);
          },
        ),
      );
    }

    Widget _buildEmptyState({
      required IconData icon,
      required String title,
      required String subtitle,
      required String buttonText,
      required VoidCallback onPressed,
    }) {
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
                  icon,
                  size: 60,
                  color: AppColors.primary.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: AppTextStyles.hint.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: buttonText,
                onPressed: onPressed,
                width: 200,
                icon: Icons.add_rounded,
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildClassCard(ClassModel classModel) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => _navigateToClassDetail(classModel),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header với gradient
              Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppConstants.borderRadius * 1.2),
                    topRight: Radius.circular(AppConstants.borderRadius * 1.2),
                  ),
                ),
                child: Stack(
                  children: [
                    // Icon
                    const Center(
                      child: Icon(
                        Icons.school_rounded,
                        size: 48,
                        color: Colors.white24,
                      ),
                    ),
                    // Menu
                    Positioned(
                      top: 8,
                      right: 8,
                      child: PopupMenuButton(
                        icon: const Icon(Icons.more_vert_rounded,
                            color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(AppConstants.borderRadius),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined, size: 20),
                                const SizedBox(width: 12),
                                Text('Sửa', style: AppTextStyles.label),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline,
                                    size: 20, color: AppColors.error),
                                const SizedBox(width: 12),
                                Text(
                                  'Xóa',
                                  style: AppTextStyles.label.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditDialog(classModel);
                          } else if (value == 'delete') {
                            _deleteClass(classModel);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên lớp
                    Text(
                      classModel.name,
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (classModel.description != null &&
                        classModel.description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        classModel.description!,
                        style: AppTextStyles.hint.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Stats
                    Row(
                      children: [
                        _buildStat(
                          icon: Icons.folder_outlined,
                          value: '${classModel.categoryCount ?? 0}',
                          label: 'Học phần',
                        ),
                        const SizedBox(width: 20),
                        _buildStat(
                          icon: Icons.people_outline_rounded,
                          value: '${classModel.memberCount ?? 0}',
                          label: 'Thành viên',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildStat({
      required IconData icon,
      required String value,
      required String label,
    }) {
      return Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.hint.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }
  }