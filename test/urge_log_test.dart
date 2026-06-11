import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_app/features/vault/domain/entities/urge_log.dart';
import 'package:habit_tracker_app/features/vault/data/models/urge_log_model.dart';

void main() {
  group('Dailio Vault - Urge Log Entity & Model Tests', () {
    final now = DateTime(2026, 6, 11, 12, 0, 0);

    final urgeLog = UrgeLogModel(
      id: 'urge-1',
      date: '2026-06-11',
      time: '14:30',
      severity: 4,
      triggerEmotion: 'Bosan',
      notes: 'Sendirian di kamar, tergoda membuka sosmed.',
      createdAt: now,
    );

    test('should serialize and deserialize urge log to/from SQLite map', () {
      // Act
      final sqlMap = urgeLog.toSqlMap();
      final decoded = UrgeLogModel.fromSqlMap(sqlMap);

      // Assert
      expect(sqlMap['id'], 'urge-1');
      expect(sqlMap['date'], '2026-06-11');
      expect(sqlMap['time'], '14:30');
      expect(sqlMap['severity'], 4);
      expect(sqlMap['trigger_emotion'], 'Bosan');
      expect(sqlMap['notes'], 'Sendirian di kamar, tergoda membuka sosmed.');
      expect(sqlMap['created_at'], now.toIso8601String());
      
      expect(decoded.id, 'urge-1');
      expect(decoded.date, '2026-06-11');
      expect(decoded.time, '14:30');
      expect(decoded.severity, 4);
      expect(decoded.triggerEmotion, 'Bosan');
      expect(decoded.notes, 'Sendirian di kamar, tergoda membuka sosmed.');
      expect(decoded.createdAt, now);
    });

    test('should copyWith updated parameters correctly', () {
      // Act
      final updated = urgeLog.copyWith(
        severity: 5,
        notes: 'Sangat tergoda relaps.',
      );

      // Assert
      expect(updated.id, urgeLog.id);
      expect(updated.severity, 5);
      expect(updated.notes, 'Sangat tergoda relaps.');
      expect(updated.date, urgeLog.date);
      expect(updated.time, urgeLog.time);
      expect(updated.triggerEmotion, urgeLog.triggerEmotion);
      expect(updated.createdAt, urgeLog.createdAt);
    });

    test('should convert between domain entities and models correctly', () {
      // Act
      final entity = urgeLog.toEntity();
      final model = UrgeLogModel.fromEntity(entity);

      // Assert
      expect(entity, isA<UrgeLog>());
      expect(entity.triggerEmotion, 'Bosan');
      
      expect(model, isA<UrgeLogModel>());
      expect(model.id, urgeLog.id);
      expect(model.date, urgeLog.date);
      expect(model.time, urgeLog.time);
      expect(model.severity, urgeLog.severity);
      expect(model.triggerEmotion, urgeLog.triggerEmotion);
      expect(model.notes, urgeLog.notes);
      expect(model.createdAt, urgeLog.createdAt);
    });
  });
}
