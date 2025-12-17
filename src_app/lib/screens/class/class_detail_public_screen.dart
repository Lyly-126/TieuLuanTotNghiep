import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../models/category_model.dart';
import '../../models/class_model.dart';
import '../../services/category_service.dart';
import '../../services/class_service.dart';
import '../category/class_category_flashcards_screen.dart';

class ClassDetailPublicScreen extends StatefulWidget {
  final ClassModel classModel;

  const ClassDetailPublicScreen({
    Key? key,
    required this.classModel,
  }) : super(key: key);

  @override
  State<ClassDetailPublicScreen> createState() =>
      _ClassDetailPublicScreenState();
}

class _ClassDetailPublicScreenState extends State<ClassDetailPublicScreen> {
  bool _isLoading = true;
  bool _isJoining = false;
  bool _isMember = false;
  List<CategoryModel> _categories = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadClassDetails();
    print('📱 [SCREEN] ${runtimeType.toString()}'); // ← THÊM DÒNG NÀY

  }

  Future<void> _loadClassDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Kiểm tra membership và load categories đồng thời
      final results = await Future.wait([
        ClassService.isUserMemberOfClass(widget.classModel.id),
        CategoryService.getCategoriesByClassId(widget.classModel.id),
      ]);

      setState(() {
        _isMember = results[0] as bool;
        _categories = results[1] as List<CategoryModel>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleJoinClass() async {
    setState(() => _isJoining = true);

    try {
      await ClassService.joinClass(widget.classModel.id);

      setState(() {
        _isMember = true;
        _isJoining = false;
      });

      _showSuccessSnackBar('Đã tham gia lớp học thành công!');
    } catch (e) {
      setState(() => _isJoining = false);
      _showErrorSnackBar('Không thể tham gia lớp học: $e');
    }
  }

  Future<void> _handleLeaveClass() async {
    final confirm = await _showConfirmDialog(
      'Rời khỏi lớp học',
      'Bạn có chắc muốn rời khỏi lớp học này?',
    );

    if (confirm != true) return;

    setState(() => _isJoining = true);

    try {
      await ClassService.leaveClass(widget.classModel.id);

      setState(() {
        _isMember = false;
        _isJoining = false;
      });

      _showSuccessSnackBar('Đã rời khỏi lớp học');
    } catch (e) {
      setState(() => _isJoining = false);
      _showErrorSnackBar('Không thể rời lớp học: $e');
    }
  }

  void _copyInviteCode() {
    if (widget.classModel.inviteCode != null) {
      Clipboard.setData(ClipboardData(text: widget.classModel.inviteCode!));
      _showSuccessSnackBar('Đã sao chép mã mời');
    }
  }

  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        title: Text(
          title,
          style: AppTextStyles.heading2,
        ),
        content: Text(
          content,
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Hủy',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            SliverFillRemaining(
              child: _buildErrorState(),
            )
          else ...[
              SliverToBoxAdapter(child: _buildClassInfo()),
              SliverToBoxAdapter(child: _buildCategoriesHeader()),
              _buildCategoriesList(),
              // Thêm padding bottom
              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
            ],
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.classModel.name,
          style: AppTextStyles.heading2.copyWith(
            color: Colors.white,
            fontSize: 18,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
              ],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.school,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClassInfo() {
    return Container(
      margin: const EdgeInsets.all(AppConstants.padding),
      padding: const EdgeInsets.all(AppConstants.padding * 1.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề
          Text(
            'Thông tin lớp học',
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 16),

          // Mô tả
          if (widget.classModel.description != null &&
              widget.classModel.description!.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.description,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.classModel.description!,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Giáo viên
          _buildInfoRow(
            icon: Icons.person,
            label: 'Giáo viên',
            value: widget.classModel.ownerName ?? 'Không rõ',
          ),
          const SizedBox(height: 12),

          // Số học phần
          _buildInfoRow(
            icon: Icons.collections_bookmark,
            label: 'Số học phần',
            value: '${_categories.length} chủ đề',
          ),
          const SizedBox(height: 12),

          // Số thành viên
          _buildInfoRow(
            icon: Icons.people,
            label: 'Thành viên',
            value: '${widget.classModel.memberCount ?? 0} người',
          ),
          const SizedBox(height: 12),

          // Mã mời (nếu có)
          if (widget.classModel.inviteCode != null &&
              widget.classModel.inviteCode!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.vpn_key,
              label: 'Mã mời',
              value: widget.classModel.inviteCode!,
              trailing: IconButton(
                icon: Icon(Icons.copy, size: 20, color: AppColors.primary),
                onPressed: _copyInviteCode,
                tooltip: 'Sao chép mã mời',
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Trạng thái công khai
          _buildInfoRow(
            icon: widget.classModel.isPublic ? Icons.public : Icons.lock,
            label: 'Trạng thái',
            value: widget.classModel.isPublic ? 'Công khai' : 'Riêng tư',
          ),

          const SizedBox(height: 24),

          // Nút tham gia/rời khỏi
          SizedBox(
            width: double.infinity,
            height: 50,
            child: _isMember
                ? OutlinedButton.icon(
              onPressed: _isJoining ? null : _handleLeaveClass,
              icon: _isJoining
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.exit_to_app),
              label: Text(_isJoining ? 'Đang xử lý...' : 'Rời lớp học'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(AppConstants.borderRadius),
                ),
              ),
            )
                : ElevatedButton.icon(
              onPressed: _isJoining ? null : _handleJoinClass,
              icon: _isJoining
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(Icons.add),
              label: Text(
                  _isJoining ? 'Đang tham gia...' : 'Tham gia lớp học'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                AppColors.textSecondary.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(AppConstants.borderRadius),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Text(
                  '$label: ',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildCategoriesHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.padding,
        AppConstants.padding,
        AppConstants.padding,
        AppConstants.padding / 2,
      ),
      child: Row(
        children: [
          Icon(Icons.collections_bookmark, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            'Học phần (${_categories.length})',
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    if (_categories.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox,
                size: 64,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa có học phần nào',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(AppConstants.padding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final category = _categories[index];
            return _buildCategoryCard(category);
          },
          childCount: _categories.length,
        ),
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.padding),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClassCategoryFlashcardsScreen(
                category: category,
                classModel: widget.classModel,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tên chủ đề
              Row(
                children: [
                  Expanded(
                    child: Text(
                      category.name,
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.primaryDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),

              // Mô tả
              if (category.description != null &&
                  category.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  category.description!,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Số lượng thẻ
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.style,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${category.flashcardCount ?? 0} thẻ',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.padding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Đã có lỗi xảy ra',
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Không thể tải thông tin lớp học',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadClassDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}