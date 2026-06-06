import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/providers.dart';
import '../../../tracking/domain/entities/habit_log.dart';

/// State gamifikasi untuk Dailio
class GamificationState {
  final int xp;
  final int level;
  final int plantStage; // -1: Mati, 0: Benih, 1: Kecambah, 2: Bibit, 3: Dewasa, 4: Berbunga/Berbuah
  final double plantProgress; // 0.0 s/d 1.0 untuk ke fase berikutnya
  final int wiltDays; // Hari layu berturut-turut (0 s/d 3)
  final String lastWateredDate; // Tanggal terakhir tanaman disiram ('YYYY-MM-DD')
  final String lastDecayCheckDate; // Tanggal terakhir pengecekan kelayuan harian
  final String plantType; // Jenis tanaman
  final bool showLevelUpDialog; // Bendera untuk dialog Level Up
  final int previousLevel; // Level sebelum naik (untuk dialog)

  const GamificationState({
    required this.xp,
    required this.level,
    required this.plantStage,
    required this.plantProgress,
    required this.wiltDays,
    required this.lastWateredDate,
    required this.lastDecayCheckDate,
    required this.plantType,
    this.showLevelUpDialog = false,
    this.previousLevel = 1,
  });

  factory GamificationState.initial() {
    final today = DateFormatter.todayString;
    return GamificationState(
      xp: 0,
      level: 1,
      plantStage: 0, // Mulai dari Benih (🫘)
      plantProgress: 0.0,
      wiltDays: 0,
      lastWateredDate: '',
      lastDecayCheckDate: today,
      plantType: 'Bunga Matahari',
      showLevelUpDialog: false,
      previousLevel: 1,
    );
  }

  GamificationState copyWith({
    int? xp,
    int? level,
    int? plantStage,
    double? plantProgress,
    int? wiltDays,
    String? lastWateredDate,
    String? lastDecayCheckDate,
    String? plantType,
    bool? showLevelUpDialog,
    int? previousLevel,
  }) {
    return GamificationState(
      xp: xp ?? this.xp,
      level: level ?? this.level,
      plantStage: plantStage ?? this.plantStage,
      plantProgress: plantProgress ?? this.plantProgress,
      wiltDays: wiltDays ?? this.wiltDays,
      lastWateredDate: lastWateredDate ?? this.lastWateredDate,
      lastDecayCheckDate: lastDecayCheckDate ?? this.lastDecayCheckDate,
      plantType: plantType ?? this.plantType,
      showLevelUpDialog: showLevelUpDialog ?? this.showLevelUpDialog,
      previousLevel: previousLevel ?? this.previousLevel,
    );
  }
}

/// Controller untuk mengelola statistik leveling dan Dailio Garden secara reaktif.
class GamificationController extends StateNotifier<GamificationState> {
  final Ref _ref;

  GamificationController(this._ref) : super(GamificationState.initial()) {
    _loadFromPrefs();
  }

  /// Memuat status dari SharedPreferences
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final today = DateFormatter.todayString;
      final loadedState = GamificationState(
        xp: prefs.getInt('gamification_xp') ?? 0,
        level: prefs.getInt('gamification_level') ?? 1,
        plantStage: prefs.getInt('garden_plant_stage') ?? 0,
        plantProgress: prefs.getDouble('garden_plant_progress') ?? 0.0,
        wiltDays: prefs.getInt('garden_wilt_days') ?? 0,
        lastWateredDate: prefs.getString('garden_last_watered_date') ?? '',
        lastDecayCheckDate: prefs.getString('garden_last_decay_date') ?? today,
        plantType: prefs.getString('garden_plant_type') ?? 'Bunga Matahari',
        showLevelUpDialog: false,
        previousLevel: prefs.getInt('gamification_level') ?? 1,
      );

      state = loadedState;

      // Jalankan cek kelayuan setelah data termuat
      Future.microtask(() => checkDailyDecay());
    } catch (e) {
      debugPrint('GamificationController: Gagal memuat status: $e');
    }
  }

  /// Menyimpan status ke SharedPreferences
  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('gamification_xp', state.xp);
      await prefs.setInt('gamification_level', state.level);
      await prefs.setInt('garden_plant_stage', state.plantStage);
      await prefs.setDouble('garden_plant_progress', state.plantProgress);
      await prefs.setInt('garden_wilt_days', state.wiltDays);
      await prefs.setString('garden_last_watered_date', state.lastWateredDate);
      await prefs.setString('garden_last_decay_date', state.lastDecayCheckDate);
      await prefs.setString('garden_plant_type', state.plantType);
    } catch (e) {
      debugPrint('GamificationController: Gagal menyimpan status: $e');
    }
  }

  /// Menambah XP pengguna
  Future<void> addXp(int amount) async {
    int newXp = state.xp + amount;
    if (newXp < 0) newXp = 0;

    int newLevel = state.level;
    bool leveledUp = false;

    // Naik level jika XP melewati batas: Level * 100
    while (newXp >= newLevel * 100) {
      newXp -= newLevel * 100;
      newLevel++;
      leveledUp = true;
    }

    state = state.copyWith(
      xp: newXp,
      level: newLevel,
      showLevelUpDialog: leveledUp ? true : state.showLevelUpDialog,
      previousLevel: leveledUp ? state.level : state.previousLevel,
    );

    await _saveToPrefs();
  }

  /// Mengurangi XP pengguna (misal saat centang dibatalkan)
  Future<void> deductXp(int amount) async {
    int newXp = state.xp - amount;
    int newLevel = state.level;

    if (newXp < 0) {
      if (newLevel > 1) {
        newLevel--;
        newXp = (newLevel * 100) + newXp; // Konversi sisa negatif menjadi XP level sebelumnya
        if (newXp < 0) newXp = 0;
      } else {
        newXp = 0;
      }
    }

    state = state.copyWith(
      xp: newXp,
      level: newLevel,
    );

    await _saveToPrefs();
  }

  /// Menghilangkan dialog Level Up
  void dismissLevelUpDialog() {
    state = state.copyWith(showLevelUpDialog: false);
  }

  /// Menyiram tanaman harian (dipicu saat habit dicentang)
  Future<void> waterPlant() async {
    // Jika tanaman mati, tidak bisa disiram
    if (state.plantStage == -1) return;

    final today = DateFormatter.todayString;
    final bool isAlreadyWateredToday = state.lastWateredDate == today;

    // Update tanggal penyiraman dan reset wilt
    String nextWateredDate = today;
    int nextWiltDays = 0;

    // Jika sudah disiram hari ini, kita batasi progres tumbuh agar tidak terlalu cepat tumbuh dalam 1 hari
    double growthIncrement = isAlreadyWateredToday ? 0.03 : 0.15; // 15% untuk penyiraman pertama, 3% untuk berikutnya

    double newProgress = state.plantProgress + growthIncrement;
    int newStage = state.plantStage;

    if (newProgress >= 1.0) {
      if (newStage < 4) {
        newStage++;
        newProgress = 0.0;
      } else {
        newProgress = 1.0; // Maksimum di fase 4 (Berbunga)
      }
    }

    state = state.copyWith(
      lastWateredDate: nextWateredDate,
      wiltDays: nextWiltDays,
      plantProgress: newProgress,
      plantStage: newStage,
    );

    await _saveToPrefs();
  }

  /// Memeriksa kelayuan tanaman harian (dijalankan saat app dibuka)
  Future<void> checkDailyDecay() async {
    final todayStr = DateFormatter.todayString;
    if (state.lastDecayCheckDate == todayStr) return; // Sudah dicek hari ini

    try {
      final trackingRepo = _ref.read(trackingRepositoryProvider);
      final logsResult = await trackingRepo.getAllLogs();
      final List<HabitLog> logs = logsResult.fold(
        onSuccess: (list) => list,
        onFailure: (_) => [],
      );

      // Kelompokkan log berdasarkan tanggal
      final Map<String, List<HabitLog>> logsByDate = {};
      for (final log in logs) {
        logsByDate.putIfAbsent(log.date, () => []).add(log);
      }

      int wiltDaysIncrement = 0;
      double progressDecrement = 0.0;

      final lastCheckDate = DateFormatter.parseDate(state.lastDecayCheckDate);
      final daysDiff = DateFormatter.daysBetween(state.lastDecayCheckDate, todayStr);

      // Cek hari-hari yang terlewat sejak cek terakhir hingga kemarin
      for (int i = 1; i <= daysDiff; i++) {
        final date = lastCheckDate.add(Duration(days: i));
        final dateStr = DateFormatter.formatDate(date);

        // Jangan cek hari ini (karena hari ini masih berjalan)
        if (dateStr == todayStr) continue;

        final dayLogs = logsByDate[dateStr] ?? [];
        final doneCount = dayLogs.where((l) => l.status == 'done').length;

        // Jika tidak ada habit selesai pada tanggal tersebut, tanaman layu
        if (doneCount == 0) {
          wiltDaysIncrement++;
          progressDecrement += 0.20; // Berkurang 20% pertumbuhan
        }
      }

      if (wiltDaysIncrement > 0 && state.plantStage != -1) {
        int newWiltDays = state.wiltDays + wiltDaysIncrement;
        int newStage = state.plantStage;
        double newProgress = state.plantProgress - progressDecrement;

        if (newProgress < 0) {
          newProgress = 0.0;
        }

        if (newWiltDays >= 3) {
          newStage = -1; // Tanaman mati setelah 3 hari berturut-turut kering
        }

        state = state.copyWith(
          wiltDays: newWiltDays,
          plantStage: newStage,
          plantProgress: newProgress,
          lastDecayCheckDate: todayStr,
        );
      } else {
        state = state.copyWith(
          lastDecayCheckDate: todayStr,
        );
      }

      await _saveToPrefs();
    } catch (e) {
      debugPrint('GamificationController: Gagal mengecek kelayuan harian: $e');
    }
  }

  /// Menanam ulang tanaman dari benih
  Future<void> resetPlant() async {
    state = state.copyWith(
      plantStage: 0,
      plantProgress: 0.0,
      wiltDays: 0,
      lastWateredDate: '',
    );
    await _saveToPrefs();
  }

  /// Menghidupkan kembali tanaman layu/mati dengan menukar XP
  Future<bool> revivePlant(int xpCost) async {
    // Hitung total akumulasi XP pengguna
    // Format XP level saat ini ditambah level * 100 (jika kita mau menghitung total absolut)
    // Untuk mempermudah, kita kurangkan saja XP dari XP bar level saat ini.
    // Jika XP level saat ini tidak cukup, kita turunkan levelnya.
    if (state.plantStage != -1) return false;

    // Cek apakah total XP mencukupi
    int currentTotalXp = state.xp;
    int currentLevel = state.level;
    
    // Cari tahu total XP akumulatif
    // Level 1 = xp
    // Level 2 = 100 + xp
    // Level 3 = 100 + 200 + xp = 300 + xp
    int accumulativeXp = currentTotalXp;
    for (int l = 1; l < currentLevel; l++) {
      accumulativeXp += l * 100;
    }

    if (accumulativeXp < xpCost) {
      return false; // XP tidak cukup
    }

    // Kurangi XP akumulatif
    int remainingXp = accumulativeXp - xpCost;
    int newLevel = 1;
    
    // Konversi kembali remainingXp ke level & xp bar
    while (remainingXp >= newLevel * 100) {
      remainingXp -= newLevel * 100;
      newLevel++;
    }

    state = state.copyWith(
      xp: remainingXp,
      level: newLevel,
      plantStage: 0, // Kembali ke benih
      plantProgress: 0.0,
      wiltDays: 0,
    );

    await _saveToPrefs();
    return true;
  }

  // Hook pemicu otomatis
  void awardHabitCompletion() {
    addXp(10);
    waterPlant();
  }

  void deductHabitCompletion() {
    deductXp(10);
  }

  void awardTaskCompletion() {
    addXp(15);
  }

  void deductTaskCompletion() {
    deductXp(15);
  }
}

/// Provider reaktif global untuk GamificationController
final gamificationProvider =
    StateNotifierProvider<GamificationController, GamificationState>((ref) {
  return GamificationController(ref);
});
