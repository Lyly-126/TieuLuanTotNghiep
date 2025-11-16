class StudyPackModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final int durationDays;

  StudyPackModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.durationDays = 30,
  });

  factory StudyPackModel.fromJson(Map<String, dynamic> json) {
    return StudyPackModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      durationDays: json['durationDays'] ?? 30,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'durationDays': durationDays,
    };
  }

  // Helper method để format price
  String get formattedPrice {
    return '${price.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    )}đ';
  }

  // Helper method để format duration
  String get durationLabel {
    if (durationDays >= 365) {
      final years = (durationDays / 365).floor();
      return '/ $years năm';
    } else if (durationDays >= 30) {
      final months = (durationDays / 30).floor();
      return '/ $months tháng';
    } else {
      return '/ $durationDays ngày';
    }
  }
}
