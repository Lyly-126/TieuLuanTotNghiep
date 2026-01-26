import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_colors.dart';
import '../../models/quiz_model.dart';
import '../../services/quiz_service.dart';
import '../../services/tts_service.dart';
import 'quiz_result_screen.dart';

/// 🎯 Màn hình làm bài kiểm tra
/// ✅ UI IMPROVED: Better cards, animations, fixed text input reset
class QuizScreen extends StatefulWidget {
  final QuizSessionModel session;

  const QuizScreen({
    super.key,
    required this.session,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  // State
  int _currentIndex = 0;
  bool _isSubmitting = false;
  bool _showResult = false;
  bool _isCorrect = false;
  String? _correctAnswer;

  // ✅ FIX: TextEditingController để reset text khi chuyển câu
  late TextEditingController _textController;
  final FocusNode _textFocusNode = FocusNode();

  // Timer
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _hasTimeLimit = false;
  int _elapsedSeconds = 0;

  // TTS
  final TTSService _ttsService = TTSService();
  bool _isPlaying = false;

  // Animation
  late AnimationController _cardController;
  late Animation<double> _cardAnimation;
  late AnimationController _resultController;
  late Animation<double> _resultAnimation;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  // Current question
  QuizQuestionModel get _currentQuestion =>
      widget.session.questions[_currentIndex];

  bool get _isLastQuestion =>
      _currentIndex >= widget.session.questions.length - 1;

  double get _progress =>
      (_currentIndex + 1) / widget.session.questions.length;

  @override
  void initState() {
    super.initState();

    // ✅ FIX: Khởi tạo TextEditingController
    _textController = TextEditingController();

    _hasTimeLimit = widget.session.timeLimitSeconds > 0;
    _remainingSeconds = widget.session.timeLimitSeconds;
    _elapsedSeconds = 0;

    // Animation controllers
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutBack,
    );

    _resultController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _resultAnimation = CurvedAnimation(
      parent: _resultController,
      curve: Curves.elasticOut,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );

    _cardController.forward();
    _progressController.forward();
    _startTimer();

    // Auto play audio cho câu hỏi nghe
    if (_currentQuestion.isListeningQuestion) {
      Future.delayed(const Duration(milliseconds: 500), _playAudio);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cardController.dispose();
    _resultController.dispose();
    _progressController.dispose();
    _textController.dispose();
    _textFocusNode.dispose();
    _ttsService.stop();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_hasTimeLimit) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
        } else {
          _timer?.cancel();
          _onTimeUp();
        }
      } else {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  void _onTimeUp() {
    HapticFeedback.heavyImpact();
    _showTimeUpDialog();
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.timer_off_rounded, color: Colors.orange.shade600, size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              'Hết thời gian!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Bài kiểm tra sẽ được nộp tự động.',
              style: TextStyle(color: AppColors.textGray, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _finishQuiz();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Xem kết quả', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _playAudio() async {
    if (_isPlaying) return;
    if (_currentQuestion.ttsUrl == null && (_currentQuestion.word.isEmpty ?? true)) return;

    setState(() => _isPlaying = true);
    HapticFeedback.lightImpact();

    try {
      await _ttsService.speak(_currentQuestion.word ?? '', languageCode: 'en-US');
      await Future.delayed(const Duration(milliseconds: 1200));
    } catch (e) {
      debugPrint('TTS error: $e');
    }

    if (mounted) setState(() => _isPlaying = false);
  }

  void _selectOption(int index) {
    if (_showResult || _isSubmitting) return;

    HapticFeedback.lightImpact();
    setState(() {
      _currentQuestion.selectedOptionIndex = index;
      _currentQuestion.userAnswer = _currentQuestion.options?[index];
    });
  }

  void _onTextAnswer(String value) {
    _currentQuestion.userAnswer = value.trim();
  }

  Future<void> _checkAnswer() async {
    if (_isSubmitting) return;
    if (!_currentQuestion.isAnswered) {
      _showSnackBar('Vui lòng chọn hoặc nhập câu trả lời', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      bool isCorrect = _checkAnswerLocally();

      setState(() {
        _isCorrect = isCorrect;
        _currentQuestion.isCorrect = isCorrect;
        _correctAnswer = _currentQuestion.correctAnswer ??
            (_currentQuestion.options?[_currentQuestion.correctOptionIndex ?? 0]);
        _showResult = true;
      });

      _resultController.forward();

      _currentQuestion.timeSpentSeconds = _hasTimeLimit
          ? widget.session.timeLimitSeconds - _remainingSeconds
          : _elapsedSeconds;

    } catch (e) {
      debugPrint('Check answer error: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  bool _checkAnswerLocally() {
    final question = _currentQuestion;

    if (question.isMultipleChoice) {
      return question.selectedOptionIndex == question.correctOptionIndex;
    } else {
      final userAnswer = (question.userAnswer ?? '').toLowerCase().trim();
      final correctAnswer = (question.correctAnswer ?? '').toLowerCase().trim();

      if (correctAnswer.length > 5) {
        return _levenshteinDistance(userAnswer, correctAnswer) <= 1;
      }
      return userAnswer == correctAnswer;
    }
  }

  int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<List<int>> matrix = List.generate(
      s1.length + 1,
          (i) => List.generate(s2.length + 1, (j) => 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }

  void _nextQuestion() {
    if (_isLastQuestion) {
      _finishQuiz();
      return;
    }

    // ✅ FIX: Reset text controller khi chuyển câu
    _textController.clear();
    _textFocusNode.unfocus();

    setState(() {
      _showResult = false;
      _correctAnswer = null;
    });

    _resultController.reset();
    _cardController.reset();

    setState(() => _currentIndex++);

    _cardController.forward();

    // Auto play audio cho câu hỏi nghe
    if (_currentQuestion.isListeningQuestion) {
      Future.delayed(const Duration(milliseconds: 500), _playAudio);
    }
  }

  Future<void> _finishQuiz() async {
    _timer?.cancel();

    final answers = widget.session.questions.map((q) => {
      'questionIndex': q.index,
      'flashcardId': q.flashcardId,
      'questionType': q.questionType,
      'skillType': q.skillType,
      'userAnswer': q.userAnswer ?? '',
      'correctAnswer': q.correctAnswer,
      'isCorrect': q.isCorrect,
      'timeSpentSeconds': q.timeSpentSeconds,
    }).toList();

    final totalTime = _hasTimeLimit
        ? widget.session.timeLimitSeconds - _remainingSeconds
        : _elapsedSeconds;

    try {
      final result = await QuizService.submitQuiz(
        categoryId: widget.session.categoryId,
        quizType: widget.session.quizType,
        difficulty: widget.session.difficulty,
        answers: answers,
        totalTimeSeconds: totalTime,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizResultScreen(result: result),
          ),
        );
      }
    } catch (e) {
      debugPrint('Submit quiz error: $e');
      _showSnackBar('Có lỗi xảy ra: $e', isError: true);
      if (mounted) Navigator.pop(context);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _confirmExit() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.exit_to_app_rounded, color: Colors.red.shade400, size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              'Thoát bài kiểm tra?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tiến trình làm bài sẽ không được lưu.',
              style: TextStyle(color: AppColors.textGray, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: AppColors.border),
                    ),
                    child: Text('Tiếp tục', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Thoát', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _confirmExit();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FD),
        body: Column(
          children: [
            // Header
            _buildHeader(),

            // Question content
            Expanded(
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(_cardAnimation),
                child: FadeTransition(
                  opacity: _cardAnimation,
                  child: _buildQuestionCard(),
                ),
              ),
            ),

            // Result overlay
            if (_showResult) _buildResultOverlay(),

            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isTimeLow = _hasTimeLimit && _remainingSeconds < 60;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
          child: Column(
            children: [
              // Top row
              Row(
                children: [
                  // Close button
                  IconButton(
                    onPressed: _confirmExit,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.close_rounded, color: AppColors.textGray, size: 20),
                    ),
                  ),

                  // Title
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          widget.session.categoryName.isNotEmpty
                              ? widget.session.categoryName
                              : 'Kiểm tra',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Câu ${_currentIndex + 1} / ${widget.session.totalQuestions}',
                          style: TextStyle(fontSize: 12, color: AppColors.textGray),
                        ),
                      ],
                    ),
                  ),

                  // Timer
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isTimeLow
                          ? LinearGradient(colors: [Colors.red.shade400, Colors.red.shade600])
                          : LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade600]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (isTimeLow ? Colors.red : Colors.blue).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isTimeLow ? Icons.timer_off_rounded : Icons.timer_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _hasTimeLimit
                              ? _formatTime(_remainingSeconds)
                              : _formatTime(_elapsedSeconds),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress bar
              _buildProgressBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        // Progress info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(_progress * 100).toInt()}%',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.speed_rounded, size: 14, color: Colors.purple),
                    const SizedBox(width: 4),
                    Text(
                      widget.session.difficultyLabel,
                      style: const TextStyle(
                        color: Colors.purple,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Stack(
            children: [
              // Background
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Progress
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                height: 8,
                width: MediaQuery.of(context).size.width * _progress * 0.9,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Question dots
        const SizedBox(height: 12),
        SizedBox(
          height: 8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.session.totalQuestions > 15 ? 15 : widget.session.totalQuestions,
                  (index) {
                final actualIndex = widget.session.totalQuestions > 15
                    ? ((_currentIndex / widget.session.totalQuestions) * 15).floor()
                    : index;
                final isCurrent = widget.session.totalQuestions > 15
                    ? index == actualIndex
                    : index == _currentIndex;
                final isPast = widget.session.totalQuestions > 15
                    ? index < actualIndex
                    : index < _currentIndex;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isCurrent ? 20 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.primary
                        : isPast
                        ? AppColors.primary.withOpacity(0.4)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question type badge
          _buildQuestionTypeBadge(),
          const SizedBox(height: 16),

          // Main question card
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
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Image (if available)
                  if (_currentQuestion.imageUrl != null &&
                      _currentQuestion.questionType.contains('IMAGE'))
                    _buildQuestionImage(),

                  // Audio button (for listening questions)
                  if (_currentQuestion.isListeningQuestion)
                    _buildAudioButton(),

                  // Question text
                  Text(
                    _currentQuestion.questionText,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                      color: AppColors.primaryDark,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Hint
                  if (!_showResult)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lightbulb_outline_rounded, size: 18, color: Colors.amber.shade700),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _currentQuestion.hint,
                              style: TextStyle(
                                color: Colors.amber.shade800,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Answer options
          if (_currentQuestion.isMultipleChoice)
            _buildMultipleChoiceOptions()
          else
            _buildTextInput(),
        ],
      ),
    );
  }

  Widget _buildQuestionTypeBadge() {
    final typeInfo = _getQuestionTypeInfo(_currentQuestion.questionType);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: typeInfo['color'].withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(typeInfo['icon'], size: 18, color: typeInfo['color']),
              const SizedBox(width: 8),
              Text(
                typeInfo['label'],
                style: TextStyle(
                  color: typeInfo['color'],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getQuestionTypeInfo(String type) {
    switch (type) {
      case 'MULTIPLE_CHOICE':
        return {'label': 'Trắc nghiệm', 'icon': Icons.check_circle_outline_rounded, 'color': Colors.blue};
      case 'MULTIPLE_CHOICE_REVERSE':
        return {'label': 'Chọn từ đúng', 'icon': Icons.translate_rounded, 'color': Colors.purple};
      case 'FILL_BLANK':
      case 'FILL_BLANK_SENTENCE':
        return {'label': 'Điền từ', 'icon': Icons.edit_rounded, 'color': Colors.orange};
      case 'LISTENING':
      case 'LISTENING_SIMPLE':
        return {'label': 'Nghe', 'icon': Icons.headphones_rounded, 'color': Colors.green};
      case 'LISTENING_SPELL':
        return {'label': 'Nghe & Viết', 'icon': Icons.hearing_rounded, 'color': Colors.teal};
      case 'WRITING':
      case 'WRITING_SIMPLE':
        return {'label': 'Viết', 'icon': Icons.create_rounded, 'color': Colors.red};
      default:
        return {'label': 'Câu hỏi', 'icon': Icons.help_outline_rounded, 'color': Colors.grey};
    }
  }

  Widget _buildQuestionImage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          _currentQuestion.imageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey.shade200,
            child: Icon(Icons.image_rounded, size: 50, color: AppColors.textGray),
          ),
        ),
      ),
    );
  }

  Widget _buildAudioButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: GestureDetector(
        onTap: _playAudio,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isPlaying
                  ? [Colors.green, Colors.teal]
                  : [AppColors.primary, AppColors.accent],
            ),
            boxShadow: [
              BoxShadow(
                color: (_isPlaying ? Colors.green : AppColors.primary).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: _isPlaying
              ? const Padding(
            padding: EdgeInsets.all(30),
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
          )
              : const Icon(Icons.volume_up_rounded, color: Colors.white, size: 44),
        ),
      ),
    );
  }

  Widget _buildMultipleChoiceOptions() {
    return Column(
      children: List.generate(
        _currentQuestion.options?.length ?? 0,
            (index) => _buildOptionTile(index),
      ),
    );
  }

  Widget _buildOptionTile(int index) {
    final option = _currentQuestion.options![index];
    final isSelected = _currentQuestion.selectedOptionIndex == index;
    final isCorrectOption = index == _currentQuestion.correctOptionIndex;

    Color bgColor = Colors.white;
    Color borderColor = Colors.grey.shade300;
    Color textColor = AppColors.primaryDark;
    IconData? trailingIcon;
    Color? iconColor;

    if (_showResult) {
      if (isCorrectOption) {
        bgColor = Colors.green.shade50;
        borderColor = Colors.green;
        textColor = Colors.green.shade700;
        trailingIcon = Icons.check_circle_rounded;
        iconColor = Colors.green;
      } else if (isSelected && !isCorrectOption) {
        bgColor = Colors.red.shade50;
        borderColor = Colors.red;
        textColor = Colors.red.shade700;
        trailingIcon = Icons.cancel_rounded;
        iconColor = Colors.red;
      }
    } else if (isSelected) {
      bgColor = AppColors.primary.withOpacity(0.08);
      borderColor = AppColors.primary;
      textColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showResult ? null : () => _selectOption(index),
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: borderColor,
                width: isSelected || (_showResult && isCorrectOption) ? 2.5 : 1.5,
              ),
              boxShadow: isSelected && !_showResult
                  ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
                  : null,
            ),
            child: Row(
              children: [
                // Option letter
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected || (_showResult && isCorrectOption)
                        ? borderColor
                        : Colors.grey.shade100,
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index),
                      style: TextStyle(
                        color: isSelected || (_showResult && isCorrectOption)
                            ? Colors.white
                            : AppColors.textGray,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Option text
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),

                // Result icon
                if (trailingIcon != null)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Icon(trailingIcon, color: iconColor, size: 26),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    Color borderColor = Colors.grey.shade300;
    Color bgColor = Colors.white;

    if (_showResult) {
      borderColor = _isCorrect ? Colors.green : Colors.red;
      bgColor = _isCorrect ? Colors.green.shade50 : Colors.red.shade50;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: _showResult ? 2.5 : 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _textController,  // ✅ FIX: Dùng controller
        focusNode: _textFocusNode,
        enabled: !_showResult,
        onChanged: _onTextAnswer,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryDark,
        ),
        decoration: InputDecoration(
          hintText: 'Nhập câu trả lời...',
          hintStyle: TextStyle(
            color: AppColors.textGray,
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          suffixIcon: _showResult
              ? Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: Icon(
                _isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: _isCorrect ? Colors.green : Colors.red,
                size: 28,
              ),
            ),
          )
              : null,
        ),
      ),
    );
  }

  Widget _buildResultOverlay() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(_resultAnimation),
      child: FadeTransition(
        opacity: _resultAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isCorrect
                  ? [Colors.green.shade50, Colors.green.shade100]
                  : [Colors.red.shade50, Colors.red.shade100],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isCorrect ? Colors.green : Colors.red,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (_isCorrect ? Colors.green : Colors.red).withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isCorrect ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isCorrect ? Icons.check_rounded : Icons.close_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isCorrect ? 'Chính xác! 🎉' : 'Chưa đúng rồi',
                      style: TextStyle(
                        color: _isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    if (!_isCorrect && _correctAnswer != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                            children: [
                              const TextSpan(text: 'Đáp án: '),
                              TextSpan(
                                text: _correctAnswer,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Skip button
            if (!_showResult && !_isLastQuestion)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _nextQuestion();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'Bỏ qua',
                    style: TextStyle(
                      color: AppColors.textGray,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

            if (!_showResult && !_isLastQuestion) const SizedBox(width: 12),

            // Main button
            Expanded(
              flex: _showResult || _isLastQuestion ? 1 : 2,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _showResult
                        ? (_isLastQuestion
                        ? [Colors.green, Colors.teal]
                        : [AppColors.primary, AppColors.accent])
                        : [AppColors.primary, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (_showResult && _isLastQuestion ? Colors.green : AppColors.primary)
                          .withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                    HapticFeedback.mediumImpact();
                    _showResult ? _nextQuestion() : _checkAnswer();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _showResult
                            ? (_isLastQuestion ? 'Hoàn thành' : 'Câu tiếp theo')
                            : 'Kiểm tra',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      if (_showResult) ...[
                        const SizedBox(width: 8),
                        Icon(
                          _isLastQuestion ? Icons.check_rounded : Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}