import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/providers.dart';
import '../../../habits/domain/entities/habit.dart';
import '../../../habits/presentation/controllers/habit_list_controller.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/presentation/controllers/task_list_controller.dart';
import '../../../tracking/domain/entities/habit_log.dart';

/// Representasi data titik grafik kepatuhan habit harian
class AdherenceDataPoint {
  final DateTime date;
  final double rate; // Nilai persentase 0.0 - 1.0

  const AdherenceDataPoint(this.date, this.rate);
}

/// State data analitik lengkap untuk ProfilePage
class AnalyticsState {
  final List<AdherenceDataPoint> adherenceData; // Rentang 30 hari terakhir
  final Map<String, int> taskCategoryCounts; // Jumlah tugas selesai per kategori
  final int totalTasksCompleted;
  final double averageAdherenceRate; // Rata-rata 30 hari terakhir
  final bool hasPerfectWeekBadge; // Kepatuhan 100% selama 7 hari berturut-turut
  final int perfectWeeksCount; // Total minggu kalender (Senin-Minggu) dengan kepatuhan 100%

  const AnalyticsState({
    required this.adherenceData,
    required this.taskCategoryCounts,
    required this.totalTasksCompleted,
    required this.averageAdherenceRate,
    required this.hasPerfectWeekBadge,
    required this.perfectWeeksCount,
  });

  factory AnalyticsState.empty() {
    return const AnalyticsState(
      adherenceData: [],
      taskCategoryCounts: {},
      totalTasksCompleted: 0,
      averageAdherenceRate: 0.0,
      hasPerfectWeekBadge: false,
      perfectWeeksCount: 0,
    );
  }
}

/// Controller reaktif untuk mengolah statistik dan pencapaian pengguna.
class AnalyticsController extends StateNotifier<AsyncValue<AnalyticsState>> {
  final Ref _ref;

  AnalyticsController(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    // Watch status habit list & task list secara reaktif.
    // Jika ada penambahan/perubahan habit atau tugas, state analitik akan terupdate.
    final habitsAsync = _ref.watch(habitListProvider);
    final tasksAsync = _ref.watch(taskListProvider);

    if (habitsAsync is AsyncLoading || tasksAsync is AsyncLoading) {
      state = const AsyncValue.loading();
      return;
    }

    if (habitsAsync is AsyncError || tasksAsync is AsyncError) {
      state = AsyncValue.error(
        habitsAsync.error ?? tasksAsync.error ?? 'Error loading analytics data',
        habitsAsync.stackTrace ?? tasksAsync.stackTrace ?? StackTrace.current,
      );
      return;
    }

    final habits = habitsAsync.valueOrNull ?? [];
    final tasks = tasksAsync.valueOrNull ?? [];

    _calculateStats(habits, tasks);
  }

  /// Memaksa refresh data analitik dengan menarik data logs terbaru dari database.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final habits = _ref.read(habitListProvider).valueOrNull ?? [];
    final tasks = _ref.read(taskListProvider).valueOrNull ?? [];
    await _calculateStats(habits, tasks);
  }

  Future<void> _calculateStats(List<Habit> habits, List<Task> tasks) async {
    try {
      final trackingRepo = _ref.read(trackingRepositoryProvider);
      final logsResult = await trackingRepo.getAllLogs();

      final List<HabitLog> logs = logsResult.fold(
        onSuccess: (list) => list,
        onFailure: (_) => [],
      );

      // --- 1. PROSES ADHERENCE RATE (30 HARI TERAKHIR) ---
      final now = DateTime.now();
      final List<AdherenceDataPoint> adherencePoints = [];
      double totalAdherence = 0.0;
      int daysWithHabits = 0;

      // Map log berdasarkan tanggal untuk pencarian instan O(1)
      final Map<String, List<HabitLog>> logsByDate = {};
      for (final log in logs) {
        logsByDate.putIfAbsent(log.date, () => []).add(log);
      }

      for (int i = 29; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateStr = DateFormatter.formatDate(date);
        
        // Filter habit yang sudah dibuat pada tanggal tersebut
        final activeHabitsOnDay = habits.where((h) {
          final creationDateNormalized = DateTime(h.createdAt.year, h.createdAt.month, h.createdAt.day);
          final dateNormalized = DateTime(date.year, date.month, date.day);
          return !creationDateNormalized.isAfter(dateNormalized);
        }).toList();

        if (activeHabitsOnDay.isEmpty) {
          adherencePoints.add(AdherenceDataPoint(date, 0.0));
          continue;
        }

        final dayLogs = logsByDate[dateStr] ?? [];
        final doneCount = dayLogs.where((l) => l.status == 'done').length;
        
        final double dayRate = doneCount / activeHabitsOnDay.length;
        adherencePoints.add(AdherenceDataPoint(date, dayRate));
        
        totalAdherence += dayRate;
        daysWithHabits++;
      }

      final double avgAdherence = daysWithHabits > 0 ? (totalAdherence / daysWithHabits) * 100 : 0.0;

      // --- 2. PROSES TASK VELOCITY (KATEGORI TUGAS SELESAI) ---
      final completedTasks = tasks.where((t) => t.isCompleted).toList();
      final Map<String, int> categoryCounts = {};
      for (final task in completedTasks) {
        final cat = task.category.trim().isEmpty ? 'Lainnya' : task.category;
        categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
      }

      // --- 3. PROSES PERFECT WEEK BADGE (7 HARI TERAKHIR) ---
      bool hasPerfectWeek = true;
      int checkDaysCount = 0;

      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: i));
        final dateStr = DateFormatter.formatDate(date);

        final activeHabitsOnDay = habits.where((h) {
          final creationDateNormalized = DateTime(h.createdAt.year, h.createdAt.month, h.createdAt.day);
          final dateNormalized = DateTime(date.year, date.month, date.day);
          return !creationDateNormalized.isAfter(dateNormalized);
        }).toList();

        if (activeHabitsOnDay.isNotEmpty) {
          checkDaysCount++;
          final dayLogs = logsByDate[dateStr] ?? [];
          final doneCount = dayLogs.where((l) => l.status == 'done').length;

          if (doneCount < activeHabitsOnDay.length) {
            hasPerfectWeek = false;
          }
        }
      }

      // Jika tidak ada habit yang aktif sama sekali dalam 7 hari terakhir, maka tidak ada badge.
      if (checkDaysCount == 0) {
        hasPerfectWeek = false;
      }

      // --- 4. HITUNG TOTAL PERFECT WEEK HISTORIS ---
      // Kita menghitung berdasarkan minggu kalender (Senin - Minggu)
      // Dapatkan log tertua atau batasi hingga maksimal 6 bulan ke belakang
      int perfectWeeksCount = 0;

      if (logs.isNotEmpty && habits.isNotEmpty) {
        // Kelompokkan semua tanggal log ke dalam grup minggu kalender (diwakili oleh hari Senin minggu tersebut)
        final Map<DateTime, List<String>> datesByWeekMonday = {};
        
        // Kumpulkan seluruh tanggal unik yang memiliki log atau aktivitas
        final Set<String> allActiveDates = {};
        for (final log in logs) {
          allActiveDates.add(log.date);
        }

        for (final dateStr in allActiveDates) {
          final date = DateFormatter.parseDate(dateStr);
          // Cari hari Senin pada minggu dari tanggal tersebut
          final int daysToSubtract = date.weekday - 1;
          final monday = DateTime(date.year, date.month, date.day).subtract(Duration(days: daysToSubtract));
          
          datesByWeekMonday.putIfAbsent(monday, () => []).add(dateStr);
        }

        // Untuk setiap minggu kalender, periksa apakah seluruh 7 hari (Senin s/d Minggu) terisi penuh 100% selesai.
        datesByWeekMonday.forEach((monday, dateStringsInWeek) {
          bool isWeekPerfect = true;
          int activeDaysInWeek = 0;

          for (int weekday = 1; weekday <= 7; weekday++) {
            final checkDate = monday.add(Duration(days: weekday - 1));
            final checkDateStr = DateFormatter.formatDate(checkDate);

            // Periksa apakah ada habit aktif pada hari tersebut
            final activeHabitsOnDay = habits.where((h) {
              final creationDateNormalized = DateTime(h.createdAt.year, h.createdAt.month, h.createdAt.day);
              final checkDateNormalized = DateTime(checkDate.year, checkDate.month, checkDate.day);
              return !creationDateNormalized.isAfter(checkDateNormalized);
            }).toList();

            if (activeHabitsOnDay.isNotEmpty) {
              activeDaysInWeek++;
              final dayLogs = logsByDate[checkDateStr] ?? [];
              final doneCount = dayLogs.where((l) => l.status == 'done').length;

              if (doneCount < activeHabitsOnDay.length) {
                isWeekPerfect = false;
                break;
              }
            }
          }

          if (isWeekPerfect && activeDaysInWeek > 0) {
            perfectWeeksCount++;
          }
        });
      }

      state = AsyncValue.data(AnalyticsState(
        adherenceData: adherencePoints,
        taskCategoryCounts: categoryCounts,
        totalTasksCompleted: completedTasks.length,
        averageAdherenceRate: avgAdherence,
        hasPerfectWeekBadge: hasPerfectWeek,
        perfectWeeksCount: perfectWeeksCount,
      ));
    } catch (e, stack) {
      state = AsyncValue.error('Gagal menghitung statistik analytics: $e', stack);
    }
  }
}

/// Provider reaktif global untuk Analytics Controller
final analyticsControllerProvider =
    StateNotifierProvider<AnalyticsController, AsyncValue<AnalyticsState>>((ref) {
  return AnalyticsController(ref);
});
