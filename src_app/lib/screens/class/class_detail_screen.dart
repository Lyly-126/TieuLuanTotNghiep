import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../models/class_model.dart';
import '../../models/class_member_model.dart';
import '../../services/class_service.dart';
import '../../widgets/custom_button.dart';
import '../../screens/class/add_members_screen.dart';
//lỗi ch sửa đc

class ClassDetailScreen extends StatefulWidget {
  final int classId;

  const ClassDetailScreen({Key? key, required this.classId}) : super(key: key);

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
    _tabController = TabController(length: 3, vsync: this);
    _loadClassDetail();
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
        // Log toàn bộ chi tiết lỗi
        _errorMessage = e.toString();
        _isLoading = false;
      });

      // In ra log để debug
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
          // Header với gradient
          Container(
            height: 220,
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
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // AppBar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 22),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            _classDetail!.name,
                            style: AppTextStyles.heading2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share_rounded,
                              color: Colors.white),
                          onPressed: _shareInviteCode,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Icon
                  const Icon(
                    Icons.school_rounded,
                    size: 80,
                    color: Colors.white38,
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(0),
              children: [
                // Info card
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius * 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Description
                        if (_classDetail!.description != null &&
                            _classDetail!.description!.isNotEmpty) ...[
                          Text(
                            _classDetail!.description!,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Stats
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.people_rounded,
                                count: _classDetail!.memberCount ?? 0,
                                label: 'Thành viên',
                                color: AppColors.info,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.folder_rounded,
                                count: _classDetail!.categoryCount ?? 0,
                                label: 'Học phần',
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 20),

                        // Invite code
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.inputBackground,
                                  borderRadius: BorderRadius.circular(
                                      AppConstants.borderRadius),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.vpn_key_rounded,
                                          size: 16,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Mã lớp',
                                          style: AppTextStyles.hint.copyWith(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _classDetail!.inviteCode ?? '',
                                      style: AppTextStyles.heading2.copyWith(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 3,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.inputBackground,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.copy_rounded),
                                    onPressed: _copyInviteCode,
                                    color: AppColors.primary,
                                    tooltip: 'Sao chép',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.inputBackground,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.share_rounded),
                                    onPressed: _shareInviteCode,
                                    color: AppColors.primary,
                                    tooltip: 'Chia sẻ',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Tabs
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                              AppConstants.borderRadius),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.textSecondary,
                          indicatorColor: AppColors.primary,
                          indicatorWeight: 3,
                          labelStyle: AppTextStyles.label.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          tabs: const [
                            Tab(text: 'Học phần'),
                            Tab(text: 'Thành viên'),
                            Tab(text: 'Hoạt động'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 400,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildSetsTab(),
                            _buildMembersTab(),
                            _buildActivityTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: AppTextStyles.hint.copyWith(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetsTab() {
    return _buildEmptyTab(
      icon: Icons.folder_open_rounded,
      title: 'Danh sách học phần',
      subtitle: 'Chức năng đang được phát triển',
    );
  }

  Widget _buildMembersTab() {
    if (_classDetail?.members == null || _classDetail!.members!.isEmpty) {
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
        // Header với nút thêm thành viên
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

  Widget _buildActivityTab() {
    return _buildEmptyTab(
      icon: Icons.assessment_outlined,
      title: 'Lịch sử hoạt động',
      subtitle: 'Chức năng đang được phát triển',
    );
  }

  Widget _buildEmptyTab({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
              icon,
              size: 50,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTextStyles.heading3.copyWith(
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
        ],
      ),
    );
  }
}