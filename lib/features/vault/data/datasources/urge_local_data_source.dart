import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/urge_log_model.dart';

/// Data Source lokal untuk mengelola operasi CRUD tabel urge_logs.
class UrgeLocalDataSource {
  final DatabaseHelper _dbHelper;

  UrgeLocalDataSource(this._dbHelper);

  /// Menambahkan log urge baru ke database SQLite.
  Future<void> insertUrgeLog(UrgeLogModel log) async {
    final db = await _dbHelper.database;
    await db.insert(
      'urge_logs',
      log.toSqlMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Mengambil semua log urge dari database diurutkan dari yang terbaru.
  Future<List<UrgeLogModel>> getUrgeLogs() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'urge_logs',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => UrgeLogModel.fromSqlMap(map)).toList();
  }

  /// Memperbarui log urge yang sudah ada.
  Future<void> updateUrgeLog(UrgeLogModel log) async {
    final db = await _dbHelper.database;
    await db.update(
      'urge_logs',
      log.toSqlMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  /// Menghapus log urge berdasarkan ID.
  Future<void> deleteUrgeLog(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'urge_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
