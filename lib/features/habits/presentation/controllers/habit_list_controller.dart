import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../shared/providers.dart';
import '../../domain/entities/habit.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/utils/notification_service.dart';

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
      onSuccess: (habits) {
        // Segarkan semua notifikasi pengingat berdasarkan data SQLite terbaru
        NotificationService.scheduleAllNotifications(habits).catchError((_) {});
        return habits;
      },
      onFailure: (failure) => throw Exception(failure.message),
    );
  }

  /// Memuat ulang daftar habit dari database SQLite dan sinkronisasi Cloud.
  Future<void> refresh() async {
    // Jalankan Cloud Sync secara aktif saat user melakukan pull-to-refresh (jika terautentikasi)
    final authState = ref.read(authControllerProvider);
    final user = authState.valueOrNull;
    if (user != null && user.isAuthenticated) {
      try {
        await ref.read(syncServiceProvider).syncData(user.id);
      } catch (e) {
        debugPrint('Gagal sinkronisasi cloud saat pull-to-refresh: $e');
      }
    }

    state = await AsyncValue.guard(() => _fetchHabits());
  }

  /// Menambahkan habit baru ke dalam sistem dan menyegarkan tampilan.
  Future<Result<void>> addHabit(Habit habit) async {
    final createHabitUsecase = ref.read(createHabitProvider);
    final result = await createHabitUsecase(habit);

    if (result is Success<void>) {
      // Jadwalkan notifikasi untuk habit baru jika ada reminderTime
      if (habit.reminderTime != null) {
        try {
          await NotificationService.scheduleHabitNotification(habit);
        } catch (e) {
          debugPrint('Gagal menjadwalkan notifikasi habit baru: $e');
        }
      }
      state = await AsyncValue.guard(() => _fetchHabits());
      _triggerBackgroundSync();
    }
    return result;
  }

  /// Memperbarui data habit dan menyegarkan tampilan.
  Future<Result<void>> updateHabit(Habit habit) async {
    final updateHabitUsecase = ref.read(updateHabitProvider);
    final result = await updateHabitUsecase(habit);

    if (result is Success<void>) {
      // Jadwalkan ulang atau batalkan notifikasi sesuai reminderTime terbaru
      try {
        if (habit.reminderTime != null && !habit.isArchived) {
          await NotificationService.scheduleHabitNotification(habit);
        } else {
          await NotificationService.cancelHabitNotification(habit.id);
        }
      } catch (e) {
        debugPrint('Gagal memperbarui/membatalkan notifikasi habit: $e');
      }
      state = await AsyncValue.guard(() => _fetchHabits());
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
      // Batalkan notifikasi dari habit yang dihapus
      await NotificationService.cancelHabitNotification(id);
      state = await AsyncValue.guard(() => _fetchHabits());
      _triggerBackgroundSync();
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

/// Opsi pengurutan Habit
enum HabitSortOption {
  closestTime,
  alphabetical,
  newest,
}

/// Provider untuk menyimpan filter kategori yang aktif
final habitCategoryFilterProvider = StateProvider<String>((ref) => 'Semua');

/// Provider untuk menyimpan opsi pengurutan yang aktif
final habitSortOptionProvider = StateProvider<HabitSortOption>((ref) => HabitSortOption.closestTime);

/// Menghitung selisih menit mutlak antara waktu sekarang dengan waktu pengingat (dengan wrap-around 24 jam)
int _calculateClosenessMinutes(String? reminderTime) {
  if (reminderTime == null) {
    return 99999; // Tanpa reminder, taruh di paling bawah
  }

  final parts = reminderTime.split(':');
  if (parts.length != 2) return 99999;

  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts[1]) ?? 0;

  final now = DateTime.now();
  final nowMinutes = now.hour * 60 + now.minute;
  final reminderMinutes = hour * 60 + minute;

  final diff = (nowMinutes - reminderMinutes).abs();
  // Tangani pembulatan 24 jam (wrap-around)
  return diff < 1440 - diff ? diff : 1440 - diff;
}

/// Provider gabungan untuk memfilter dan mengurutkan Habit secara reaktif
final filteredHabitsProvider = Provider<AsyncValue<List<Habit>>>((ref) {
  final habitsAsync = ref.watch(habitListProvider);
  final categoryFilter = ref.watch(habitCategoryFilterProvider);
  final sortOption = ref.watch(habitSortOptionProvider);

  return habitsAsync.whenData((habits) {
    // 1. Lakukan penyaringan Kategori
    var resultList = habits;
    if (categoryFilter != 'Semua') {
      resultList = resultList.where((h) => h.category == categoryFilter).toList();
    }

    // 2. Lakukan pengurutan
    switch (sortOption) {
      case HabitSortOption.closestTime:
        resultList = List.from(resultList)
          ..sort((a, b) {
            final diffA = _calculateClosenessMinutes(a.reminderTime);
            final diffB = _calculateClosenessMinutes(b.reminderTime);
            return diffA.compareTo(diffB);
          });
        break;
      case HabitSortOption.alphabetical:
        resultList = List.from(resultList)
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case HabitSortOption.newest:
        resultList = List.from(resultList)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return resultList;
  });
});
