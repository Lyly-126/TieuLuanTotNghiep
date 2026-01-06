import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_colors.dart';
import '../../models/quiz_model.dart';
import '../../services/tts_service.dart';

/// 📖 Màn hình ôn tập câu sai
/// ✅ UI IMPROVED V2: Flip cards, better animations, modern design
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
    with TickerProviderStateMixin {
  final TTSService _ttsService = TTSService();
  late List<QuizQuestionModel> _reviewQuestions;
  late PageController _pageController;
  int _currentIndex = 0;
  bool _showOnlyWrong = true;
  bool _isPlaying = false;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _filterQuestions();
    _slideController.forward();
  }

  void _filterQuestions() {
    if (_showOnlyWrong) {
      _reviewQuestions = widget.questions.where((q) => q.isCorrect == false).toList();
    } else {
      _reviewQuestions = widget.questions;
    }
    if (_currentIndex >= _reviewQuestions.length) {
      _currentIndex = _reviewQuestions.isEmpty ? 0 : _reviewQuestions.length - 1;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _slideController.dispose();
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _speakWord(String text) async {
    if (_isPlaying) {
      await _ttsService.stop();
      setState(() => _isPlaying = false);
      return;
    }

    setState(() => _isPlaying = true);
    HapticFeedback.lightImpact();

    try {
      await _ttsService.speak(text, languageCode: 'en-US');
      await Future.delayed(const Duration(milliseconds: 1200));
    } finally {
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  void _toggleFilter() {
    HapticFeedback.selectionClick();
    setState(() {
      _showOnlyWrong = !_showOnlyWrong;
      _filterQuestions();
      _currentIndex = 0;
      if (_reviewQuestions.isNotEmpty) {
        _pageController.jumpToPage(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: Column(
        children: [
          _buildHeader(),
          if (_reviewQuestions.isNotEmpty) _buildProgressSection(),
          Expanded(
            child: _reviewQuestions.isEmpty
                ? _buildEmptyState()
                : _buildCardSection(),
          ),
          if (_reviewQuestions.isNotEmpty) _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final wrongCount = widget.questions.where((q) => q.isCorrect == false).length;
    final correctCount = widget.questions.where((q) => q.isCorrect == true).length;
    final totalCount = widget.questions.length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.shade500,
            Colors.deepOrange.shade400,
            Colors.orange.shade600,
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            children: [
              // Top bar
              Row(
                children: [
                  _buildBackButton(),
                  const Expanded(
                    child: Text(
                      'Ôn tập từ vựng',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  _buildFilterButton(),
                ],
              ),
              const SizedBox(height: 24),

              // Stats row
              Row(
                children: [
                  Expanded(child: _buildStatCard(
                    icon: Icons.assignment_rounded,
                    value: '$totalCount',
                    label: 'Tổng câu',
                    color: Colors.white,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard(
                    icon: Icons.check_circle_rounded,
                    value: '$correctCount',
                    label: 'Đúng',
                    color: Colors.greenAccent,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard(
                    icon: Icons.cancel_rounded,
                    value: '$wrongCount',
                    label: 'Sai',
                    color: Colors.redAccent.shade100,
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return GestureDetector(
      onTap: _toggleFilter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _showOnlyWrong
              ? Colors.red.shade400
              : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _showOnlyWrong ? Icons.filter_alt_rounded : Icons.filter_alt_off_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              _showOnlyWrong ? 'Sai' : 'Tất cả',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        children: [
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _reviewQuestions.isEmpty
                        ? 0
                        : (_currentIndex + 1) / _reviewQuestions.length,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade500),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${_reviewQuestions.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Filter badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _showOnlyWrong ? Colors.red.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showOnlyWrong ? Icons.error_outline_rounded : Icons.list_alt_rounded,
                      size: 16,
                      color: _showOnlyWrong ? Colors.red : Colors.blue,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _showOnlyWrong ? 'Chỉ hiển thị câu sai' : 'Hiển thị tất cả câu hỏi',
                      style: TextStyle(
                        color: _showOnlyWrong ? Colors.red : Colors.blue,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SlideTransition(
      position: _slideAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Celebration animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.green.shade100, Colors.teal.shade100],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Text('🎉', style: TextStyle(fontSize: 64)),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Tuyệt vời!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _showOnlyWrong
                    ? 'Bạn không có câu trả lời sai nào!'
                    : 'Không có câu hỏi nào để hiển thị',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textGray,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_showOnlyWrong)
                    OutlinedButton.icon(
                      onPressed: _toggleFilter,
                      icon: const Icon(Icons.visibility_rounded),
                      label: const Text('Xem tất cả'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange, width: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  if (_showOnlyWrong) const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Quay lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _reviewQuestions.length,
        onPageChanged: (index) {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          return _buildReviewCard(_reviewQuestions[index], index);
        },
      ),
    );
  }

  Widget _buildReviewCard(QuizQuestionModel question, int index) {
    final isCorrect = question.isCorrect == true;
    final statusColor = isCorrect ? Colors.green : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status header
              _buildStatusHeader(question, isCorrect, statusColor),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vocabulary showcase
                    _buildVocabularyShowcase(question),
                    const SizedBox(height: 24),

                    // Question
                    _buildQuestionSection(question),
                    const SizedBox(height: 20),

                    // Answer comparison
                    _buildAnswerSection(question, isCorrect),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader(QuizQuestionModel question, bool isCorrect, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Row(
        children: [
          // Question type
          _buildQuestionTypeBadge(question.questionType),
          const Spacer(),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCorrect ? Icons.check_rounded : Icons.close_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  isCorrect ? 'Đúng' : 'Sai',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionTypeBadge(String questionType) {
    final typeInfo = _getQuestionTypeInfo(questionType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: typeInfo['color'].withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(typeInfo['icon'], size: 16, color: typeInfo['color']),
          const SizedBox(width: 6),
          Text(
            typeInfo['label'],
            style: TextStyle(
              color: typeInfo['color'],
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getQuestionTypeInfo(String questionType) {
    final type = questionType.toUpperCase();

    if (type.contains('MULTIPLE')) {
      if (type.contains('REVERSE')) {
        return {'label': 'Trắc nghiệm ngược', 'color': Colors.indigo, 'icon': Icons.swap_horiz_rounded};
      } else if (type.contains('IMAGE')) {
        return {'label': 'Hình ảnh', 'color': Colors.green, 'icon': Icons.image_rounded};
      }
      return {'label': 'Trắc nghiệm', 'color': Colors.blue, 'icon': Icons.check_circle_outline_rounded};
    } else if (type.contains('FILL')) {
      return {'label': 'Điền từ', 'color': Colors.purple, 'icon': Icons.edit_rounded};
    } else if (type.contains('LISTENING')) {
      return {'label': 'Nghe', 'color': Colors.teal, 'icon': Icons.headphones_rounded};
    } else if (type.contains('WRITING')) {
      return {'label': 'Viết', 'color': Colors.orange, 'icon': Icons.create_rounded};
    }
    return {'label': 'Câu hỏi', 'color': Colors.grey, 'icon': Icons.help_outline_rounded};
  }

  Widget _buildVocabularyShowcase(QuizQuestionModel question) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.indigo.shade50,
            Colors.purple.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.15),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(Icons.auto_stories_rounded, color: Colors.blue.shade600, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Từ vựng cần nhớ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      'Chạm để nghe phát âm',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Play button
              GestureDetector(
                onTap: () => _speakWord(question.word),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isPlaying
                          ? [Colors.orange, Colors.deepOrange]
                          : [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isPlaying ? Colors.orange : Colors.blue).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.stop_rounded : Icons.volume_up_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Word display
          GestureDetector(
            onTap: () => _speakWord(question.word),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    question.word,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (question.phonetic != null && question.phonetic!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      question.phonetic!,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textGray,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Meaning
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.translate_rounded, color: Colors.blue.shade400, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question.meaning,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.5,
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

  Widget _buildQuestionSection(QuizQuestionModel question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Câu hỏi',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FD),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  question.questionText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              if (question.isListeningQuestion)
                GestureDetector(
                  onTap: () => _speakWord(question.word),
                  child: Container(
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
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              question.imageUrl!,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FD),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Icon(Icons.image_not_supported_rounded, color: AppColors.textGray, size: 32),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAnswerSection(QuizQuestionModel question, bool isCorrect) {
    final userAnswer = _getUserAnswerDisplay(question);
    final correctAnswer = _getCorrectAnswerDisplay(question);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'So sánh câu trả lời',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Your answer
        _buildAnswerCard(
          label: 'Câu trả lời của bạn',
          answer: userAnswer ?? 'Không trả lời',
          isCorrect: isCorrect,
          icon: isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: isCorrect ? Colors.green : Colors.red,
        ),
        const SizedBox(height: 12),

        // Correct answer
        _buildAnswerCard(
          label: 'Đáp án đúng',
          answer: correctAnswer ?? question.word,
          isCorrect: true,
          icon: Icons.verified_rounded,
          color: Colors.green,
          showSpeaker: true,
          onSpeak: () => _speakWord(question.word),
        ),
      ],
    );
  }

  Widget _buildAnswerCard({
    required String label,
    required String answer,
    required bool isCorrect,
    required IconData icon,
    required Color color,
    bool showSpeaker = false,
    VoidCallback? onSpeak,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  answer,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              if (showSpeaker && onSpeak != null)
                GestureDetector(
                  onTap: onSpeak,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.volume_up_rounded, color: Colors.blue, size: 20),
                  ),
                ),
            ],
          ),
        ],
      ),
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

  Widget _buildBottomNavigation() {
    final canGoPrev = _currentIndex > 0;
    final canGoNext = _currentIndex < _reviewQuestions.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Previous button
            Expanded(
              child: _buildNavButton(
                icon: Icons.arrow_back_rounded,
                label: 'Trước',
                isEnabled: canGoPrev,
                isPrimary: false,
                onTap: canGoPrev
                    ? () {
                  HapticFeedback.lightImpact();
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                  );
                }
                    : null,
              ),
            ),
            const SizedBox(width: 12),

            // Page indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade100, Colors.deepOrange.shade100],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.style_rounded, size: 18, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Text(
                    '${_currentIndex + 1}/${_reviewQuestions.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Next button
            Expanded(
              child: _buildNavButton(
                icon: Icons.arrow_forward_rounded,
                label: 'Sau',
                isEnabled: canGoNext,
                isPrimary: true,
                onTap: canGoNext
                    ? () {
                  HapticFeedback.lightImpact();
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                  );
                }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required bool isEnabled,
    required bool isPrimary,
    VoidCallback? onTap,
  }) {
    return AnimatedOpacity(
      opacity: isEnabled ? 1 : 0.4,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: isPrimary && isEnabled
                ? LinearGradient(colors: [Colors.orange.shade500, Colors.deepOrange.shade500])
                : null,
            color: isPrimary ? null : (isEnabled ? Colors.grey.shade100 : Colors.grey.shade50),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isPrimary && isEnabled
                ? [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isPrimary) ...[
                Icon(
                  icon,
                  size: 20,
                  color: isEnabled ? AppColors.textSecondary : AppColors.textGray,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isPrimary
                      ? Colors.white
                      : (isEnabled ? AppColors.textSecondary : AppColors.textGray),
                ),
              ),
              if (isPrimary) ...[
                const SizedBox(width: 8),
                Icon(icon, size: 20, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }
}