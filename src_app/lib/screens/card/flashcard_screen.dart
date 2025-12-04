import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../config/app_constants.dart';
import '../../models/flashcard_model.dart';
import '../../services/flash_card_service.dart';
import '../../services/tts_service.dart';

const Color _knownButtonColor = AppColors.primary;
const Color _continueButtonColor = Color(0xFFE5E7EB);
const Color _continueTextColor = AppColors.textSecondary;

class FlashcardScreen extends StatefulWidget {
  final int? categoryId;

  const FlashcardScreen({
    super.key,
    this.categoryId,
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen>
    with SingleTickerProviderStateMixin {

  GlobalKey<FlipCardState> _cardKey = GlobalKey<FlipCardState>();
  final TTSService _ttsService = TTSService();

  bool _isSpeaking = false;
  bool _isCardFlipped = false;
  bool _isLoading = true;

  List<FlashcardModel> _flashcards = [];
  int _currentIndex = 0;
  String? _errorMessage;

  late AnimationController _transitionController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _transitionController, curve: Curves.easeInOut),
    );

    _loadFlashcards();
  }

  @override
  void dispose() {
    _ttsService.stop();
    _transitionController.dispose();
    super.dispose();
  }

  /// Parse meaning để lấy các phần riêng biệt
  Map<String, String> _parseMeaning(String meaning) {
    try {
      if (kDebugMode) {
        print('\n🔍 ===== PARSING MEANING =====');
        print('📝 Raw meaning: "$meaning"');
      }

      // ✅ CHECK: Nếu meaning ngắn (< 50 ký tự) và không có "\n\n"
      // → Đây là nghĩa đơn giản từ database, không cần parse
      if (meaning.length < 50 && !meaning.contains('\n\n')) {
        if (kDebugMode) {
          print('✅ Simple meaning detected: "$meaning"');
          print('===============================\n');
        }
        return {
          'translation': meaning.trim(),
          'example': '',
          'exampleTranslation': '',
        };
      }

      // ✅ Nếu có format phức tạp thì parse
      final parts = meaning.split('\n\n');

      String translation = '';
      String example = '';
      String exampleTranslation = '';

      for (var part in parts) {
        final trimmed = part.trim();

        if (trimmed.toLowerCase().startsWith('translation:')) {
          translation = trimmed.replaceFirst(RegExp(r'translation:\s*', caseSensitive: false), '').trim();
        } else if (trimmed.toLowerCase().startsWith('example:')) {
          example = trimmed.replaceFirst(RegExp(r'example:\s*', caseSensitive: false), '').trim();
        } else if (trimmed.toLowerCase().startsWith('example translation:')) {
          exampleTranslation = trimmed.replaceFirst(RegExp(r'example translation:\s*', caseSensitive: false), '').trim();
        }
      }

      // ✅ FALLBACK: Nếu không parse được translation, lấy toàn bộ
      if (translation.isEmpty) {
        translation = meaning.trim();
      }

      if (kDebugMode) {
        print('✅ Parsed translation: "$translation"');
        print('✅ Parsed example: "$example"');
        print('✅ Parsed exampleTranslation: "$exampleTranslation"');
        print('===============================\n');
      }

      return {
        'translation': translation,
        'example': example,
        'exampleTranslation': exampleTranslation,
      };
    } catch (e) {
      if (kDebugMode) print('❌ Parse error: $e');
      return {
        'translation': meaning.isNotEmpty ? meaning : 'Không có nghĩa',
        'example': '',
        'exampleTranslation': '',
      };
    }
  }

  /// Dịch part of speech sang tiếng Việt
  String _translatePartOfSpeech(String? partOfSpeech) {
    if (partOfSpeech == null || partOfSpeech.isEmpty) return '';

    final Map<String, String> translations = {
      'noun': 'Danh từ',
      'verb': 'Động từ',
      'adjective': 'Tính từ',
      'adverb': 'Trạng từ',
      'pronoun': 'Đại từ',
      'preposition': 'Giới từ',
      'conjunction': 'Liên từ',
      'interjection': 'Thán từ',
      'determiner': 'Từ hạn định',
      'article': 'Mạo từ',
    };

    String lower = partOfSpeech.toLowerCase().trim();
    return translations[lower] ?? partOfSpeech;
  }

  Future<void> _loadFlashcards() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<FlashcardModel> flashcards;

      if (widget.categoryId != null) {
        flashcards = await FlashcardService.getFlashcardsByCategory(widget.categoryId!);
      } else {
        flashcards = await FlashcardService.getRandomFlashcards(limit: 20);
      }

      if (flashcards.isEmpty) {
        setState(() {
          _errorMessage = 'Không có flashcard nào';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _flashcards = flashcards;
        _currentIndex = 0;
        _isLoading = false;
      });

      _transitionController.forward();
    } catch (e) {
      if (kDebugMode) print('❌ Load error: $e');
      setState(() {
        _errorMessage = 'Lỗi tải dữ liệu: $e';
        _isLoading = false;
      });
    }
  }

  FlashcardModel? get _currentCard {
    if (_flashcards.isEmpty || _currentIndex >= _flashcards.length) {
      return null;
    }
    return _flashcards[_currentIndex];
  }

  Future<void> _nextCard() async {
    if (_flashcards.isEmpty) return;

    await _transitionController.reverse();

    setState(() {
      _currentIndex = (_currentIndex + 1) % _flashcards.length;
      _isCardFlipped = false;
      _cardKey = GlobalKey<FlipCardState>();
    });

    await _transitionController.forward();
  }

  /// ✅ Phát âm
  Future<void> _playPronunciation() async {
    final card = _currentCard;
    if (card == null) return;

    if (_ttsService.isPlaying) {
      await _ttsService.stop();
      setState(() => _isSpeaking = false);
      return;
    }

    if (!_ttsService.isConfigured) {
      _showApiKeyDialog();
      return;
    }

    try {
      setState(() => _isSpeaking = true);

      if (kDebugMode) {
        print('🔊 Playing: ${card.question}');
      }

      // Phát âm bình thường
      await _ttsService.speak(
        card.question,
        languageCode: 'en-US',
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSpeaking = false);
        _showErrorDialog('Không thể phát âm: ${e.toString()}');
      }
    }
  }

  void _showApiKeyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cần cấu hình Google TTS API'),
        content: const Text(
            'Bạn cần thêm Google Cloud Text-to-Speech API key vào file tts_service.dart để sử dụng chức năng này.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleKnown() {
    if (kDebugMode) print('✅ Đã biết - Card: ${_currentCard?.question}');
    _nextCard();
  }

  void _handleContinue() {
    if (kDebugMode) print('📝 Tiếp tục - Card: ${_currentCard?.question}');
    _nextCard();
  }

  /// Build image
  Widget _buildCardImage(FlashcardModel card) {
    final hasImage = card.imageUrl != null &&
        card.imageUrl!.isNotEmpty &&
        card.imageUrl != 'null';

    if (!hasImage) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.primary.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.quiz_outlined,
          color: AppColors.primary.withOpacity(0.3),
          size: 70,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Image.network(
        card.imageUrl!,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;

          return Container(
            height: 200,
            width: double.infinity,
            color: AppColors.inputBackground,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.textGray,
                  size: 50,
                ),
                const SizedBox(height: 8),
                Text(
                  'Không thể tải ảnh',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// ✅ MẶT TRƯỚC: Toàn bộ tiếng Anh
  Widget _buildFrontCardContent(FlashcardModel card) {
    final meaningData = _parseMeaning(card.answer);

    return Container(
      alignment: Alignment.center,
      color: AppColors.background,
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Hình ảnh
            _buildCardImage(card),

            const SizedBox(height: 24),

            // Từ vựng chính (Tiếng Anh)
            Text(
              card.question,
              style: AppTextStyles.title.copyWith(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDark,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Part of Speech (Tiếng Anh)
            if (card.partOfSpeech != null && card.partOfSpeech!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  card.partOfSpeech!,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Phiên âm
            if (card.phonetic != null && card.phonetic!.isNotEmpty)
              Text(
                card.phonetic!,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),

            // Example (Tiếng Anh)
            if (meaningData['example']!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.format_quote,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Example',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      meaningData['example']!,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// ✅ MẶT SAU: Nghĩa tiếng Việt (giống style mặt trước)
  Widget _buildBackCardContent(FlashcardModel card) {
    final meaningData = _parseMeaning(card.answer);
    final partOfSpeechVi = _translatePartOfSpeech(card.partOfSpeech);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
          ],
        ),
      ),
      padding: const EdgeInsets.all(32),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Từ gốc (nhỏ, để nhắc nhở)
              // Container(
              //   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              //   decoration: BoxDecoration(
              //     color: Colors.white.withOpacity(0.2),
              //     borderRadius: BorderRadius.circular(20),
              //   ),
              //   child: Text(
              //     card.term,
              //     style: AppTextStyles.body.copyWith(
              //       color: Colors.white.withOpacity(0.85),
              //       fontSize: 18,
              //       fontWeight: FontWeight.w500,
              //     ),
              //   ),
              // ),

              const SizedBox(height: 40),

              // Loại từ (Tiếng Việt) - Ở TRÊN nghĩa
              if (partOfSpeechVi.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    partOfSpeechVi,
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),

              if (partOfSpeechVi.isNotEmpty)
                const SizedBox(height: 24),

              // Nghĩa tiếng Việt (CHÍNH) - Style giống từ vựng mặt trước
              Text(
                meaningData['translation']!,
                style: AppTextStyles.title.copyWith(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                  height: 1.3,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ NÚT PHÁT ÂM (chỉ 1 nút)
  Widget _buildSpeakerButton() {
    return GestureDetector(
      onTap: _playPronunciation,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _isCardFlipped
              ? Colors.white.withOpacity(0.9)
              : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _isCardFlipped
                  ? Colors.black.withOpacity(0.2)
                  : AppColors.primaryDark.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _isSpeaking
            ? Padding(
          padding: const EdgeInsets.all(14),
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        )
            : const Icon(
          Icons.volume_up_rounded,
          color: AppColors.primary,
          size: 28,
        ),
      ),
    );
  }

  /// Nút hành động (buttons to lên)
  Widget _buildActionButtons() {
    return Row(
      children: [
        // NÚT 1: ĐÃ BIẾT
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _handleKnown,
            icon: const Icon(Icons.check_circle_outline, size: 24),
            label: Text(
              'Đã biết',
              style: AppTextStyles.button.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _knownButtonColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // NÚT 2: TIẾP TỤC
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _handleContinue,
            icon: const Icon(Icons.restart_alt, size: 24),
            label: Text(
              'Tiếp tục',
              style: AppTextStyles.button.copyWith(
                color: _continueTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _continueButtonColor,
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.primaryDark, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.primaryDark, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.textGray),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTextStyles.heading3.copyWith(color: AppColors.textGray),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadFlashcards,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final card = _currentCard;
    if (card == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: Text('Không có flashcard nào')),
      );
    }

    final double progress = (_currentIndex + 1) / _flashcards.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.primaryDark, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            Text(
              'Flashcards • Phiên 1',
              style: AppTextStyles.heading3.copyWith(color: AppColors.textSecondary),
            ),
            Text(
              '${_currentIndex + 1} / ${_flashcards.length}',
              style: AppTextStyles.label.copyWith(color: AppColors.textGray),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryDark, size: 28),
            onPressed: _loadFlashcards,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: GestureDetector(
                  onTap: () {
                    _cardKey.currentState?.toggleCard();
                  },
                  child: FlipCard(
                    key: _cardKey,
                    direction: FlipDirection.HORIZONTAL,
                    front: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryDark.withOpacity(0.15),
                                blurRadius: 25,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: _buildFrontCardContent(card),
                          ),
                        ),
                        Positioned(
                          top: 16,
                          left: 16,
                          child: _buildSpeakerButton(),
                        ),
                      ],
                    ),
                    back: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryDark.withOpacity(0.15),
                                blurRadius: 25,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: _buildBackCardContent(card),
                          ),
                        ),
                        Positioned(
                          top: 16,
                          left: 16,
                          child: _buildSpeakerButton(),
                        ),
                      ],
                    ),
                    fill: Fill.fillBack,
                    speed: 400,
                    onFlip: () {
                      setState(() {
                        _isCardFlipped = !_isCardFlipped;
                      });
                    },
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            color: AppColors.background,
            child: _buildActionButtons(),
          ),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.textGray.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 8,
          ),
        ],
      ),
    );
  }
}