import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/study_progress_model.dart';

// ==================== PROGRESS CARD ====================

/// Widget hiển thị phần trăm đã học
class StudyProgressCard extends StatelessWidget {
  final CategoryProgressModel progress;
  final VoidCallback? onResetProgress;

  const StudyProgressCard({
    super.key,
    required this.progress,
    this.onResetProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Tiến trình học',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              if (onResetProgress != null && progress.studiedCards > 0)
                IconButton(
                  icon: Icon(Icons.refresh, color: AppColors.textGray, size: 20),
                  onPressed: onResetProgress,
                  tooltip: 'Reset tiến trình',
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress Bar
          _buildProgressBar(),
          const SizedBox(height: 16),

          // Stats Grid - ✅ BỎ THÀNH THẠO
          _buildStatsGrid(),

          // Last studied
          if (progress.lastStudiedAt != null) ...[
            const SizedBox(height: 16),
            _buildLastStudied(),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final percent = progress.progressPercent / 100;

    return Column(
      children: [
        // Percentage Text
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${progress.progressPercent.toStringAsFixed(0)}% đã học',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getProgressColor(progress.progressPercent).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${progress.studiedCards}/${progress.totalCards} thẻ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _getProgressColor(progress.progressPercent),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ✅ FIX: Progress Bar - DÙNG LayoutBuilder + Positioned căn trái
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final progressWidth = maxWidth * percent.clamp(0.0, 1.0);

            return Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Stack(
                children: [
                  // ✅ Progress bar căn trái bằng Positioned
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: progressWidth,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),

        // Legend - ✅ BỎ THÀNH THẠO
        Row(
          children: [
            _buildLegendItem(AppColors.primary, 'Đang học'),
            const SizedBox(width: 16),
            _buildLegendItem(AppColors.background, 'Chưa học'),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: color == AppColors.background
                ? Border.all(color: AppColors.textGray.withOpacity(0.3), width: 1)
                : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.textGray),
        ),
      ],
    );
  }

  // ✅ Stats Grid - BỎ MỤC THÀNH THẠO
  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(child: _buildStatItem(
          icon: Icons.pending,
          color: AppColors.warning,
          value: '${progress.learningCards}',
          label: 'Đang học',
        )),
        Expanded(child: _buildStatItem(
          icon: Icons.schedule,
          color: AppColors.textGray,
          value: '${progress.notStartedCards}',
          label: 'Chưa học',
        )),
        Expanded(child: _buildStatItem(
          icon: Icons.track_changes,
          color: progress.accuracyRate >= 70 ? AppColors.success : AppColors.warning,
          value: '${progress.accuracyRate.toStringAsFixed(0)}%',
          label: 'Độ chính xác',
        )),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: AppColors.textGray),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLastStudied() {
    final lastStudied = progress.lastStudiedAt!;
    final now = DateTime.now();
    final diff = now.difference(lastStudied);

    String timeAgo;
    if (diff.inMinutes < 1) {
      timeAgo = 'Vừa xong';
    } else if (diff.inMinutes < 60) {
      timeAgo = '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      timeAgo = '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      timeAgo = '${diff.inDays} ngày trước';
    } else {
      timeAgo = '${lastStudied.day}/${lastStudied.month}/${lastStudied.year}';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, size: 16, color: AppColors.textGray),
          const SizedBox(width: 8),
          Text(
            'Học lần cuối: $timeAgo',
            style: TextStyle(fontSize: 12, color: AppColors.textGray),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double percent) {
    if (percent >= 80) return AppColors.success;
    if (percent >= 50) return AppColors.primary;
    if (percent >= 20) return AppColors.warning;
    return AppColors.textGray;
  }
}


// ==================== STREAK CARD ====================

/// Widget hiển thị streak đầy đủ
class StudyStreakCard extends StatelessWidget {
  final StudyStreakModel streak;
  final VoidCallback? onTap;

  const StudyStreakCard({
    super.key,
    required this.streak,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: streak.hasStudiedToday
                ? [AppColors.success, AppColors.success.withOpacity(0.8)]
                : streak.isStreakAtRisk
                ? [AppColors.warning, AppColors.warning.withOpacity(0.8)]
                : [AppColors.primary, AppColors.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (streak.hasStudiedToday ? AppColors.success : AppColors.primary)
                  .withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('🔥', style: TextStyle(fontSize: 32)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${streak.currentStreak}',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: Text(
                              'ngày streak',
                              style: TextStyle(fontSize: 16, color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        streak.hasStudiedToday
                            ? '✓ Đã học hôm nay - Tuyệt vời!'
                            : streak.isStreakAtRisk
                            ? '⚠ Học ngay để giữ streak!'
                            : 'Kỷ lục: ${streak.longestStreak} ngày',
                        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildWeeklyCalendar(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyCalendar() {
    const dayLabels = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final isStudied = index < streak.weeklyData.length
            ? streak.weeklyData[index].isStudied
            : false;
        final isToday = index == DateTime.now().weekday % 7;

        return Column(
          children: [
            Text(dayLabels[index], style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7))),
            const SizedBox(height: 6),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isStudied ? Colors.white : Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: isToday ? Border.all(color: Colors.white, width: 2) : null,
              ),
              child: Center(
                child: isStudied ? const Icon(Icons.check, size: 18, color: AppColors.success) : null,
              ),
            ),
          ],
        );
      }),
    );
  }
}


// ==================== REMINDER CARD ====================

class StudyReminderCard extends StatelessWidget {
  final StudyReminderModel reminder;
  final Function(StudyReminderModel) onUpdate;

  const StudyReminderCard({
    super.key,
    required this.reminder,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
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
                child: Icon(Icons.notifications_active_rounded, color: AppColors.secondary, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Nhắc nhở học tập', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
              ),
              Switch(
                value: reminder.isEnabled,
                onChanged: (value) => onUpdate(reminder.copyWith(isEnabled: value)),
                activeThumbColor: AppColors.secondary,
              ),
            ],
          ),
          if (reminder.isEnabled) ...[
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 20),
            _buildTimePicker(context),
            const SizedBox(height: 16),
            _buildDaysSelector(),
          ],
        ],
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context) {
    return GestureDetector(
      onTap: () => _showTimePicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: AppColors.secondary, size: 22),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thời gian nhắc nhở', style: TextStyle(fontSize: 12, color: AppColors.textGray)),
                Text(reminder.displayTime, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
              ],
            ),
            const Spacer(),
            Icon(Icons.edit, color: AppColors.textGray, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: reminder.hour, minute: reminder.minute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary, secondary: AppColors.secondary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onUpdate(reminder.copyWith(hour: picked.hour, minute: picked.minute));
    }
  }

  Widget _buildDaysSelector() {
    const dayLabels = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nhắc nhở vào các ngày', style: TextStyle(fontSize: 13, color: AppColors.textGray)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final isEnabled = reminder.isDayEnabled(index);
            return GestureDetector(
              onTap: () => onUpdate(reminder.toggleDay(index)),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isEnabled ? AppColors.secondary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isEnabled ? AppColors.secondary : AppColors.border, width: 1.5),
                ),
                child: Center(
                  child: Text(dayLabels[index], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isEnabled ? Colors.white : AppColors.textGray)),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}


// ==================== STREAK MINI CARD ====================

class StreakMiniCard extends StatelessWidget {
  final StudyStreakModel streak;
  final VoidCallback? onTap;

  const StreakMiniCard({
    super.key,
    required this.streak,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: streak.hasStudiedToday
                ? [AppColors.success, AppColors.success.withOpacity(0.8)]
                : streak.isStreakAtRisk
                ? [AppColors.warning, AppColors.warning.withOpacity(0.8)]
                : [AppColors.primary, AppColors.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (streak.hasStudiedToday ? AppColors.success : AppColors.primary).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: const Text('🔥', style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('${streak.currentStreak}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(width: 6),
                      const Text('ngày streak', style: TextStyle(fontSize: 14, color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    streak.hasStudiedToday
                        ? '✓ Đã học hôm nay'
                        : streak.isStreakAtRisk
                        ? '⚠ Học ngay để giữ streak!'
                        : 'Kỷ lục: ${streak.longestStreak} ngày',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
            _buildWeeklyDots(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyDots() {
    return Row(
      children: List.generate(7, (index) {
        final isStudied = index < streak.weeklyData.length ? streak.weeklyData[index].isStudied : false;
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isStudied ? Colors.white : Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}