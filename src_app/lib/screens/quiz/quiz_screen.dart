import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../models/quiz_model.dart';
import '../../services/quiz_service.dart';
import '../../services/tts_service.dart';
import 'quiz_result_screen.dart';

/// 🎯 Màn hình làm bài kiểm tra
class QuizScreen extends StatefulWidget {
  final QuizSessionModel session;

  const QuizScreen({
    Key? key,
    required this.session,
  }) : super(key: key);

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

  // Timer
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _hasTimeLimit = false;  // ✅ NEW: Flag kiểm tra có giới hạn thời gian không
  int _elapsedSeconds = 0;

  // TTS
  final TTSService _ttsService = TTSService();
  bool _isPlaying = false;

  // Animation
  late AnimationController _cardController;
  late Animation<double> _cardAnimation;
  late AnimationController _resultController;
  late Animation<double> _resultAnimation;

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

    // ✅ FIX: Chỉ set timer nếu có giới hạn thời gian
    _hasTimeLimit = widget.session.timeLimitSeconds > 0;
    _remainingSeconds = widget.session.timeLimitSeconds;
    _elapsedSeconds = 0;

    // Animation controllers
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutBack,
    );

    _resultController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _resultAnimation = CurvedAnimation(
      parent: _resultController,
      curve: Curves.elasticOut,
    );

    _cardController.forward();
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
    _ttsService.stop();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_hasTimeLimit) {
        // Có giới hạn thời gian → đếm ngược
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
        } else {
          _timer?.cancel();
          _onTimeUp();
        }
      } else {
        // Không có giới hạn → đếm tiến lên
        setState(() => _elapsedSeconds++);
      }
    });
  }

  void _onTimeUp() {
    _showTimeUpDialog();
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.timer_off, color: Colors.orange[700], size: 28),
            const SizedBox(width: 12),
            const Text('Hết thời gian!'),
          ],
        ),
        content: const Text(
          'Thời gian làm bài đã hết. Bài kiểm tra sẽ được nộp tự động.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _finishQuiz();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Xem kết quả'),
          ),
        ],
      ),
    );
  }

  Future<void> _playAudio() async {
    if (_currentQuestion.ttsUrl == null && (_currentQuestion.word?.isEmpty ?? true)) return;

    setState(() => _isPlaying = true);

    try {
      // Use the word for TTS - ttsUrl is for future audio file support
      await _ttsService.speak(_currentQuestion.word ?? '');
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
      _showSnackBar('Vui lòng chọn hoặc nhập câu trả lời');
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      // Check answer locally first for better UX
      bool isCorrect = _checkAnswerLocally();

      setState(() {
        _isCorrect = isCorrect;
        _currentQuestion.isCorrect = isCorrect;
        _correctAnswer = _currentQuestion.correctAnswer ??
            (_currentQuestion.options?[_currentQuestion.correctOptionIndex ?? 0]);
        _showResult = true;
      });

      _resultController.forward();

      // Submit to server in background
      // QuizService.submitAnswer(
      //   quizResultId: widget.session.quizResultId,
      //   flashcardId: _currentQuestion.flashcardId,
      //   questionType: _currentQuestion.questionType,
      //   userAnswer: _currentQuestion.userAnswer,
      //   selectedOptionIndex: _currentQuestion.selectedOptionIndex,
      //   timeSpentSeconds: widget.session.timeLimitSeconds - _remainingSeconds,
      // ).catchError((e) => debugPrint('Submit answer error: $e'));

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
      // So sánh text không phân biệt hoa thường
      final userAnswer = (question.userAnswer ?? '').toLowerCase().trim();
      final correctAnswer = (question.correctAnswer ?? '').toLowerCase().trim();

      if (correctAnswer.length > 5) {
        // Chấp nhận sai 1 ký tự
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

    for (int i = 0; i <= s1.length; i++) matrix[i][0] = i;
    for (int j = 0; j <= s2.length; j++) matrix[0][j] = j;

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

    // ✅ FIX: Prepare answers theo format mới của backend
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

    // Tính tổng thời gian
    final totalTime = _hasTimeLimit
        ? widget.session.timeLimitSeconds - _remainingSeconds
        : _elapsedSeconds;

    try {
      // ✅ FIX: Dùng submitQuiz thay vì submitAllAnswers
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
      _showSnackBar('Có lỗi xảy ra: $e');
      if (mounted) Navigator.pop(context);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Thoát bài kiểm tra?'),
        content: const Text(
          'Bạn có chắc muốn thoát? Tiến trình làm bài sẽ không được lưu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Thoát'),
          ),
        ],
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
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: Column(
            children: [
              // Progress bar
              _buildProgressBar(),

              // Question content
              Expanded(
                child: ScaleTransition(
                  scale: _cardAnimation,
                  child: _buildQuestionCard(),
                ),
              ),

              // Result overlay
              if (_showResult) _buildResultOverlay(),

              // Action buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.black87),
        onPressed: _confirmExit,
      ),
      title: Column(
        children: [
          Text(
            widget.session.categoryName.isNotEmpty
                ? widget.session.categoryName
                : 'Kiểm tra',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Câu ${_currentIndex + 1}/${widget.session.totalQuestions}',
            style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        // Timer
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _hasTimeLimit && _remainingSeconds < 60
                ? Colors.red.withOpacity(0.1)
                : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 18,
                color: _hasTimeLimit && _remainingSeconds < 60
                    ? Colors.red
                    : Colors.blue[700],
              ),
              const SizedBox(width: 4),
              Text(
                _hasTimeLimit
                    ? _formatTime(_remainingSeconds)
                    : _formatTime(_elapsedSeconds),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: _hasTimeLimit && _remainingSeconds < 60
                      ? Colors.red
                      : Colors.blue[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(_progress * 100).toInt()}% hoàn thành',
                style: AppTextStyles.caption,
              ),
              Text(
                'Độ khó: ${widget.session.difficultyLabel}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question type badge
          _buildQuestionTypeBadge(),
          const SizedBox(height: 16),

          // Question card
          Card(
            elevation: 4,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
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
                    style: AppTextStyles.heading3.copyWith(
                      fontSize: 20,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Hint
                  if (_currentQuestion.hint != null && !_showResult)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Gợi ý: ${_currentQuestion.hint}',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.orange[700],
                          fontStyle: FontStyle.italic,
                        ),
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
    String label;
    IconData icon;
    Color color;

    switch (_currentQuestion.questionType) {
      case 'MULTIPLE_CHOICE':
        label = 'Trắc nghiệm';
        icon = Icons.check_circle_outline;
        color = Colors.blue;
        break;
      case 'MULTIPLE_CHOICE_REVERSE':
        label = 'Chọn từ đúng';
        icon = Icons.translate;
        color = Colors.purple;
        break;
      case 'FILL_BLANK':
      case 'FILL_BLANK_SENTENCE':
        label = 'Điền từ';
        icon = Icons.edit;
        color = Colors.orange;
        break;
      case 'LISTENING':
      case 'LISTENING_SIMPLE':
        label = 'Nghe';
        icon = Icons.headphones;
        color = Colors.green;
        break;
      case 'LISTENING_SPELL':
        label = 'Nghe & Viết';
        icon = Icons.hearing;
        color = Colors.teal;
        break;
      case 'WRITING':
      case 'WRITING_SIMPLE':
        label = 'Viết';
        icon = Icons.create;
        color = Colors.red;
        break;
      default:
        label = 'Câu hỏi';
        icon = Icons.help_outline;
        color = Colors.grey;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionImage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _currentQuestion.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.image, size: 50, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildAudioButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTap: _isPlaying ? null : _playAudio,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isPlaying ? Colors.green : AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: (_isPlaying ? Colors.green : AppColors.primary)
                    .withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _isPlaying
              ? const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          )
              : const Icon(
            Icons.volume_up,
            color: Colors.white,
            size: 36,
          ),
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

    Color? bgColor;
    Color? borderColor;
    IconData? trailingIcon;

    if (_showResult) {
      if (isCorrectOption) {
        bgColor = Colors.green.withOpacity(0.1);
        borderColor = Colors.green;
        trailingIcon = Icons.check_circle;
      } else if (isSelected && !isCorrectOption) {
        bgColor = Colors.red.withOpacity(0.1);
        borderColor = Colors.red;
        trailingIcon = Icons.cancel;
      }
    } else if (isSelected) {
      bgColor = AppColors.primary.withOpacity(0.1);
      borderColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _showResult ? null : () => _selectOption(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor ?? Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor ?? Colors.grey[300]!,
              width: isSelected || (_showResult && isCorrectOption) ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Option letter
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? (borderColor ?? AppColors.primary)
                      : Colors.grey[200],
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + index), // A, B, C, D
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Option text
              Expanded(
                child: Text(
                  option,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: _showResult && isCorrectOption
                        ? Colors.green[700]
                        : Colors.black87,
                  ),
                ),
              ),

              // Result icon
              if (trailingIcon != null)
                Icon(
                  trailingIcon,
                  color: isCorrectOption ? Colors.green : Colors.red,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _showResult
              ? (_isCorrect ? Colors.green : Colors.red)
              : Colors.grey[300]!,
          width: _showResult ? 2 : 1,
        ),
      ),
      child: TextField(
        enabled: !_showResult,
        onChanged: _onTextAnswer,
        textAlign: TextAlign.center,
        style: AppTextStyles.heading3,
        decoration: InputDecoration(
          hintText: 'Nhập câu trả lời...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
          suffixIcon: _showResult
              ? Icon(
            _isCorrect ? Icons.check_circle : Icons.cancel,
            color: _isCorrect ? Colors.green : Colors.red,
          )
              : null,
        ),
      ),
    );
  }

  Widget _buildResultOverlay() {
    return ScaleTransition(
      scale: _resultAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isCorrect
              ? Colors.green.withOpacity(0.1)
              : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isCorrect ? Colors.green : Colors.red,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _isCorrect ? Icons.check_circle : Icons.cancel,
              color: _isCorrect ? Colors.green : Colors.red,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isCorrect ? 'Chính xác! 🎉' : 'Chưa đúng',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: _isCorrect ? Colors.green[700] : Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!_isCorrect && _correctAnswer != null)
                    Text(
                      'Đáp án: $_correctAnswer',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.grey[700],
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

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Skip button (only if not showing result)
          if (!_showResult && !_isLastQuestion)
            Expanded(
              child: OutlinedButton(
                onPressed: _nextQuestion,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey[400]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Bỏ qua',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),

          if (!_showResult && !_isLastQuestion)
            const SizedBox(width: 12),

          // Main action button
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : (_showResult ? _nextQuestion : _checkAnswer),
              style: ElevatedButton.styleFrom(
                backgroundColor: _showResult
                    ? (_isLastQuestion ? Colors.green : AppColors.primary)
                    : AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Text(
                _showResult
                    ? (_isLastQuestion ? 'Hoàn thành' : 'Câu tiếp theo')
                    : 'Kiểm tra',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}