import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/habit.dart';
import '../repositories/habit_repository.dart';

/// Usecase untuk mendapatkan daftar seluruh habit aktif (non-archived).
class GetHabits implements UseCase<List<Habit>, NoParams> {
  final HabitRepository _repository;

  GetHabits(this._repository);

  @override
  Future<Result<List<Habit>>> call(NoParams params) async {
    return await _repository.getHabits();
  }
}
