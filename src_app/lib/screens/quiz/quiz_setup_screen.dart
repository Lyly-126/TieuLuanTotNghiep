import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/quiz_model.dart';
import '../../models/category_model.dart';
import '../../services/quiz_service.dart';
import 'quiz_screen.dart';

/// 🔄 Màn hình cài đặt trước khi bắt đầu bài kiểm tra
/// ✅ UI IMPROVED: Gradient header, card animations, better spacing
/// ✅ FIX OVERFLOW: Sử dụng Flexible và Expanded đúng cách
class QuizSetupScreen extends StatefulWidget {
  final CategoryModel category;

  const QuizSetupScreen({
    super.key,
    required this.category,
  });

  @override
  State<QuizSetupScreen> createState() => _QuizSetupScreenState();
}

class _QuizSetupScreenState extends State<QuizSetupScreen>
    with SingleTickerProviderStateMixin {
  QuizType _selectedType = QuizType.quickTest;
  final bool _onlyStudiedCards = false;
  final bool _focusWeakCards = false;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _quizTypeToString(QuizType type) {
    switch (type) {
      case QuizType.quickTest:
        return 'MIXED';
      case QuizType.fullTest:
        return 'MIXED';
      case QuizType.listeningTest:
        return 'LISTENING';
      case QuizType.writingTest:
        return 'WRITING';
      case QuizType.mixedTest:
        return 'MIXED';
    }
  }

  final List<QuizTypeOption> _quizTypes = [
    QuizTypeOption(
      type: QuizType.quickTest,
      title: 'Kiểm tra nhanh',
      questionCount: 10,
      duration: 'Khoảng 5 phút',
      icon: Icons.flash_on_rounded,
      color: Colors.orange,
      gradient: [Colors.orange, Colors.deepOrange],
    ),
    QuizTypeOption(
      type: QuizType.fullTest,
      title: 'Kiểm tra đầy đủ',
      questionCount: 20,
      duration: 'Khoảng 15 phút',
      icon: Icons.assignment_rounded,
      color: Colors.blue,
      gradient: [Colors.blue, Colors.indigo],
    ),
    QuizTypeOption(
      type: QuizType.listeningTest,
      title: 'Kiểm tra nghe',
      questionCount: 15,
      duration: 'Khoảng 10 phút',
      icon: Icons.headphones_rounded,
      color: Colors.green,
      gradient: [Colors.green, Colors.teal],
    ),
    QuizTypeOption(
      type: QuizType.writingTest,
      title: 'Kiểm tra viết',
      questionCount: 10,
      duration: 'Khoảng 10 phút',
      icon: Icons.edit_rounded,
      color: Colors.purple,
      gradient: [Colors.purple, Colors.deepPurple],
    ),
    QuizTypeOption(
      type: QuizType.mixedTest,
      title: 'Kiểm tra tổng hợp',
      questionCount: 25,
      duration: 'Khoảng 20 phút',
      icon: Icons.shuffle_rounded,
      color: Colors.teal,
      gradient: [Colors.teal, Colors.cyan],
    ),
  ];

  Future<void> _startQuiz() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final request = CreateQuizRequest(
        categoryId: widget.category.id,
        quizType: _quizTypeToString(_selectedType),
        onlyStudiedCards: _onlyStudiedCards,
        focusWeakCards: _focusWeakCards,
      );

      final session = await QuizService.createQuiz(request);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizScreen(session: session),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Không thể tạo bài kiểm tra: $e')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ✅ Custom SliverAppBar với gradient
          _buildSliverAppBar(),

          // ✅ Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // Section title
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Chọn loại kiểm tra',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Quiz types
                    ..._quizTypes.asMap().entries.map((entry) {
                      final index = entry.key;
                      final option = entry.value;
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 400 + (index * 100)),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: _buildQuizTypeCard(option),
                            ),
                          );
                        },
                      );
                    }),

                    const SizedBox(height: 32),

                    // Start button
                    _buildStartButton(),

                    const SizedBox(height: 16),

                    // Tip
                    _buildTipCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.accent],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.quiz_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Text content - ✅ FIX: Wrap với Expanded
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.category.flashcardCount} thẻ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.category.name,
                              style: const TextStyle(
                                fontSize: 22,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizTypeCard(QuizTypeOption option) {
    final isSelected = _selectedType == option.type;

    return GestureDetector(
      onTap: () => setState(() => _selectedType = option.type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? option.color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? option.color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? option.color.withOpacity(0.15)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isSelected ? 12 : 8,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon với gradient
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(colors: option.gradient)
                    : null,
                color: isSelected ? null : option.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                option.icon,
                color: isSelected ? Colors.white : option.color,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),

            // Text content - ✅ FIX: Sử dụng Expanded đúng cách
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? option.color : AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // ✅ FIX: Thay Row bằng Wrap hoặc dùng Text đơn giản
                  Text(
                    '⏱ ${option.questionCount} câu hỏi • ${option.duration}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textGray,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Check icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected ? option.color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? option.color : AppColors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    final selectedOption = _quizTypes.firstWhere((o) => o.type == _selectedType);

    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: selectedOption.gradient),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: selectedOption.color.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _startQuiz,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
            SizedBox(width: 10),
            Text(
              'Bắt đầu kiểm tra',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mẹo nhỏ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Làm bài kiểm tra đều đặn giúp ghi nhớ từ vựng lâu hơn 2-3 lần!',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Model cho loại quiz option
class QuizTypeOption {
  final QuizType type;
  final String title;
  final int questionCount;
  final String duration;
  final IconData icon;
  final Color color;
  final List<Color> gradient;

  QuizTypeOption({
    required this.type,
    required this.title,
    required this.questionCount,
    required this.duration,
    required this.icon,
    required this.color,
    required this.gradient,
  });
}