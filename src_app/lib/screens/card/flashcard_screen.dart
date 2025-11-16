import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../config/app_constants.dart';
import '../../models/flashcard_model.dart';
import '../../services/flash_card_service.dart';
import '../../services/google_tts_service.dart';

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
  final GoogleTTSService _ttsService = GoogleTTSService();

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

  /// ✅ SIMPLIFIED: Chỉ lấy nghĩa tiếng Việt (dòng đầu tiên)
  String _getVietnameseMeaning(String meaning) {
    try {
      if (kDebugMode) {
        print('\n🔍 Getting Vietnamese meaning from DB');
        print('📝 Raw meaning: "$meaning"');
      }

      // Split bằng \n\n
      List<String> parts = meaning.split('\n\n');

      if (kDebugMode) {
        print('📦 Split into ${parts.length} parts');
      }

      // Lấy dòng đầu tiên (translation)
      String translation = parts[0].trim();

      // Remove "Translation:" nếu có
      if (translation.toLowerCase().startsWith('translation:')) {
        translation = translation
            .replaceFirst(RegExp(r'translation:\s*', caseSensitive: false), '')
            .trim();
      }

      if (kDebugMode) {
        print('✅ Vietnamese meaning: "$translation"');
      }

      return translation.isNotEmpty ? translation : meaning;

    } catch (e) {
      if (kDebugMode) print('❌ Parse error: $e');
      return meaning;
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

      // ✅ DEBUG: Log data từ DB
      if (kDebugMode) {
        print('\n📚 ===== LOADED ${flashcards.length} FLASHCARDS FROM DB =====');

        for (int i = 0; i < flashcards.length; i++) {
          final card = flashcards[i];
          print('\n📝 Flashcard ${i + 1}:');
          print('   - ID: ${card.id}');
          print('   - term: "${card.term}"');
          print('   - partOfSpeech: "${card.partOfSpeech}"');
          print('   - phonetic: "${card.phonetic}"');
          print('   - imageUrl: "${card.imageUrl}"');
          print('   - imageUrl length: ${card.imageUrl?.length ?? 0}');
          print('   - imageUrl isEmpty: ${card.imageUrl?.isEmpty ?? true}');
          print('   - meaning: "${card.meaning}"');
          print('   - ttsUrl: "${card.ttsUrl}"');
        }
        print('======================================\n');
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

      if (card.ttsUrl != null && card.ttsUrl!.isNotEmpty) {
        if (kDebugMode) print('🎵 Playing from TTS URL: ${card.ttsUrl}');
        // await _ttsService.speakFromUrl(card.ttsUrl!);
        await _ttsService.speak(card.term, languageCode: 'en-US');
      } else {
        if (kDebugMode) print('🔊 Using Google TTS for: ${card.term}');
        await _ttsService.speak(card.term, languageCode: 'en-US');
      }

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
            'Bạn cần thêm Google Cloud Text-to-Speech API key vào file google_tts_service.dart để sử dụng chức năng này.'),
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
    if (kDebugMode) print('✅ Đã biết - Card: ${_currentCard?.term}');
    _nextCard();
  }

  void _handleContinue() {
    if (kDebugMode) print('📝 Tiếp tục - Card: ${_currentCard?.term}');
    _nextCard();
  }

  /// ✅ FIXED: Build image với debug chi tiết
  Widget _buildCardImage(FlashcardModel card) {
    if (kDebugMode) {
      print('\n🖼️ ===== BUILDING IMAGE =====');
      print('📝 Term: ${card.term}');
      print('🔗 imageUrl type: ${card.imageUrl.runtimeType}');
      print('🔗 imageUrl value: "${card.imageUrl}"');
      print('📏 imageUrl length: ${card.imageUrl?.length ?? 0}');
      print('❓ imageUrl == null: ${card.imageUrl == null}');
      print('❓ imageUrl.isEmpty: ${card.imageUrl?.isEmpty ?? true}');
      print('===============================\n');
    }

    // ✅ CHECK NULL hoặc EMPTY
    final hasImage = card.imageUrl != null &&
        card.imageUrl!.isNotEmpty &&
        card.imageUrl != 'null';

    if (!hasImage) {
      if (kDebugMode) print('⚠️ No valid image URL, showing placeholder');

      return Container(
        height: 180,
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
          size: 60,
        ),
      );
    }

    if (kDebugMode) print('✅ Attempting to load image from: ${card.imageUrl}');

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Image.network(
        card.imageUrl!,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            if (kDebugMode) print('✅ Image loaded successfully!');
            return child;
          }

          if (kDebugMode) {
            final progress = loadingProgress.expectedTotalBytes != null
                ? (loadingProgress.cumulativeBytesLoaded /
                loadingProgress.expectedTotalBytes! * 100).toStringAsFixed(0)
                : 'unknown';
            print('⏳ Loading image... $progress%');
          }

          return Container(
            height: 180,
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
          if (kDebugMode) {
            print('❌ IMAGE LOAD FAILED!');
            print('   Error: $error');
            print('   URL: ${card.imageUrl}');
            print('   StackTrace: $stackTrace');
          }

          return Container(
            height: 180,
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
                  size: 40,
                ),
                const SizedBox(height: 6),
                Text(
                  'Không thể tải ảnh',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 4),
                if (kDebugMode)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      error.toString(),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.error,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ✨ MẶT TRƯỚC: Ảnh + Từ + Loại từ (TV) + Phiên âm
  Widget _buildFrontCardContent(FlashcardModel card) {
    final partOfSpeechVi = _translatePartOfSpeech(card.partOfSpeech);

    return Container(
      alignment: Alignment.center,
      color: AppColors.background,
      padding: AppConstants.screenPadding.copyWith(top: 20, bottom: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hình ảnh
            _buildCardImage(card),

            const SizedBox(height: 20),

            // Từ vựng chính
            Text(
              card.term,
              style: AppTextStyles.title.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDark,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Loại từ (Tiếng Việt) và phiên âm
            if (card.partOfSpeech != null || card.phonetic != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${partOfSpeechVi.isNotEmpty ? partOfSpeechVi : ''}'
                      '${partOfSpeechVi.isNotEmpty && card.phonetic != null ? ' • ' : ''}'
                      '${card.phonetic ?? ''}',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ✨ MẶT SAU: Chỉ hiển thị nghĩa tiếng Việt
  Widget _buildBackCardContent(FlashcardModel card) {
    if (kDebugMode) {
      print('\n🔄 ===== BUILDING BACK CARD =====');
      print('📝 Card: ${card.term}');
      print('📋 Raw meaning: "${card.meaning}"');
    }

    // ✅ Lấy nghĩa tiếng Việt
    final translation = _getVietnameseMeaning(card.meaning);
    final partOfSpeechVi = _translatePartOfSpeech(card.partOfSpeech);

    // ✅ Build display text
    String displayMeaning;
    if (partOfSpeechVi.isNotEmpty) {
      displayMeaning = '$partOfSpeechVi: $translation';
    } else {
      displayMeaning = translation;
    }

    if (kDebugMode) {
      print('📺 Display on screen: "$displayMeaning"');
      print('================================\n');
    }

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primaryDark.withOpacity(0.9),
          ],
        ),
      ),
      padding: AppConstants.screenPadding.copyWith(left: 30, right: 30, top: 80, bottom: 80),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  displayMeaning,
                  style: AppTextStyles.heading2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                    fontSize: 30,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ ĐỔI CHỖ 2 NÚT: Đã biết (trái) | Tiếp tục (phải)
  Widget _buildActionButtons() {
    return Row(
      children: [
        // NÚT 1: ĐÃ BIẾT (màu xanh, bên trái)
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _handleKnown,
            icon: const Icon(Icons.check_circle_outline, size: 20),
            label: Text(
              'Đã biết',
              style: AppTextStyles.button.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _knownButtonColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.inputPadding * 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: AppConstants.sectionSpacingSmall),
        // NÚT 2: TIẾP TỤC (màu xám, bên phải)
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _handleContinue,
            icon: const Icon(Icons.restart_alt, size: 20),
            label: Text(
              'Tiếp tục',
              style: AppTextStyles.button.copyWith(
                color: _continueTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _continueButtonColor,
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.inputPadding * 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              elevation: 0,
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
              padding: AppConstants.screenPadding.copyWith(top: 10, bottom: 10),
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
                            borderRadius: BorderRadius.circular(AppConstants.borderRadius * 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryDark.withOpacity(0.15),
                                blurRadius: 25,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppConstants.borderRadius * 2),
                            child: _buildFrontCardContent(card),
                          ),
                        ),
                        Positioned(
                          top: 16,
                          left: 16,
                          child: GestureDetector(
                            onTap: _playPronunciation,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryDark.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: _isSpeaking
                                  ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                ),
                              )
                                  : const Icon(
                                Icons.volume_up_rounded,
                                color: AppColors.primary,
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    back: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppConstants.borderRadius * 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryDark.withOpacity(0.15),
                                blurRadius: 25,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppConstants.borderRadius * 2),
                            child: _buildBackCardContent(card),
                          ),
                        ),
                        Positioned(
                          top: 16,
                          left: 16,
                          child: GestureDetector(
                            onTap: _playPronunciation,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: _isSpeaking
                                  ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                ),
                              )
                                  : const Icon(
                                Icons.volume_up_rounded,
                                color: AppColors.primary,
                                size: 26,
                              ),
                            ),
                          ),
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
            padding: AppConstants.screenPadding.copyWith(top: 10, bottom: 20),
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