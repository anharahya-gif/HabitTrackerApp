import '../../../../core/errors/failure.dart';
import '../entities/habit.dart';
import '../entities/habit_streak.dart';

/// Interface repository untuk mengelola data Habit & Streak di Domain Layer.
abstract class HabitRepository {
  /// Membuat habit baru.
  Future<Result<void>> createHabit(Habit habit);

  /// Mengambil semua daftar habit yang tidak diarsipkan.
  Future<Result<List<Habit>>> getHabits();

  /// Mengambil habit tertentu berdasarkan ID.
  Future<Result<Habit?>> getHabitById(String id);

  /// Memperbarui informasi habit.
  Future<Result<void>> updateHabit(Habit habit);

  /// Menghapus habit permanen berdasarkan ID.
  Future<Result<void>> deleteHabit(String id);

  /// Mengambil informasi streak suatu habit.
  Future<Result<HabitStreak?>> getHabitStreak(String habitId);

  /// Memperbarui data streak untuk habit tertentu.
  Future<Result<void>> updateHabitStreak(HabitStreak streak);

  /// Mengarsipkan atau mengaktifkan kembali habit berdasarkan ID.
  Future<Result<void>> toggleArchiveHabit(String id, bool isArchived);
}
