/// Entitas domain murni untuk item Papan Visi / My Why.
class VisionItem {
  final String id;
  final String title;
  final String content;
  final int color; // Nilai ARGB untuk background kartu
  final DateTime createdAt;
  final DateTime updatedAt;

  const VisionItem({
    required this.id,
    required this.title,
    required this.content,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  VisionItem copyWith({
    String? id,
    String? title,
    String? content,
    int? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VisionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
