import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flip_card/flip_card.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../models/flashcard_model.dart';
import '../../services/flash_card_service.dart';
import '../../services/tts_service.dart';

/// 🎨 Màn hình học Flashcard
/// ✅ UPDATED v2:
/// - Mặt trước & mặt sau BẰNG NHAU về kích thước
/// - Tiêu đề hiện TÊN CHỦ ĐỀ
/// - Hệ thống PHIÊN HỌC: mỗi phiên 20 từ
/// - Mặt sau màu xanh lá cây
/// - Nút phát âm góc trên trái cả 2 mặt
class FlashcardScreen extends StatefulWidget {
  final int? categoryId;
  final String? categoryName;

  const FlashcardScreen({
    super.key,
    this.categoryId,
    this.categoryName,
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen>
    with TickerProviderStateMixin {
  GlobalKey<FlipCardState> _cardKey = GlobalKey<FlipCardState>();
  final TTSService _ttsService = TTSService();

  // State
  bool _isSpeakingEnglish = false;
  bool _isSpeakingVietnamese = false;
  bool _isCardFlipped = false;
  bool _isLoading = true;

  // Data
  List<FlashcardModel> _allFlashcards = [];  // Tất cả flashcards
  List<FlashcardModel> _sessionFlashcards = [];  // Flashcards của phiên hiện tại
  int _currentIndex = 0;
  String? _errorMessage;

  // ✅ Session management
  static const int _cardsPerSession = 20;
  int _currentSession = 0;
  int _totalSessions = 1;

  // Tracking học tập
  Set<int> _knownCards = {};
  Set<int> _learningCards = {};

  // Animation
  late AnimationController _transitionController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    print('📱 [SCREEN] $runtimeType');
    _initAnimations();
    _loadFlashcards();
  }

  void _initAnimations() {
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _transitionController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _transitionController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _ttsService.stop();
    _transitionController.dispose();
    super.dispose();
  }

  // ==================== DATA LOADING ====================

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
        flashcards = await FlashcardService.getRandomFlashcards(limit: 100);
      }

      if (flashcards.isEmpty) {
        setState(() {
          _errorMessage = 'Chưa có flashcard nào trong chủ đề này';
          _isLoading = false;
        });
        return;
      }

      // Shuffle
      flashcards.shuffle();

      // ✅ Tính số phiên
      _totalSessions = (flashcards.length / _cardsPerSession).ceil();

      setState(() {
        _allFlashcards = flashcards;
        _currentSession = 0;
        _knownCards.clear();
        _learningCards.clear();
        _isLoading = false;
      });

      // Load session đầu tiên
      _loadSession(0);

      _transitionController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải dữ liệu. Vui lòng thử lại.';
        _isLoading = false;
      });
    }
  }

  /// ✅ Load một phiên học cụ thể
  void _loadSession(int sessionIndex) {
    final startIndex = sessionIndex * _cardsPerSession;
    final endIndex = (startIndex + _cardsPerSession).clamp(0, _allFlashcards.length);

    setState(() {
      _currentSession = sessionIndex;
      _sessionFlashcards = _allFlashcards.sublist(startIndex, endIndex);
      _currentIndex = 0;
      _isCardFlipped = false;
      _cardKey = GlobalKey<FlipCardState>();
    });

    _transitionController.reset();
    _transitionController.forward();
  }

  /// ✅ Chuyển sang phiên tiếp theo
  void _nextSession() {
    if (_currentSession < _totalSessions - 1) {
      _loadSession(_currentSession + 1);
      _showSnackBar('Phiên ${_currentSession + 1}/$_totalSessions');
    } else {
      // Hoàn thành tất cả
      _showCompletionDialog();
    }
  }

  // ==================== HELPERS ====================

  FlashcardModel? get _currentCard {
    if (_sessionFlashcards.isEmpty || _currentIndex >= _sessionFlashcards.length) {
      return null;
    }
    return _sessionFlashcards[_currentIndex];
  }

  String _getPartOfSpeechVi(FlashcardModel card) {
    if (card.partOfSpeechVi != null && card.partOfSpeechVi!.isNotEmpty) {
      return card.partOfSpeechVi!;
    }
    return _translatePartOfSpeech(card.partOfSpeech);
  }

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
      'phrase': 'Cụm từ',
    };

    String lower = partOfSpeech.toLowerCase().trim();
    return translations[lower] ?? partOfSpeech;
  }

  String _getMainMeaning(String meaning) {
    if (meaning.isEmpty) return 'Không có nghĩa';

    if (meaning.contains('\n\n')) {
      final parts = meaning.split('\n\n');
      for (var part in parts) {
        final trimmed = part.trim();
        if (!trimmed.startsWith('📖') && !trimmed.startsWith('📝') && !trimmed.toLowerCase().startsWith('example')) {
          return trimmed;
        }
      }
    }

    if (meaning.contains('📖') || meaning.contains('📝')) {
      final index = meaning.indexOf('📖');
      final index2 = meaning.indexOf('📝');
      final minIndex = index == -1 ? index2 : (index2 == -1 ? index : (index < index2 ? index : index2));
      if (minIndex > 0) {
        return meaning.substring(0, minIndex).trim();
      }
    }

    return meaning.trim();
  }

  // ==================== NAVIGATION ====================

  Future<void> _nextCard() async {
    if (_sessionFlashcards.isEmpty) return;

    HapticFeedback.lightImpact();
    await _transitionController.reverse();

    // Kiểm tra hết phiên chưa
    if (_currentIndex >= _sessionFlashcards.length - 1) {
      // Hết phiên này
      _showSessionCompleteDialog();
      return;
    }

    setState(() {
      _currentIndex = _currentIndex + 1;
      _isCardFlipped = false;
      _cardKey = GlobalKey<FlipCardState>();
    });

    await _transitionController.forward();
  }

  void _handleKnown() {
    final card = _currentCard;
    if (card?.id != null) {
      setState(() {
        _knownCards.add(card!.id!);
        _learningCards.remove(card.id!);
      });
    }
    _nextCard();
  }

  void _handleLearning() {
    final card = _currentCard;
    if (card?.id != null) {
      setState(() {
        _learningCards.add(card!.id!);
        _knownCards.remove(card.id!);
      });
    }
    _nextCard();
  }

  // ==================== TTS ====================

  Future<void> _playEnglishPronunciation() async {
    final card = _currentCard;
    if (card == null) return;

    if (_ttsService.isPlaying) {
      await _ttsService.stop();
      setState(() {
        _isSpeakingEnglish = false;
        _isSpeakingVietnamese = false;
      });
      return;
    }

    HapticFeedback.selectionClick();

    try {
      setState(() => _isSpeakingEnglish = true);
      await _ttsService.speak(card.word, languageCode: 'en-US');
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) setState(() => _isSpeakingEnglish = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isSpeakingEnglish = false);
        _showSnackBar('Không thể phát âm', isError: true);
      }
    }
  }

  Future<void> _playVietnamesePronunciation() async {
    final card = _currentCard;
    if (card == null) return;

    if (_ttsService.isPlaying) {
      await _ttsService.stop();
      setState(() {
        _isSpeakingEnglish = false;
        _isSpeakingVietnamese = false;
      });
      return;
    }

    HapticFeedback.selectionClick();

    try {
      setState(() => _isSpeakingVietnamese = true);
      final vietnameseText = _getMainMeaning(card.meaning);
      await _ttsService.speak(vietnameseText, languageCode: 'vi-VN');
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) setState(() => _isSpeakingVietnamese = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isSpeakingVietnamese = false);
        _showSnackBar('Không thể phát âm', isError: true);
      }
    }
  }

  // ==================== DIALOGS ====================

  void _showSessionCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: AppColors.success, size: 28),
            ),
            const SizedBox(width: 12),
            const Text('Hoàn thành phiên!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Phiên ${_currentSession + 1}/$_totalSessions',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('Đã biết', _knownCards.length, AppColors.success),
                _buildStatItem('Đang học', _learningCards.length, Colors.orange),
              ],
            ),
          ],
        ),
        actions: [
          if (_currentSession < _totalSessions - 1) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Thoát'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _nextSession();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Phiên tiếp theo'),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showCompletionDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hoàn thành'),
            ),
          ],
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.celebration, color: AppColors.warning, size: 32),
            SizedBox(width: 12),
            Text('Xuất sắc!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bạn đã hoàn thành tất cả ${_allFlashcards.length} thẻ!',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('Đã biết', _knownCards.length, AppColors.success),
                _buildStatItem('Cần ôn', _learningCards.length, Colors.orange),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Thoát'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadFlashcards(); // Học lại từ đầu
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Học lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade400 : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ==================== BUILD UI ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _errorMessage != null
            ? _buildErrorState()
            : _buildMainContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Đang tải flashcards...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.sentiment_dissatisfied_rounded,
                size: 64,
                color: Colors.red.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadFlashcards,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    final card = _currentCard;
    if (card == null) return const SizedBox.shrink();

    return Column(
      children: [
        _buildHeader(),
        _buildProgressSection(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: _buildFlipCard(card),
              ),
            ),
          ),
        ),
        _buildActionButtons(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          // Close button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                ],
              ),
              child: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 24),
            ),
          ),

          // ✅ Title: Tên chủ đề
          Expanded(
            child: Column(
              children: [
                Text(
                  widget.categoryName ?? 'Flashcards',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // ✅ Hiện phiên và số thẻ
                Text(
                  _totalSessions > 1
                      ? 'Phiên ${_currentSession + 1}/$_totalSessions • ${_currentIndex + 1}/${_sessionFlashcards.length}'
                      : '${_currentIndex + 1}/${_sessionFlashcards.length}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Shuffle button
          IconButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              setState(() {
                _sessionFlashcards.shuffle();
                _currentIndex = 0;
                _cardKey = GlobalKey<FlipCardState>();
                _isCardFlipped = false;
              });
              _transitionController.reset();
              _transitionController.forward();
              _showSnackBar('Đã xáo trộn thẻ');
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                ],
              ),
              child: const Icon(Icons.shuffle_rounded, color: AppColors.primary, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final progress = (_currentIndex + 1) / _sessionFlashcards.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(AppColors.success),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatChip(
                icon: Icons.check_circle_outline,
                count: _knownCards.length,
                color: AppColors.success,
              ),
              const SizedBox(width: 16),
              _buildStatChip(
                icon: Icons.refresh_rounded,
                count: _learningCards.length,
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required int count,
    required Color color,
  }) {
    return Container(
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
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlipCard(FlashcardModel card) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _cardKey.currentState?.toggleCard();
      },
      child: FlipCard(
        key: _cardKey,
        direction: FlipDirection.HORIZONTAL,
        speed: 400,
        front: _buildFrontCard(card),
        back: _buildBackCard(card),
        onFlip: () {
          HapticFeedback.lightImpact();
          setState(() => _isCardFlipped = !_isCardFlipped);
        },
      ),
    );
  }

  // ==================== MẶT TRƯỚC - TIẾNG ANH ====================
  Widget _buildFrontCard(FlashcardModel card) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ✅ Main content - căn giữa
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ✅ Image (if exists)
                  if (card.imageUrl != null && card.imageUrl!.isNotEmpty) ...[
                    Flexible(
                      flex: 3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          card.imageUrl!,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stack) {
                            return Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ✅ Word
                  Text(
                    card.word,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // ✅ Part of speech (English)
                  if (card.partOfSpeech != null && card.partOfSpeech!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        card.partOfSpeech!,
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // ✅ Phonetic
                  if (card.phonetic != null && card.phonetic!.isNotEmpty)
                    Text(
                      card.phonetic!,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),

                  const SizedBox(height: 24),

                  // Hint to flip
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_rounded, size: 16, color: AppColors.textGray),
                      const SizedBox(width: 6),
                      Text(
                        'Chạm để xem nghĩa',
                        style: TextStyle(
                          color: AppColors.textGray,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ✅ Speaker button (top-left)
          Positioned(
            top: 16,
            left: 16,
            child: _buildSpeakerButton(
              isPlaying: _isSpeakingEnglish,
              onTap: _playEnglishPronunciation,
              label: 'EN',
              backgroundColor: AppColors.success.withOpacity(0.1),
              iconColor: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MẶT SAU - TIẾNG VIỆT (XANH LÁ) ====================
  Widget _buildBackCard(FlashcardModel card) {
    final partOfSpeechVi = _getPartOfSpeechVi(card);
    final mainMeaning = _getMainMeaning(card.meaning);

    return Container(
      decoration: BoxDecoration(
        // ✅ GRADIENT XANH LÁ CÂY
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF10B981),  // Emerald 500
            Color(0xFF059669),  // Emerald 600
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),

          // ✅ Main content - căn giữa
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Original word (reminder)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      card.word,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ✅ Part of speech (Vietnamese)
                  if (partOfSpeechVi.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Text(
                        partOfSpeechVi,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // ✅ Vietnamese meaning (main)
                  Text(
                    mainMeaning,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Hint to flip back
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_rounded, size: 16, color: Colors.white.withOpacity(0.6)),
                      const SizedBox(width: 6),
                      Text(
                        'Chạm để quay lại',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ✅ Speaker button (top-left) - ĐỒNG BỘ VỊ TRÍ với mặt trước
          Positioned(
            top: 16,
            left: 16,
            child: _buildSpeakerButton(
              isPlaying: _isSpeakingVietnamese,
              onTap: _playVietnamesePronunciation,
              label: 'VI',
              backgroundColor: Colors.white,
              iconColor: const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ SPEAKER BUTTON - Đồng bộ style
  Widget _buildSpeakerButton({
    required bool isPlaying,
    required VoidCallback onTap,
    required String label,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isPlaying
            ? Padding(
          padding: const EdgeInsets.all(14),
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation(iconColor),
          ),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.volume_up_rounded,
              color: iconColor,
              size: 22,
            ),
            Text(
              label,
              style: TextStyle(
                color: iconColor,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ACTION BUTTONS ====================

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              onTap: _handleLearning,
              icon: Icons.refresh_rounded,
              label: 'Học lại',
              color: Colors.orange,
              isOutlined: true,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildActionButton(
              onTap: _handleKnown,
              icon: Icons.check_rounded,
              label: 'Đã biết',
              color: AppColors.success,
              isOutlined: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required Color color,
    required bool isOutlined,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isOutlined ? Colors.white : color,
          borderRadius: BorderRadius.circular(16),
          border: isOutlined ? Border.all(color: color, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isOutlined ? 0.1 : 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isOutlined ? color : Colors.white,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isOutlined ? color : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}