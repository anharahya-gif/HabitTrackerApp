/// Entitas bisnis representasi statistik streak harian dari sebuah Habit.
class HabitStreak {
  final String habitId;
  final int currentStreak;
  final int bestStreak;
  final String? lastCompletedDate; // Format 'YYYY-MM-DD'

  const HabitStreak({
    required this.habitId,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastCompletedDate,
  });

  HabitStreak copyWith({
    String? habitId,
    int? currentStreak,
    int? bestStreak,
    String? lastCompletedDate,
  }) {
    return HabitStreak(
      habitId: habitId ?? this.habitId,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
    );
  }
}
