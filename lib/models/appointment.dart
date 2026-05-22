class Appointment {
  final String id;
  final String clientName;
  final DateTime when;
  final String? service;
  final double? price;
  final int remindBeforeMin;
  final String? ownerUid;
  final String? notes; // Pro: notas técnicas del turno (qué se hizo, alergias, etc)
  final bool whatsappReminderSent; // Pro: si ya se envió el WhatsApp 24h antes

  Appointment({
    required this.id,
    required this.clientName,
    required this.when,
    this.service,
    this.price,
    this.remindBeforeMin = 15,
    this.ownerUid,
    this.notes,
    this.whatsappReminderSent = false,
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
      notes: data['notes'] as String?,
      whatsappReminderSent: (data['whatsappReminderSent'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'clientName': clientName,
        'whenMs': when.toUtc().millisecondsSinceEpoch,
        'service': service,
        'price': price,
        'remindBeforeMin': remindBeforeMin,
        'ownerUid': ownerUid,
        'notes': notes,
        'whatsappReminderSent': whatsappReminderSent,
      };

  Appointment copyWith({
    String? clientName,
    DateTime? when,
    String? service,
    double? price,
    int? remindBeforeMin,
    String? notes,
    bool? whatsappReminderSent,
  }) =>
      Appointment(
        id: id,
        clientName: clientName ?? this.clientName,
        when: when ?? this.when,
        service: service ?? this.service,
        price: price ?? this.price,
        remindBeforeMin: remindBeforeMin ?? this.remindBeforeMin,
        ownerUid: ownerUid,
        notes: notes ?? this.notes,
        whatsappReminderSent: whatsappReminderSent ?? this.whatsappReminderSent,
      );
}
