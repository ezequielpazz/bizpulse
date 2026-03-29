class Appointment {
  final String id;
  final String clientName;
  final DateTime when;
  final String? service;
  final double? price;
  final int remindBeforeMin;
  final String? ownerUid;

  Appointment({
    required this.id,
    required this.clientName,
    required this.when,
    this.service,
    this.price,
    this.remindBeforeMin = 15,
    this.ownerUid,
  });

  factory Appointment.fromMap(String id, Map<String, dynamic> data) {
    return Appointment(
      id: id,
      clientName: (data['clientName'] ?? '') as String,
      when: DateTime.fromMillisecondsSinceEpoch(
        (data['whenMs'] as num).toInt(),
        isUtc: true,
      ).toLocal(),
      service: data['service'] as String?,
      price: (data['price'] is num) ? (data['price'] as num).toDouble() : null,
      remindBeforeMin: (data['remindBeforeMin'] is num)
          ? (data['remindBeforeMin'] as num).toInt()
          : 15,
      ownerUid: data['ownerUid'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'clientName': clientName,
        'whenMs': when.toUtc().millisecondsSinceEpoch,
        'service': service,
        'price': price,
        'remindBeforeMin': remindBeforeMin,
        'ownerUid': ownerUid,
      };
}
