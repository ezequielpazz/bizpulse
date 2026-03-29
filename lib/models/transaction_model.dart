import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense }

class FinanceTransaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String description;
  final DateTime date;

  FinanceTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
  });

  bool get isIncome => type == TransactionType.income;

  factory FinanceTransaction.fromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return FinanceTransaction(
      id: doc.id,
      type: (d['type'] as String?) == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      amount: (d['amount'] as num?)?.toDouble() ?? 0.0,
      description: d['description'] as String? ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(
        (d['dateMs'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type == TransactionType.income ? 'income' : 'expense',
        'amount': amount,
        'description': description,
        'dateMs': date.millisecondsSinceEpoch,
      };
}
