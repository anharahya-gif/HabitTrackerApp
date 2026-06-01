import '../../../../core/errors/exception.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/habit_log.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../datasources/tracking_local_data_source.dart';
import '../models/habit_log_model.dart';

/// Implementasi nyata dari [TrackingRepository] di Data Layer.
class TrackingRepositoryImpl implements TrackingRepository {
  final TrackingLocalDataSource _localDataSource;

  TrackingRepositoryImpl(this._localDataSource);

  @override
  Future<Result<void>> saveLog(HabitLog log) async {
    try {
      final model = HabitLogModel.fromEntity(log);
      await _localDataSource.insertOrUpdateLog(model);
      return const Success(null);
    } on DatabaseException catch (e) {
      return Failure(e.message, e);
    } catch (e) {
      return Failure('Terjadi kesalahan saat menyimpan status tracking.', e);
    }
  }

  @override
  Future<Result<List<HabitLog>>> getLogsForHabit(String habitId) async {
    try {
      final models = await _localDataSource.getLogsForHabit(habitId);
      final entities = models.map((model) => model.toEntity()).toList();
      return Success(entities);
    } on DatabaseException catch (e) {
      return Failure(e.message, e);
    } catch (e) {
      return Failure('Terjadi kesalahan saat mengambil histori tracking.', e);
    }
  }

  @override
  Future<Result<HabitLog?>> getLogForHabitAndDate(String habitId, String date) async {
    try {
      final model = await _localDataSource.getLogForHabitAndDate(habitId, date);
      return Success(model?.toEntity());
    } on DatabaseException catch (e) {
      return Failure(e.message, e);
    } catch (e) {
      return Failure('Terjadi kesalahan saat memuat log harian habit.', e);
    }
  }

  @override
  Future<Result<void>> deleteLog(String id) async {
    try {
      await _localDataSource.deleteLog(id);
      return const Success(null);
    } on DatabaseException catch (e) {
      return Failure(e.message, e);
    } catch (e) {
      return Failure('Terjadi kesalahan saat menghapus log tracking.', e);
    }
  }
}
