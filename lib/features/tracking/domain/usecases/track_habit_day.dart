import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../habits/domain/entities/habit_streak.dart';
import '../entities/habit_log.dart';
import '../repositories/tracking_repository.dart';
import 'calculate_streak.dart';

/// Parameter objek untuk mengeksekusi track habit harian.
class TrackHabitParams {
  final String habitId;
  final String date; // YYYY-MM-DD
  final String status; // 'done', 'missed', 'skipped'

  const TrackHabitParams({
    required this.habitId,
    required this.date,
    required this.status,
  });
}

/// Usecase untuk menandai status harian habit (done/skipped/missed).
/// Otomatis memicu CalculateStreak untuk menghitung ulang streak dan menyimpan hasilnya.
class TrackHabitDay implements UseCase<HabitStreak, TrackHabitParams> {
  final TrackingRepository _trackingRepository;
  final CalculateStreak _calculateStreak;

  TrackHabitDay(this._trackingRepository, this._calculateStreak);

  @override
  Future<Result<HabitStreak>> call(TrackHabitParams params) async {
    try {
      if (params.habitId.trim().isEmpty) {
        return const Failure('ID Habit tidak boleh kosong.');
      }
      if (params.date.trim().isEmpty) {
        return const Failure('Tanggal log tidak boleh kosong.');
      }
      if (params.status != 'done' && params.status != 'skipped' && params.status != 'missed') {
        return const Failure('Status log tidak valid (harus: done, skipped, atau missed).');
      }

      // 1. Buat entity log harian baru
      final log = HabitLog(
        id: '${params.habitId}_${params.date}', // ID unik gabungan habit & tanggal
        habitId: params.habitId,
        date: params.date,
        status: params.status,
        completedAt: params.status == 'done' ? DateTime.now() : null,
        isSynced: false,
        updatedAt: DateTime.now(),
      );

      // 2. Simpan log harian
      final saveResult = await _trackingRepository.saveLog(log);
      if (saveResult is Failure<void>) {
        return Failure(saveResult.message, saveResult.exception);
      }

      // 3. Hitung ulang streak
      final streakResult = await _calculateStreak(params.habitId);
      return streakResult;
    } catch (e) {
      return Failure('Terjadi kesalahan saat memproses tracking harian.', e);
    }
  }
}
