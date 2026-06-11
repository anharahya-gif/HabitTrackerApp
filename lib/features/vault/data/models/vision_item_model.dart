import '../../domain/entities/vision_item.dart';

/// Model data VisionItem untuk serialisasi/deserialisasi SQLite.
class VisionItemModel extends VisionItem {
  const VisionItemModel({
    required super.id,
    required super.title,
    required super.content,
    required super.color,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Mengonversi dari Map SQLite ke Model
  factory VisionItemModel.fromSqlMap(Map<String, dynamic> map) {
    return VisionItemModel(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      color: map['color'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Mengonversi Model ke Map SQLite
  Map<String, dynamic> toSqlMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'color': color,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Mengonversi dari Entitas ke Model
  factory VisionItemModel.fromEntity(VisionItem entity) {
    return VisionItemModel(
      id: entity.id,
      title: entity.title,
      content: entity.content,
      color: entity.color,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Mengonversi ke objek domain entitas murni [VisionItem]
  VisionItem toEntity() {
    return VisionItem(
      id: id,
      title: title,
      content: content,
      color: color,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
