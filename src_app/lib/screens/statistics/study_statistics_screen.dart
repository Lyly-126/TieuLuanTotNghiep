import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../services/study_progress_service.dart';
import '../../models/study_progress_model.dart';

class StudyStatisticsScreen extends StatefulWidget {
  const StudyStatisticsScreen({super.key});

  @override
  State<StudyStatisticsScreen> createState() => _StudyStatisticsScreenState();
}

class _StudyStatisticsScreenState extends State<StudyStatisticsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;

  // Data từ API
  StudyStreakModel? _streakInfo;
  List<DailyStudyModel> _weeklyData = [];

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Gọi API lấy dữ liệu
      final streakInfo = await StudyProgressService.getStreakInfo();
      final weeklyData = await StudyProgressService.getWeeklyData();

      setState(() {
        _streakInfo = streakInfo;
        _weeklyData = weeklyData;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải dữ liệu. Vui lòng thử lại.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
          ? _buildErrorState()
          : _buildContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primary,
            size: 18,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: Text(
        'Thống kê học tập',
        style: AppTextStyles.heading2.copyWith(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.refresh_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          onPressed: _loadData,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Đang tải dữ liệu...',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: AppConstants.screenPadding.copyWith(top: 16, bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Streak Hero Card
              _buildStreakHeroCard(),
              const SizedBox(height: 24),

              // Overview Stats
              _buildOverviewStats(),
              const SizedBox(height: 24),

              // Weekly Calendar
              _buildWeeklyCalendar(),
              const SizedBox(height: 24),

              // Activity Chart
              _buildActivityChart(),
              const SizedBox(height: 24),

              // Study Summary
              _buildStudySummary(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakHeroCard() {
    final streak = _streakInfo;
    if (streak == null) return const SizedBox.shrink();

    final bool hasStudiedToday = streak.hasStudiedToday;
    final bool isAtRisk = streak.isStreakAtRisk;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasStudiedToday
              ? [AppColors.success, AppColors.success.withOpacity(0.8)]
              : isAtRisk
              ? [AppColors.warning, AppColors.warning.withOpacity(0.8)]
              : [AppColors.primary, AppColors.accent],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (hasStudiedToday ? AppColors.success : AppColors.primary)
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Fire icon với animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '🔥',
                    style: TextStyle(fontSize: 40),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Streak number
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${streak.currentStreak}',
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'ngày',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Status message
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasStudiedToday
                      ? Icons.check_circle_rounded
                      : isAtRisk
                      ? Icons.warning_rounded
                      : Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  hasStudiedToday
                      ? 'Đã học hôm nay!'
                      : isAtRisk
                      ? 'Học ngay để giữ streak!'
                      : 'Chuỗi học liên tục',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Longest streak
          Text(
            'Kỷ lục: ${streak.longestStreak} ngày',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStats() {
    final streak = _streakInfo;
    if (streak == null) return const SizedBox.shrink();

    // Tính tổng từ weekly data
    int totalCards = 0;
    for (var day in _weeklyData) {
      totalCards += day.cardsStudied;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.style_rounded,
              iconColor: AppColors.primary,
              value: '$totalCards',
              label: 'Thẻ đã học',
              sublabel: 'tuần này',
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: AppColors.border,
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.calendar_today_rounded,
              iconColor: AppColors.secondary,
              value: '${streak.totalStudyDays}',
              label: 'Tổng ngày',
              sublabel: 'đã học',
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: AppColors.border,
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.emoji_events_rounded,
              iconColor: AppColors.warning,
              value: '${streak.longestStreak}',
              label: 'Kỷ lục',
              sublabel: 'streak',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    String? sublabel,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.hint.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (sublabel != null) ...[
          const SizedBox(height: 2),
          Text(
            sublabel,
            textAlign: TextAlign.center,
            style: AppTextStyles.hint.copyWith(
              color: AppColors.textGray,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWeeklyCalendar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.secondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lịch học trong tuần',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Giữ streak mỗi ngày để không gián đoạn!',
                      style: AppTextStyles.hint.copyWith(
                        color: AppColors.textGray,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Week days
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              // Lấy ngày từ weekly data
              final dayData = index < _weeklyData.length
                  ? _weeklyData[index]
                  : DailyStudyModel.empty();

              final bool learned = dayData.isStudied;
              final dayLabel = _getDayLabel(dayData.date);
              final isToday = _isToday(dayData.date);

              return Column(
                children: [
                  // Day circle
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: learned
                          ? AppColors.primary
                          : isToday
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.transparent,
                      border: Border.all(
                        color: learned
                            ? AppColors.primary
                            : isToday
                            ? AppColors.primary
                            : AppColors.border,
                        width: isToday ? 2 : 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: learned
                          ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 22,
                      )
                          : Text(
                        '${dayData.date?.day ?? ''}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isToday
                              ? AppColors.primary
                              : AppColors.textGray,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Day label
                  Text(
                    dayLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      color: learned
                          ? AppColors.primaryDark
                          : isToday
                          ? AppColors.primary
                          : AppColors.textGray,
                    ),
                  ),

                  // Cards studied indicator
                  if (learned && dayData.cardsStudied > 0) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${dayData.cardsStudied}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart() {
    if (_weeklyData.isEmpty) return const SizedBox.shrink();

    // Tìm max để scale chart
    double maxCards = 1;
    for (var day in _weeklyData) {
      if (day.cardsStudied > maxCards) {
        maxCards = day.cardsStudied.toDouble();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Hoạt động trong tuần',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxCards > 4 ? maxCards / 4 : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.border.withOpacity(0.5),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: maxCards > 4 ? maxCards / 4 : 1,
                      getTitlesWidget: (value, _) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textGray,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index < _weeklyData.length) {
                          final dayLabel =
                          _getDayLabel(_weeklyData[index].date);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              dayLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textGray,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(_weeklyData.length, (index) {
                  final day = _weeklyData[index];
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: day.cardsStudied.toDouble(),
                        width: 24,
                        color: day.isStudied
                            ? AppColors.primary
                            : AppColors.border,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxCards,
                          color: AppColors.inputBackground,
                        ),
                      ),
                    ],
                  );
                }),
                alignment: BarChartAlignment.spaceAround,
                maxY: maxCards * 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudySummary() {
    // Tính toán thống kê
    int totalCards = 0;
    int studyDays = 0;

    for (var day in _weeklyData) {
      totalCards += day.cardsStudied;
      if (day.isStudied) studyDays++;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.summarize_rounded,
                  color: AppColors.success,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Tổng kết tuần',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Summary items - Xóa phiên học, giữ lại thẻ và ngày
          _buildSummaryItem(
            icon: Icons.style_rounded,
            color: AppColors.primary,
            label: 'Số thẻ đã học',
            value: '$totalCards thẻ',
          ),
          const SizedBox(height: 12),
          _buildSummaryItem(
            icon: Icons.calendar_today_rounded,
            color: AppColors.success,
            label: 'Ngày đã học',
            value: '$studyDays/7 ngày',
            showProgress: true,
            progressValue: studyDays / 7,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    bool showProgress = false,
    double progressValue = 0,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (showProgress) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      backgroundColor: color.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getDayLabel(DateTime? date) {
    if (date == null) return '';
    const days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return days[date.weekday % 7];
  }

  bool _isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}