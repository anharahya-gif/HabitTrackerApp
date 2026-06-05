import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../shared/providers.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../habits/presentation/controllers/habit_list_controller.dart';
import '../../../tasks/presentation/controllers/task_list_controller.dart';
import '../../../tracking/domain/entities/habit_log.dart';

/// State untuk [ProductivityCalendarController]
class ProductivityCalendarState {
  final DateTime selectedMonth;
  final bool googleCalendarSyncEnabled;
  final bool autoSyncTasks;
  final bool autoSyncHabits;
  final bool isSyncing;
  final String? syncError;

  ProductivityCalendarState({
    required this.selectedMonth,
    this.googleCalendarSyncEnabled = false,
    this.autoSyncTasks = true,
    this.autoSyncHabits = true,
    this.isSyncing = false,
    this.syncError,
  });

  ProductivityCalendarState copyWith({
    DateTime? selectedMonth,
    bool? googleCalendarSyncEnabled,
    bool? autoSyncTasks,
    bool? autoSyncHabits,
    bool? isSyncing,
    String? syncError,
  }) {
    return ProductivityCalendarState(
      selectedMonth: selectedMonth ?? this.selectedMonth,
      googleCalendarSyncEnabled: googleCalendarSyncEnabled ?? this.googleCalendarSyncEnabled,
      autoSyncTasks: autoSyncTasks ?? this.autoSyncTasks,
      autoSyncHabits: autoSyncHabits ?? this.autoSyncHabits,
      isSyncing: isSyncing ?? this.isSyncing,
      syncError: syncError,
    );
  }
}

/// Controller reaktif untuk fitur Kalender Produktivitas Bulanan dan Google Calendar.
class ProductivityCalendarController extends StateNotifier<ProductivityCalendarState> {
  final Ref _ref;

  ProductivityCalendarController(this._ref)
      : super(ProductivityCalendarState(selectedMonth: DateTime.now())) {
    _loadSettings();
  }

  /// Memuat preferensi sinkronisasi dari SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = state.copyWith(
        googleCalendarSyncEnabled: prefs.getBool('google_calendar_sync_enabled') ?? false,
        autoSyncTasks: prefs.getBool('google_calendar_auto_sync_tasks') ?? true,
        autoSyncHabits: prefs.getBool('google_calendar_auto_sync_habits') ?? true,
      );
    } catch (e) {
      debugPrint('ProductivityCalendarController: Gagal memuat preferensi: $e');
    }
  }

  /// Mengubah bulan yang sedang ditampilkan di kalender
  void setMonth(DateTime month) {
    state = state.copyWith(selectedMonth: month);
  }

  /// Mengaktifkan/menonaktifkan integrasi Google Calendar secara umum
  Future<void> toggleGoogleCalendarSync(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('google_calendar_sync_enabled', enabled);
      state = state.copyWith(googleCalendarSyncEnabled: enabled);
      
      if (enabled) {
        // Jika diaktifkan, langsung picu sinkronisasi awal
        await triggerManualSync();
      } else {
        // Jika dinonaktifkan, hapus semua event Dailio dari Google Calendar
        state = state.copyWith(isSyncing: true, syncError: null);
        debugPrint('ProductivityCalendarController: Menghapus semua event Dailio dari Google Calendar...');
        try {
          final calendarService = _ref.read(googleCalendarServiceProvider);
          final deletedCount = await calendarService.deleteAllDailioEvents();
          debugPrint('ProductivityCalendarController: $deletedCount event berhasil dihapus.');
          state = state.copyWith(
            isSyncing: false,
            syncError: deletedCount > 0
                ? '✅ $deletedCount event Dailio dihapus dari Google Calendar.'
                : null,
          );
        } catch (e) {
          debugPrint('ProductivityCalendarController: Gagal menghapus event: $e');
          state = state.copyWith(
            isSyncing: false,
            syncError: 'Gagal menghapus event dari Google Calendar: $e',
          );
        }
      }
    } catch (e) {
      debugPrint('ProductivityCalendarController: Gagal menyimpan preferensi sync: $e');
    }
  }

  /// Mengubah opsi sinkronisasi otomatis tugas
  Future<void> toggleAutoSyncTasks(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('google_calendar_auto_sync_tasks', enabled);
      state = state.copyWith(autoSyncTasks: enabled);
    } catch (e) {
      debugPrint('ProductivityCalendarController: Gagal menyimpan preferensi tasks: $e');
    }
  }

  /// Mengubah opsi sinkronisasi otomatis kebiasaan
  Future<void> toggleAutoSyncHabits(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('google_calendar_auto_sync_habits', enabled);
      state = state.copyWith(autoSyncHabits: enabled);
    } catch (e) {
      debugPrint('ProductivityCalendarController: Gagal menyimpan preferensi habits: $e');
    }
  }

  /// Memicu sinkronisasi data lokal ke Google Calendar secara manual
  Future<bool> triggerManualSync() async {
    debugPrint('ProductivityCalendarController: triggerManualSync() dipicu.');
    // Pastikan user sudah login dengan akun riil
    final authUser = _ref.read(authControllerProvider).valueOrNull;
    if (authUser == null || authUser.isGuest) {
      debugPrint('ProductivityCalendarController: Batal sinkronisasi karena status Tamu (Guest).');
      state = state.copyWith(syncError: 'Silakan login dengan Akun Google terlebih dahulu di menu Profil.');
      return false;
    }

    if (authUser.id == 'demo_user_google_123') {
      debugPrint('ProductivityCalendarController: Batal sinkronisasi karena status Akun Demo.');
      state = state.copyWith(syncError: 'Sinkronisasi tidak dapat berjalan dalam Mode Demo. Silakan hubungkan dengan Akun Google riil.');
      return false;
    }

    state = state.copyWith(isSyncing: true, syncError: null);
    try {
      final calendarService = _ref.read(googleCalendarServiceProvider);

      // Sinkronisasi tugas
      if (state.autoSyncTasks) {
        final tasks = _ref.read(taskListProvider).valueOrNull ?? [];
        debugPrint('ProductivityCalendarController: Memulai sinkronisasi ${tasks.length} tugas ke Google Calendar...');
        await calendarService.syncTasks(tasks);
      } else {
        debugPrint('ProductivityCalendarController: Sinkronisasi tugas dinonaktifkan.');
      }

      // Sinkronisasi kebiasaan
      if (state.autoSyncHabits) {
        final habits = _ref.read(habitListProvider).valueOrNull ?? [];
        debugPrint('ProductivityCalendarController: Memulai sinkronisasi ${habits.length} kebiasaan ke Google Calendar...');
        await calendarService.syncHabits(habits);
      } else {
        debugPrint('ProductivityCalendarController: Sinkronisasi kebiasaan dinonaktifkan.');
      }

      debugPrint('ProductivityCalendarController: Sinkronisasi manual selesai dengan sukses.');
      state = state.copyWith(isSyncing: false);
      return true;
    } catch (e) {
      debugPrint('ProductivityCalendarController: Sinkronisasi manual gagal dengan error: $e');
      state = state.copyWith(isSyncing: false, syncError: e.toString());
      return false;
    }
  }
}

/// Provider global untuk mengakses state dan kontroler Kalender Produktivitas
final productivityCalendarControllerProvider =
    StateNotifierProvider<ProductivityCalendarController, ProductivityCalendarState>((ref) {
  return ProductivityCalendarController(ref);
});

/// Data teragregasi untuk render heatmap & deadline di halaman Kalender.
class ProductivityData {
  final Map<String, int> completions; // YYYY-MM-DD -> total penyelesaian
  final Map<String, String> highestPriorityDeadline; // YYYY-MM-DD -> 'high' | 'medium' | 'low'
  final Map<String, List<dynamic>> dailyDetails; // YYYY-MM-DD -> daftar habit/task harian

  ProductivityData({
    required this.completions,
    required this.highestPriorityDeadline,
    required this.dailyDetails,
  });
}

/// Provider reaktif yang mengagregasikan seluruh logs habit dan task untuk heatmap & deadline.
final monthlyProductivityProvider = FutureProvider<ProductivityData>((ref) async {
  final habitsAsync = ref.watch(habitListProvider);
  final tasksAsync = ref.watch(taskListProvider);

  final habits = habitsAsync.valueOrNull ?? [];
  final tasks = tasksAsync.valueOrNull ?? [];

  final Map<String, int> completions = {};
  final Map<String, String> highestPriorityDeadline = {};
  final Map<String, List<dynamic>> dailyDetails = {};

  void addDetail(String dateStr, dynamic item) {
    if (!dailyDetails.containsKey(dateStr)) {
      dailyDetails[dateStr] = [];
    }
    dailyDetails[dateStr]!.add(item);
  }

  // 1. Proses task
  for (final task in tasks) {
    // Jika task selesai, hitung sebagai penyelesaian produktif pada tanggal selesai
    if (task.isCompleted && task.completedAt != null) {
      final dateStr = DateFormatter.formatDate(task.completedAt!);
      completions[dateStr] = (completions[dateStr] ?? 0) + 1;
      addDetail(dateStr, task);
    }

    // Jika task belum selesai dan memiliki tenggat waktu, tampilkan sebagai deadline & detail hari itu
    if (task.dueDate != null) {
      final dateStr = DateFormatter.formatDate(task.dueDate!);
      if (!task.isCompleted) {
        addDetail(dateStr, task);
      }

      // Hitung prioritas tertinggi untuk deadline mark hari itu
      final currentHighest = highestPriorityDeadline[dateStr];
      final newPriority = task.priority.toLowerCase();

      if (currentHighest == null) {
        highestPriorityDeadline[dateStr] = newPriority;
      } else {
        const priorityOrder = {'high': 3, 'medium': 2, 'low': 1};
        final currentWeight = priorityOrder[currentHighest] ?? 0;
        final newWeight = priorityOrder[newPriority] ?? 0;
        if (newWeight > currentWeight) {
          highestPriorityDeadline[dateStr] = newPriority;
        }
      }
    }
  }

  // 2. Proses logs habit harian
  final getLogs = ref.read(getLogsForHabitProvider);
  for (final habit in habits) {
    final logsResult = await getLogs(habit.id);
    logsResult.fold(
      onSuccess: (logs) {
        for (final log in logs) {
          final dateStr = log.date;
          addDetail(dateStr, {'habit': habit, 'log': log});

          if (log.status == 'done') {
            completions[dateStr] = (completions[dateStr] ?? 0) + 1;
          }
        }
      },
      onFailure: (_) {},
    );
  }

  return ProductivityData(
    completions: completions,
    highestPriorityDeadline: highestPriorityDeadline,
    dailyDetails: dailyDetails,
  );
});
