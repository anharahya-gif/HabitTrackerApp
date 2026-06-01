import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/habit.dart';
import '../repositories/habit_repository.dart';

/// Usecase untuk memperbarui data Habit yang sudah ada.
class UpdateHabit implements UseCase<void, Habit> {
  final HabitRepository _repository;

  UpdateHabit(this._repository);

  @override
  Future<Result<void>> call(Habit params) async {
    if (params.name.trim().isEmpty) {
      return const Failure('Nama habit tidak boleh kosong.');
    }
    return await _repository.updateHabit(params);
  }
}
