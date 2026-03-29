class ServiceModel {
  final String id;
  final String name;
  final int durationMinutes;
  final double price;
  final String category;
  final bool isActive;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.price,
    required this.category,
    required this.isActive,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'durationMinutes': durationMinutes,
        'price': price,
        'category': category,
        'isActive': isActive ? 1 : 0,
      };

  factory ServiceModel.fromMap(Map<String, dynamic> m) => ServiceModel(
        id: m['id'] as String,
        name: m['name'] as String,
        durationMinutes: m['durationMinutes'] as int,
        price: (m['price'] as num).toDouble(),
        category: m['category'] as String? ?? '',
        isActive: (m['isActive'] as int? ?? 1) == 1,
      );

  ServiceModel copyWith({
    String? id,
    String? name,
    int? durationMinutes,
    double? price,
    String? category,
    bool? isActive,
  }) =>
      ServiceModel(
        id: id ?? this.id,
        name: name ?? this.name,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        price: price ?? this.price,
        category: category ?? this.category,
        isActive: isActive ?? this.isActive,
      );
}
