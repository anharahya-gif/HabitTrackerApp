import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/habit.dart';
import '../repositories/habit_repository.dart';

/// Usecase untuk membuat Habit baru.
class CreateHabit implements UseCase<void, Habit> {
  final HabitRepository _repository;

  CreateHabit(this._repository);

  @override
  Future<Result<void>> call(Habit params) async {
    if (params.name.trim().isEmpty) {
      return const Failure('Nama habit tidak boleh kosong.');
    }
    return await _repository.createHabit(params);
  }
}
