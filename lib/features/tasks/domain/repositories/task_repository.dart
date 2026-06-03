import '../../../../core/errors/failure.dart';
import '../entities/task.dart';

/// Repository contract for managing Task data in the Domain Layer.
abstract class TaskRepository {
  /// Creates a new task.
  Future<Result<void>> createTask(Task task);

  /// Retrieves all tasks.
  Future<Result<List<Task>>> getTasks();

  /// Retrieves a task by its ID.
  Future<Result<Task?>> getTaskById(String id);

  /// Updates an existing task.
  Future<Result<void>> updateTask(Task task);

  /// Deletes a task by its ID.
  Future<Result<void>> deleteTask(String id);
}
