/// Flashcard Model
///
/// Schema:
/// - id: Primary key
/// - userId: Người tạo flashcard
/// - word: Từ vựng
/// - partOfSpeech: Loại từ tiếng Anh (noun, verb, adj...)
/// - partOfSpeechVi: Loại từ tiếng Việt (danh từ, động từ...)
/// - phonetic: Phiên âm IPA
/// - imageUrl: URL hình ảnh
/// - meaning: Nghĩa tiếng Việt
/// - categoryId: ID category
/// - ttsUrl: URL file audio TTS
/// - createdAt: Thời gian tạo
class FlashcardModel {
  final int? id;
  final int? userId;
  final String word;
  final String? partOfSpeech;
  final String? partOfSpeechVi;
  final String? phonetic;
  final String? imageUrl;
  final String meaning;
  final int? categoryId;
  final String? ttsUrl;
  final DateTime? createdAt;

  FlashcardModel({
    this.id,
    this.userId,
    required this.word,
    this.partOfSpeech,
    this.partOfSpeechVi,
    this.phonetic,
    this.imageUrl,
    required this.meaning,
    this.categoryId,
    this.ttsUrl,
    this.createdAt,
  });

  // ============ BACKWARD COMPATIBILITY ============
  // Để tương thích với code cũ dùng question/answer

  /// Alias cho word (tương thích code cũ)
  String get question => word;

  /// Alias cho meaning (tương thích code cũ)
  String get answer => meaning;

  // ============ Factory ============

  factory FlashcardModel.fromJson(Map<String, dynamic> json) {
    return FlashcardModel(
      id: json['id'],
      userId: json['userId'],
      // Hỗ trợ cả 'word' và 'term' (backward compatible)
      word: json['word'] ?? json['term'] ?? '',
      partOfSpeech: json['partOfSpeech'],
      partOfSpeechVi: json['partOfSpeechVi'],
      phonetic: json['phonetic'],
      imageUrl: json['imageUrl'],
      // Hỗ trợ cả 'meaning' và 'answer'
      meaning: json['meaning'] ?? json['answer'] ?? '',
      categoryId: json['categoryId'],
      ttsUrl: json['ttsUrl'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'word': word,
      'partOfSpeech': partOfSpeech,
      'partOfSpeechVi': partOfSpeechVi,
      'phonetic': phonetic,
      'imageUrl': imageUrl,
      'meaning': meaning,
      'categoryId': categoryId,
      'ttsUrl': ttsUrl,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  FlashcardModel copyWith({
    int? id,
    int? userId,
    String? word,
    String? partOfSpeech,
    String? partOfSpeechVi,
    String? phonetic,
    String? imageUrl,
    String? meaning,
    int? categoryId,
    String? ttsUrl,
    DateTime? createdAt,
  }) {
    return FlashcardModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      word: word ?? this.word,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      partOfSpeechVi: partOfSpeechVi ?? this.partOfSpeechVi,
      phonetic: phonetic ?? this.phonetic,
      imageUrl: imageUrl ?? this.imageUrl,
      meaning: meaning ?? this.meaning,
      categoryId: categoryId ?? this.categoryId,
      ttsUrl: ttsUrl ?? this.ttsUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Hiển thị loại từ (ưu tiên tiếng Việt)
  String get displayPartOfSpeech {
    if (partOfSpeechVi != null && partOfSpeechVi!.isNotEmpty) {
      return partOfSpeechVi!;
    }
    return partOfSpeech ?? '';
  }

  /// Hiển thị loại từ đầy đủ (cả 2 ngôn ngữ)
  String get fullPartOfSpeech {
    if (partOfSpeech != null && partOfSpeechVi != null) {
      return '$partOfSpeech ($partOfSpeechVi)';
    }
    return partOfSpeech ?? partOfSpeechVi ?? '';
  }

  @override
  String toString() {
    return 'FlashcardModel(id: $id, userId: $userId, word: $word, categoryId: $categoryId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlashcardModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}