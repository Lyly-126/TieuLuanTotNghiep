// ✅ FIXED: Parse JSON với camelCase (match với backend)

class FlashcardModel {
  final int id;
  final String term;
  final String? partOfSpeech;
  final String? phonetic;
  final String? imageUrl;
  final String meaning;
  final int? categoryId;
  final String? ttsUrl;

  FlashcardModel({
    required this.id,
    required this.term,
    this.partOfSpeech,
    this.phonetic,
    this.imageUrl,
    required this.meaning,
    this.categoryId,
    this.ttsUrl,
  });

  /// ✅ ĐÚNG: Parse từ JSON với camelCase (vì backend trả về camelCase)
  factory FlashcardModel.fromJson(Map<String, dynamic> json) {
    print('\n🔍 ===== PARSING FLASHCARD =====');
    print('📦 Raw JSON: $json');
    print('🔑 Keys: ${json.keys.toList()}');

    // ✅ Parse với camelCase
    final model = FlashcardModel(
      id: json['id'] ?? 0,
      term: json['term'] ?? '',
      partOfSpeech: json['partOfSpeech'],      // ✅ camelCase
      phonetic: json['phonetic'],
      imageUrl: json['imageUrl'],              // ✅ camelCase - QUAN TRỌNG!
      meaning: json['meaning'] ?? '',
      categoryId: json['categoryId'],          // ✅ camelCase
      ttsUrl: json['ttsUrl'],                  // ✅ camelCase
    );

    print('✅ Parsed imageUrl: "${model.imageUrl}"');
    print('✅ Parsed categoryId: ${model.categoryId}');
    print('===============================\n');

    return model;
  }

  /// Convert to JSON (camelCase để gửi lên backend)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'term': term,
      'partOfSpeech': partOfSpeech,      // ✅ camelCase
      'phonetic': phonetic,
      'imageUrl': imageUrl,              // ✅ camelCase
      'meaning': meaning,
      'categoryId': categoryId,          // ✅ camelCase
      'ttsUrl': ttsUrl,                  // ✅ camelCase
    };
  }

  /// Check if flashcard has valid image
  bool get hasImage {
    return imageUrl != null &&
        imageUrl!.isNotEmpty &&
        imageUrl != 'null' &&
        (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://'));
  }

  /// Check if flashcard has TTS audio
  bool get hasAudio {
    return ttsUrl != null &&
        ttsUrl!.isNotEmpty &&
        ttsUrl != 'null';
  }

  @override
  String toString() {
    return 'FlashcardModel(id: $id, term: $term, imageUrl: $imageUrl, categoryId: $categoryId)';
  }
}