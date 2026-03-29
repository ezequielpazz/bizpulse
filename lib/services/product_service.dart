import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';

class ProductService {
  CollectionReference<Map<String, dynamic>>? get _col {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('products');
  }

  Stream<List<Product>> stream() {
    final col = _col;
    if (col == null) return const Stream.empty();
    return col
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map(Product.fromDoc).toList());
  }

  Future<void> create({
    required String name,
    required double price,
    required int stock,
    required int minStock,
  }) {
    final col = _col ?? (throw StateError('No hay usuario autenticado'));
    return col.add({
      'name': name,
      'price': price,
      'stock': stock,
      'minStock': minStock,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> update(
    String id, {
    required String name,
    required double price,
    required int stock,
    required int minStock,
  }) {
    final col = _col ?? (throw StateError('No hay usuario autenticado'));
    return col.doc(id).update({
      'name': name,
      'price': price,
      'stock': stock,
      'minStock': minStock,
    });
  }

  Future<void> delete(String id) {
    final col = _col ?? (throw StateError('No hay usuario autenticado'));
    return col.doc(id).delete();
  }
}
