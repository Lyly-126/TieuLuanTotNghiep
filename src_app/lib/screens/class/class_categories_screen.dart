import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../models/class_model.dart';
import '../../models/category_model.dart';
import '../../models/user_model.dart';
import '../../services/category_service.dart';
import '../../services/user_service.dart';
import '../../widgets/custom_button.dart';
import '../category/category_detail_screen.dart';

class ClassCategoriesScreen extends StatefulWidget {
  final ClassModel classModel;

  const ClassCategoriesScreen({Key? key, required this.classModel})
      : super(key: key);

  @override
  State<ClassCategoriesScreen> createState() => _ClassCategoriesScreenState();
}

class _ClassCategoriesScreenState extends State<ClassCategoriesScreen> {
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    print('📱 [SCREEN] $runtimeType');
    _loadCurrentUser();
    _loadCategories();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await UserService.getCurrentUser();
      if (mounted) setState(() => _currentUser = user);
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
  }

  String _errorMessage = '';

  UserModel? _currentUser;

  /// Load categories của lớp
  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final categories =
      await CategoryService.getCategoriesByClassId(widget.classModel.id);
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _navigateToCategory(CategoryModel category) {
    // isOwner = true nếu user là owner của Class
    final isClassOwner = widget.classModel.ownerId == _currentUser?.userId;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryDetailScreen(
          category: category,
          isOwner: isClassOwner,
        ),
      ),
    ).then((_) {
      _loadCategories();
    });
  }

  /// Hiển thị dialog tạo category mới
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
                  classId: widget.classModel.id,
                  description: descriptionController.text.trim().isNotEmpty
                      ? descriptionController.text.trim()
                      : null,
                );

                Navigator.pop(context);
                _loadCategories();
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

  /// Hiển thị dialog sửa category
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
                _loadCategories();
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

  /// Xóa category
  Future<void> _deleteCategory(CategoryModel category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Xác nhận xóa'),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            children: [
              const TextSpan(text: 'Bạn có chắc muốn xóa chủ đề '),
              TextSpan(
                text: '"${category.name}"',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '?\n\n'),
              TextSpan(
                text: '⚠️ Tất cả ${category.flashcardCount ?? 0} thẻ trong chủ đề này cũng sẽ bị xóa!',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
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
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await CategoryService.deleteCategory(category.id);
        _loadCategories();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã xóa chủ đề'),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button & title
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chủ đề',
                            style: AppTextStyles.heading2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.classModel.name,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Stats
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        icon: Icons.folder_rounded,
                        value: '${_categories.length}',
                        label: 'Chủ đề',
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      _buildStatItem(
                        icon: Icons.style_rounded,
                        value: '${_categories.fold<int>(0, (sum, c) => sum + (c.flashcardCount ?? 0))}',
                        label: 'Thẻ',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
                : _errorMessage.isNotEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Đã có lỗi xảy ra',
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage,
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadCategories,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            )
                : _categories.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.folder_open_rounded,
                        size: 60,
                        color: AppColors.primary.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Chưa có chủ đề nào',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tạo chủ đề đầu tiên để bắt đầu\nthêm flashcard vào lớp học',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.hint.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: 'Tạo chủ đề đầu tiên',
                      onPressed: _showCreateCategoryDialog,
                      icon: Icons.add_rounded,
                    ),
                  ],
                ),
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadCategories,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return _buildCategoryCard(category);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: !_isLoading && _categories.isNotEmpty
          ? FloatingActionButton(
        onPressed: _showCreateCategoryDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, size: 28),
      )
          : null,
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.heading2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  /// ✅ Build category card với navigation tới CategoryDetailScreen
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
        // ✅ FIX: Navigate tới CategoryDetailScreen thay vì route string
        onTap: () => _navigateToCategory(category),
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
                    style: AppTextStyles.label.copyWith(color: AppColors.error),
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
}