import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failure.dart';
import '../../../../shared/providers.dart';
import '../../../tracking/domain/entities/habit_log.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_streak.dart';
import 'habit_list_controller.dart';

/// State gabungan yang dikelola oleh [HabitDetailController]
/// untuk menyuplai halaman detail secara lengkap.
class HabitDetailState {
  final Habit habit;
  final HabitStreak? streak;
  final List<HabitLog> logs;

  const HabitDetailState({
    required this.habit,
    this.streak,
    required this.logs,
  });

  HabitDetailState copyWith({
    Habit? habit,
    HabitStreak? streak,
    List<HabitLog>? logs,
  }) {
    return HabitDetailState(
      habit: habit ?? this.habit,
      streak: streak ?? this.streak,
      logs: logs ?? this.logs,
    );
  }
}

/// Controller state management untuk detail Habit tertentu berdasarkan ID-nya.
/// Menggunakan [FamilyAsyncNotifier] untuk mengikat instance controller ke ID habit tertentu.
class HabitDetailController extends FamilyAsyncNotifier<HabitDetailState, String> {
  @override
  FutureOr<HabitDetailState> build(String arg) async {
    return _fetchDetail(arg);
  }

  Future<HabitDetailState> _fetchDetail(String id) async {
    // 1. Dapatkan detail Habit
    final getHabitByIdUsecase = ref.read(getHabitByIdProvider);
    final habitResult = await getHabitByIdUsecase(id);
    
    if (habitResult is Failure<Habit?>) {
      throw Exception((habitResult as Failure).message);
    }
    
    final habit = (habitResult as Success<Habit?>).data;
    if (habit == null) {
      throw Exception('Habit tidak ditemukan.');
    }

    // 2. Dapatkan data Streak
    final repository = ref.read(habitRepositoryProvider);
    final streakResult = await repository.getHabitStreak(id);
    final streak = streakResult is Success<HabitStreak?> ? streakResult.data : null;

    // 3. Dapatkan histori Logs
    final getLogsUsecase = ref.read(getLogsForHabitProvider);
    final logsResult = await getLogsUsecase(id);
    final logs = logsResult is Success<List<HabitLog>> ? logsResult.data : <HabitLog>[];

    return HabitDetailState(
      habit: habit,
      streak: streak,
      logs: logs,
    );
  }

  /// Memuat ulang data detail habit beserta log dan streak terbarunya.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchDetail(arg));
  }

  /// Mengubah status pengarsipan habit saat ini.
  Future<Result<void>> toggleArchive(bool isArchived) async {
    final repository = ref.read(habitRepositoryProvider);
    final result = await repository.toggleArchiveHabit(arg, isArchived);

    if (result is Success<void>) {
      // Refresh detail dan segarkan list utama
      await refresh();
      ref.read(habitListProvider.notifier).refresh();
    }
    return result;
  }
}

/// Provider family dinamis untuk detail Habit.
final habitDetailProvider = AsyncNotifierProviderFamily<HabitDetailController, HabitDetailState, String>(() {
  return HabitDetailController();
});
