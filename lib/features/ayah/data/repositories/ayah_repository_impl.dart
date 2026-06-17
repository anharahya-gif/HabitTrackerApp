import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/daily_ayah.dart';
import '../../domain/repositories/ayah_repository.dart';
import '../constants/curated_ayahs.dart';
import '../datasources/ayah_local_data_source.dart';
import '../datasources/ayah_remote_data_source.dart';
import '../models/daily_ayah_model.dart';

class AyahRepositoryImpl implements AyahRepository {
  final AyahLocalDataSource _localDataSource;
  final AyahRemoteDataSource _remoteDataSource;

  AyahRepositoryImpl(this._localDataSource, this._remoteDataSource);

  @override
  Future<DailyAyah> getDailyAyah(String date) async {
    // 1. Coba baca dari cache lokal SQLite
    try {
      final cached = await _localDataSource.getDailyAyah(date);
      if (cached != null) {
        debugPrint('AyahRepository: Cache hit untuk tanggal $date');
        return cached;
      }
    } catch (e) {
      debugPrint('AyahRepository: Gagal membaca cache SQLite - $e');
    }

    // 2. Cache miss -> Hitung secara deterministik ayat kurasi hari ini
    // Menggunakan parsing tanggal untuk menghitung index deterministik
    int index = 0;
    try {
      final parsedDate = DateTime.parse(date);
      // Gunakan representasi hari sejak epoch agar konsisten di seluruh zona waktu
      final daysSinceEpoch = parsedDate.millisecondsSinceEpoch ~/ (1000 * 60 * 60 * 24);
      index = daysSinceEpoch % curatedAyahsList.length;
    } catch (_) {
      // Fallback acak berbasis hash string tanggal
      index = date.hashCode.abs() % curatedAyahsList.length;
    }

    final curated = curatedAyahsList[index];

    // 3. Tentukan apakah online dan coba fetch dari API
    bool isOnline = false;
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      isOnline = connectivityResult != ConnectivityResult.none;
    } catch (_) {
      isOnline = true; // default coba konek jika checkConnectivity bermasalah
    }

    if (isOnline) {
      try {
        debugPrint('AyahRepository: Cache miss. Mengambil dari API untuk $date: ${curated.surahNumber}:${curated.ayahNumber}');
        final remoteModel = await _remoteDataSource.fetchAyah(
          curated.surahNumber,
          curated.ayahNumber,
          date,
          curated.surahName,
          curated.tajwidList,
        );

        // Simpan hasil fetch ke cache SQLite
        await _localDataSource.insertDailyAyah(remoteModel);
        return remoteModel;
      } catch (e) {
        debugPrint('AyahRepository: Gagal mengambil dari API, menggunakan data luring fallback. Error: $e');
      }
    } else {
      debugPrint('AyahRepository: Perangkat offline. Menggunakan data luring fallback untuk $date.');
    }

    // 4. Fallback Luring: Gunakan data statis pre-bundled dan simpan di cache SQLite agar pemanggilan berikutnya instan
    final fallbackModel = DailyAyahModel(
      id: date,
      date: date,
      surahNumber: curated.surahNumber,
      ayahNumber: curated.ayahNumber,
      surahName: curated.surahName,
      arabicText: curated.arabicText,
      translation: curated.translation,
      audioUrl: curated.audioUrl,
      tajwidOccurrences: curated.tajwidList,
      createdAt: DateTime.now(),
    );

    try {
      await _localDataSource.insertDailyAyah(fallbackModel);
    } catch (e) {
      debugPrint('AyahRepository: Gagal menyimpan fallback model ke SQLite - $e');
    }

    return fallbackModel;
  }

  @override
  Future<List<DailyAyah>> getFavoriteAyahs() async {
    final list = await _localDataSource.getFavoriteAyahs();
    return list.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> toggleFavoriteAyah(DailyAyah ayah, bool isFav) async {
    final model = DailyAyahModel.fromEntity(ayah);
    if (isFav) {
      await _localDataSource.insertFavoriteAyah(model);
    } else {
      await _localDataSource.deleteFavoriteAyah(ayah.surahNumber, ayah.ayahNumber);
    }
  }

  @override
  Future<bool> isFavoriteAyah(int surahNumber, int ayahNumber) async {
    return await _localDataSource.isFavoriteAyah(surahNumber, ayahNumber);
  }
}
