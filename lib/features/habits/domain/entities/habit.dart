/// Kelas entitas murni untuk Habit (tanpa ketergantungan framework/database).
class Habit {
  final String id;
  final String name;
  final String? description;
  final String category;
  final String type; // e.g. 'daily', 'weekly'
  final DateTime createdAt;
  final bool isArchived;
  final String? reminderTime; // e.g. '08:00'
  final int color; // Nilai integer warna ARGB (e.g. 0xFF4CAF50)
  final bool isSynced;
  final DateTime? updatedAt;
  final String? startTime; // e.g. '08:00'
  final String? endTime; // e.g. '10:00'
  final String reminderType; // 'notification' atau 'alarm'
  final String? alarmSound; // URI nada suara alarm kustom (e.g. content://media/internal/audio/media/12)

  const Habit({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.type,
    required this.createdAt,
    this.isArchived = false,
    this.reminderTime,
    required this.color,
    this.isSynced = false,
    this.updatedAt,
    this.startTime,
    this.endTime,
    this.reminderType = 'notification',
    this.alarmSound,
  });

  /// Menggandakan entitas dengan perubahan properti tertentu.
  Habit copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? type,
    DateTime? createdAt,
    bool? isArchived,
    String? reminderTime,
    int? color,
    bool? isSynced,
    DateTime? updatedAt,
    String? startTime,
    String? endTime,
    String? reminderType,
    String? alarmSound,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isArchived: isArchived ?? this.isArchived,
      reminderTime: reminderTime ?? this.reminderTime,
      color: color ?? this.color,
      isSynced: isSynced ?? this.isSynced,
      updatedAt: updatedAt ?? this.updatedAt,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      reminderType: reminderType ?? this.reminderType,
      alarmSound: alarmSound ?? this.alarmSound,
    );
  }
}
