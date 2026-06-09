/// Domain entity representing a daily task.
class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String priority; // 'low', 'medium', 'high'
  final String category;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final List<String> tags;

  const Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.priority = 'medium',
    this.category = 'Lainnya',
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.tags = const [],
  });

  /// Creates a copy of this Task with the given fields replaced by the new values.
  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? priority,
    String? category,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    List<String>? tags,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      tags: tags ?? this.tags,
    );
  }
}
