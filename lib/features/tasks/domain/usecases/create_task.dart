import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';

/// Usecase for creating a new Task.
class CreateTask implements UseCase<void, Task> {
  final TaskRepository _repository;

  CreateTask(this._repository);

  @override
  Future<Result<void>> call(Task params) async {
    if (params.title.trim().isEmpty) {
      return const Failure('Judul tugas tidak boleh kosong.');
    }
    return await _repository.createTask(params);
  }
}
