import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';

class StudyStatisticsScreen extends StatelessWidget {
  const StudyStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Thống kê học tập',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(
        padding: AppConstants.screenPadding.copyWith(top: 16, bottom: 40),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // ---------------- Tổng quan ----------------
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius:
                  BorderRadius.circular(AppConstants.borderRadius * 1.2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '120',
                            style: AppTextStyles.heading3.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tổng thẻ đã học',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.hint.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '7 ngày',
                            style: AppTextStyles.heading3.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Chuỗi học liên tục',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.hint.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '18 phút',
                            style: AppTextStyles.heading3.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Trung bình/ngày',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.hint.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // ---------------- Lịch học trong tuần (dạng Quizlet) ----------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Chuỗi học liên tục: 7 ngày',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Giữ streak của bạn mỗi ngày để không gián đoạn tiến độ!',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.hint.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Lịch tuần
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(7, (index) {
                        const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

                        // ví dụ: giả định đã học 5 ngày đầu, 2 ngày cuối chưa học
                        final bool learned = index < 5;

                        return Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: learned
                                    ? AppColors.primary.withValues(alpha: 0.9)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: learned
                                      ? AppColors.primary
                                      : AppColors.primary.withValues(alpha: 0.3),
                                  width: 1.4,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Icon(
                                  learned ? Icons.check_rounded : Icons.circle_outlined,
                                  color: learned ? Colors.white : AppColors.textGray,
                                  size: learned ? 22 : 18,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              days[index],
                              style: AppTextStyles.hint.copyWith(
                                fontSize: 13,
                                color: learned
                                    ? AppColors.primaryDark
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),


              const SizedBox(height: 36),

              // ---------------- Biểu đồ ----------------
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Hoạt động trong tuần',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(AppConstants.borderRadius * 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),
                        leftTitles: const AxisTitles(),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                              if (value.toInt() < days.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    days[value.toInt()],
                                    style: AppTextStyles.hint.copyWith(
                                      fontSize: 12,
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
                      barGroups: [
                        _bar(0, 3),
                        _bar(1, 6),
                        _bar(2, 5),
                        _bar(3, 7),
                        _bar(4, 4),
                        _bar(5, 8),
                        _bar(6, 2),
                      ],
                      alignment: BarChartAlignment.spaceAround,
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

  // ----------------- Thanh biểu đồ -----------------
  BarChartGroupData _bar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 16,
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }
}
