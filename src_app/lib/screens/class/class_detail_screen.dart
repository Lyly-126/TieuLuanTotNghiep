
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../models/class_model.dart';
import '../../models/class_member_model.dart';
import '../../models/category_model.dart';
import '../../services/class_service.dart';
import '../../services/category_service.dart';
import '../../widgets/custom_button.dart';
import '../../screens/class/add_members_screen.dart';

class ClassDetailScreen extends StatefulWidget {
  final int classId;
  final bool isOwner; // ✅ THÊM PARAMETER

  const ClassDetailScreen({
    Key? key,
    required this.classId,
    this.isOwner = false, // ✅ DEFAULT = false
  }) : super(key: key);

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen>
    with SingleTickerProviderStateMixin {
  ClassDetailModel? _classDetail;
  bool _isLoading = true;
  String _errorMessage = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // ✅ CHỈ CÒN 2 TABS (không có tab pending ở đây)
    _tabController = TabController(length: 2, vsync: this);
    _loadClassDetail();
    print('📱 [SCREEN] ${runtimeType.toString()}'); // ← THÊM DÒNG NÀY
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClassDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final detail = await ClassService.getClassDetail(widget.classId);
      setState(() {
        _classDetail = detail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('Chi tiết lỗi khi tải thông tin lớp: $e');
    }
  }

  void _shareInviteCode() {
    if (_classDetail?.inviteCode != null) {
      Share.share(
        'Tham gia lớp "${_classDetail!.name}" của tôi!\n\n'
            '📚 Mã lớp: ${_classDetail!.inviteCode}\n\n'
            '🔗 Link: https://yourapp.com/join/${_classDetail!.inviteCode}',
        subject: 'Mời tham gia lớp ${_classDetail!.name}',
      );
    }
  }

  void _copyInviteCode() {
    if (_classDetail?.inviteCode != null) {
      Clipboard.setData(ClipboardData(text: _classDetail!.inviteCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã sao chép mã lớp'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _removeMember(ClassMemberModel member) async {
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
          'Bạn có chắc muốn xóa ${member.userFullName ?? "thành viên này"} khỏi lớp?',
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
        await ClassService.removeMember(widget.classId, member.userId);
        _loadClassDetail();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Đã xóa thành viên'),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
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
        ),
        body: Center(
          child: Padding(
            padding: AppConstants.screenPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 80,
                  color: AppColors.error.withOpacity(0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  'Không thể tải thông tin lớp',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.hint.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Thử lại',
                  onPressed: _loadClassDetail,
                  width: 200,
                  icon: Icons.refresh_rounded,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ✅ HEADER - ĐÃ SỬA: Giảm chiều cao để không che mất nội dung
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 16,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.7),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button & Share button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_rounded,
                          color: Colors.white, size: 24),
                      onPressed: _shareInviteCode,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Class name
                Text(
                  _classDetail!.name,
                  style: AppTextStyles.heading2.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                // Description (if exists)
                if (_classDetail!.description != null &&
                    _classDetail!.description!.isNotEmpty) ...[
                  Text(
                    _classDetail!.description!,
                    style: AppTextStyles.hint.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                // ✅ STATS: Hiển thị số học phần và thành viên
                Row(
                  children: [
                    _buildStatChip(
                      icon: Icons.folder_outlined,
                      value: '${_classDetail!.categoryCount ?? 0}',
                      label: 'Học phần',
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      icon: Icons.people_outline_rounded,
                      value: '${_classDetail!.memberCount ?? 0}',
                      label: 'Thành viên',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Invite code card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.vpn_key_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mã lớp',
                              style: AppTextStyles.hint.copyWith(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _classDetail!.inviteCode ?? 'N/A',
                              style: AppTextStyles.label.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.content_copy_rounded,
                            color: Colors.white, size: 20),
                        onPressed: _copyInviteCode,
                        tooltip: 'Sao chép mã',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ✅ TABS - CHỈ CÒN 2: Học phần & Thành viên
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textGray,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: AppTextStyles.label.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              tabs: const [
                Tab(text: 'Học phần'),
                Tab(text: 'Thành viên'),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCategoriesTab(),
                _buildMembersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ STAT CHIP WIDGET cho header
  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            value,
            style: AppTextStyles.label.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.hint.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ TAB 1: HỌC PHẦN (CATEGORIES)
  Widget _buildCategoriesTab() {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // ✅ FIXED: Header với nút tạo chủ đề - style đồng bộ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_classDetail!.categoryCount ?? 0} chủ đề',
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                // ✅ FIXED: Nút tạo chủ đề - style giống nút "Thêm"
                TextButton.icon(
                  onPressed: _showCreateCategoryDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Tạo chủ đề'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          // List categories hoặc empty state
          Expanded(
            child: _buildCategoriesList(),
          ),
        ],
      ),
    );
  }

  // ✅ HIỂN THỊ DANH SÁCH CATEGORIES
  Widget _buildCategoriesList() {
    return FutureBuilder<List<CategoryModel>>(
      future: CategoryService.getCategoriesByClassId(widget.classId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 60,
                    color: AppColors.error.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Không thể tải học phần',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.hint.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final categories = snapshot.data ?? [];

        if (categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.folder_open_rounded,
                    size: 50,
                    color: AppColors.primary.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa có chủ đề nào',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tạo chủ đề để thêm flashcard',
                  style: AppTextStyles.hint.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Tạo chủ đề đầu tiên',
                  onPressed: _showCreateCategoryDialog,
                  icon: Icons.add_rounded,
                ),
              ],
            ),
          );
        }

        // ✅ HIỂN THỊ DANH SÁCH CATEGORIES
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            await _loadClassDetail();
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryCard(category);
            },
          ),
        );
      },
    );
  }

  // ✅ CARD CATEGORY
  Widget _buildCategoryCard(CategoryModel category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: () {
          // ✅ Navigate to category flashcards
          Navigator.pushNamed(
            context,
            '/class-category-flashcards',
            arguments: {
              'category': category,
              'classModel': ClassModel(
                id: widget.classId,
                name: _classDetail!.name,
                description: _classDetail!.description,
              ),
            },
          ).then((_) {
            setState(() {});
            _loadClassDetail();
          });
        },
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.folder_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          category.name,
          style: AppTextStyles.label.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (category.description != null &&
                category.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                category.description!,
                style: AppTextStyles.hint,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.style_rounded,
                  size: 14,
                  color: AppColors.primary.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  '${category.flashcardCount ?? 0} thẻ',
                  style: AppTextStyles.hint.copyWith(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert_rounded),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined,
                      size: 20, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text('Sửa', style: AppTextStyles.label),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete_outlined,
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
              _showEditCategoryDialog(category);
            } else if (value == 'delete') {
              _deleteCategory(category);
            }
          },
        ),
      ),
    );
  }

  // ✅ DIALOG TẠO CATEGORY
  void _showCreateCategoryDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.5),
        ),
        title: Text(
          'Tạo chủ đề mới',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.primaryDark,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Tên chủ đề *',
                hintText: 'VD: Từ vựng Unit 1',
                labelStyle: AppTextStyles.label,
                hintStyle: AppTextStyles.hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Mô tả',
                hintText: 'VD: 20 từ vựng về gia đình',
                labelStyle: AppTextStyles.label,
                hintStyle: AppTextStyles.hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          CustomButton(
            text: 'Tạo',
            width: 100,
            height: 40,
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚠️ Vui lòng nhập tên chủ đề'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }

              try {
                await CategoryService.createCategory(
                  name: nameController.text.trim(),
                  classId: widget.classId,
                  description: descriptionController.text.trim().isNotEmpty
                      ? descriptionController.text.trim()
                      : null,
                );

                Navigator.pop(context);
                setState(() {});
                _loadClassDetail();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Tạo chủ đề thành công'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // ✅ DIALOG SỬA CATEGORY
  void _showEditCategoryDialog(CategoryModel category) {
    final nameController = TextEditingController(text: category.name);
    final descriptionController =
    TextEditingController(text: category.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.5),
        ),
        title: Text(
          'Sửa chủ đề',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.primaryDark,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Tên chủ đề *',
                labelStyle: AppTextStyles.label,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Mô tả',
                labelStyle: AppTextStyles.label,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          CustomButton(
            text: 'Lưu',
            width: 100,
            height: 40,
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚠️ Vui lòng nhập tên chủ đề'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }

              try {
                await CategoryService.updateCategory(
                  categoryId: category.id,
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isNotEmpty
                      ? descriptionController.text.trim()
                      : null,
                );

                Navigator.pop(context);
                setState(() {});
                _loadClassDetail();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Cập nhật thành công'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // ✅ XÓA CATEGORY
  Future<void> _deleteCategory(CategoryModel category) async {
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
          'Bạn có chắc muốn xóa chủ đề "${category.name}"?\nTất cả flashcard trong chủ đề này cũng sẽ bị xóa.',
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
        await CategoryService.deleteCategory(category.id);
        setState(() {});
        _loadClassDetail();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Đã xóa chủ đề'),
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

  // ✅ TAB 2: THÀNH VIÊN
  Widget _buildMembersTab() {
    if (_classDetail!.members == null || _classDetail!.members!.isEmpty) {
      return Center(
        child: Padding(
          padding: AppConstants.screenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.people_outline_rounded,
                  size: 50,
                  color: AppColors.primary.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa có thành viên',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chia sẻ mã lớp để mời thành viên',
                style: AppTextStyles.hint.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Thêm thành viên',
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddMembersScreen(
                        classModel: ClassModel(
                          id: widget.classId,
                          name: _classDetail!.name,
                          description: _classDetail!.description,
                        ),
                      ),
                    ),
                  );
                  if (result == true) {
                    _loadClassDetail();
                  }
                },
                icon: Icons.person_add_alt_1_rounded,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // ✅ Header với nút thêm thành viên - GIỮ NGUYÊN style này
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_classDetail!.members!.length} thành viên',
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddMembersScreen(
                        classModel: ClassModel(
                          id: widget.classId,
                          name: _classDetail!.name,
                          description: _classDetail!.description,
                        ),
                      ),
                    ),
                  );
                  if (result == true) {
                    _loadClassDetail();
                  }
                },
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Thêm'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        // List members
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _classDetail!.members!.length,
            itemBuilder: (context, index) {
              final member = _classDetail!.members![index];
              final isOwner = member.userId == _classDetail!.ownerId;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(AppConstants.borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: isOwner
                        ? AppColors.warning.withOpacity(0.2)
                        : AppColors.primary.withOpacity(0.1),
                    child: Text(
                      member.userFullName?.substring(0, 1).toUpperCase() ?? 'U',
                      style: AppTextStyles.heading3.copyWith(
                        color: isOwner ? AppColors.warning : AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text(
                    member.userFullName ?? 'Unknown',
                    style: AppTextStyles.label.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        member.userEmail ?? '',
                        style: AppTextStyles.hint,
                      ),
                      if (isOwner) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '👑 Chủ lớp',
                            style: AppTextStyles.hint.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: !isOwner
                      ? PopupMenuButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            const Icon(Icons.person_remove_outlined,
                                size: 20, color: AppColors.error),
                            const SizedBox(width: 12),
                            Text(
                              'Xóa khỏi lớp',
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'remove') {
                        _removeMember(member);
                      }
                    },
                  )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}