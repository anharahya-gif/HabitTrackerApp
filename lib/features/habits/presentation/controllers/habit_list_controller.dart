import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../shared/providers.dart';
import '../../domain/entities/habit.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Controller state management untuk daftar Habit menggunakan [AsyncNotifier].
/// State berupa [AsyncValue<List<Habit>>] untuk menangani state loading, error, dan success secara elegan.
class HabitListController extends AsyncNotifier<List<Habit>> {
  @override
  FutureOr<List<Habit>> build() async {
    return _fetchHabits();
  }

  Future<List<Habit>> _fetchHabits() async {
    final getHabitsUsecase = ref.read(getHabitsProvider);
    final result = await getHabitsUsecase(const NoParams());

    return result.fold(
      onSuccess: (habits) => habits,
      onFailure: (failure) => throw Exception(failure.message),
    );
  }

  /// Memuat ulang daftar habit dari database SQLite.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchHabits());
  }

  /// Menambahkan habit baru ke dalam sistem dan menyegarkan tampilan.
  Future<Result<void>> addHabit(Habit habit) async {
    final createHabitUsecase = ref.read(createHabitProvider);
    final result = await createHabitUsecase(habit);

    if (result is Success<void>) {
      await refresh();
      _triggerBackgroundSync();
    }
    return result;
  }

  /// Menghapus habit permanen berdasarkan ID.
  Future<Result<void>> removeHabit(String id) async {
    final deleteHabitUsecase = ref.read(deleteHabitProvider);
    
    // Hapus dari cloud secara background jika terhubung
    final authState = ref.read(authControllerProvider);
    authState.whenData((user) {
      if (user.isAuthenticated) {
        ref.read(trackingRemoteDataSourceProvider).deleteRemoteHabit(user.id, id).catchError((_) {});
      }
    });

    final result = await deleteHabitUsecase(id);

    if (result is Success<void>) {
      await refresh();
    }
    return result;
  }

  /// Sinkronisasi cloud otomatis di latar belakang
  void _triggerBackgroundSync() {
    final authState = ref.read(authControllerProvider);
    authState.whenData((user) {
      if (user.isAuthenticated) {
        ref.read(syncServiceProvider).syncData(user.id).catchError((_) {});
      }
    });
  }
}

/// Provider global untuk mengakses state daftar Habit.
final habitListProvider = AsyncNotifierProvider<HabitListController, List<Habit>>(() {
  return HabitListController();
});
