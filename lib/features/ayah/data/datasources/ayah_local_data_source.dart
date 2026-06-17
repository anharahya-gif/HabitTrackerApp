import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/daily_ayah_model.dart';

class AyahLocalDataSource {
  final DatabaseHelper _dbHelper;

  AyahLocalDataSource(this._dbHelper);

  // ─── DAILY AYAH CACHE ─────────────────────────────────────────────────────

  /// Menyimpan Ayat Hari Ini ke database lokal (cache harian).
  Future<void> insertDailyAyah(DailyAyahModel model) async {
    final db = await _dbHelper.database;
    await db.insert(
      'daily_ayah',
      model.toSqlMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Mengambil cache Ayat Hari Ini berdasarkan tanggal.
  Future<DailyAyahModel?> getDailyAyah(String date) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_ayah',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return DailyAyahModel.fromSqlMap(maps.first);
  }

  // ─── FAVORITE AYAHS ───────────────────────────────────────────────────────

  /// Menyimpan ayat ke daftar favorit.
  Future<void> insertFavoriteAyah(DailyAyahModel model) async {
    final db = await _dbHelper.database;
    final Map<String, dynamic> row = {
      'id': '${model.surahNumber}:${model.ayahNumber}',
      'surah_number': model.surahNumber,
      'ayah_number': model.ayahNumber,
      'surah_name': model.surahName,
      'arabic_text': model.arabicText,
      'translation': model.translation,
      'audio_url': model.audioUrl,
      'tajwid_json': model.toSqlMap()['tajwid_json'], // reuse serialization
      'saved_at': DateTime.now().toIso8601String(),
    };
    await db.insert(
      'favorite_ayahs',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Mengambil semua ayat terfavorit.
  Future<List<DailyAyahModel>> getFavoriteAyahs() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'favorite_ayahs',
      orderBy: 'saved_at DESC',
    );
    return maps.map((map) {
      return DailyAyahModel(
        id: map['id'] as String,
        date: '', // Favorit tidak terikat tanggal
        surahNumber: map['surah_number'] as int,
        ayahNumber: map['ayah_number'] as int,
        surahName: map['surah_name'] as String,
        arabicText: map['arabic_text'] as String,
        translation: map['translation'] as String,
        audioUrl: map['audio_url'] as String?,
        // Parse kembali tajwid list
        tajwidOccurrences: DailyAyahModel.fromSqlMap({
          'id': map['id'],
          'date': '',
          'surah_number': map['surah_number'],
          'ayah_number': map['ayah_number'],
          'surah_name': map['surah_name'],
          'arabic_text': map['arabic_text'],
          'translation': map['translation'],
          'audio_url': map['audio_url'],
          'tajwid_json': map['tajwid_json'],
          'created_at': DateTime.now().toIso8601String(),
        }).tajwidOccurrences,
        createdAt: DateTime.parse(map['saved_at'] as String),
      );
    }).toList();
  }

  /// Menghapus ayat dari daftar favorit.
  Future<void> deleteFavoriteAyah(int surahNumber, int ayahNumber) async {
    final db = await _dbHelper.database;
    await db.delete(
      'favorite_ayahs',
      where: 'surah_number = ? AND ayah_number = ?',
      whereArgs: [surahNumber, ayahNumber],
    );
  }

  /// Mengecek apakah suatu ayat terfavorit.
  Future<bool> isFavoriteAyah(int surahNumber, int ayahNumber) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'favorite_ayahs',
      where: 'surah_number = ? AND ayah_number = ?',
      whereArgs: [surahNumber, ayahNumber],
      limit: 1,
    );
    return maps.isNotEmpty;
  }
}
