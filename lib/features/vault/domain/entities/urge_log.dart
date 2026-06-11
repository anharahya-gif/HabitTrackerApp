/// Entitas domain murni untuk pencatatan urge / pemicu hasrat.
class UrgeLog {
  final String id;
  final String date;          // format YYYY-MM-DD
  final String time;          // format HH:MM
  final int severity;         // 1 - 5 (tingkat keparahan)
  final String triggerEmotion;// stres, bosan, sepi, lelah, sosmed, lainnya
  final String? notes;        // catatan pendek opsional
  final DateTime createdAt;

  const UrgeLog({
    required this.id,
    required this.date,
    required this.time,
    required this.severity,
    required this.triggerEmotion,
    this.notes,
    required this.createdAt,
  });

  UrgeLog copyWith({
    String? id,
    String? date,
    String? time,
    int? severity,
    String? triggerEmotion,
    String? notes,
    DateTime? createdAt,
  }) {
    return UrgeLog(
      id: id ?? this.id,
      date: date ?? this.date,
      time: time ?? this.time,
      severity: severity ?? this.severity,
      triggerEmotion: triggerEmotion ?? this.triggerEmotion,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
