import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/quiz_model.dart';
import '../../services/tts_service.dart';

/// 📖 Màn hình ôn tập câu sai
/// ✅ UI IMPROVED: Better cards, swipe navigation, animations
class QuizReviewScreen extends StatefulWidget {
  final QuizResultModel result;
  final List<QuizQuestionModel> questions;

  const QuizReviewScreen({
    Key? key,
    required this.result,
    required this.questions,
  }) : super(key: key);

  @override
  State<QuizReviewScreen> createState() => _QuizReviewScreenState();
}

class _QuizReviewScreenState extends State<QuizReviewScreen>
    with SingleTickerProviderStateMixin {
  final TTSService _ttsService = TTSService();
  late List<QuizQuestionModel> _wrongAnswers;
  late PageController _pageController;
  int _currentIndex = 0;
  bool _showOnlyWrong = true;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _filterQuestions();
    _animController.forward();
  }

  void _filterQuestions() {
    if (_showOnlyWrong) {
      _wrongAnswers = widget.questions.where((q) {
        if (q.isCorrect == null) return false;
        return q.isCorrect == false;
      }).toList();
    } else {
      _wrongAnswers = widget.questions;
    }
    if (_currentIndex >= _wrongAnswers.length) {
      _currentIndex = _wrongAnswers.isEmpty ? 0 : _wrongAnswers.length - 1;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    _ttsService.stop();
    super.dispose();
  }

  void _speakWord(String text) {
    _ttsService.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverFillRemaining(
            child: _wrongAnswers.isEmpty ? _buildEmptyState() : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final wrongCount = widget.questions.where((q) => q.isCorrect == false).length;
    final correctCount = widget.questions.where((q) => q.isCorrect == true).length;

    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: Colors.orange.shade600,
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
      actions: [
        // Filter toggle
        GestureDetector(
          onTap: () {
            setState(() {
              _showOnlyWrong = !_showOnlyWrong;
              _filterQuestions();
              _currentIndex = 0;
              _pageController.jumpToPage(0);
            });
          },
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  _showOnlyWrong ? Icons.filter_alt_rounded : Icons.filter_alt_off_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  _showOnlyWrong ? 'Chỉ câu sai' : 'Tất cả',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.orange.shade600,
                Colors.orange.shade500,
                Colors.deepOrange.shade400,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ôn tập từ vựng',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildStatBadge(Icons.cancel_rounded, '$wrongCount sai', Colors.red.shade300),
                                const SizedBox(width: 10),
                                _buildStatBadge(Icons.check_circle_rounded, '$correctCount đúng', Colors.green.shade300),
                              ],
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

  Widget _buildStatBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.celebration_rounded, size: 72, color: Colors.green.shade400),
            ),
            const SizedBox(height: 28),
            const Text(
              'Tuyệt vời! 🎉',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bạn không có câu trả lời sai nào!',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textGray,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Quay lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Progress indicator
        _buildProgressIndicator(),

        // Question cards with PageView
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _wrongAnswers.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              return _buildQuestionCard(_wrongAnswers[index], index);
            },
          ),
        ),

        // Navigation buttons
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _showOnlyWrong ? Colors.red.shade50 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _showOnlyWrong ? Icons.cancel_rounded : Icons.list_alt_rounded,
                          size: 16,
                          color: _showOnlyWrong ? Colors.red : Colors.blue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _showOnlyWrong ? 'Câu sai' : 'Tất cả',
                          style: TextStyle(
                            color: _showOnlyWrong ? Colors.red : Colors.blue,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Text(
                'Câu ${_currentIndex + 1} / ${_wrongAnswers.length}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _wrongAnswers.length > 10 ? 10 : _wrongAnswers.length,
                  (index) {
                final actualIndex = _wrongAnswers.length > 10
                    ? ((_currentIndex / _wrongAnswers.length) * 10).floor()
                    : index;
                final isCurrent = _wrongAnswers.length > 10
                    ? index == actualIndex
                    : index == _currentIndex;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isCurrent ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: isCurrent ? Colors.orange : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuizQuestionModel question, int index) {
    final isCorrect = question.isCorrect == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          // Main card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with question type
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCorrect
                          ? [Colors.green.shade50, Colors.green.shade100]
                          : [Colors.red.shade50, Colors.red.shade100],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      _buildQuestionTypeLabel(question.questionType),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCorrect ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isCorrect ? Icons.check_rounded : Icons.close_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isCorrect ? 'Đúng' : 'Sai',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question text
                      _buildQuestionContent(question),
                      const SizedBox(height: 24),

                      // Vocabulary card
                      _buildVocabularyCard(question),
                      const SizedBox(height: 24),

                      // Answer comparison
                      _buildAnswerComparison(question),
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

  Widget _buildQuestionTypeLabel(String questionType) {
    String label;
    Color color;
    IconData icon;

    final type = questionType.toUpperCase();
    if (type.contains('MULTIPLE')) {
      if (type.contains('REVERSE')) {
        label = 'Trắc nghiệm (ngược)';
        color = Colors.indigo;
        icon = Icons.swap_horiz_rounded;
      } else if (type.contains('IMAGE')) {
        label = 'Hình ảnh';
        color = Colors.green;
        icon = Icons.image_rounded;
      } else {
        label = 'Trắc nghiệm';
        color = Colors.blue;
        icon = Icons.check_circle_outline_rounded;
      }
    } else if (type.contains('FILL')) {
      if (type.contains('SENTENCE')) {
        label = 'Điền vào câu';
        color = Colors.deepPurple;
        icon = Icons.short_text_rounded;
      } else {
        label = 'Điền từ';
        color = Colors.purple;
        icon = Icons.edit_rounded;
      }
    } else if (type.contains('LISTENING')) {
      label = type.contains('SPELL') ? 'Nghe & viết' : 'Nghe';
      color = Colors.teal;
      icon = Icons.headphones_rounded;
    } else if (type.contains('WRITING')) {
      label = 'Viết';
      color = Colors.orange;
      icon = Icons.create_rounded;
    } else {
      label = 'Câu hỏi';
      color = Colors.grey;
      icon = Icons.help_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent(QuizQuestionModel question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Câu hỏi:',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  question.questionText,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
              if (question.isListeningQuestion)
                IconButton(
                  onPressed: () => _speakWord(question.word),
                  icon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.volume_up_rounded, color: Colors.blue, size: 22),
                  ),
                ),
            ],
          ),
        ),

        // Image if available
        if (question.imageUrl != null && question.imageUrl!.isNotEmpty) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              question.imageUrl!,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.image_not_supported_rounded, color: AppColors.textGray, size: 40),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVocabularyCard(QuizQuestionModel question) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.indigo.shade50],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.book_rounded, color: Colors.blue.shade600, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Từ vựng cần nhớ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _speakWord(question.word),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(Icons.volume_up_rounded, color: Colors.blue.shade600, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            question.word,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          if (question.phonetic != null && question.phonetic!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              question.phonetic!,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textGray,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.translate_rounded, color: AppColors.textGray, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    question.meaning,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerComparison(QuizQuestionModel question) {
    final userAnswer = _getUserAnswerDisplay(question);
    final correctAnswer = _getCorrectAnswerDisplay(question);
    final isCorrect = question.isCorrect == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User's answer
        _buildAnswerRow(
          label: 'Câu trả lời của bạn',
          answer: userAnswer ?? 'Không trả lời',
          isCorrect: isCorrect,
          icon: isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: isCorrect ? Colors.green : Colors.red,
        ),
        const SizedBox(height: 14),
        // Correct answer
        _buildAnswerRow(
          label: 'Đáp án đúng',
          answer: correctAnswer ?? '',
          isCorrect: true,
          icon: Icons.check_circle_rounded,
          color: Colors.green,
          showSpeaker: true,
          onSpeak: () => _speakWord(question.word),
        ),
      ],
    );
  }

  String? _getUserAnswerDisplay(QuizQuestionModel question) {
    if (question.selectedOptionIndex != null &&
        question.options != null &&
        question.options!.isNotEmpty) {
      final index = question.selectedOptionIndex!;
      if (index >= 0 && index < question.options!.length) {
        return question.options![index];
      }
    }
    return question.userAnswer;
  }

  String? _getCorrectAnswerDisplay(QuizQuestionModel question) {
    if (question.correctAnswer != null && question.correctAnswer!.isNotEmpty) {
      return question.correctAnswer;
    }
    if (question.options != null &&
        question.correctOptionIndex != null &&
        question.correctOptionIndex! >= 0 &&
        question.correctOptionIndex! < question.options!.length) {
      return question.options![question.correctOptionIndex!];
    }
    return question.word;
  }

  Widget _buildAnswerRow({
    required String label,
    required String answer,
    required bool isCorrect,
    required IconData icon,
    required Color color,
    bool showSpeaker = false,
    VoidCallback? onSpeak,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  answer,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              if (showSpeaker && onSpeak != null)
                GestureDetector(
                  onTap: onSpeak,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.volume_up_rounded, color: Colors.blue, size: 20),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Previous button
            Expanded(
              child: AnimatedOpacity(
                opacity: _currentIndex > 0 ? 1 : 0.4,
                duration: const Duration(milliseconds: 200),
                child: OutlinedButton.icon(
                  onPressed: _currentIndex > 0
                      ? () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  }
                      : null,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Trước'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: AppColors.border),
                    foregroundColor: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Page indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentIndex + 1}/${_wrongAnswers.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Next button
            Expanded(
              child: AnimatedOpacity(
                opacity: _currentIndex < _wrongAnswers.length - 1 ? 1 : 0.4,
                duration: const Duration(milliseconds: 200),
                child: ElevatedButton.icon(
                  onPressed: _currentIndex < _wrongAnswers.length - 1
                      ? () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  }
                      : null,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Sau'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}