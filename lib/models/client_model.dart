class ClientModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String notes;
  final DateTime? lastVisit;
  final int totalVisits;
  final double totalSpent;
  final String? photoPath; // ruta local a la foto del cliente
  final DateTime? birthday;

  const ClientModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.notes = '',
    this.lastVisit,
    this.totalVisits = 0,
    this.totalSpent = 0,
    this.photoPath,
    this.birthday,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'email': email,
        'notes': notes,
        'lastVisitMs': lastVisit?.millisecondsSinceEpoch,
        'totalVisits': totalVisits,
        'totalSpent': totalSpent,
        'photoPath': photoPath,
        'birthdayMs': birthday?.millisecondsSinceEpoch,
      };

  factory ClientModel.fromMap(String id, Map<String, dynamic> m) => ClientModel(
        id: id,
        name: m['name'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        email: m['email'] as String?,
        notes: m['notes'] as String? ?? '',
        lastVisit: m['lastVisitMs'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['lastVisitMs'] as int)
            : null,
        totalVisits: (m['totalVisits'] as num?)?.toInt() ?? 0,
        totalSpent: (m['totalSpent'] as num?)?.toDouble() ?? 0,
        photoPath: m['photoPath'] as String?,
        birthday: m['birthdayMs'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['birthdayMs'] as int)
            : null,
      );

  ClientModel copyWith({
    String? name,
    String? phone,
    String? email,
    String? notes,
    DateTime? lastVisit,
    int? totalVisits,
    double? totalSpent,
    String? photoPath,
    DateTime? birthday,
  }) =>
      ClientModel(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        notes: notes ?? this.notes,
        lastVisit: lastVisit ?? this.lastVisit,
        totalVisits: totalVisits ?? this.totalVisits,
        totalSpent: totalSpent ?? this.totalSpent,
        photoPath: photoPath ?? this.photoPath,
        birthday: birthday ?? this.birthday,
      );
}
