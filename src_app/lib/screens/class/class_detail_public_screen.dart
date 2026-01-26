import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../models/category_model.dart';
import '../../models/class_model.dart';
import '../../services/category_service.dart';
import '../../services/class_service.dart';
import '../category/category_detail_screen.dart';

class ClassDetailPublicScreen extends StatefulWidget {
  final ClassModel classModel;

  const ClassDetailPublicScreen({
    super.key,
    required this.classModel,
  });

  @override
  State<ClassDetailPublicScreen> createState() => _ClassDetailPublicScreenState();
}

class _ClassDetailPublicScreenState extends State<ClassDetailPublicScreen> {
  bool _isLoading = true;
  bool _isJoining = false;
  bool _isMember = false;
  bool _isPending = false;
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
        _isJoining = false;

        if (widget.classModel.isPublic) {
          _isMember = true;
          _isPending = false;
          _showSuccessSnackBar('✅ Đã tham gia lớp học thành công!');
        } else {
          _isMember = false;
          _isPending = true;
          _showInfoSnackBar('⏳ Yêu cầu tham gia đã được gửi!\nVui lòng đợi giáo viên phê duyệt.');
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
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.primary, title: const Text('Lỗi')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Không thể tải thông tin lớp học', style: AppTextStyles.heading2),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(_errorMessage!, style: AppTextStyles.body, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadClassDetails,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
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
          style: AppTextStyles.heading2.copyWith(color: Colors.white, fontSize: 18),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
          child: Center(
            child: Icon(Icons.school, size: 80, color: Colors.white.withOpacity(0.3)),
          ),
        ),
      ),
    );
  }

  Widget _buildClassInfo() {
    return Container(
      margin: const EdgeInsets.all(AppConstants.padding),
      padding: const EdgeInsets.all(AppConstants.padding),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visibility badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.classModel.isPublic
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.classModel.isPublic ? Icons.public : Icons.lock_outline,
                      size: 16,
                      color: widget.classModel.isPublic ? AppColors.success : AppColors.warning,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.classModel.isPublic ? 'Công khai' : 'Riêng tư',
                      style: TextStyle(
                        color: widget.classModel.isPublic ? AppColors.success : AppColors.warning,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (widget.classModel.inviteCode != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.key, size: 16, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Text(
                        widget.classModel.inviteCode!,
                        style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          if (widget.classModel.description != null && widget.classModel.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(widget.classModel.description!, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, height: 1.5)),
          ],

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Stats row
          Row(
            children: [
              _buildStatItem(Icons.person, widget.classModel.ownerName ?? 'Giáo viên', 'Giảng viên'),
              const SizedBox(width: 24),
              _buildStatItem(Icons.people, '${widget.classModel.memberCount ?? 0}', 'Thành viên'),
              const SizedBox(width: 24),
              _buildStatItem(Icons.folder, '${widget.classModel.categoryCount ?? 0}', 'Học phần'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryDark)),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textGray)),
      ],
    );
  }

  Widget _buildActionButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.padding),
      child: _buildActionContent(),
    );
  }

  Widget _buildActionContent() {
    if (_isJoining) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    // ✅ ĐÃ LÀ THÀNH VIÊN
    if (_isMember) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.success.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle, color: AppColors.success, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Đã tham gia', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 16)),
                  Text('Bạn là thành viên của lớp học này', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            TextButton(
              onPressed: _handleLeaveClass,
              child: Text('Rời lớp', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      );
    }

    // ✅ ĐANG CHỜ PHÊ DUYỆT - THIẾT KẾ ĐẸP HƠN
    if (_isPending) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.warning.withOpacity(0.1), AppColors.warning.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppColors.warning.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: const Icon(Icons.hourglass_top, color: AppColors.warning, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đang chờ phê duyệt',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Giáo viên sẽ xem xét yêu cầu của bạn',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Cancel button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _handleCancelRequest,
                  icon: const Icon(Icons.close_rounded, size: 20),
                  label: const Text('Hủy yêu cầu tham gia'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withOpacity(0.5), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ✅ CHƯA THAM GIA - NÚT THAM GIA
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _handleJoinClass,
        icon: Icon(widget.classModel.isPublic ? Icons.add : Icons.send, color: Colors.white),
        label: Text(
          widget.classModel.isPublic ? 'Tham gia lớp học' : 'Gửi yêu cầu tham gia',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildCategoriesHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppConstants.padding, AppConstants.padding, AppConstants.padding, AppConstants.padding / 2),
      child: Row(
        children: [
          Icon(Icons.collections_bookmark, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('Học phần (${_categories.length})', style: AppTextStyles.heading2.copyWith(color: AppColors.primaryDark)),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) => _buildCategoryCard(_categories[index]),
        childCount: _categories.length,
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.padding, vertical: AppConstants.padding / 2),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: InkWell(
          onTap: () => _navigateToFlashcards(category),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.padding),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
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
                  child: Icon(Icons.collections_bookmark, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text('${category.flashcardCount ?? 0} thẻ', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
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
            Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Chưa có học phần nào', style: AppTextStyles.heading2.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text('Giáo viên chưa thêm học phần vào lớp này', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void _navigateToFlashcards(CategoryModel category) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CategoryDetailScreen(category: category, isOwner: false)),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
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
        content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text(message))]),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [const Icon(Icons.info, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text(message))]),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [const Icon(Icons.error, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text(message))]),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}