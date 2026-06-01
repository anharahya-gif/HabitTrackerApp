import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/habit_repository.dart';

/// Usecase untuk menghapus Habit secara permanen.
class DeleteHabit implements UseCase<void, String> {
  final HabitRepository _repository;

  DeleteHabit(this._repository);

  @override
  Future<Result<void>> call(String params) async {
    if (params.trim().isEmpty) {
      return const Failure('ID Habit tidak boleh kosong.');
    }
    return await _repository.deleteHabit(params);
  }
}
