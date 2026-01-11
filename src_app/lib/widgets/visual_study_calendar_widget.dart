import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/category_study_schedule_model.dart';

/// ==================== VISUAL STUDY CALENDAR WIDGET ====================
/// Widget hiển thị lịch học trực quan dạng lưới tuần
/// - Hiển thị 7 ngày trong tuần với các slot thời gian
/// - Highlight ngày hiện tại
/// - Hiển thị các buổi học đã đặt lịch
/// - Animation đẹp mắt
class VisualStudyCalendarWidget extends StatefulWidget {
  final StudyScheduleOverview overview;
  final Function(ScheduleItem)? onTapItem;
  final VoidCallback? onTapAddSchedule;
  final VoidCallback? onTapViewAll;

  const VisualStudyCalendarWidget({
    Key? key,
    required this.overview,
    this.onTapItem,
    this.onTapAddSchedule,
    this.onTapViewAll,
  }) : super(key: key);

  @override
  State<VisualStudyCalendarWidget> createState() => _VisualStudyCalendarWidgetState();
}

class _VisualStudyCalendarWidgetState extends State<VisualStudyCalendarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Ngày được chọn (mặc định là hôm nay)
  int _selectedDayIndex = 0;

  // Scroll controller cho timeline
  final ScrollController _timelineScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();

    // Set ngày hiện tại - Convert từ Dart weekday (1=T2, 7=CN) sang index (0=CN, 1=T2)
    final now = DateTime.now();
    _selectedDayIndex = now.weekday % 7; // 7%7=0 (CN), 1=T2, 2=T3...

    debugPrint('📅 [Calendar] Today: weekday=${now.weekday}, selectedIndex=$_selectedDayIndex');
    debugPrint('📅 [Calendar] Overview: total=${widget.overview.totalActiveSchedules}, today=${widget.overview.todaySchedules.length}');
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timelineScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),

            // Week Days Selector
            _buildWeekDaysSelector(),

            // Divider
            Divider(height: 1, color: Colors.grey.shade100),

            // Schedule Timeline cho ngày được chọn
            _buildScheduleTimeline(),

            // Footer với nút xem thêm
            if (widget.overview.totalActiveSchedules > 0)
              _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
      child: Row(
        children: [
          // Icon với gradient
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // Title và subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lịch học của bạn',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: widget.overview.totalActiveSchedules > 0
                            ? AppColors.success
                            : AppColors.textGray,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.overview.totalActiveSchedules > 0
                          ? '${widget.overview.totalActiveSchedules} học phần đang theo dõi'
                          : 'Chưa có lịch học',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Nút thêm lịch
          if (widget.onTapAddSchedule != null)
            IconButton(
              onPressed: widget.onTapAddSchedule,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeekDaysSelector() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final date = startOfWeek.add(Duration(days: index));
          final isToday = date.day == now.day &&
              date.month == now.month &&
              date.year == now.year;
          final isSelected = index == _selectedDayIndex;
          final hasSchedule = _hasScheduleOnDay(index);

          return _buildDayItem(
            dayName: _getDayName(index),
            dayNumber: date.day.toString(),
            isToday: isToday,
            isSelected: isSelected,
            hasSchedule: hasSchedule,
            scheduleCount: _getScheduleCountOnDay(index),
            onTap: () {
              setState(() {
                _selectedDayIndex = index;
              });
            },
          );
        }),
      ),
    );
  }

  Widget _buildDayItem({
    required String dayName,
    required String dayNumber,
    required bool isToday,
    required bool isSelected,
    required bool hasSchedule,
    required int scheduleCount,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : isToday
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Tên ngày
            Text(
              dayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white.withOpacity(0.8)
                    : isToday
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),

            // Số ngày
            Text(
              dayNumber,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.white
                    : isToday
                    ? AppColors.primary
                    : AppColors.primaryDark,
              ),
            ),

            // Indicator cho ngày có lịch
            const SizedBox(height: 4),
            if (hasSchedule)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  scheduleCount.clamp(0, 3),
                      (i) => Container(
                    margin: EdgeInsets.only(left: i > 0 ? 2 : 0),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleTimeline() {
    final schedulesForDay = _getSchedulesForSelectedDay();

    if (schedulesForDay.isEmpty) {
      return _buildEmptyDayState();
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      child: ListView.builder(
        controller: _timelineScrollController,
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        itemCount: schedulesForDay.length,
        itemBuilder: (context, index) {
          final item = schedulesForDay[index];
          final isFirst = index == 0;
          final isLast = index == schedulesForDay.length - 1;

          return _buildTimelineItem(
            item: item,
            index: index,
            isFirst: isFirst,
            isLast: isLast,
          );
        },
      ),
    );
  }

  Widget _buildTimelineItem({
    required ScheduleItem item,
    required int index,
    required bool isFirst,
    required bool isLast,
  }) {
    final now = DateTime.now();
    final isToday = _selectedDayIndex == (now.weekday % 7);
    final scheduleTime = DateTime(
      now.year, now.month, now.day,
      item.hour, item.minute,
    );
    final isPast = isToday && scheduleTime.isBefore(now);
    final isUpcoming = isToday &&
        scheduleTime.isAfter(now) &&
        scheduleTime.difference(now).inMinutes <= 60;

    // Gradient colors cho mỗi item
    final gradientColors = _getGradientColors(index);

    return InkWell(
      onTap: () => widget.onTapItem?.call(item),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline line và dot
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  // Top line
                  if (!isFirst)
                    Container(
                      width: 2,
                      height: 10,
                      color: isPast
                          ? AppColors.success.withOpacity(0.3)
                          : AppColors.border,
                    ),

                  // Dot
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isPast
                          ? AppColors.success
                          : isUpcoming
                          ? AppColors.primary
                          : gradientColors[0],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isPast
                              ? AppColors.success
                              : isUpcoming
                              ? AppColors.primary
                              : gradientColors[0]).withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isPast
                        ? const Icon(Icons.check, size: 8, color: Colors.white)
                        : null,
                  ),

                  // Bottom line
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            isPast
                                ? AppColors.success.withOpacity(0.3)
                                : AppColors.border,
                            AppColors.border.withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Content card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isPast
                      ? AppColors.success.withOpacity(0.05)
                      : isUpcoming
                      ? AppColors.primary.withOpacity(0.08)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isPast
                        ? AppColors.success.withOpacity(0.2)
                        : isUpcoming
                        ? AppColors.primary.withOpacity(0.3)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    // Icon với gradient
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isPast
                              ? [AppColors.success, AppColors.success.withOpacity(0.7)]
                              : gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isPast
                            ? Icons.check_rounded
                            : Icons.auto_stories_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.categoryName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isPast
                                  ? AppColors.textSecondary
                                  : AppColors.primaryDark,
                              decoration: isPast
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: isUpcoming
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.displayTime,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isUpcoming
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isUpcoming
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                              if (isUpcoming) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'SẮP ĐẾN',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Action button
                    if (!isPast)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isUpcoming
                              ? AppColors.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: isUpcoming
                              ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                              : null,
                        ),
                        child: Icon(
                          isUpcoming
                              ? Icons.play_arrow_rounded
                              : Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: isUpcoming
                              ? Colors.white
                              : AppColors.textGray,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDayState() {
    final isToday = _selectedDayIndex == (DateTime.now().weekday % 7);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isToday
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isToday
                  ? Icons.celebration_rounded
                  : Icons.event_available_rounded,
              color: isToday ? AppColors.success : AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isToday
                ? 'Không có lịch học hôm nay'
                : 'Không có lịch học ngày này',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isToday
                ? 'Bạn có thể tự học hoặc nghỉ ngơi 🎉'
                : 'Thêm lịch học để không bỏ lỡ buổi học',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (!isToday && widget.onTapAddSchedule != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: widget.onTapAddSchedule,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Thêm lịch học'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final nextSchedule = _getNextSchedule();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          // Thông tin buổi học tiếp theo
          if (nextSchedule != null)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.upcoming_rounded,
                      size: 16,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Tiếp theo: ${nextSchedule.displayTime} - ${nextSchedule.categoryName}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const Spacer(),

          // Nút xem tất cả
          if (widget.onTapViewAll != null)
            TextButton(
              onPressed: widget.onTapViewAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Xem tất cả',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ==================== HELPER METHODS ====================

  String _getDayName(int index) {
    const days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return days[index];
  }

  bool _hasScheduleOnDay(int dayIndex) {
    // Kiểm tra trong todaySchedules
    if (dayIndex == (DateTime.now().weekday % 7)) {
      return widget.overview.todaySchedules.isNotEmpty;
    }

    // Kiểm tra trong upcomingSchedules
    return widget.overview.upcomingSchedules
        .any((item) => item.dayOfWeek == dayIndex);
  }

  int _getScheduleCountOnDay(int dayIndex) {
    if (dayIndex == (DateTime.now().weekday % 7)) {
      return widget.overview.todaySchedules.length;
    }

    return widget.overview.upcomingSchedules
        .where((item) => item.dayOfWeek == dayIndex)
        .length;
  }

  List<ScheduleItem> _getSchedulesForSelectedDay() {
    final todayIndex = DateTime.now().weekday % 7;

    if (_selectedDayIndex == todayIndex) {
      return widget.overview.todaySchedules;
    }

    return widget.overview.upcomingSchedules
        .where((item) => item.dayOfWeek == _selectedDayIndex)
        .toList()
      ..sort((a, b) => a.compareTime(b));
  }

  ScheduleItem? _getNextSchedule() {
    final now = DateTime.now();

    // Tìm trong lịch hôm nay
    for (var item in widget.overview.todaySchedules) {
      if (item.scheduledDateTime != null &&
          item.scheduledDateTime!.isAfter(now)) {
        return item;
      }
    }

    // Nếu không có, lấy từ upcoming
    if (widget.overview.upcomingSchedules.isNotEmpty) {
      return widget.overview.upcomingSchedules.first;
    }

    return null;
  }

  List<Color> _getGradientColors(int index) {
    final gradients = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)],
      [const Color(0xFF11998e), const Color(0xFF38ef7d)],
      [const Color(0xFFfc4a1a), const Color(0xFFf7b733)],
      [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
      [const Color(0xFFf093fb), const Color(0xFFf5576c)],
      [const Color(0xFF30cfd0), const Color(0xFF330867)],
    ];
    return gradients[index % gradients.length];
  }
}


/// ==================== COMPACT SCHEDULE BANNER ====================
/// Widget nhỏ gọn hiển thị buổi học sắp tới (dùng cho header)
class CompactScheduleBanner extends StatelessWidget {
  final ScheduleItem? nextSchedule;
  final VoidCallback? onTap;

  const CompactScheduleBanner({
    Key? key,
    this.nextSchedule,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (nextSchedule == null) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final isUpcoming = nextSchedule!.scheduledDateTime != null &&
        nextSchedule!.scheduledDateTime!.isAfter(now) &&
        nextSchedule!.scheduledDateTime!.difference(now).inMinutes <= 30;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isUpcoming
                ? [AppColors.primary, AppColors.accent]
                : [AppColors.primary.withOpacity(0.1), AppColors.accent.withOpacity(0.1)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isUpcoming
              ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isUpcoming
                    ? Colors.white.withOpacity(0.2)
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isUpcoming ? Icons.notifications_active_rounded : Icons.schedule_rounded,
                color: isUpcoming ? Colors.white : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isUpcoming ? 'Sắp đến giờ học!' : 'Buổi học tiếp theo',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isUpcoming
                          ? Colors.white.withOpacity(0.9)
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${nextSchedule!.displayTime} - ${nextSchedule!.categoryName}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isUpcoming ? Colors.white : AppColors.primaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Action
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isUpcoming
                    ? Colors.white
                    : AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: isUpcoming ? AppColors.primary : Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// ==================== MINI WEEK CALENDAR ====================
/// Widget lịch tuần mini (dùng cho các màn hình khác)
class MiniWeekCalendar extends StatelessWidget {
  final Map<int, int> scheduleCountByDay;
  final int selectedDay;
  final Function(int)? onDaySelected;

  const MiniWeekCalendar({
    Key? key,
    required this.scheduleCountByDay,
    this.selectedDay = -1,
    this.onDaySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayIndex = now.weekday % 7;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (index) {
          final hasSchedule = (scheduleCountByDay[index] ?? 0) > 0;
          final isToday = index == todayIndex;
          final isSelected = index == selectedDay;

          return GestureDetector(
            onTap: () => onDaySelected?.call(index),
            child: Container(
              width: 36,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : isToday
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    _getDayName(index),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : isToday
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (hasSchedule)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    const SizedBox(height: 6),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  String _getDayName(int index) {
    const days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return days[index];
  }
}