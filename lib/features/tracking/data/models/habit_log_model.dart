import '../../domain/entities/habit_log.dart';

/// Model data HabitLog yang menangani interaksi map database SQLite.
class HabitLogModel extends HabitLog {
  const HabitLogModel({
    required super.id,
    required super.habitId,
    required super.date,
    required super.status,
    super.completedAt,
  });

  /// Mengonversi dari Map SQLite ke Model
  factory HabitLogModel.fromSqlMap(Map<String, dynamic> map) {
    return HabitLogModel(
      id: map['id'] as String,
      habitId: map['habit_id'] as String,
      date: map['date'] as String,
      status: map['status'] as String,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
    );
  }

  /// Mengonversi dari Entitas ke Model
  factory HabitLogModel.fromEntity(HabitLog log) {
    return HabitLogModel(
      id: log.id,
      habitId: log.habitId,
      date: log.date,
      status: log.status,
      completedAt: log.completedAt,
    );
  }

  /// Mengonversi Model ke Map SQLite
  Map<String, dynamic> toSqlMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'date': date,
      'status': status,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  /// Mengonversi ke objek domain entitas murni [HabitLog]
  HabitLog toEntity() {
    return HabitLog(
      id: id,
      habitId: habitId,
      date: date,
      status: status,
      completedAt: completedAt,
    );
  }
}
