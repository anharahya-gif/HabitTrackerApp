import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

/// Service untuk menangani ekspor database SQLite lengkap ke format JSON
/// dan melakukan impor restorasi secara transaksional dan aman.
class BackupService {
  final DatabaseHelper _dbHelper;

  BackupService({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Mengekspor seluruh tabel database SQLite ke struktur Map JSON tunggal
  Future<Map<String, dynamic>> exportBackup() async {
    final db = await _dbHelper.database;

    final habits = await db.query('habits');
    final habitLogs = await db.query('habit_logs');
    final habitStreaks = await db.query('habit_streaks');
    final tasks = await db.query('tasks');
    final journalEntries = await db.query('journal_entries');

    return {
      'app': 'Dailio',
      'version': 2, // Versi backup disesuaikan dengan DB versi 8
      'backup_date': DateTime.now().toIso8601String(),
      'data': {
        'habits': habits,
        'habit_logs': habitLogs,
        'habit_streaks': habitStreaks,
        'tasks': tasks,
        'journal_entries': journalEntries,
      }
    };
  }

  /// Memulihkan database dari JSON secara transaksional (hapus & insert ulang)
  Future<void> importBackup(Map<String, dynamic> backupJson) async {
    // 1. Validasi struktur JSON dasar
    if (backupJson['app'] != 'Dailio' || backupJson['data'] == null) {
      throw Exception('Berkas cadangan tidak valid atau bukan buatan Dailio.');
    }

    final data = backupJson['data'] as Map<String, dynamic>;
    final habits = data['habits'] as List? ?? [];
    final habitLogs = data['habit_logs'] as List? ?? [];
    final habitStreaks = data['habit_streaks'] as List? ?? [];
    final tasks = data['tasks'] as List? ?? [];
    final journalEntries = data['journal_entries'] as List? ?? [];

    final db = await _dbHelper.database;

    // 2. Jalankan pembersihan dan restorasi transaksional
    await db.transaction((txn) async {
      // Hapus tabel dengan relasi foreign key terlebih dahulu
      await txn.delete('journal_entries');
      await txn.delete('tasks');
      await txn.delete('habit_streaks');
      await txn.delete('habit_logs');
      await txn.delete('habits');

      // Masukkan kembali record baru dari JSON
      for (final h in habits) {
        await txn.insert('habits', Map<String, dynamic>.from(h), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final l in habitLogs) {
        await txn.insert('habit_logs', Map<String, dynamic>.from(l), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final s in habitStreaks) {
        await txn.insert('habit_streaks', Map<String, dynamic>.from(s), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final t in tasks) {
        await txn.insert('tasks', Map<String, dynamic>.from(t), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final j in journalEntries) {
        await txn.insert('journal_entries', Map<String, dynamic>.from(j), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }
}
