import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/task_repository.dart';

/// Usecase for deleting a Task by its ID.
class DeleteTask implements UseCase<void, String> {
  final TaskRepository _repository;

  DeleteTask(this._repository);

  @override
  Future<Result<void>> call(String params) async {
    if (params.trim().isEmpty) {
      return const Failure('ID tugas tidak valid.');
    }
    return await _repository.deleteTask(params);
  }
}
