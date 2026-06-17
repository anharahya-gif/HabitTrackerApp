import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/ibadah_log_model.dart';
import '../models/prayer_time_model.dart';

/// Data Source lokal untuk mengelola operasi database Ibadah Hub.
class IbadahLocalDataSource {
  final DatabaseHelper _dbHelper;

  IbadahLocalDataSource(this._dbHelper);

  // ─── PRAYER TIMES SCHEDULES ───────────────────────────────────────────────

  /// Menyimpan jadwal shalat untuk kota dan tanggal tertentu ke database.
  Future<void> insertPrayerTime(PrayerTimeModel model) async {
    final db = await _dbHelper.database;
    await db.insert(
      'prayer_times',
      model.toSqlMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Mengambil jadwal shalat berdasarkan kota dan tanggal.
  Future<PrayerTimeModel?> getPrayerTime(String date, String city) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'prayer_times',
      where: 'date = ? AND city = ?',
      whereArgs: [date, city],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return PrayerTimeModel.fromSqlMap(maps.first);
  }

  // ─── DAILY IBADAH LOGS ────────────────────────────────────────────────────

  /// Menyimpan catatan ibadah baru.
  Future<void> insertIbadahLog(IbadahLogModel log) async {
    final db = await _dbHelper.database;
    await db.insert(
      'ibadah_logs',
      log.toSqlMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Mengambil catatan ibadah berdasarkan tanggal.
  Future<IbadahLogModel?> getIbadahLog(String date) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ibadah_logs',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return IbadahLogModel.fromSqlMap(maps.first);
  }

  /// Mengambil seluruh catatan ibadah untuk keperluan kalkulasi statistik/pencapaian.
  Future<List<IbadahLogModel>> getAllIbadahLogs() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ibadah_logs',
      orderBy: 'date DESC',
    );
    return maps.map((map) => IbadahLogModel.fromSqlMap(map)).toList();
  }

  /// Memperbarui catatan ibadah.
  Future<void> updateIbadahLog(IbadahLogModel log) async {
    final db = await _dbHelper.database;
    await db.update(
      'ibadah_logs',
      log.toSqlMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  // ─── FAVORITE PRayers (DOA) ────────────────────────────────────────────────

  /// Mengambil semua ID doa yang difavoritkan.
  Future<List<String>> getFavoriteDoaIds() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'favorite_doas',
      columns: ['doa_id'],
    );
    return maps.map((map) => map['doa_id'] as String).toList();
  }

  /// Menambahkan doa ke dalam daftar favorit.
  Future<void> addFavoriteDoa(String doaId) async {
    final db = await _dbHelper.database;
    await db.insert(
      'favorite_doas',
      {
        'doa_id': doaId,
        'saved_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Menghapus doa dari daftar favorit.
  Future<void> removeFavoriteDoa(String doaId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'favorite_doas',
      where: 'doa_id = ?',
      whereArgs: [doaId],
    );
  }
}
