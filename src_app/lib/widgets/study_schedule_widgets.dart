import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/category_study_schedule_model.dart';

// ==================== STUDY SCHEDULE CARD (HOME SCREEN) ====================

/// Widget hiển thị lịch học trực quan trên màn hình chính
class StudyScheduleCard extends StatelessWidget {
  final StudyScheduleOverview overview;
  final VoidCallback? onTapSchedule;
  final Function(ScheduleItem)? onTapItem;
  final VoidCallback? onResolveConflicts;

  const StudyScheduleCard({
    Key? key,
    required this.overview,
    this.onTapSchedule,
    this.onTapItem,
    this.onResolveConflicts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Nếu không có lịch nào
    if (overview.totalActiveSchedules == 0) {
      return _buildEmptyState();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),

          // Cảnh báo xung đột (nếu có)
          if (overview.hasConflicts) _buildConflictWarning(),

          // Lịch học hôm nay
          if (overview.hasTodaySchedules) ...[
            _buildTodaySchedules(),
          ] else ...[
            _buildNoTodaySchedule(),
          ],

          // Lịch học sắp tới
          if (overview.upcomingSchedules.isNotEmpty) ...[
            const Divider(height: 1),
            _buildUpcomingSchedules(),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có lịch học',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đặt lịch nhắc nhở để học đều đặn hơn',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onTapSchedule,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Tạo lịch học'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lịch học của bạn',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                Text(
                  '${overview.totalActiveSchedules} học phần đang theo dõi',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onTapSchedule,
            icon: Icon(
              Icons.settings_rounded,
              color: AppColors.textGray,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictWarning() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: onResolveConflicts,
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${overview.conflicts.length} xung đột lịch học',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ),
            Text(
              'Xem chi tiết',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: AppColors.warning,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySchedules() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.today_rounded, size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      'Hôm nay',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${overview.todaySchedules.length} buổi học',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...overview.todaySchedules.take(3).map((item) => _buildScheduleItem(item, isToday: true)),
          if (overview.todaySchedules.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+ ${overview.todaySchedules.length - 3} buổi học khác',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoTodaySchedule() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.success,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Không có lịch học hôm nay',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  Text(
                    'Bạn có thể tự học hoặc nghỉ ngơi',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingSchedules() {
    // Nhóm theo ngày
    Map<int, List<ScheduleItem>> groupedByDay = {};
    for (var item in overview.upcomingSchedules.take(10)) {
      groupedByDay.putIfAbsent(item.dayOfWeek, () => []);
      groupedByDay[item.dayOfWeek]!.add(item);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_note_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Sắp tới',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Hiển thị theo ngày
          ...groupedByDay.entries.take(3).map((entry) {
            final dayName = _getDayName(entry.key);
            final items = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      dayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: items.map((item) => _buildMiniScheduleChip(item)).toList(),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(ScheduleItem item, {bool isToday = false}) {
    final now = DateTime.now();
    final isPast = isToday && item.scheduledDateTime != null &&
        item.scheduledDateTime!.isBefore(now);
    final isNext = isToday && item.scheduledDateTime != null &&
        item.scheduledDateTime!.isAfter(now) &&
        item.scheduledDateTime!.difference(now).inMinutes <= 60;

    return InkWell(
      onTap: () => onTapItem?.call(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isNext
              ? AppColors.primary.withOpacity(0.1)
              : isPast
              ? AppColors.textGray.withOpacity(0.05)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: isNext
              ? Border.all(color: AppColors.primary.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            // Thời gian
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isNext
                    ? AppColors.primary
                    : isPast
                    ? AppColors.textGray.withOpacity(0.2)
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.displayTime,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isNext
                      ? Colors.white
                      : isPast
                      ? AppColors.textGray
                      : AppColors.primaryDark,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Tên category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.categoryName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isPast ? AppColors.textGray : AppColors.primaryDark,
                      decoration: isPast ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isNext)
                    Text(
                      'Sắp đến giờ học!',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            // Status icon
            if (isPast)
              Icon(Icons.check_circle, size: 20, color: AppColors.success)
            else if (isNext)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, size: 14, color: Colors.white),
              )
            else
              Icon(Icons.chevron_right, size: 20, color: AppColors.textGray),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniScheduleChip(ScheduleItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.displayTime,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            item.categoryName,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.primaryDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getDayName(int dayOfWeek) {
    const dayNames = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return dayNames[dayOfWeek];
  }
}

// ==================== CATEGORY SCHEDULE SETTING CARD ====================

/// Widget cài đặt lịch học cho một category (trong category_detail)
class CategoryScheduleSettingCard extends StatefulWidget {
  final CategoryStudyScheduleModel schedule;
  final Function(CategoryStudyScheduleModel) onUpdate;
  final List<ScheduleConflict>? conflicts;
  final VoidCallback? onShowConflictDetail;

  const CategoryScheduleSettingCard({
    Key? key,
    required this.schedule,
    required this.onUpdate,
    this.conflicts,
    this.onShowConflictDetail,
  }) : super(key: key);

  @override
  State<CategoryScheduleSettingCard> createState() => _CategoryScheduleSettingCardState();
}

class _CategoryScheduleSettingCardState extends State<CategoryScheduleSettingCard> {
  static const List<String> _dayLabels = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),

          // Content (chỉ hiện khi enabled)
          if (widget.schedule.isEnabled) ...[
            const Divider(height: 1),
            _buildTimeSelector(),
            _buildDaysSelector(),

            // Cảnh báo xung đột
            if (widget.conflicts != null && widget.conflicts!.isNotEmpty)
              _buildConflictWarning(),

            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.schedule.isEnabled
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.textGray.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.notifications_active_rounded,
              color: widget.schedule.isEnabled ? AppColors.success : AppColors.textGray,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nhắc nhở học tập',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                if (widget.schedule.isEnabled && widget.schedule.hasAnyDayEnabled)
                  Text(
                    '${widget.schedule.displayTime} - ${widget.schedule.enabledDayNames.join(", ")}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: widget.schedule.isEnabled,
            onChanged: (value) {
              widget.onUpdate(widget.schedule.copyWith(isEnabled: value));
            },
            activeColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thời gian nhắc nhở',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => _showTimePicker(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    widget.schedule.displayTime,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.edit_rounded, color: AppColors.textGray, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Các ngày trong tuần',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (widget.schedule.enabledDaysCount > 0)
                Text(
                  '${widget.schedule.enabledDaysCount} ngày',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final isSelected = widget.schedule.isDayEnabled(index);
              return GestureDetector(
                onTap: () {
                  widget.onUpdate(widget.schedule.toggleDay(index));
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textGray.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      _dayLabels[index],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.textGray,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          // Quick select buttons
          Row(
            children: [
              _buildQuickSelectButton('Hàng ngày', '1111111'),
              const SizedBox(width: 8),
              _buildQuickSelectButton('Ngày thường', '0111110'),
              const SizedBox(width: 8),
              _buildQuickSelectButton('Cuối tuần', '1000001'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSelectButton(String label, String daysPattern) {
    final isActive = widget.schedule.daysOfWeek == daysPattern;
    return Expanded(
      child: InkWell(
        onTap: () {
          widget.onUpdate(widget.schedule.copyWith(daysOfWeek: daysPattern));
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.textGray.withOpacity(0.2),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? AppColors.primary : AppColors.textGray,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConflictWarning() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: widget.onShowConflictDetail,
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phát hiện xung đột lịch học',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                  Text(
                    '${widget.conflicts!.length} thời điểm trùng với học phần khác',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.warning.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.warning),
          ],
        ),
      ),
    );
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: widget.schedule.hour, minute: widget.schedule.minute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.primaryDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      widget.onUpdate(widget.schedule.copyWith(
        hour: picked.hour,
        minute: picked.minute,
      ));
    }
  }
}

// ==================== CONFLICT RESOLUTION DIALOG ====================

/// Dialog hiển thị chi tiết xung đột và cho phép giải quyết
class ScheduleConflictDialog extends StatelessWidget {
  final List<ScheduleConflict> conflicts;
  final Function(int categoryId)? onGoToCategory;

  const ScheduleConflictDialog({
    Key? key,
    required this.conflicts,
    this.onGoToCategory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Xung đột lịch học',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: AppColors.textGray),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: conflicts.length,
                separatorBuilder: (_, __) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final conflict = conflicts[index];
                  return _buildConflictItem(context, conflict);
                },
              ),
            ),

            const SizedBox(height: 16),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Đã hiểu'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConflictItem(BuildContext context, ScheduleConflict conflict) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, size: 14, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    '${conflict.dayName} ${conflict.displayTime}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Các học phần trùng giờ:',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ...conflict.categories.map((cat) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: InkWell(
            onTap: () {
              Navigator.pop(context);
              onGoToCategory?.call(cat.categoryId);
            },
            child: Row(
              children: [
                Icon(Icons.folder_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cat.categoryName,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textGray),
              ],
            ),
          ),
        )),
      ],
    );
  }
}