import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/knife.dart';

class KnifeService {
  final _col = FirebaseFirestore.instance.collection('knives');

  Stream<List<Knife>> streamAll() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Knife.fromMap(d.id, d.data())).toList());
  }

  Future<void> create({
    required String name,
    required String brand,
    double? bladeLength,
    String? ownerUid,
  }) async {
    await _col.add({
      'name': name,
      'brand': brand,
      'bladeLength': bladeLength,
      'ownerUid': ownerUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
