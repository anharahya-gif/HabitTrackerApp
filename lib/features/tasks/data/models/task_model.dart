import '../../domain/entities/task.dart';

/// Data Model representing Task, extends [Task] entity.
/// Handles SQLite Map serialization & deserialization.
class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.title,
    super.description,
    super.dueDate,
    super.priority,
    super.category,
    super.isCompleted,
    super.completedAt,
    required super.createdAt,
    required super.updatedAt,
    super.isSynced,
  });

  /// Map from SQLite query results to TaskModel
  factory TaskModel.fromSqlMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      dueDate: map['due_date'] != null && (map['due_date'] as String).isNotEmpty
          ? DateTime.parse(map['due_date'] as String)
          : null,
      priority: map['priority'] as String? ?? 'medium',
      category: map['category'] as String? ?? 'Lainnya',
      isCompleted: (map['is_completed'] as int) == 1,
      completedAt: map['completed_at'] != null && (map['completed_at'] as String).isNotEmpty
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
    );
  }

  /// Map from Firestore map to TaskModel
  factory TaskModel.fromFirestoreMap(Map<String, dynamic> map, String docId) {
    return TaskModel(
      id: docId,
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      dueDate: map['due_date'] != null && map['due_date'] is String && (map['due_date'] as String).isNotEmpty
          ? DateTime.tryParse(map['due_date'] as String)
          : null,
      priority: map['priority'] as String? ?? 'medium',
      category: map['category'] as String? ?? 'Lainnya',
      isCompleted: map['is_completed'] as bool? ?? false,
      completedAt: map['completed_at'] != null && map['completed_at'] is String && (map['completed_at'] as String).isNotEmpty
          ? DateTime.tryParse(map['completed_at'] as String)
          : null,
      createdAt: map['created_at'] != null && map['created_at'] is String && (map['created_at'] as String).isNotEmpty
          ? (DateTime.tryParse(map['created_at'] as String) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: map['updated_at'] != null && map['updated_at'] is String && (map['updated_at'] as String).isNotEmpty
          ? (DateTime.tryParse(map['updated_at'] as String) ?? DateTime.now())
          : DateTime.now(),
      isSynced: true, // Synced because it is fetched from Firestore
    );
  }

  /// Converts TaskModel to SQLite Map
  Map<String, dynamic> toSqlMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate?.toIso8601String(),
      'priority': priority,
      'category': category,
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  /// Converts TaskModel to Firestore Map
  Map<String, dynamic> toFirestoreMap() {
    return {
      'title': title,
      'description': description,
      'due_date': dueDate?.toIso8601String(),
      'priority': priority,
      'category': category,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Converts base [Task] entity to TaskModel
  factory TaskModel.fromEntity(Task task) {
    return TaskModel(
      id: task.id,
      title: task.title,
      description: task.description,
      dueDate: task.dueDate,
      priority: task.priority,
      category: task.category,
      isCompleted: task.isCompleted,
      completedAt: task.completedAt,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      isSynced: task.isSynced,
    );
  }

  /// Converts TaskModel to clean [Task] entity
  Task toEntity() {
    return Task(
      id: id,
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
      category: category,
      isCompleted: isCompleted,
      completedAt: completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isSynced: isSynced,
    );
  }
}
