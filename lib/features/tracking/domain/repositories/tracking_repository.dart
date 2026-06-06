import '../../../../core/errors/failure.dart';
import '../entities/habit_log.dart';

/// Interface repository untuk mengelola histori log tracking harian habit.
abstract class TrackingRepository {
  /// Menyimpan atau memperbarui log harian untuk habit tertentu.
  Future<Result<void>> saveLog(HabitLog log);

  /// Mengambil semua log tracking historis untuk suatu habit.
  Future<Result<List<HabitLog>>> getLogsForHabit(String habitId);

  /// Mengambil semua log tracking historis untuk seluruh habit.
  Future<Result<List<HabitLog>>> getAllLogs();

  /// Mengambil log tracking spesifik pada tanggal tertentu.
  Future<Result<HabitLog?>> getLogForHabitAndDate(String habitId, String date);

  /// Menghapus log harian tertentu berdasarkan ID.
  Future<Result<void>> deleteLog(String id);
}
