import '../../../../core/errors/exception.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_data_source.dart';
import '../models/task_model.dart';

/// Real implementation of [TaskRepository] in the Data Layer.
class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource _localDataSource;

  TaskRepositoryImpl(this._localDataSource);

  @override
  Future<Result<void>> createTask(Task task) async {
    try {
      final model = TaskModel.fromEntity(task);
      await _localDataSource.insertTask(model);
      return const Success(null);
    } on DatabaseException catch (e) {
      return Failure(e.message, e);
    } catch (e) {
      return Failure('Terjadi kesalahan yang tidak terduga saat menyimpan tugas.', e);
    }
  }

  @override
  Future<Result<List<Task>>> getTasks() async {
    try {
      final models = await _localDataSource.getAllTasks();
      final entities = models.map((model) => model.toEntity()).toList();
      return Success(entities);
    } on DatabaseException catch (e) {
      return Failure(e.message, e);
    } catch (e) {
      return Failure('Terjadi kesalahan saat memuat daftar tugas.', e);
    }
  }

  @override
  Future<Result<Task?>> getTaskById(String id) async {
    try {
      final model = await _localDataSource.getTaskById(id);
      return Success(model?.toEntity());
    } on DatabaseException catch (e) {
      return Failure(e.message, e);
    } catch (e) {
      return Failure('Terjadi kesalahan saat memuat detail tugas.', e);
    }
  }

  @override
  Future<Result<void>> updateTask(Task task) async {
    try {
      final model = TaskModel.fromEntity(task);
      await _localDataSource.updateTask(model);
      return const Success(null);
    } on DatabaseException catch (e) {
      return Failure(e.message, e);
    } catch (e) {
      return Failure('Terjadi kesalahan saat memperbarui tugas.', e);
    }
  }

  @override
  Future<Result<void>> deleteTask(String id) async {
    try {
      await _localDataSource.deleteTask(id);
      return const Success(null);
    } on DatabaseException catch (e) {
      return Failure(e.message, e);
    } catch (e) {
      return Failure('Terjadi kesalahan saat menghapus tugas.', e);
    }
  }
}
