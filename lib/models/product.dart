import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final int stock;
  final int minStock;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.minStock = 0,
  });

  bool get isLowStock => stock <= minStock;

  factory Product.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return Product(
      id: doc.id,
      name: d['name'] as String? ?? '',
      price: (d['price'] as num?)?.toDouble() ?? 0.0,
      stock: (d['stock'] as num?)?.toInt() ?? 0,
      minStock: (d['minStock'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'price': price,
        'stock': stock,
        'minStock': minStock,
      };
}
