class ProductModel {
  final String id;
  final String name;
  final String? englishName;
  final double price;
  final bool isAvailable;

  ProductModel({
    required this.id,
    required this.name,
    this.englishName,
    required this.price,
    this.isAvailable = true,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      englishName: json['englishName'],
      price: json['price'] != null ? (json['price'] as num).toDouble() : 0.0,
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'englishName': englishName,
      'price': price,
      'isAvailable': isAvailable,
    };
  }
}
