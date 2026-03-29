import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';

class FinanceService {
  CollectionReference<Map<String, dynamic>>? get _col {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('transactions');
  }

  /// All transactions ordered by date descending.
  Stream<List<FinanceTransaction>> stream() {
    final col = _col;
    if (col == null) return const Stream.empty();
    return col
        .orderBy('dateMs', descending: true)
        .snapshots()
        .map((s) => s.docs.map(FinanceTransaction.fromDoc).toList());
  }

  Future<void> create({
    required TransactionType type,
    required double amount,
    required String description,
    required DateTime date,
  }) {
    final col = _col ?? (throw StateError('No hay usuario autenticado'));
    return col.add({
      'type': type == TransactionType.income ? 'income' : 'expense',
      'amount': amount,
      'description': description,
      'dateMs': date.millisecondsSinceEpoch,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String id) {
    final col = _col ?? (throw StateError('No hay usuario autenticado'));
    return col.doc(id).delete();
  }
}
