import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/appointment.dart';
import 'notification_service.dart';

class AppointmentService {
  CollectionReference<Map<String, dynamic>>? get _col {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('appointments');
  }

  /// Stream de TODOS los turnos del usuario logueado, ordenados por fecha,
  /// y luego filtramos por el día seleccionado en memoria.
  Stream<List<Appointment>> streamForDay(DateTime dayLocal) {
    final col = _col;
    if (col == null) return const Stream<List<Appointment>>.empty();

    final dayStartLocal = DateTime(dayLocal.year, dayLocal.month, dayLocal.day);
    final dayEndLocal = dayStartLocal.add(const Duration(days: 1));

    return col
        .orderBy('whenMs')
        .snapshots()
        .map((snap) {
      final all = snap.docs
          .map((d) => Appointment.fromMap(d.id, d.data()))
          .toList();

      // filtramos en memoria sólo los del día seleccionado
      return all.where((appt) {
        final t = appt.when; // ya viene en local time gracias fromMap
        return (t.isAfter(dayStartLocal) || t.isAtSameMomentAs(dayStartLocal))
            && t.isBefore(dayEndLocal);
      }).toList();
    });
  }

  /// Próximos turnos desde ahora, ordenados por fecha (filtrado en memoria
  /// para evitar requerir un índice compuesto en Firestore).
  Stream<List<Appointment>> streamUpcoming({int limit = 5}) {
    final col = _col;
    if (col == null) return const Stream<List<Appointment>>.empty();
    return col.orderBy('whenMs').snapshots().map((snap) {
      final now = DateTime.now();
      return snap.docs
          .map((d) => Appointment.fromMap(d.id, d.data()))
          .where((a) => a.when.isAfter(now))
          .take(limit)
          .toList();
    });
  }

  /// Crear turno nuevo
  Future<void> create({
    required String clientName,
    required DateTime whenLocal,
    String? service,
    double? price,
    int remindBeforeMin = 15,
  }) async {
    final col = _col ?? (throw StateError('No hay usuario autenticado'));

    final doc = await col.add({
      'clientName': clientName,
      'whenMs': whenLocal.toUtc().millisecondsSinceEpoch,
      'service': service,
      'price': price,
      'remindBeforeMin': remindBeforeMin,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final notifyAt = whenLocal.subtract(Duration(minutes: remindBeforeMin));
    await NotificationService().scheduleOneShot(
      id: _makeNotifId(doc.id),
      whenLocal: notifyAt,
      title: 'Turno $clientName',
      body: 'Tenés un turno a las ${_hhmm(whenLocal)}',
      payload: 'appointment:${doc.id}',
    );
  }

  /// Borrar turno
  Future<void> delete(String id) async {
    final col = _col ?? (throw StateError('No hay usuario autenticado'));
    await col.doc(id).delete();
    await NotificationService().cancel(_makeNotifId(id));
  }

  String _makeNotifId(String docId) => docId.hashCode.toString();

  String _hhmm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
