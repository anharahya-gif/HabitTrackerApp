import '../../domain/entities/habit.dart';

/// Model data Habit yang memperluas kelas domain entitas [Habit],
/// menangani proses parsing JSON/Map SQLite.
class HabitModel extends Habit {
  const HabitModel({
    required super.id,
    required super.name,
    super.description,
    required super.category,
    required super.type,
    required super.createdAt,
    super.isArchived,
    super.reminderTime,
    required super.color,
  });

  /// Mengonversi dari Map SQLite ke Model
  factory HabitModel.fromSqlMap(Map<String, dynamic> map) {
    return HabitModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      category: map['category'] as String,
      type: map['type'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      isArchived: (map['is_archived'] as int) == 1,
      reminderTime: map['reminder_time'] as String?,
      color: map['color'] as int,
    );
  }

  /// Mengonversi dari Entitas ke Model
  factory HabitModel.fromEntity(Habit habit) {
    return HabitModel(
      id: habit.id,
      name: habit.name,
      description: habit.description,
      category: habit.category,
      type: habit.type,
      createdAt: habit.createdAt,
      isArchived: habit.isArchived,
      reminderTime: habit.reminderTime,
      color: habit.color,
    );
  }

  /// Mengonversi Model ke Map SQLite
  Map<String, dynamic> toSqlMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'is_archived': isArchived ? 1 : 0,
      'reminder_time': reminderTime,
      'color': color,
    };
  }

  /// Mengonversi ke objek domain entitas murni [Habit]
  Habit toEntity() {
    return Habit(
      id: id,
      name: name,
      description: description,
      category: category,
      type: type,
      createdAt: createdAt,
      isArchived: isArchived,
      reminderTime: reminderTime,
      color: color,
    );
  }
}
