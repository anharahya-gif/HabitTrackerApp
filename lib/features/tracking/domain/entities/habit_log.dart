/// Entitas murni representasi log status harian suatu Habit.
class HabitLog {
  final String id;
  final String habitId;
  final String date; // Format 'YYYY-MM-DD'
  final String status; // 'done', 'missed', 'skipped'
  final DateTime? completedAt;
  final bool isSynced;
  final DateTime? updatedAt;

  const HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
    required this.status,
    this.completedAt,
    this.isSynced = false,
    this.updatedAt,
  });

  HabitLog copyWith({
    String? id,
    String? habitId,
    String? date,
    String? status,
    DateTime? completedAt,
    bool? isSynced,
    DateTime? updatedAt,
  }) {
    return HabitLog(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      isSynced: isSynced ?? this.isSynced,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
