import 'dart:math';
import '../../features/habits/data/models/habit_model.dart';
import '../../features/tracking/data/models/habit_log_model.dart';
import '../../features/habits/data/datasources/habit_local_data_source.dart';
import '../../features/tracking/data/datasources/tracking_local_data_source.dart';
import '../../features/tracking/domain/usecases/calculate_streak.dart';
import 'date_formatter.dart';

class DummySeeder {
  static Future<void> seedDummyHabit({
    required HabitLocalDataSource habitLocalDS,
    required TrackingLocalDataSource trackingLocalDS,
    required CalculateStreak calculateStreak,
  }) async {
    final random = Random();
    final habitId = 'dummy-habit-olahraga-pagi';

    // 1. Bersihkan data dummy yang lama jika ada (agar datanya ter-reset untuk pengujian baru)
    try {
      await habitLocalDS.deleteHabit(habitId);
    } catch (_) {}

    // 2. Buat Habit Dummy
    final now = DateTime.now();
    final dummyHabit = HabitModel(
      id: habitId,
      name: 'Olahraga Pagi 🏃',
      description: 'Lari pagi 20 menit untuk kebugaran jantung.',
      category: 'Kebugaran',
      type: 'daily',
      createdAt: now.subtract(const Duration(days: 40)),
      isArchived: false,
      reminderTime: '07:00',
      color: 0xFF3B82F6, // Blue
      isSynced: false,
      updatedAt: now,
    );

    await habitLocalDS.insertHabit(dummyHabit);

    // 3. Buat Logs histori 40 hari ke belakang secara acak/realistis
    for (int i = 1; i <= 40; i++) {
      final logDate = now.subtract(Duration(days: i));
      final dateStr = DateFormatter.formatDate(logDate);

      // Probabilitas: 70% Done, 10% Skipped, 10% Missed, 10% Kosong
      final randVal = random.nextDouble();
      String status;
      DateTime? completedAt;

      if (randVal < 0.7) {
        status = 'done';
        // Jam acak antara 07:00 sampai 07:45 pagi
        completedAt = DateTime(
          logDate.year,
          logDate.month,
          logDate.day,
          7,
          random.nextInt(45),
          random.nextInt(60),
        );
      } else if (randVal < 0.8) {
        status = 'skipped';
      } else if (randVal < 0.9) {
        status = 'missed';
      } else {
        continue; // Kosongkan hari ini
      }

      final logId = '${habitId}_$dateStr';
      final dummyLog = HabitLogModel(
        id: logId,
        habitId: habitId,
        date: dateStr,
        status: status,
        completedAt: completedAt,
        isSynced: false,
        updatedAt: now,
      );

      await trackingLocalDS.insertOrUpdateLog(dummyLog);
    }

    // 4. Hitung ulang streak agar statistik sinkron
    await calculateStreak(habitId);
  }
}
