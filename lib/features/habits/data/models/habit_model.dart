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
    super.isSynced,
    super.updatedAt,
    super.startTime,
    super.endTime,
    super.reminderType,
    super.alarmSound,
    super.frequencyConfig,
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
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
      updatedAt: map['updated_at'] != null && (map['updated_at'] as String).isNotEmpty
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
      startTime: map['start_time'] as String?,
      endTime: map['end_time'] as String?,
      reminderType: map['reminder_type'] as String? ?? 'notification',
      alarmSound: map['alarm_sound'] as String?,
      frequencyConfig: map['frequency_config'] as String?,
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
      isSynced: habit.isSynced,
      updatedAt: habit.updatedAt,
      startTime: habit.startTime,
      endTime: habit.endTime,
      reminderType: habit.reminderType,
      alarmSound: habit.alarmSound,
      frequencyConfig: habit.frequencyConfig,
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
      'is_synced': isSynced ? 1 : 0,
      'updated_at': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'reminder_type': reminderType,
      'alarm_sound': alarmSound,
      'frequency_config': frequencyConfig,
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
      isSynced: isSynced,
      updatedAt: updatedAt,
      startTime: startTime,
      endTime: endTime,
      reminderType: reminderType,
      alarmSound: alarmSound,
      frequencyConfig: frequencyConfig,
    );
  }
}
