import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_app/features/habits/data/models/habit_model.dart';
import 'package:habit_tracker_app/features/tracking/data/models/habit_log_model.dart';

void main() {
  group('HabitModel Tests', () {
    final now = DateTime(2026, 6, 2, 8, 0, 0);
    
    final habit = HabitModel(
      id: 'habit-123',
      name: 'Minum Air 2L',
      description: 'Minum air putih minimal 2 liter sehari',
      category: 'Kesehatan',
      type: 'daily',
      createdAt: now,
      isArchived: false,
      reminderTime: '08:00',
      color: 0xFF4CAF50,
      isSynced: false,
      updatedAt: now,
    );

    test('should convert to and from SQL Map properly', () {
      // Act
      final sqlMap = habit.toSqlMap();
      final decodedHabit = HabitModel.fromSqlMap(sqlMap);

      // Assert
      expect(decodedHabit.id, 'habit-123');
      expect(decodedHabit.name, 'Minum Air 2L');
      expect(decodedHabit.description, 'Minum air putih minimal 2 liter sehari');
      expect(decodedHabit.category, 'Kesehatan');
      expect(decodedHabit.type, 'daily');
      expect(decodedHabit.createdAt, now);
      expect(decodedHabit.isArchived, false);
      expect(decodedHabit.reminderTime, '08:00');
      expect(decodedHabit.color, 0xFF4CAF50);
      expect(decodedHabit.isSynced, false);
      expect(decodedHabit.updatedAt, now);
      expect(decodedHabit.reminderType, 'notification');
    });

    test('should copyWith updated parameters correctly', () {
      // Act
      final updatedHabit = habit.copyWith(
        name: 'Minum Air 3L',
        isSynced: true,
        reminderType: 'alarm',
      );

      // Assert
      expect(updatedHabit.name, 'Minum Air 3L');
      expect(updatedHabit.isSynced, true);
      expect(updatedHabit.reminderType, 'alarm');
      expect(updatedHabit.id, habit.id); // remains unchanged
      expect(updatedHabit.description, habit.description); // remains unchanged
    });
  });

  group('HabitLogModel Tests', () {
    final now = DateTime(2026, 6, 2, 8, 0, 0);

    final log = HabitLogModel(
      id: 'log-456',
      habitId: 'habit-123',
      date: '2026-06-02',
      status: 'completed',
      completedAt: now,
      isSynced: false,
      updatedAt: now,
    );

    test('should convert to and from SQL Map properly', () {
      // Act
      final sqlMap = log.toSqlMap();
      final decodedLog = HabitLogModel.fromSqlMap(sqlMap);

      // Assert
      expect(decodedLog.id, 'log-456');
      expect(decodedLog.habitId, 'habit-123');
      expect(decodedLog.date, '2026-06-02');
      expect(decodedLog.status, 'completed');
      expect(decodedLog.completedAt, now);
      expect(decodedLog.isSynced, false);
      expect(decodedLog.updatedAt, now);
    });
  });
}

