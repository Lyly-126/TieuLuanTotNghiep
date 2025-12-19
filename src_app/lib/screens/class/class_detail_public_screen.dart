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
  bool _isPending = false; // ✅ THÊM: Trạng thái chờ duyệt
  List<CategoryModel> _categories = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadClassDetails();
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

  // ✅ CẬP NHẬT: Xử lý join với logic public/private
  Future<void> _handleJoinClass() async {
    setState(() => _isJoining = true);

    try {
      await ClassService.joinClass(widget.classModel.id);

      setState(() {
        _isJoining = false;

        // ✅ Nếu là public → approved ngay
        if (widget.classModel.isPublic) {
          _isMember = true;
          _isPending = false;
          _showSuccessSnackBar('✅ Đã tham gia lớp học thành công!');
        } else {
          // ✅ Nếu là private → chờ duyệt
          _isMember = false;
          _isPending = true;
          _showInfoSnackBar(
            '⏳ Yêu cầu tham gia đã được gửi!\n'
                'Vui lòng đợi giáo viên phê duyệt.',
          );
        }
      });
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
        _isPending = false;
        _isJoining = false;
      });

      _showSuccessSnackBar('Đã rời khỏi lớp học');
    } catch (e) {
      setState(() => _isJoining = false);
      _showErrorSnackBar('Không thể rời lớp học: $e');
    }
  }

  // ✅ THÊM: Hủy yêu cầu tham gia (khi đang pending)
  Future<void> _handleCancelRequest() async {
    final confirm = await _showConfirmDialog(
      'Hủy yêu cầu',
      'Bạn có chắc muốn hủy yêu cầu tham gia lớp học này?',
    );

    if (confirm != true) return;

    setState(() => _isJoining = true);

    try {
      await ClassService.leaveClass(widget.classModel.id);

      setState(() {
        _isPending = false;
        _isJoining = false;
      });

      _showSuccessSnackBar('Đã hủy yêu cầu tham gia');
    } catch (e) {
      setState(() => _isJoining = false);
      _showErrorSnackBar('Không thể hủy yêu cầu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text('Lỗi'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Không thể tải thông tin lớp học',
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadClassDetails,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildClassInfo()),

          // ✅ CẬP NHẬT: Hiển thị action button phù hợp
          SliverToBoxAdapter(child: _buildActionButton()),

          if (_isMember) ...[
            SliverToBoxAdapter(child: _buildCategoriesHeader()),
            _categories.isEmpty
                ? SliverFillRemaining(child: _buildEmptyCategories())
                : _buildCategoriesList(),
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

  // ✅ CẬP NHẬT: Ẩn mã mời, chỉ hiển thị thông tin cần thiết
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

          // ❌ XÓA: Không hiển thị mã mời cho user thường
          // Chỉ teacher mới thấy mã mời trong màn hình class management

          // Trạng thái công khai/riêng tư
          _buildInfoRow(
            icon: widget.classModel.isPublic ? Icons.public : Icons.lock,
            label: 'Trạng thái',
            value: widget.classModel.isPublic ? 'Công khai' : 'Riêng tư',
          ),

          // ✅ THÊM: Giải thích về private class
          if (!widget.classModel.isPublic && !_isMember && !_isPending) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warning.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lớp riêng tư: Cần phê duyệt từ giáo viên',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  // ✅ MỚI: Build action button dựa trên trạng thái
  Widget _buildActionButton() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.padding,
        vertical: 8,
      ),
      child: _buildActionButtonContent(),
    );
  }

  Widget _buildActionButtonContent() {
    // Đang xử lý
    if (_isJoining) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Đang xử lý...'),
          ],
        ),
      );
    }

    // ✅ Đã là thành viên → Nút rời lớp
    if (_isMember) {
      return OutlinedButton.icon(
        onPressed: _handleLeaveClass,
        icon: const Icon(Icons.exit_to_app),
        label: const Text('Rời khỏi lớp học'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
        ),
      );
    }

    // ✅ Đang chờ duyệt (PENDING) → Hiển thị thông báo + nút hủy
    if (_isPending) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              border: Border.all(
                color: AppColors.warning.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.hourglass_empty, color: AppColors.warning),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đang chờ phê duyệt',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Giáo viên sẽ xem xét yêu cầu của bạn',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _handleCancelRequest,
            icon: const Icon(Icons.close),
            label: const Text('Hủy yêu cầu'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
            ),
          ),
        ],
      );
    }

    // ✅ Chưa tham gia → Nút tham gia
    return ElevatedButton.icon(
      onPressed: _handleJoinClass,
      icon: const Icon(Icons.add),
      label: Text(
        widget.classModel.isPublic
            ? 'Tham gia lớp học'
            : 'Gửi yêu cầu tham gia',
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
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
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final category = _categories[index];
          return _buildCategoryCard(category);
        },
        childCount: _categories.length,
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.padding,
        vertical: AppConstants.padding / 2,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: InkWell(
          onTap: () => _navigateToFlashcards(category),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.padding),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.primary.withOpacity(0.1),
              ),
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.collections_bookmark,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${category.flashcardCount ?? 0} thẻ',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCategories() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.padding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có học phần nào',
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Giáo viên chưa thêm học phần vào lớp này',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToFlashcards(CategoryModel category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassCategoryFlashcardsScreen(
          category: category,
          classModel: widget.classModel,
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
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
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}