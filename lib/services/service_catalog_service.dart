import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/service_model.dart';

class ServiceCatalogService {
  static const _dbName = 'bizpulse.db';
  static const _table = 'services';
  static const _version = 1;

  static Database? _db;

  Future<Database> _open() async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    _db = await openDatabase(
      path,
      version: _version,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE $_table (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            durationMinutes INTEGER NOT NULL,
            price REAL NOT NULL,
            category TEXT NOT NULL DEFAULT '',
            isActive INTEGER NOT NULL DEFAULT 1
          )
        ''');
      },
    );
    return _db!;
  }

  Future<List<ServiceModel>> getAll() async {
    final db = await _open();
    final rows = await db.query(_table, orderBy: 'category ASC, name ASC');
    return rows.map(ServiceModel.fromMap).toList();
  }

  Future<List<ServiceModel>> getActive() async {
    final db = await _open();
    final rows = await db.query(
      _table,
      where: 'isActive = 1',
      orderBy: 'category ASC, name ASC',
    );
    return rows.map(ServiceModel.fromMap).toList();
  }

  Future<void> create(ServiceModel s) async {
    final db = await _open();
    await db.insert(_table, s.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(ServiceModel s) async {
    final db = await _open();
    await db.update(_table, s.toMap(), where: 'id = ?', whereArgs: [s.id]);
  }

  Future<void> delete(String id) async {
    final db = await _open();
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
