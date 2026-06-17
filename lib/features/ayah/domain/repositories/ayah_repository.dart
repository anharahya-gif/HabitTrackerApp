import '../entities/daily_ayah.dart';

abstract class AyahRepository {
  /// Mengambil data Ayat Hari Ini (cache-first dengan remote fetch & offline fallback).
  ///
  /// [date] — tanggal harian dalam format YYYY-MM-DD
  Future<DailyAyah> getDailyAyah(String date);

  /// Mengambil semua ayat favorit.
  Future<List<DailyAyah>> getFavoriteAyahs();

  /// Menambah atau menghapus ayat dari daftar favorit.
  Future<void> toggleFavoriteAyah(DailyAyah ayah, bool isFav);

  /// Mengecek apakah suatu ayat terfavorit.
  Future<bool> isFavoriteAyah(int surahNumber, int ayahNumber);
}
