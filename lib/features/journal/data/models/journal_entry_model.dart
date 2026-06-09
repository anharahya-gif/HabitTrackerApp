import '../../domain/entities/journal_entry.dart';

/// Data Model representing JournalEntry, extends [JournalEntry] entity.
/// Handles SQLite Map serialization & deserialization.
class JournalEntryModel extends JournalEntry {
  const JournalEntryModel({
    required super.id,
    required super.date,
    required super.mood,
    super.content,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Map from SQLite query results to JournalEntryModel
  factory JournalEntryModel.fromSqlMap(Map<String, dynamic> map) {
    return JournalEntryModel(
      id: map['id'] as String,
      date: map['date'] as String,
      mood: map['mood'] as String,
      content: map['content'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Converts JournalEntryModel to SQLite Map
  Map<String, dynamic> toSqlMap() {
    return {
      'id': id,
      'date': date,
      'mood': mood,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Factory to convert Domain entity to Model
  factory JournalEntryModel.fromEntity(JournalEntry entity) {
    return JournalEntryModel(
      id: entity.id,
      date: entity.date,
      mood: entity.mood,
      content: entity.content,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
