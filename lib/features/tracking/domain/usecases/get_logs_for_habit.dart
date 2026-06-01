import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/habit_log.dart';
import '../repositories/tracking_repository.dart';

/// Usecase untuk mendapatkan daftar histori log harian dari habit tertentu.
class GetLogsForHabit implements UseCase<List<HabitLog>, String> {
  final TrackingRepository _repository;

  GetLogsForHabit(this._repository);

  @override
  Future<Result<List<HabitLog>>> call(String params) async {
    if (params.trim().isEmpty) {
      return const Failure('ID Habit tidak boleh kosong.');
    }
    return await _repository.getLogsForHabit(params);
  }
}
