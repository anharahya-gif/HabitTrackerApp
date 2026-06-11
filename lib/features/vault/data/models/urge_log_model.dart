import '../../domain/entities/urge_log.dart';

/// Model data UrgeLog untuk serialisasi SQLite.
class UrgeLogModel extends UrgeLog {
  const UrgeLogModel({
    required super.id,
    required super.date,
    required super.time,
    required super.severity,
    required super.triggerEmotion,
    super.notes,
    required super.createdAt,
  });

  /// Mengonversi dari Map SQLite ke Model
  factory UrgeLogModel.fromSqlMap(Map<String, dynamic> map) {
    return UrgeLogModel(
      id: map['id'] as String,
      date: map['date'] as String,
      time: map['time'] as String,
      severity: map['severity'] as int,
      triggerEmotion: map['trigger_emotion'] as String,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Mengonversi Model ke Map SQLite
  Map<String, dynamic> toSqlMap() {
    return {
      'id': id,
      'date': date,
      'time': time,
      'severity': severity,
      'trigger_emotion': triggerEmotion,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Mengonversi dari Entitas ke Model
  factory UrgeLogModel.fromEntity(UrgeLog entity) {
    return UrgeLogModel(
      id: entity.id,
      date: entity.date,
      time: entity.time,
      severity: entity.severity,
      triggerEmotion: entity.triggerEmotion,
      notes: entity.notes,
      createdAt: entity.createdAt,
    );
  }

  /// Mengonversi ke objek domain entitas murni [UrgeLog]
  UrgeLog toEntity() {
    return UrgeLog(
      id: id,
      date: date,
      time: time,
      severity: severity,
      triggerEmotion: triggerEmotion,
      notes: notes,
      createdAt: createdAt,
    );
  }
}
