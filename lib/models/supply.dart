class Supply {
  final String id;
  final String name;
  final int qty;
  final int minQty;

  Supply({required this.id, required this.name, required this.qty, required this.minQty});

  factory Supply.fromMap(String id, Map<String, dynamic> data) {
    return Supply(
      id: id,
      name: (data['name'] ?? '') as String,
      qty: (data['qty'] as num).toInt(),
      minQty: (data['minQty'] as num).toInt(),
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'qty': qty, 'minQty': minQty};
}
