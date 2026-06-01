import '../../domain/entities/habit_streak.dart';

/// Model data HabitStreak yang menangani interaksi map database SQLite.
class HabitStreakModel extends HabitStreak {
  const HabitStreakModel({
    required super.habitId,
    super.currentStreak,
    super.bestStreak,
    super.lastCompletedDate,
  });

  /// Mengonversi dari Map SQLite ke Model
  factory HabitStreakModel.fromSqlMap(Map<String, dynamic> map) {
    return HabitStreakModel(
      habitId: map['habit_id'] as String,
      currentStreak: map['current_streak'] as int,
      bestStreak: map['best_streak'] as int,
      lastCompletedDate: map['last_completed_date'] as String?,
    );
  }

  /// Mengonversi dari Entitas ke Model
  factory HabitStreakModel.fromEntity(HabitStreak streak) {
    return HabitStreakModel(
      habitId: streak.habitId,
      currentStreak: streak.currentStreak,
      bestStreak: streak.bestStreak,
      lastCompletedDate: streak.lastCompletedDate,
    );
  }

  /// Mengonversi Model ke Map SQLite
  Map<String, dynamic> toSqlMap() {
    return {
      'habit_id': habitId,
      'current_streak': currentStreak,
      'best_streak': bestStreak,
      'last_completed_date': lastCompletedDate,
    };
  }

  /// Mengonversi ke objek domain entitas murni [HabitStreak]
  HabitStreak toEntity() {
    return HabitStreak(
      habitId: habitId,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      lastCompletedDate: lastCompletedDate,
    );
  }
}
