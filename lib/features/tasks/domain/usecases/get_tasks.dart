import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';

/// Usecase for retrieving all Tasks.
class GetTasks implements UseCase<List<Task>, NoParams> {
  final TaskRepository _repository;

  GetTasks(this._repository);

  @override
  Future<Result<List<Task>>> call(NoParams params) async {
    return await _repository.getTasks();
  }
}
