import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/client_model.dart';

class ClientService {
  CollectionReference<Map<String, dynamic>>? get _col {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('clients');
  }

  Future<List<ClientModel>> getAll() async {
    final col = _col;
    if (col == null) return [];
    final snap = await col.orderBy('name').get();
    return snap.docs.map((d) => ClientModel.fromMap(d.id, d.data())).toList();
  }

  Future<String> create(ClientModel client) async {
    final col = _col;
    if (col == null) return '';
    final ref = await col.add(client.toMap());
    return ref.id;
  }

  Future<void> update(ClientModel client) async {
    await _col?.doc(client.id).update(client.toMap());
  }

  Future<void> delete(String id) async {
    await _col?.doc(id).delete();
  }

  Future<List<ClientModel>> getByName(String query) async {
    final all = await getAll();
    final q = query.toLowerCase();
    return all.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  Future<void> incrementVisit(String id, double price) async {
    final col = _col;
    if (col == null) return;
    await col.doc(id).update({
      'totalVisits': FieldValue.increment(1),
      'totalSpent': FieldValue.increment(price),
      'lastVisitMs': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
