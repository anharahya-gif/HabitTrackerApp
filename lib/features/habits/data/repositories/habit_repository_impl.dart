import '../../../../core/errors/exception.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_streak.dart';
import '../../domain/repositories/habit_repository.dart';
import '../datasources/habit_local_data_source.dart';
import '../models/habit_model.dart';
import '../models/habit_streak_model.dart';

/// Implementasi nyata dari [HabitRepository] di Data Layer.
/// Menjembatani Domain dengan Local Data Source, menangkap Exception,
/// dan mengembalikan objek Result (Success/Failure) yang aman.
class HabitRepositoryImpl implements HabitRepository {
  final HabitLocalDataSource _localDataSource;

  HabitRepositoryImpl(this._localDataSource);

  @override
  Future<Result<void>> createHabit(Habit habit) async {
    try {
      final model = HabitModel.fromEntity(habit);
      await _localDataSource.insertHabit(model);
      return const Success(null);
    } on DatabaseException catch (e) {
      return Failure(e.message, e);
    } catch (e) {
      return Failure('Terjadi kesalahan yang tidak terduga saat menyimpan habit.', e);
    }
  }

  @override
  Future<Result<List<Habit>>> getHabits() async {
    try {
      final models = await _localDataSource.getAllHabits();
      final entities = models.map((model) => model.toEntity()).toList();
      return Success(entities);
    } on DatabaseException catch (e) {
      return Failure(e.message, e);
    } catch (e) {
      return Failure('Terjadi kesalahan saat memuat daftar habit.', e);
    }
  }

  @override
  Future<Result<Habit?>> getHabitById(String id) async {
    try {
      final model = await _localDataSource.getHabitById(id);
      return Success(model?.toEntity());
    } on DatabaseException catch (e) {
      return Failure(e.message, e);
    } catch (e) {
      return Failure('Terjadi kesalahan saat memuat detail habit.', e);
    }
  }

  @override
  Future<Result<void>> updateHabit(Habit habit) async {
    try {
      final model = HabitModel.fromEntity(habit);
      await _localDataSource.updateHabit(model);
      return const Success(null);
    } on DatabaseException catch (e) {
      return Failure(e.message, e);
    } catch (e) {
      return Failure('Terjadi kesalahan saat memperbarui habit.', e);
    }
  }

  @override
  Future<Result<void>> deleteHabit(String id) async {
    try {
      await _localDataSource.deleteHabit(id);
      return const Success(null);
    } on DatabaseException catch (e) {
      return Failure(e.message, e);
    } catch (e) {
      return Failure('Terjadi kesalahan saat menghapus habit.', e);
    }
  }

  @override
  Future<Result<HabitStreak?>> getHabitStreak(String habitId) async {
    try {
      final model = await _localDataSource.getHabitStreak(habitId);
      return Success(model?.toEntity());
    } on DatabaseException catch (e) {
      return Failure(e.message, e);
    } catch (e) {
      return Failure('Terjadi kesalahan saat memuat statistik streak habit.', e);
    }
  }

  @override
  Future<Result<void>> updateHabitStreak(HabitStreak streak) async {
    try {
      final model = HabitStreakModel.fromEntity(streak);
      await _localDataSource.updateHabitStreak(model);
      return const Success(null);
    } on DatabaseException catch (e) {
      return Failure(e.message, e);
    } catch (e) {
      return Failure('Terjadi kesalahan saat memperbarui data streak.', e);
    }
  }

  @override
  Future<Result<void>> toggleArchiveHabit(String id, bool isArchived) async {
    try {
      final habitResult = await getHabitById(id);
      if (habitResult is Success<Habit?> && habitResult.data != null) {
        final updatedHabit = habitResult.data!.copyWith(isArchived: isArchived);
        await updateHabit(updatedHabit);
        return const Success(null);
      }
      return const Failure('Habit tidak ditemukan untuk diarsipkan.');
    } on DatabaseException catch (e) {
      return Failure(e.message, e);
    } catch (e) {
      return Failure('Terjadi kesalahan saat mengubah status pengarsipan habit.', e);
    }
  }
}
