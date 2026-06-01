import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/habit.dart';
import '../repositories/habit_repository.dart';

/// Usecase untuk mendapatkan detail habit tertentu berdasarkan ID.
class GetHabitById implements UseCase<Habit?, String> {
  final HabitRepository _repository;

  GetHabitById(this._repository);

  @override
  Future<Result<Habit?>> call(String params) async {
    if (params.trim().isEmpty) {
      return const Failure('ID Habit tidak boleh kosong.');
    }
    return await _repository.getHabitById(params);
  }
}
