import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_app/features/vault/domain/entities/vision_item.dart';
import 'package:habit_tracker_app/features/vault/data/models/vision_item_model.dart';

void main() {
  group('Dailio Vault - Vision Board Entity & Model Tests', () {
    final now = DateTime(2026, 6, 11, 12, 0, 0);

    final visionItem = VisionItemModel(
      id: 'vision-1',
      title: 'Masa Depanku',
      content: 'Surat komitmen untuk selalu menjaga integritas dan fokus.',
      color: 0xff7e57c2,
      createdAt: now,
      updatedAt: now,
    );

    test('should serialize and deserialize vision item to/from SQLite map', () {
      // Act
      final sqlMap = visionItem.toSqlMap();
      final decoded = VisionItemModel.fromSqlMap(sqlMap);

      // Assert
      expect(sqlMap['id'], 'vision-1');
      expect(sqlMap['title'], 'Masa Depanku');
      expect(sqlMap['content'], 'Surat komitmen untuk selalu menjaga integritas dan fokus.');
      expect(sqlMap['color'], 0xff7e57c2);
      expect(sqlMap['created_at'], now.toIso8601String());
      
      expect(decoded.id, 'vision-1');
      expect(decoded.title, 'Masa Depanku');
      expect(decoded.content, 'Surat komitmen untuk selalu menjaga integritas dan fokus.');
      expect(decoded.color, 0xff7e57c2);
      expect(decoded.createdAt, now);
      expect(decoded.updatedAt, now);
    });

    test('should copyWith updated parameters correctly', () {
      // Act
      final updated = visionItem.copyWith(
        title: 'Masa Depan Lebih Cerah',
        color: 0xff00897b,
      );

      // Assert
      expect(updated.id, visionItem.id);
      expect(updated.title, 'Masa Depan Lebih Cerah');
      expect(updated.content, visionItem.content);
      expect(updated.color, 0xff00897b);
      expect(updated.createdAt, visionItem.createdAt);
      expect(updated.updatedAt, visionItem.updatedAt);
    });

    test('should convert between domain entities and models correctly', () {
      // Act
      final entity = visionItem.toEntity();
      final model = VisionItemModel.fromEntity(entity);

      // Assert
      expect(entity, isA<VisionItem>());
      expect(entity.title, 'Masa Depanku');
      
      expect(model, isA<VisionItemModel>());
      expect(model.id, visionItem.id);
      expect(model.title, visionItem.title);
      expect(model.content, visionItem.content);
      expect(model.color, visionItem.color);
      expect(model.createdAt, visionItem.createdAt);
      expect(model.updatedAt, visionItem.updatedAt);
    });
  });
}
