import 'package:flutter/foundation.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/exception.dart';
import '../models/habit_log_model.dart';

/// Data source lokal untuk berinteraksi langsung dengan database SQLite
/// guna memproses log harian.
class TrackingLocalDataSource {
  final DatabaseHelper _dbHelper;

  TrackingLocalDataSource(this._dbHelper);

  // ==========================================
  // IN-MEMORY MOCK LOGS UNTUK PLATFORM WEB/CHROME
  // ==========================================
  static final List<HabitLogModel> _webLogs = [
    // Logs Olahraga Pagi (Streak 3 hari berturut-turut)
    HabitLogModel(
      id: 'mock-1_2026-05-31',
      habitId: 'mock-1',
      date: '2026-05-31',
      status: 'done',
      completedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    HabitLogModel(
      id: 'mock-1_2026-05-30',
      habitId: 'mock-1',
      date: '2026-05-30',
      status: 'done',
      completedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    HabitLogModel(
      id: 'mock-1_2026-05-29',
      habitId: 'mock-1',
      date: '2026-05-29',
      status: 'done',
      completedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),

    // Logs Membaca Buku (Kemarin skip, 2 hari lalu done)
    HabitLogModel(
      id: 'mock-2_2026-05-31',
      habitId: 'mock-2',
      date: '2026-05-31',
      status: 'skipped',
    ),
    HabitLogModel(
      id: 'mock-2_2026-05-30',
      habitId: 'mock-2',
      date: '2026-05-30',
      status: 'done',
      completedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  /// Menyimpan atau memperbarui log harian ke database.
  /// Jika pada tanggal dan habit tersebut log sudah ada, maka status akan diperbarui.
  Future<void> insertOrUpdateLog(HabitLogModel log) async {
    if (kIsWeb) {
      final index = _webLogs.indexWhere(
        (l) => l.habitId == log.habitId && l.date == log.date,
      );

      if (index == -1) {
        _webLogs.add(log);
      } else {
        _webLogs[index] = log;
      }
      return;
    }

    try {
      final db = await _dbHelper.database;
      
      // Cek terlebih dahulu apakah log untuk habit_id dan date ini sudah ada
      final List<Map<String, dynamic>> existing = await db.query(
        'habit_logs',
        where: 'habit_id = ? AND date = ?',
        whereArgs: [log.habitId, log.date],
        limit: 1,
      );

      if (existing.isEmpty) {
        // Jika belum ada, masukkan data baru
        await db.insert('habit_logs', log.toSqlMap());
      } else {
        // Jika sudah ada, lakukan update
        await db.update(
          'habit_logs',
          {
            'status': log.status,
            'completed_at': log.completedAt?.toIso8601String(),
          },
          where: 'habit_id = ? AND date = ?',
          whereArgs: [log.habitId, log.date],
        );
      }
    } catch (e) {
      throw DatabaseException('Gagal menyimpan log harian ke SQLite.', e);
    }
  }

  /// Mendapatkan seluruh histori log untuk habit tertentu, diurutkan berdasarkan tanggal terbaru.
  Future<List<HabitLogModel>> getLogsForHabit(String habitId) async {
    if (kIsWeb) {
      final list = _webLogs.where((l) => l.habitId == habitId).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    }

    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'habit_logs',
        where: 'habit_id = ?',
        whereArgs: [habitId],
        orderBy: 'date DESC',
      );

      return maps.map((map) => HabitLogModel.fromSqlMap(map)).toList();
    } catch (e) {
      throw DatabaseException('Gagal mengambil daftar log habit.', e);
    }
  }

  /// Mendapatkan log habit pada tanggal tertentu.
  Future<HabitLogModel?> getLogForHabitAndDate(String habitId, String date) async {
    if (kIsWeb) {
      try {
        return _webLogs.firstWhere((l) => l.habitId == habitId && l.date == date);
      } catch (_) {
        return null;
      }
    }

    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'habit_logs',
        where: 'habit_id = ? AND date = ?',
        whereArgs: [habitId, date],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return HabitLogModel.fromSqlMap(maps.first);
    } catch (e) {
      throw DatabaseException('Gagal mengambil log habit pada tanggal tersebut.', e);
    }
  }

  /// Menghapus log harian tertentu berdasarkan ID-nya.
  Future<void> deleteLog(String id) async {
    if (kIsWeb) {
      _webLogs.removeWhere((l) => l.id == id);
      return;
    }

    try {
      final db = await _dbHelper.database;
      final rowsAffected = await db.delete(
        'habit_logs',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rowsAffected == 0) {
        throw DatabaseException('Log harian tidak ditemukan untuk dihapus.');
      }
    } catch (e) {
      throw DatabaseException('Gagal menghapus log harian.', e);
    }
  }
}
