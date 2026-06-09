import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' hide DatabaseException;
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/exception.dart';
import '../models/journal_entry_model.dart';

/// Data source lokal untuk berinteraksi langsung dengan database SQLite
/// guna memproses data Catatan Jurnal & Mood Tracker.
class JournalLocalDataSource {
  final DatabaseHelper _dbHelper;

  JournalLocalDataSource(this._dbHelper);

  // In-memory mock data untuk platform web/chrome
  static final List<JournalEntryModel> _webJournalEntries = [];

  /// Menyimpan atau memperbarui Catatan Harian (JournalEntry).
  Future<void> insertOrUpdate(JournalEntryModel entry) async {
    if (kIsWeb) {
      final index = _webJournalEntries.indexWhere((e) => e.date == entry.date);
      if (index != -1) {
        _webJournalEntries[index] = entry;
      } else {
        _webJournalEntries.add(entry);
      }
      return;
    }

    try {
      final db = await _dbHelper.database;
      await db.insert(
        'journal_entries',
        entry.toSqlMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw DatabaseException('Gagal menyimpan catatan harian ke database.', e);
    }
  }

  /// Mengambil Catatan Harian berdasarkan tanggal (YYYY-MM-DD).
  Future<JournalEntryModel?> getByDate(String date) async {
    if (kIsWeb) {
      try {
        return _webJournalEntries.firstWhere((e) => e.date == date);
      } catch (_) {
        return null;
      }
    }

    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'journal_entries',
        where: 'date = ?',
        whereArgs: [date],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return JournalEntryModel.fromSqlMap(maps.first);
    } catch (e) {
      throw DatabaseException('Gagal mengambil catatan harian untuk tanggal $date.', e);
    }
  }

  /// Mengambil seluruh daftar catatan harian, diurutkan berdasarkan tanggal terbaru.
  Future<List<JournalEntryModel>> getAll() async {
    if (kIsWeb) {
      final sorted = List<JournalEntryModel>.from(_webJournalEntries);
      sorted.sort((a, b) => b.date.compareTo(a.date));
      return sorted;
    }

    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'journal_entries',
        orderBy: 'date DESC',
      );

      return maps.map((map) => JournalEntryModel.fromSqlMap(map)).toList();
    } catch (e) {
      throw DatabaseException('Gagal mengambil semua catatan harian.', e);
    }
  }

  /// Menghapus catatan harian berdasarkan ID.
  Future<void> delete(String id) async {
    if (kIsWeb) {
      _webJournalEntries.removeWhere((e) => e.id == id);
      return;
    }

    try {
      final db = await _dbHelper.database;
      final rowsAffected = await db.delete(
        'journal_entries',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rowsAffected == 0) {
        throw DatabaseException('Catatan harian tidak ditemukan untuk dihapus.');
      }
    } catch (e) {
      throw DatabaseException('Gagal menghapus catatan harian.', e);
    }
  }
}
