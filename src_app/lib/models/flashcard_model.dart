class FlashcardModel {
  final int id;
  final String question;  // Maps to 'term' from backend
  final String answer;    // Maps to 'meaning' from backend
  final String? partOfSpeech;
  final String? phonetic;
  final String? imageUrl;
  final String? ttsUrl;
  final int? categoryId;

  FlashcardModel({
    required this.id,
    required this.question,
    required this.answer,
    this.partOfSpeech,
    this.phonetic,
    this.imageUrl,
    this.ttsUrl,
    this.categoryId,
  });

  // ✅ CRITICAL: Map backend fields to Flutter fields
  factory FlashcardModel.fromJson(Map<String, dynamic> json) {
    return FlashcardModel(
      id: json['id'] as int,
      question: json['term'] as String,      // ← Map term → question
      answer: json['meaning'] as String,     // ← Map meaning → answer
      partOfSpeech: json['part_of_speech'] as String?,
      phonetic: json['phonetic'] as String?,
      imageUrl: json['image_url'] as String?,
      ttsUrl: json['tts_url'] as String?,
      categoryId: json['category_id'] as int?,
    );
  }

  // ✅ CRITICAL: Map Flutter fields to backend fields
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'term': question,          // ← Map question → term
      'meaning': answer,         // ← Map answer → meaning
      'part_of_speech': partOfSpeech,
      'phonetic': phonetic,
      'image_url': imageUrl,
      'tts_url': ttsUrl,
      'category_id': categoryId,
    };
  }
}