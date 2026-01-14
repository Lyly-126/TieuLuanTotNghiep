import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/app_colors.dart';
import '../../screens/class/class_category_management_tab.dart';
import '../../config/app_text_styles.dart';
import '../../models/class_model.dart';
import '../../models/class_member_model.dart';
import '../../models/category_model.dart';
import '../../services/class_service.dart';
import '../../services/category_service.dart';
import '../../services/share_link_service.dart';
import '../../screens/class/add_members_screen.dart';
import '../category/category_detail_screen.dart';

class ClassDetailScreen extends StatefulWidget {
  final int classId;
  final bool isOwner;

  const ClassDetailScreen({
    Key? key,
    required this.classId,
    this.isOwner = false,
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

  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    print('📱 [SCREEN] $runtimeType');
    _tabController = TabController(length: widget.isOwner ? 3 : 2, vsync: this);
    _loadClassDetail();
    print('📱 [SCREEN] ${runtimeType.toString()}');
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

      if (widget.isOwner) {
        final pendingMembers =
        await ClassService.getPendingMembers(widget.classId);
        setState(() {
          _pendingCount = pendingMembers.length;
        });
      }

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

  Future<void> _regenerateInviteCode() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.refresh_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            const Text('Tạo mã mới?'),
          ],
        ),
        content: const Text(
          'Mã cũ sẽ không còn sử dụng được. Bạn có chắc chắn muốn tạo mã mới?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tạo mã mới'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        setState(() => _isLoading = true);
        final newInviteCode =
        await ClassService.regenerateInviteCode(widget.classId);
        await _loadClassDetail();
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã tạo mã mời mới: $newInviteCode'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _classDetail?.name ?? 'Chi tiết lớp',
          style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary),
          overflow: TextOverflow.ellipsis,
        ),
        actions: widget.isOwner
            ? [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textPrimary),
            onPressed: _showOptionsMenu,
          ),
        ]
            : null,
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage.isNotEmpty
          ? _buildErrorState()
          : Column(
        children: [
          // Class Info Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Class Name
                Text(
                  _classDetail?.name ?? '',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.primary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Description
                if (_classDetail?.description != null &&
                    _classDetail!.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _classDetail!.description!,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 12),

                // Stats
                Row(
                  children: [
                    _buildStat(
                      Icons.people_rounded,
                      '${_classDetail?.memberCount ?? 0}',
                    ),
                    const SizedBox(width: 20),
                    _buildStat(
                      Icons.folder_rounded,
                      '${_classDetail?.categoryCount ?? 0}',
                    ),
                    const Spacer(),
                    if (_classDetail?.isPublic == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.public_rounded,
                              color: AppColors.success,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Công khai',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // Invite Code Section
                if (widget.isOwner &&
                    _classDetail?.inviteCode != null) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    'Mã lớp',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _classDetail!.inviteCode!,
                            style: AppTextStyles.heading3.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(
                                text: _classDetail!.inviteCode!));
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text('Đã sao chép mã lớp'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded,
                              size: 16),
                          label: const Text('Sao chép'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(
                                color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _regenerateInviteCode,
                          icon: const Icon(Icons.refresh_rounded,
                              size: 16),
                          label: const Text('Tạo mới'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.warning,
                            side: const BorderSide(
                                color: AppColors.warning),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () async {
                          try {
                            print('🔗 Sharing class: ${_classDetail!.name}');
                            print('🔗 Invite code: ${_classDetail!.inviteCode}');

                            await ShareLinkService.shareClass(
                              className: _classDetail!.name,
                              inviteCode: _classDetail!.inviteCode!,
                              description: _classDetail!.description,
                            );

                            print('✅ Share completed');
                          } catch (e) {
                            print('❌ Share error: $e');

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Lỗi khi chia sẻ: ${e.toString()}'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.share_rounded),
                        color: AppColors.secondary,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.secondary.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // TabBar
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: AppTextStyles.body
                  .copyWith(fontWeight: FontWeight.w600),
              unselectedLabelStyle: AppTextStyles.body,
              isScrollable: false,
              tabs: [
                const Tab(
                  child: Text(
                    'Thành viên',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Tab(
                  child: Text(
                    'Danh mục',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.isOwner)
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Chờ duyệt',
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_pendingCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$_pendingCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _MembersTab(
                  classId: widget.classId,
                  isOwner: widget.isOwner,
                  onMemberUpdated: _loadClassDetail,
                  className: _classDetail?.name ?? '',
                  classDescription: _classDetail?.description,
                  classIsPublic: _classDetail?.isPublic ?? false,
                  classInviteCode: _classDetail?.inviteCode,
                  classMemberCount: _classDetail?.memberCount,
                  classCategoryCount: _classDetail?.categoryCount,
                ),

                ClassCategoryManagementTab(
                  classId: widget.classId,
                  isOwner: widget.isOwner,
                  onCategoryUpdated: _loadClassDetail,
                ),

                if (widget.isOwner)
                  _PendingMembersTab(
                    classId: widget.classId,
                    onUpdate: () {
                      _loadClassDetail();
                      setState(() {});
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.secondary),
        const SizedBox(width: 6),
        Text(
          value,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Có lỗi xảy ra', style: AppTextStyles.heading3),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style:
              AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadClassDetail,
              icon: const Icon(Icons.refresh_rounded),
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

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
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
                _showEditClassDialog();  // ✅ Gọi hàm edit
              },
            ),
            ListTile(
              leading:
              const Icon(Icons.delete_rounded, color: AppColors.error),
              title: const Text('Xóa lớp',
                  style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: const Row(
                      children: [
                        Icon(Icons.warning_rounded, color: AppColors.error),
                        SizedBox(width: 12),
                        Text('Xóa lớp?'),
                      ],
                    ),
                    content:
                    const Text('Bạn có chắc chắn muốn xóa lớp này?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Hủy'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Xóa'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  try {
                    await ClassService.deleteClass(widget.classId);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã xóa lớp'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
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
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showEditClassDialog() {
    if (_classDetail == null) return;

    final nameController = TextEditingController(text: _classDetail!.name);
    final descriptionController = TextEditingController(text: _classDetail!.description ?? '');
    bool isPublic = _classDetail!.isPublic ?? false;
    bool isLoading = false;

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
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chỉnh sửa lớp',
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

              // Tên lớp
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Tên lớp *',
                  hintText: 'Nhập tên lớp học',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Mô tả
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Mô tả',
                  hintText: 'Nhập mô tả về lớp học',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Switch công khai
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
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
                  activeColor: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Button Lưu
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                    // Validate
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng nhập tên lớp'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }

                    // Set loading
                    setModalState(() {
                      isLoading = true;
                    });

                    try {
                      print('🔄 Đang cập nhật lớp ${widget.classId}...');

                      await ClassService.updateClass(
                        classId: widget.classId,
                        name: nameController.text.trim(),
                        description: descriptionController.text.trim(),
                        isPublic: isPublic,
                      );

                      print('✅ Cập nhật thành công!');

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Cập nhật thành công'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        _loadClassDetail(); // Refresh data
                      }
                    } catch (e) {
                      print('❌ Lỗi cập nhật: $e');

                      setModalState(() {
                        isLoading = false;
                      });

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ Lỗi: $e'),
                            backgroundColor: AppColors.error,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text(
                    'Lưu thay đổi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}

// ==================== MEMBERS TAB ====================

class _MembersTab extends StatefulWidget {
  final int classId;
  final bool isOwner;
  final VoidCallback onMemberUpdated;
  final String className;
  final String? classDescription;
  final bool classIsPublic;
  final String? classInviteCode;
  final int? classMemberCount;
  final int? classCategoryCount;

  const _MembersTab({
    required this.classId,
    required this.isOwner,
    required this.onMemberUpdated,
    required this.className,
    this.classDescription,
    required this.classIsPublic,
    this.classInviteCode,
    this.classMemberCount,
    this.classCategoryCount,
  });

  @override
  State<_MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<_MembersTab> {
  List<ClassMemberModel> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);

    try {
      final members = await ClassService.getClassMembers(widget.classId);
      setState(() {
        _members = members.where((m) => m.status == 'APPROVED').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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

  Future<void> _removeMember(ClassMemberModel member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa thành viên?'),
        content: Text('Bạn có chắc muốn xóa ${member.userFullName} khỏi lớp?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ClassService.removeMember(widget.classId, member.userId);
        _loadMembers();
        widget.onMemberUpdated();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa thành viên'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
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
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_members.isEmpty && !widget.isOwner) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Chưa có thành viên',
              style:
              AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMembers,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _members.length + (widget.isOwner ? 1 : 0),
        itemBuilder: (context, index) {
          if (widget.isOwner && index == 0) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    final classModel = ClassModel(
                      id: widget.classId,
                      name: widget.className,
                      description: widget.classDescription,
                      isPublic: widget.classIsPublic,
                      inviteCode: widget.classInviteCode,
                      memberCount: widget.classMemberCount,
                      categoryCount: widget.classCategoryCount,
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddMembersScreen(classModel: classModel),
                      ),
                    ).then((_) {
                      _loadMembers();
                      widget.onMemberUpdated();
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.1),
                          AppColors.secondary.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person_add_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Thêm thành viên',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Mời người khác tham gia lớp học',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppColors.primary,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          final memberIndex = widget.isOwner ? index - 1 : index;
          final member = _members[memberIndex];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.secondary.withOpacity(0.2),
                child: Text(
                  member.userFullName.isNotEmpty
                      ? member.userFullName[0].toUpperCase()
                      : '?',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(member.userFullName, style: AppTextStyles.body),
              subtitle: Text(
                member.userEmail,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
              trailing: widget.isOwner
                  ? IconButton(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.textSecondary),
                onPressed: () => _removeMember(member),
              )
                  : null,
            ),
          );
        },
      ),
    );
  }
}

// ==================== CATEGORIES TAB ====================

class _CategoriesTab extends StatefulWidget {
  final int classId;
  final bool isOwner;

  const _CategoriesTab({
    required this.classId,
    required this.isOwner,
  });

  @override
  State<_CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<_CategoriesTab> {
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    try {
      final categories =
      await CategoryService.getCategoriesByClassId(widget.classId);
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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

  // ✅ THÊM METHOD NAVIGATION
  void _navigateToCategory(CategoryModel category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryDetailScreen(
          category: category,
          isOwner: widget.isOwner, // ✅ Truyền isOwner từ parent
        ),
      ),
    ).then((_) {
      _loadCategories(); // Refresh sau khi quay lại
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_outlined,
                size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Chưa có danh mục',
              style:
              AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCategories,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.secondary.withOpacity(0.2),
                child:
                const Icon(Icons.folder_rounded, color: AppColors.secondary),
              ),
              title: Text(category.name, style: AppTextStyles.body),
              subtitle: Text(
                '${category.flashcardCount ?? 0} flashcards',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded,
                  color: AppColors.textSecondary, size: 16),
              // ✅ SỬA: Navigate đến CategoryDetailScreen thay vì route string
              onTap: () => _navigateToCategory(category),
            ),
          );
        },
      ),
    );
  }
}

// ==================== PENDING MEMBERS TAB ====================

class _PendingMembersTab extends StatefulWidget {
  final int classId;
  final VoidCallback onUpdate;

  const _PendingMembersTab({
    required this.classId,
    required this.onUpdate,
  });

  @override
  State<_PendingMembersTab> createState() => _PendingMembersTabState();
}

class _PendingMembersTabState extends State<_PendingMembersTab> {
  List<ClassMemberModel> _pendingMembers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingMembers();
  }

  Future<void> _loadPendingMembers() async {
    setState(() => _isLoading = true);

    try {
      final members = await ClassService.getPendingMembers(widget.classId);
      setState(() {
        _pendingMembers = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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

  Future<void> _approveMember(ClassMemberModel member) async {
    try {
      await ClassService.approveMember(widget.classId, member.userId);
      _loadPendingMembers();
      widget.onUpdate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã duyệt ${member.userFullName}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
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

  Future<void> _rejectMember(ClassMemberModel member) async {
    try {
      await ClassService.rejectMember(widget.classId, member.userId);
      _loadPendingMembers();
      widget.onUpdate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã từ chối ${member.userFullName}'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_pendingMembers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded,
                size: 64, color: AppColors.success.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Không có yêu cầu chờ duyệt',
              style:
              AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingMembers,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingMembers.length,
        itemBuilder: (context, index) {
          final member = _pendingMembers[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.warning.withOpacity(0.2),
                child: Text(
                  member.userFullName.isNotEmpty
                      ? member.userFullName[0].toUpperCase()
                      : '?',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(member.userFullName, style: AppTextStyles.body),
              subtitle: Text(
                member.userEmail,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_rounded,
                        color: AppColors.success),
                    onPressed: () => _approveMember(member),
                    tooltip: 'Duyệt',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.error),
                    onPressed: () => _rejectMember(member),
                    tooltip: 'Từ chối',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}