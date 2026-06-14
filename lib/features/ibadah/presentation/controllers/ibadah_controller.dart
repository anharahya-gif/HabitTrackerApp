import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/providers.dart';
import '../../../../core/database/database_helper.dart';
import '../../../dashboard/presentation/controllers/gamification_controller.dart';
import '../../data/datasources/ibadah_local_data_source.dart';
import '../../data/models/ibadah_log_model.dart';
import '../../data/models/prayer_time_model.dart';
import '../../domain/entities/ibadah_log.dart';
import '../../domain/entities/prayer_time.dart';

/// State lengkap untuk fitur Ibadah Hub
class IbadahState {
  final String selectedDate; // format YYYY-MM-DD
  final String city;
  final PrayerTime? prayerTime;
  final IbadahLog? ibadahLog;
  final List<IbadahLog> allLogs;
  final String errorMessage;
  final bool isLoading;

  IbadahState({
    required this.selectedDate,
    this.city = 'Jakarta',
    this.prayerTime,
    this.ibadahLog,
    this.allLogs = const [],
    this.errorMessage = '',
    this.isLoading = false,
  });

  IbadahState copyWith({
    String? selectedDate,
    String? city,
    PrayerTime? prayerTime,
    IbadahLog? ibadahLog,
    List<IbadahLog>? allLogs,
    String? errorMessage,
    bool? isLoading,
  }) {
    return IbadahState(
      selectedDate: selectedDate ?? this.selectedDate,
      city: city ?? this.city,
      prayerTime: prayerTime ?? this.prayerTime,
      ibadahLog: ibadahLog ?? this.ibadahLog,
      allLogs: allLogs ?? this.allLogs,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Provider lokal untuk IbadahLocalDataSource
final ibadahLocalDataSourceProvider = Provider<IbadahLocalDataSource>((ref) {
  return IbadahLocalDataSource(DatabaseHelper.instance);
});

/// Controller reaktif global Ibadah Hub
class IbadahController extends StateNotifier<IbadahState> {
  final Ref _ref;
  final IbadahLocalDataSource _localDataSource;

  IbadahController(this._ref, this._localDataSource)
      : super(IbadahState(selectedDate: DateFormatter.todayString)) {
    _init();
  }

  /// Inisialisasi awal: Muat nama kota dari SharedPreferences dan load data hari ini
  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    final prefs = _ref.read(sharedPreferencesProvider);
    final savedCity = prefs.getString('ibadah_city') ?? 'Jakarta';
    
    state = state.copyWith(city: savedCity);
    await loadDataForDate(state.selectedDate, savedCity);
  }

  /// Mengubah tanggal yang dipilih
  Future<void> setSelectedDate(String dateStr) async {
    state = state.copyWith(selectedDate: dateStr, isLoading: true);
    await loadDataForDate(dateStr, state.city);
  }

  /// Mengubah kota pilihan pengguna untuk jadwal shalat
  Future<void> changeCity(String newCity) async {
    final cleanedCity = newCity.trim();
    if (cleanedCity.isEmpty) return;

    state = state.copyWith(city: cleanedCity, isLoading: true);
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.setString('ibadah_city', cleanedCity);

    await loadDataForDate(state.selectedDate, cleanedCity);
  }

  /// Memuat jadwal shalat dan log ibadah untuk tanggal dan kota tertentu
  Future<void> loadDataForDate(String dateStr, String city) async {
    try {
      // 1. Muat logs harian dari database lokal
      IbadahLog? log = await _localDataSource.getIbadahLog(dateStr);
      if (log == null) {
        // Buat log kosong baru jika belum pernah dicatat
        final newLog = IbadahLogModel(
          id: const Uuid().v4(),
          date: dateStr,
          updatedAt: DateTime.now(),
        );
        await _localDataSource.insertIbadahLog(newLog);
        log = newLog.toEntity();
      }

      // 2. Muat seluruh logs untuk kalkulasi statistik
      final allLogs = await _localDataSource.getAllIbadahLogs();

      // 3. Muat jadwal shalat dari database lokal
      PrayerTime? prayerTime = await _localDataSource.getPrayerTime(dateStr, city);

      state = state.copyWith(
        selectedDate: dateStr,
        city: city,
        ibadahLog: log,
        allLogs: allLogs,
        prayerTime: prayerTime,
        errorMessage: '',
        isLoading: false,
      );

      // 4. Jika jadwal shalat tidak ada di SQLite lokal, coba fetch dari API
      if (prayerTime == null) {
        await fetchPrayerTimesFromApi(dateStr, city);
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Gagal memuat data: $e',
        isLoading: false,
      );
    }
  }

  /// Mengambil jadwal shalat dari API Aladhan dan menyimpannya di SQLite
  Future<void> fetchPrayerTimesFromApi(String dateStr, String city) async {
    try {
      // Format tanggal ke DD-MM-YYYY untuk Aladhan API
      final parsedDate = DateTime.parse(dateStr);
      final day = parsedDate.day.toString().padLeft(2, '0');
      final month = parsedDate.month.toString().padLeft(2, '0');
      final year = parsedDate.year;
      final apiDateStr = '$day-$month-$year';

      final url = Uri.parse(
          'https://api.aladhan.com/v1/timingsByCity/$apiDateStr?city=${Uri.encodeComponent(city)}&country=Indonesia&method=20');

      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['code'] == 200 && jsonResponse['data'] != null) {
          final timings = jsonResponse['data']['timings'];
          
          final model = PrayerTimeModel.fromApiMap(timings, dateStr, city);
          await _localDataSource.insertPrayerTime(model);

          // Cek apakah tanggal yang sedang dipilih masih sama untuk menghindari race condition
          if (state.selectedDate == dateStr && state.city == city) {
            state = state.copyWith(
              prayerTime: model.toEntity(),
              errorMessage: '',
            );
          }
        } else {
          state = state.copyWith(
            errorMessage: 'Format respon API Jadwal Shalat tidak valid.',
          );
        }
      } else {
        state = state.copyWith(
          errorMessage: 'Server waktu shalat merespon dengan kode: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Offline / error koneksi: biarkan tetap kosong tanpa crash. UI akan menampilkan Empty State yang informatif.
      state = state.copyWith(
        errorMessage: 'Gagal mengunduh jadwal shalat online (Mode Offline).',
      );
    }
  }

  // ─── ACTION HANDLERS ──────────────────────────────────────────────────────

  /// Memperbarui status shalat fardhu (Subuh, Dzuhur, Ashar, Maghrib, Isya)
  Future<void> updatePrayerStatus(String prayerName, String newStatus) async {
    final log = state.ibadahLog;
    if (log == null) return;

    // Ambil status lama
    String oldStatus = 'belum';
    switch (prayerName.toLowerCase()) {
      case 'subuh': oldStatus = log.subuh; break;
      case 'dzuhur': oldStatus = log.dzuhur; break;
      case 'ashar': oldStatus = log.ashar; break;
      case 'maghrib': oldStatus = log.maghrib; break;
      case 'isya': oldStatus = log.isya; break;
    }

    if (oldStatus == newStatus) return;

    // Buat objek log baru yang dimodifikasi
    IbadahLog updatedLog = log;
    switch (prayerName.toLowerCase()) {
      case 'subuh': updatedLog = log.copyWith(subuh: newStatus, updatedAt: DateTime.now()); break;
      case 'dzuhur': updatedLog = log.copyWith(dzuhur: newStatus, updatedAt: DateTime.now()); break;
      case 'ashar': updatedLog = log.copyWith(ashar: newStatus, updatedAt: DateTime.now()); break;
      case 'maghrib': updatedLog = log.copyWith(maghrib: newStatus, updatedAt: DateTime.now()); break;
      case 'isya': updatedLog = log.copyWith(isya: newStatus, updatedAt: DateTime.now()); break;
    }

    // Hitung perubahan XP
    int getXp(String status) {
      if (status == 'munfarid') return 5;
      if (status == 'berjamaah') return 10;
      return 0; // 'belum', 'qadha', 'terlewat'
    }

    final int oldXp = getXp(oldStatus);
    final int newXp = getXp(newStatus);
    final int xpDiff = newXp - oldXp;

    final gameController = _ref.read(gamificationProvider.notifier);
    if (xpDiff > 0) {
      await gameController.addXp(xpDiff);
    } else if (xpDiff < 0) {
      await gameController.deductXp(-xpDiff);
    }

    // Jika shalat diselesaikan (Berjamaah/Munfarid) dan sebelumnya belum selesai, siram tanaman
    final bool oldCompleted = oldStatus == 'berjamaah' || oldStatus == 'munfarid';
    final bool newCompleted = newStatus == 'berjamaah' || newStatus == 'munfarid';
    if (newCompleted && !oldCompleted) {
      await gameController.waterPlant();
    }

    // Simpan ke SQLite lokal
    final model = IbadahLogModel.fromEntity(updatedLog);
    await _localDataSource.updateIbadahLog(model);

    // Refresh state
    final allLogs = await _localDataSource.getAllIbadahLogs();
    state = state.copyWith(
      ibadahLog: updatedLog,
      allLogs: allLogs,
    );
  }

  /// Memperbarui jumlah halaman bacaan Quran harian
  Future<void> updateQuranPages(int newPages) async {
    final log = state.ibadahLog;
    if (log == null) return;

    final int oldPages = log.quranPages;
    if (oldPages == newPages) return;

    // Hitung perubahan XP (+2 XP per halaman)
    final int oldXp = oldPages * 2;
    final int newXp = newPages * 2;
    final int xpDiff = newXp - oldXp;

    final gameController = _ref.read(gamificationProvider.notifier);
    if (xpDiff > 0) {
      await gameController.addXp(xpDiff);
    } else if (xpDiff < 0) {
      await gameController.deductXp(-xpDiff);
    }

    IbadahLog updatedLog = log.copyWith(quranPages: newPages, updatedAt: DateTime.now());
    final model = IbadahLogModel.fromEntity(updatedLog);
    await _localDataSource.updateIbadahLog(model);

    final allLogs = await _localDataSource.getAllIbadahLogs();
    state = state.copyWith(
      ibadahLog: updatedLog,
      allLogs: allLogs,
    );
  }

  /// Memperbarui jumlah ketukan dzikir (Tasbih digital) harian
  Future<void> updateDhikrCount(int newCount) async {
    final log = state.ibadahLog;
    if (log == null) return;

    final int oldCount = log.dhikrCount;
    if (oldCount == newCount) return;

    // Hitung perubahan XP (+1 XP setiap kelipatan 10)
    final int oldInterval = oldCount ~/ 10;
    final int newInterval = newCount ~/ 10;
    final int xpDiff = newInterval - oldInterval;

    final gameController = _ref.read(gamificationProvider.notifier);
    if (xpDiff > 0) {
      await gameController.addXp(xpDiff * 1);
    } else if (xpDiff < 0) {
      await gameController.deductXp(-xpDiff * 1);
    }

    IbadahLog updatedLog = log.copyWith(dhikrCount: newCount, updatedAt: DateTime.now());
    final model = IbadahLogModel.fromEntity(updatedLog);
    await _localDataSource.updateIbadahLog(model);

    final allLogs = await _localDataSource.getAllIbadahLogs();
    state = state.copyWith(
      ibadahLog: updatedLog,
      allLogs: allLogs,
    );
  }

  /// Men-toggle status amalan sunnah (Duha, Tahajjud, Sedekah)
  Future<void> toggleSunnah(String sunnahType) async {
    final log = state.ibadahLog;
    if (log == null) return;

    int oldVal = 0;
    int xpReward = 10; // default Duha & Sedekah: +10 XP
    if (sunnahType.toLowerCase() == 'tahajjud') xpReward = 15; // Tahajjud: +15 XP

    IbadahLog updatedLog = log;
    switch (sunnahType.toLowerCase()) {
      case 'duha':
        oldVal = log.duha;
        final newVal = oldVal == 1 ? 0 : 1;
        updatedLog = log.copyWith(duha: newVal, updatedAt: DateTime.now());
        break;
      case 'tahajjud':
        oldVal = log.tahajjud;
        final newVal = oldVal == 1 ? 0 : 1;
        updatedLog = log.copyWith(tahajjud: newVal, updatedAt: DateTime.now());
        break;
      case 'sedekah':
        oldVal = log.sedekah;
        final newVal = oldVal == 1 ? 0 : 1;
        updatedLog = log.copyWith(sedekah: newVal, updatedAt: DateTime.now());
        break;
    }

    // Hitung perubahan XP
    final bool isToggledOn = oldVal == 0;
    final int xpDiff = isToggledOn ? xpReward : -xpReward;

    final gameController = _ref.read(gamificationProvider.notifier);
    if (xpDiff > 0) {
      await gameController.addXp(xpDiff);
    } else if (xpDiff < 0) {
      await gameController.deductXp(-xpDiff);
    }

    final model = IbadahLogModel.fromEntity(updatedLog);
    await _localDataSource.updateIbadahLog(model);

    final allLogs = await _localDataSource.getAllIbadahLogs();
    state = state.copyWith(
      ibadahLog: updatedLog,
      allLogs: allLogs,
    );
  }
}

/// Provider reaktif global untuk Ibadah Controller
final ibadahControllerProvider =
    StateNotifierProvider<IbadahController, IbadahState>((ref) {
  final localDataSource = ref.watch(ibadahLocalDataSourceProvider);
  return IbadahController(ref, localDataSource);
});
