import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class BackupException implements Exception {
  final String message;
  BackupException(this.message);
  @override
  String toString() => message;
}

class BackupService {
  static const int _schemaVersion = 1;

  String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw BackupException('No hay sesión activa. Iniciá sesión e intentá de nuevo.');
    }
    return uid;
  }
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ── Collection references ───────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _appointmentsCol =>
      _db.collection('users').doc(_uid).collection('appointments');

  CollectionReference<Map<String, dynamic>> get _productsCol =>
      _db.collection('users').doc(_uid).collection('products');

  CollectionReference<Map<String, dynamic>> get _transactionsCol =>
      _db.collection('users').doc(_uid).collection('transactions');

  // ── Export ──────────────────────────────────────────────────────────────────

  /// Reads all user data, serializes to JSON, writes to disk.
  /// Returns the full path of the saved file.
  Future<String> export({void Function(String)? onStatus}) async {
    final uid = _uid;

    onStatus?.call('Leyendo turnos...');
    final apptSnap =
        await _appointmentsCol.where('ownerUid', isEqualTo: uid).get();
    final appointments = apptSnap.docs
        .map((d) => <String, dynamic>{'_id': d.id, ..._sanitizeMap(d.data())})
        .toList();

    onStatus?.call('Leyendo productos...');
    final prodSnap = await _productsCol.get();
    final products = prodSnap.docs
        .map((d) => <String, dynamic>{'_id': d.id, ..._sanitizeMap(d.data())})
        .toList();

    onStatus?.call('Leyendo transacciones...');
    final txSnap = await _transactionsCol.get();
    final transactions = txSnap.docs
        .map((d) => <String, dynamic>{'_id': d.id, ..._sanitizeMap(d.data())})
        .toList();

    final payload = <String, dynamic>{
      'version': _schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'uid': uid,
      'appointments': appointments,
      'products': products,
      'transactions': transactions,
    };

    onStatus?.call('Guardando archivo...');
    final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
    final dateFmt = DateFormat('yyyy-MM-dd');
    final filename = 'bizpulse_backup_${dateFmt.format(DateTime.now())}.json';
    final dir = await _getSaveDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(jsonStr, encoding: utf8);

    await _writeLastBackupMarker();
    return file.path;
  }

  // ── Import ──────────────────────────────────────────────────────────────────

  /// Validates the file, auto-backs up current data, then replaces all data.
  Future<void> importFromFile(
    String filePath, {
    void Function(String)? onStatus,
  }) async {
    // 1. Read and parse
    onStatus?.call('Leyendo archivo...');
    final file = File(filePath);
    if (!await file.exists()) {
      throw BackupException('Archivo no encontrado: $filePath');
    }
    final content = await file.readAsString(encoding: utf8);

    onStatus?.call('Validando estructura...');
    late Map<String, dynamic> data;
    try {
      data = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      throw BackupException('El archivo no contiene JSON válido.');
    }

    // 2. Validate BEFORE touching any data
    _validate(data);

    final appointments = _mapList(data['appointments'] as List);
    final products = _mapList(data['products'] as List);
    final transactions = _mapList(data['transactions'] as List);

    // 3. Auto-backup current data before modifying anything
    onStatus?.call('Creando respaldo automático previo...');
    await export(onStatus: null);

    // 4. Delete existing data
    onStatus?.call('Eliminando turnos existentes...');
    await _deleteQuery(
        _appointmentsCol.where('ownerUid', isEqualTo: _uid));

    onStatus?.call('Eliminando productos existentes...');
    await _deleteQuery(_productsCol);

    onStatus?.call('Eliminando transacciones existentes...');
    await _deleteQuery(_transactionsCol);

    // 5. Restore
    onStatus?.call('Restaurando ${appointments.length} turno(s)...');
    for (final a in appointments) {
      final map = _prepareForWrite(a);
      await _appointmentsCol.add(map);
    }

    onStatus?.call('Restaurando ${products.length} producto(s)...');
    for (final p in products) {
      final map = _prepareForWrite(p);
      await _productsCol.add(map);
    }

    onStatus?.call('Restaurando ${transactions.length} transacción(es)...');
    for (final t in transactions) {
      final map = _prepareForWrite(t);
      await _transactionsCol.add(map);
    }

    await _writeLastBackupMarker();
    onStatus?.call('¡Restauración completada!');
  }

  // ── Last backup date ────────────────────────────────────────────────────────

  Future<DateTime?> getLastBackupDate() async {
    try {
      final marker = await _markerFile();
      if (!await marker.exists()) return null;
      final content = await marker.readAsString();
      return DateTime.tryParse(content.trim());
    } catch (_) {
      return null;
    }
  }

  // ── Validation ──────────────────────────────────────────────────────────────

  void _validate(Map<String, dynamic> data) {
    if (data['version'] is! int) {
      throw BackupException(
          'Campo "version" inválido o faltante. ¿Es un archivo de respaldo de BizPulse?');
    }
    for (final key in ['appointments', 'products', 'transactions']) {
      if (data[key] is! List) {
        throw BackupException(
            'Campo "$key" faltante o inválido en el archivo.');
      }
    }
    for (final raw in data['appointments'] as List) {
      final a = raw as Map;
      if (a['clientName'] == null || a['whenMs'] == null) {
        throw BackupException(
            'Turno inválido: falta "clientName" o "whenMs".');
      }
    }
    for (final raw in data['products'] as List) {
      final p = raw as Map;
      for (final f in ['name', 'price', 'stock']) {
        if (p[f] == null) {
          throw BackupException('Producto inválido: falta el campo "$f".');
        }
      }
    }
    for (final raw in data['transactions'] as List) {
      final t = raw as Map;
      for (final f in ['type', 'amount', 'description', 'dateMs']) {
        if (t[f] == null) {
          throw BackupException(
              'Transacción inválida: falta el campo "$f".');
        }
      }
      if (!['income', 'expense'].contains(t['type'])) {
        throw BackupException('Tipo de transacción inválido: "${t['type']}".');
      }
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Recursively converts Firestore types (Timestamp, GeoPoint, etc.)
  /// to JSON-safe primitives.
  Map<String, dynamic> _sanitizeMap(Map<String, dynamic> map) {
    return {for (final e in map.entries) e.key: _sanitize(e.value)};
  }

  dynamic _sanitize(dynamic v) {
    if (v is Timestamp) return v.millisecondsSinceEpoch;
    if (v is Map<String, dynamic>) return _sanitizeMap(v);
    if (v is Map) {
      return {
        for (final e in v.entries) e.key.toString(): _sanitize(e.value)
      };
    }
    if (v is List) return [for (final item in v) _sanitize(item)];
    return v; // String, int, double, bool, null
  }

  /// Strips internal fields and adds a fresh server timestamp.
  Map<String, dynamic> _prepareForWrite(Map<String, dynamic> src) {
    return {
      ...src,
      '_id': null, // remove _id (we don't care about original doc ID)
      'createdAt': FieldValue.serverTimestamp(),
    }..remove('_id');
  }

  List<Map<String, dynamic>> _mapList(List raw) =>
      raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

  /// Batch-delete all documents matching [query].
  Future<void> _deleteQuery(Query<Map<String, dynamic>> query) async {
    QuerySnapshot<Map<String, dynamic>> snap;
    do {
      snap = await query.limit(100).get();
      if (snap.docs.isEmpty) break;
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } while (snap.docs.length >= 100);
  }

  Future<Directory> _getSaveDirectory() async {
    if (Platform.isAndroid) {
      final ext = await getExternalStorageDirectory();
      if (ext != null) return ext;
    }
    return getApplicationDocumentsDirectory();
  }

  Future<File> _markerFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/_last_backup.txt');
  }

  Future<void> _writeLastBackupMarker() async {
    final marker = await _markerFile();
    await marker.writeAsString(DateTime.now().toIso8601String());
  }
}
