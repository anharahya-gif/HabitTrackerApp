import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failure.dart';
import '../../../../shared/providers.dart';
import '../../../habits/presentation/controllers/habit_detail_controller.dart';
import '../../../habits/presentation/controllers/habit_list_controller.dart';
import '../../domain/usecases/track_habit_day.dart';

/// State untuk proses tracking harian.
sealed class TrackingState {
  const TrackingState();
}

class TrackingIdle extends TrackingState {
  const TrackingIdle();
}

class TrackingLoading extends TrackingState {
  const TrackingLoading();
}

class TrackingSuccess extends TrackingState {
  const TrackingSuccess();
}

class TrackingError extends TrackingState {
  final String message;
  const TrackingError(this.message);
}

/// Controller state management untuk memproses tracking harian (mark done, skip, missed).
/// State melacak progres operasi harian secara asinkron.
class TrackingController extends AutoDisposeNotifier<TrackingState> {
  @override
  TrackingState build() {
    return const TrackingIdle();
  }

  /// Menandai status harian habit (done/skipped/missed).
  /// Menyegarkan daftar habit di halaman beranda dan detail habit jika halaman tersebut aktif.
  Future<Result<void>> trackHabit({
    required String habitId,
    required String date,
    required String status,
  }) async {
    state = const TrackingLoading();

    final trackUsecase = ref.read(trackHabitDayProvider);
    final params = TrackHabitParams(habitId: habitId, date: date, status: status);
    final result = await trackUsecase(params);

    return result.fold(
      onSuccess: (streak) {
        state = const TrackingSuccess();

        // 1. Segarkan list utama di home
        ref.read(habitListProvider.notifier).refresh();

        // 2. Segarkan detail spesifik (jika ada observer aktif untuk habitId tersebut)
        ref.read(habitDetailProvider(habitId).notifier).refresh();

        // 3. Segarkan provider family individu secara reaktif
        ref.invalidate(habitStreakProvider(habitId));
        ref.invalidate(habitTodayLogProvider(habitId));

        return Success(streak);
      },
      onFailure: (failure) {
        state = TrackingError(failure.message);
        return Failure(failure.message, failure.exception);
      },
    );
  }
}

/// Provider global untuk memicu tracking harian.
final trackingProvider = NotifierProvider.autoDispose<TrackingController, TrackingState>(() {
  return TrackingController();
});
