import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' hide DatabaseException;
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/exception.dart';
import '../models/habit_model.dart';
import '../models/habit_streak_model.dart';

/// Data source lokal untuk berinteraksi langsung dengan database SQLite
/// guna memproses data Habit dan Streak.
class HabitLocalDataSource {
  final DatabaseHelper _dbHelper;

  HabitLocalDataSource(this._dbHelper);

  // ==========================================
  // IN-MEMORY MOCK DATA UNTUK PLATFORM WEB/CHROME
  // ==========================================
  static final List<HabitModel> _webHabits = [
    HabitModel(
      id: 'mock-1',
      name: 'Olahraga Pagi 🏃‍♂️',
      description: 'Jogging 20 menit di sekitar kompleks',
      category: 'Kebugaran',
      type: 'daily',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      color: 0xFF5AA9FF,
      isSynced: true,
      updatedAt: DateTime.now(),
    ),
    HabitModel(
      id: 'mock-2',
      name: 'Membaca Buku 📚',
      description: 'Membaca minimal 10 halaman buku sains/teknologi',
      category: 'Mental/Pikiran',
      type: 'daily',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      color: 0xFF4ADE80,
      isSynced: true,
      updatedAt: DateTime.now(),
    ),
  ];

  static final List<HabitStreakModel> _webStreaks = [
    HabitStreakModel(
      habitId: 'mock-1',
      currentStreak: 3,
      bestStreak: 7,
      lastCompletedDate: '2026-05-31',
    ),
    HabitStreakModel(
      habitId: 'mock-2',
      currentStreak: 0,
      bestStreak: 2,
    ),
  ];

  /// Menyimpan Habit baru ke database.
  /// Otomatis membuat baris streak awal dengan nilai 0.
  Future<void> insertHabit(HabitModel habit) async {
    if (kIsWeb) {
      _webHabits.add(habit);
      _webStreaks.add(HabitStreakModel(habitId: habit.id));
      return;
    }

    try {
      final db = await _dbHelper.database;
      
      await db.transaction((txn) async {
        // 1. Simpan habit
        await txn.insert(
          'habits',
          habit.toSqlMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // 2. Inisialisasi streak awal kosong
        final streak = HabitStreakModel(habitId: habit.id);
        await txn.insert(
          'habit_streaks',
          streak.toSqlMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      });
    } catch (e) {
      throw DatabaseException('Gagal menyimpan habit baru ke database.', e);
    }
  }

  /// Mengambil seluruh habit yang tidak diarsipkan.
  Future<List<HabitModel>> getAllHabits() async {
    if (kIsWeb) {
      return _webHabits.where((h) => !h.isArchived).toList();
    }

    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'habits',
        where: 'is_archived = ?',
        whereArgs: [0],
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => HabitModel.fromSqlMap(map)).toList();
    } catch (e) {
      throw DatabaseException('Gagal mengambil daftar habit.', e);
    }
  }

  /// Mengambil satu habit berdasarkan ID-nya.
  Future<HabitModel?> getHabitById(String id) async {
    if (kIsWeb) {
      try {
        return _webHabits.firstWhere((h) => h.id == id);
      } catch (_) {
        return null;
      }
    }

    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'habits',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return HabitModel.fromSqlMap(maps.first);
    } catch (e) {
      throw DatabaseException('Gagal mengambil detail habit dengan ID: $id.', e);
    }
  }

  /// Memperbarui data habit.
  Future<void> updateHabit(HabitModel habit) async {
    if (kIsWeb) {
      final index = _webHabits.indexWhere((h) => h.id == habit.id);
      if (index != -1) {
        _webHabits[index] = habit;
      }
      return;
    }

    try {
      final db = await _dbHelper.database;
      final rowsAffected = await db.update(
        'habits',
        habit.toSqlMap(),
        where: 'id = ?',
        whereArgs: [habit.id],
      );
      if (rowsAffected == 0) {
        throw DatabaseException('Habit tidak ditemukan untuk diperbarui.');
      }
    } catch (e) {
      throw DatabaseException('Gagal memperbarui habit.', e);
    }
  }

  /// Menghapus habit permanen berdasarkan ID.
  /// (Mengandalkan ON DELETE CASCADE untuk menghapus log & streak terkait).
  Future<void> deleteHabit(String id) async {
    if (kIsWeb) {
      _webHabits.removeWhere((h) => h.id == id);
      _webStreaks.removeWhere((s) => s.habitId == id);
      return;
    }

    try {
      final db = await _dbHelper.database;
      final rowsAffected = await db.delete(
        'habits',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rowsAffected == 0) {
        throw DatabaseException('Habit tidak ditemukan untuk dihapus.');
      }
    } catch (e) {
      throw DatabaseException('Gagal menghapus habit dari database.', e);
    }
  }

  /// Mengambil daftar habit yang belum tersinkronisasi (is_synced = 0).
  Future<List<HabitModel>> getUnsyncedHabits() async {
    if (kIsWeb) {
      return _webHabits.where((h) => !h.isSynced).toList();
    }

    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'habits',
        where: 'is_synced = ?',
        whereArgs: [0],
      );
      return maps.map((map) => HabitModel.fromSqlMap(map)).toList();
    } catch (e) {
      throw DatabaseException('Gagal mengambil daftar habit yang belum tersinkronisasi.', e);
    }
  }

  /// Menandai status sinkronisasi habit lokal menjadi tersinkronisasi (is_synced = 1).
  Future<void> markHabitAsSynced(String id) async {
    if (kIsWeb) {
      final index = _webHabits.indexWhere((h) => h.id == id);
      if (index != -1) {
        _webHabits[index] = HabitModel.fromEntity(
          _webHabits[index].copyWith(isSynced: true),
        );
      }
      return;
    }

    try {
      final db = await _dbHelper.database;
      await db.update(
        'habits',
        {'is_synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException('Gagal menandai sinkronisasi habit di SQLite.', e);
    }
  }

  /// Mengambil streak saat ini dari database.
  Future<HabitStreakModel?> getHabitStreak(String habitId) async {
    if (kIsWeb) {
      try {
        return _webStreaks.firstWhere((s) => s.habitId == habitId);
      } catch (_) {
        return HabitStreakModel(habitId: habitId);
      }
    }

    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'habit_streaks',
        where: 'habit_id = ?',
        whereArgs: [habitId],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return HabitStreakModel.fromSqlMap(maps.first);
    } catch (e) {
      throw DatabaseException('Gagal mengambil data streak habit.', e);
    }
  }

  /// Memperbarui data streak untuk habit tertentu.
  Future<void> updateHabitStreak(HabitStreakModel streak) async {
    if (kIsWeb) {
      final index = _webStreaks.indexWhere((s) => s.habitId == streak.habitId);
      if (index != -1) {
        _webStreaks[index] = streak;
      } else {
        _webStreaks.add(streak);
      }
      return;
    }

    try {
      final db = await _dbHelper.database;
      await db.update(
        'habit_streaks',
        streak.toSqlMap(),
        where: 'habit_id = ?',
        whereArgs: [streak.habitId],
      );
    } catch (e) {
      throw DatabaseException('Gagal memperbarui data streak.', e);
    }
  }
}
