class Knife {
  final String id;
  final String name;
  final String brand;
  final double? bladeLength;

  Knife({
    required this.id,
    required this.name,
    required this.brand,
    this.bladeLength,
  });

  factory Knife.fromMap(String id, Map<String, dynamic> data) {
    return Knife(
      id: id,
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      bladeLength: (data['bladeLength'] is num)
          ? (data['bladeLength'] as num).toDouble()
          : null,
    );
  }
}
