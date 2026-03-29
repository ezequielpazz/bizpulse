import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/supply.dart';
import 'notification_service.dart';

class SupplyService {
  CollectionReference<Map<String, dynamic>>? get _col {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('supplies');
  }

  // Stream de insumos SOLO del usuario logueado
  Stream<List<Supply>> streamAll() {
    final col = _col;
    if (col == null) return const Stream<List<Supply>>.empty();

    return col
        .orderBy('name')
        .snapshots()
        .map((s) =>
            s.docs.map((d) => Supply.fromMap(d.id, d.data())).toList());
  }

  Future<void> create({
    required String name,
    required int qty,
    required int minQty,
  }) async {
    final col = _col ?? (throw StateError('No hay usuario autenticado'));
    await col.add({
      'name': name,
      'qty': qty,
      'minQty': minQty,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (qty <= minQty) {
      await NotificationService().scheduleOneShot(
        id: 'supply_$name',
        whenLocal: DateTime.now().add(const Duration(seconds: 2)),
        title: 'Insumo bajo',
        body: '$name en mínimo ($qty ≤ $minQty)',
      );
    }
  }

  Future<void> updateQty(String id, int newQty) async {
    final doc = (_col ?? (throw StateError('No hay usuario autenticado'))).doc(id);
    await doc.update({
      'qty': newQty,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final snap = await doc.get();
    final s = Supply.fromMap(snap.id, snap.data()!);

    if (s.qty <= s.minQty) {
      await NotificationService().scheduleOneShot(
        id: 'supply_${s.name}',
        whenLocal: DateTime.now().add(const Duration(seconds: 2)),
        title: 'Insumo bajo',
        body: '${s.name} en mínimo (${s.qty} ≤ ${s.minQty})',
      );
    }
  }

  Future<void> update(
    String id, {
    required String name,
    required int qty,
    required int minQty,
  }) async {
    final col = _col ?? (throw StateError('No hay usuario autenticado'));
    await col.doc(id).update({
      'name': name,
      'qty': qty,
      'minQty': minQty,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String id) {
    final col = _col ?? (throw StateError('No hay usuario autenticado'));
    return col.doc(id).delete();
  }
}
