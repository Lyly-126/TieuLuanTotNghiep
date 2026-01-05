import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../models/quiz_model.dart';

/// 🏆 Màn hình kết quả bài kiểm tra
/// ✅ UI IMPROVED: Better animations, gradient cards, confetti
class QuizResultScreen extends StatefulWidget {
  final QuizResultModel result;

  const QuizResultScreen({
    Key? key,
    required this.result,
  }) : super(key: key);

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _scoreController;
  late Animation<double> _scoreAnimation;
  late AnimationController _confettiController;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    // Score animation
    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _scoreAnimation = Tween<double>(
      begin: 0,
      end: widget.result.score,
    ).animate(CurvedAnimation(
      parent: _scoreController,
      curve: Curves.easeOutCubic,
    ));

    // Confetti animation
    _confettiController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Bounce animation for icon
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    // Start animations
    Future.delayed(const Duration(milliseconds: 300), () {
      _scoreController.forward();
      _bounceController.forward();
    });

    if (widget.result.passed) {
      _confettiController.repeat();
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _confettiController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background gradient
          _buildBackground(),

          // Confetti
          if (widget.result.passed) _buildConfetti(),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Close button
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(Icons.close, color: AppColors.textGray, size: 20),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Result icon with bounce animation
                  _buildResultIcon(),

                  const SizedBox(height: 32),

                  // Score circle
                  _buildScoreCircle(),

                  const SizedBox(height: 20),

                  // Grade badge
                  _buildGradeBadge(),

                  const SizedBox(height: 12),

                  // Message
                  Text(
                    widget.result.scoreMessage,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Stats cards
                  _buildStatsCards(),

                  const SizedBox(height: 20),

                  // Improvement card
                  if (widget.result.previousScore != null) _buildImprovementCard(),

                  const SizedBox(height: 20),

                  // Category info
                  _buildCategoryInfo(),

                  const SizedBox(height: 32),

                  // Action buttons
                  _buildActionButtons(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    final color = widget.result.passed ? Colors.green : Colors.orange;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
            AppColors.background,
            AppColors.background,
          ],
          stops: const [0, 0.3, 0.5, 1],
        ),
      ),
    );
  }

  Widget _buildConfetti() {
    return AnimatedBuilder(
      animation: _confettiController,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: ConfettiPainter(progress: _confettiController.value),
        );
      },
    );
  }

  Widget _buildResultIcon() {
    IconData icon;
    List<Color> gradient;
    String emoji;

    if (widget.result.score >= 90) {
      icon = Icons.emoji_events_rounded;
      gradient = [Colors.amber, Colors.orange];
      emoji = '🏆';
    } else if (widget.result.score >= 80) {
      icon = Icons.star_rounded;
      gradient = [Colors.orange, Colors.deepOrange];
      emoji = '⭐';
    } else if (widget.result.score >= 60) {
      icon = Icons.thumb_up_rounded;
      gradient = [Colors.green, Colors.teal];
      emoji = '✅';
    } else {
      icon = Icons.fitness_center_rounded;
      gradient = [Colors.blue, Colors.indigo];
      emoji = '💪';
    }

    return ScaleTransition(
      scale: _bounceAnimation,
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradient[0].withOpacity(0.4),
                  blurRadius: 24,
                  spreadRadius: 4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 56)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _getResultTitle(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: gradient[0],
            ),
          ),
        ],
      ),
    );
  }

  String _getResultTitle() {
    if (widget.result.score >= 90) return 'Xuất sắc!';
    if (widget.result.score >= 80) return 'Rất tốt!';
    if (widget.result.score >= 60) return 'Đạt yêu cầu!';
    return 'Cố gắng hơn nhé!';
  }

  Widget _buildScoreCircle() {
    return AnimatedBuilder(
      animation: _scoreAnimation,
      builder: (context, child) {
        final score = _scoreAnimation.value;
        final color = _getScoreColor(score);

        return SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            children: [
              // Background circle
              Center(
                child: SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 14,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade200),
                  ),
                ),
              ),

              // Progress circle
              Center(
                child: SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 14,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),

              // Score text
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${score.toInt()}',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: color,
                        height: 1,
                      ),
                    ),
                    Text(
                      'điểm',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGradeBadge() {
    final color = _getGradeColor(widget.result.grade);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.grade_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Text(
            'Xếp loại: ${widget.result.grade}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle_rounded,
            iconColor: Colors.green,
            value: widget.result.correctAnswers.toString(),
            label: 'Đúng',
            gradient: [Colors.green.shade50, Colors.green.shade100],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.cancel_rounded,
            iconColor: Colors.red,
            value: widget.result.incorrectAnswers.toString(),
            label: 'Sai',
            gradient: [Colors.red.shade50, Colors.red.shade100],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.timer_rounded,
            iconColor: Colors.blue,
            value: widget.result.timeFormatted,
            label: 'Thời gian',
            gradient: [Colors.blue.shade50, Colors.blue.shade100],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textGray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementCard() {
    final improvement = widget.result.scoreImprovement ?? 0;
    final isImproved = improvement > 0;
    final color = isImproved ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isImproved ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isImproved ? 'Bạn đã tiến bộ! 🎉' : 'Hãy cố gắng hơn nhé! 💪',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lần trước: ${widget.result.previousScore?.toInt()}đ → Lần này: ${widget.result.score.toInt()}đ',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${improvement > 0 ? '+' : ''}${improvement.toInt()}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryInfo() {
    return Container(
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.folder_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.result.categoryName.isNotEmpty
                      ? widget.result.categoryName
                      : 'Chủ đề',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip(Icons.quiz_rounded, _getQuizTypeLabel(widget.result.quizType)),
                    const SizedBox(width: 8),
                    _buildInfoChip(Icons.speed_rounded, _getDifficultyLabel(widget.result.difficulty)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textGray),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textGray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Retry button
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, 'retry'),
            icon: const Icon(Icons.refresh_rounded, size: 24),
            label: const Text(
              'Làm lại bài kiểm tra',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ),

        // Review wrong answers button
        if (widget.result.incorrectAnswers > 0) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context, 'review'),
              icon: Icon(Icons.menu_book_rounded, color: Colors.orange.shade700),
              label: Text(
                'Ôn lại ${widget.result.incorrectAnswers} từ sai',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.orange.shade400, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ),
        ],

        // Back button
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_rounded, color: AppColors.textGray),
            label: Text(
              'Quay lại chủ đề',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.deepOrange;
      default:
        return Colors.red;
    }
  }

  String _getQuizTypeLabel(String type) {
    switch (type.toUpperCase()) {
      case 'QUICK_TEST':
      case 'MIXED':
        return 'Nhanh';
      case 'FULL_TEST':
        return 'Đầy đủ';
      case 'LISTENING_TEST':
      case 'LISTENING':
        return 'Nghe';
      case 'WRITING_TEST':
      case 'WRITING':
        return 'Viết';
      case 'MIXED_TEST':
        return 'Tổng hợp';
      default:
        return type;
    }
  }

  String _getDifficultyLabel(String difficulty) {
    switch (difficulty.toUpperCase()) {
      case 'KIDS':
        return 'Trẻ em';
      case 'TEEN':
        return 'Thiếu niên';
      case 'ADULT':
        return 'Người lớn';
      case 'AUTO':
        return 'Tự động';
      default:
        return difficulty;
    }
  }
}

/// AnimatedBuilder helper
class AnimatedBuilder extends StatelessWidget {
  final Listenable animation;
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    Key? key,
    required this.animation,
    required this.builder,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder2(animation: animation, builder: builder, child: child);
  }
}

class AnimatedBuilder2 extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder2({
    Key? key,
    required Listenable animation,
    required this.builder,
    this.child,
  }) : super(key: key, listenable: animation);

  @override
  Widget build(BuildContext context) => builder(context, child);
}

/// Confetti painter
class ConfettiPainter extends CustomPainter {
  final double progress;
  final List<ConfettiParticle> particles;

  ConfettiPainter({required this.progress})
      : particles = List.generate(60, (i) => ConfettiParticle());

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      final x = particle.x * size.width;
      final y = (particle.startY + progress * particle.speed) % 1.0 * size.height;

      paint.color = particle.color.withOpacity(
        (1 - (y / size.height)).clamp(0.2, 1.0),
      );

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * particle.rotationSpeed * math.pi * 2);

      if (particle.isCircle) {
        canvas.drawCircle(Offset.zero, 5, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: 10, height: 6),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => progress != oldDelegate.progress;
}

class ConfettiParticle {
  final double x = math.Random().nextDouble();
  final double startY = math.Random().nextDouble() * -0.5;
  final double speed = 0.4 + math.Random().nextDouble() * 0.4;
  final double rotationSpeed = 1 + math.Random().nextDouble() * 4;
  final bool isCircle = math.Random().nextBool();
  final Color color = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.amber,
    Colors.cyan,
    Colors.teal,
  ][math.Random().nextInt(9)];
}