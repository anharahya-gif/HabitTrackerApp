import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_app/features/habits/data/models/habit_model.dart';
import 'package:habit_tracker_app/features/habits/domain/entities/habit.dart';

void main() {
  group('Dailio Vault - Habit Entity & Model Tests', () {
    final now = DateTime(2026, 6, 9, 12, 0, 0);

    final publicHabit = HabitModel(
      id: 'habit-public',
      name: 'Olahraga Pagi',
      description: 'Lari pagi 30 menit',
      category: 'Kesehatan',
      type: 'daily',
      createdAt: now,
      isArchived: false,
      reminderTime: '06:00',
      color: 0xFF6366F1,
      isSynced: false,
      updatedAt: now,
      isPrivate: false,
    );

    final privateHabit = HabitModel(
      id: 'habit-private',
      name: 'No PMO',
      description: 'Clean streak tracking',
      category: 'Mental/Pikiran',
      type: 'daily',
      createdAt: now,
      isArchived: false,
      reminderTime: '22:00',
      color: 0xFF8B5CF6,
      isSynced: false,
      updatedAt: now,
      isPrivate: true,
    );

    test('should serialize and deserialize public habit with is_private = 0', () {
      // Act
      final sqlMap = publicHabit.toSqlMap();
      final decodedHabit = HabitModel.fromSqlMap(sqlMap);

      // Assert
      expect(sqlMap['is_private'], 0);
      expect(decodedHabit.isPrivate, isFalse);
      expect(decodedHabit.id, 'habit-public');
      expect(decodedHabit.name, 'Olahraga Pagi');
    });

    test('should serialize and deserialize private habit with is_private = 1', () {
      // Act
      final sqlMap = privateHabit.toSqlMap();
      final decodedHabit = HabitModel.fromSqlMap(sqlMap);

      // Assert
      expect(sqlMap['is_private'], 1);
      expect(decodedHabit.isPrivate, isTrue);
      expect(decodedHabit.id, 'habit-private');
      expect(decodedHabit.name, 'No PMO');
    });

    test('should copyWith updated isPrivate status correctly', () {
      // Act
      final toggledHabit = publicHabit.copyWith(isPrivate: true);

      // Assert
      expect(toggledHabit.isPrivate, isTrue);
      expect(toggledHabit.id, publicHabit.id);
      expect(toggledHabit.name, publicHabit.name);
    });

    test('should convert to entity and model back and forth and preserve isPrivate status', () {
      // Act
      final entity = privateHabit.toEntity();
      final modelFromEntity = HabitModel.fromEntity(entity);

      // Assert
      expect(entity, isA<Habit>());
      expect(entity.isPrivate, isTrue);
      expect(modelFromEntity, isA<HabitModel>());
      expect(modelFromEntity.isPrivate, isTrue);
      expect(modelFromEntity.name, privateHabit.name);
    });
  });
}
