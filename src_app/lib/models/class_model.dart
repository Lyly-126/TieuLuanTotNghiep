class ClassModel {
  final int id;
  final String name;
  final String? description;
  final int ownerId;
  final String? ownerEmail;
  final String? ownerName;
  final String createdAt;
  final String updatedAt;
  final int? categoryCount;
  final int? studentCount;

  ClassModel({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    this.ownerEmail,
    this.ownerName,
    required this.createdAt,
    required this.updatedAt,
    this.categoryCount,
    this.studentCount,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      ownerId: json['ownerId'],
      ownerEmail: json['ownerEmail'],
      ownerName: json['ownerName'],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      categoryCount: json['categoryCount'],
      studentCount: json['studentCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'ownerEmail': ownerEmail,
      'ownerName': ownerName,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'categoryCount': categoryCount,
      'studentCount': studentCount,
    };
  }

  @override
  String toString() {
    return 'ClassModel(id: $id, name: $name, categories: $categoryCount)';
  }
}