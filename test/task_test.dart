import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_app/features/tasks/data/models/task_model.dart';
import 'package:habit_tracker_app/features/tasks/domain/entities/task.dart';

void main() {
  group('TaskModel & Task Tests', () {
    final now = DateTime(2026, 6, 3, 12, 0, 0);
    final dueDate = DateTime(2026, 6, 5, 23, 59, 0);

    final task = TaskModel(
      id: 'task-123',
      title: 'Menyelesaikan Fitur Tasks',
      description: 'Menulis unit test, model, repositori, dan UI untuk fitur tugas harian.',
      dueDate: dueDate,
      priority: 'high',
      category: 'Kerja',
      isCompleted: false,
      completedAt: null,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
    );

    test('should convert to and from SQL Map correctly', () {
      // Act
      final sqlMap = task.toSqlMap();
      final decodedTask = TaskModel.fromSqlMap(sqlMap);

      // Assert
      expect(decodedTask.id, 'task-123');
      expect(decodedTask.title, 'Menyelesaikan Fitur Tasks');
      expect(decodedTask.description, 'Menulis unit test, model, repositori, dan UI untuk fitur tugas harian.');
      expect(decodedTask.dueDate, dueDate);
      expect(decodedTask.priority, 'high');
      expect(decodedTask.category, 'Kerja');
      expect(decodedTask.isCompleted, false);
      expect(decodedTask.completedAt, isNull);
      expect(decodedTask.createdAt, now);
      expect(decodedTask.updatedAt, now);
      expect(decodedTask.isSynced, false);
    });

    test('should convert to and from Firestore Map correctly', () {
      // Act
      final firestoreMap = task.toFirestoreMap();
      final decodedTask = TaskModel.fromFirestoreMap(firestoreMap, 'task-123');

      // Assert
      expect(decodedTask.id, 'task-123');
      expect(decodedTask.title, 'Menyelesaikan Fitur Tasks');
      expect(decodedTask.description, 'Menulis unit test, model, repositori, dan UI untuk fitur tugas harian.');
      expect(decodedTask.dueDate, dueDate);
      expect(decodedTask.priority, 'high');
      expect(decodedTask.category, 'Kerja');
      expect(decodedTask.isCompleted, false);
      expect(decodedTask.completedAt, isNull);
      expect(decodedTask.createdAt, now);
      expect(decodedTask.updatedAt, now);
      expect(decodedTask.isSynced, true); // remote source is marked synced
    });

    test('should copyWith updated parameters correctly', () {
      // Act
      final completedAt = DateTime(2026, 6, 3, 14, 0, 0);
      final updatedTask = task.copyWith(
        title: 'Fitur Tasks Selesai!',
        isCompleted: true,
        completedAt: completedAt,
        isSynced: true,
      );

      // Assert
      expect(updatedTask.title, 'Fitur Tasks Selesai!');
      expect(updatedTask.isCompleted, true);
      expect(updatedTask.completedAt, completedAt);
      expect(updatedTask.isSynced, true);
      expect(updatedTask.id, task.id); // remains unchanged
      expect(updatedTask.priority, task.priority); // remains unchanged
    });

    test('should convert to entity and model back and forth', () {
      // Act
      final entity = task.toEntity();
      final modelFromEntity = TaskModel.fromEntity(entity);

      // Assert
      expect(entity, isA<Task>());
      expect(modelFromEntity, isA<TaskModel>());
      expect(modelFromEntity.title, task.title);
      expect(modelFromEntity.priority, task.priority);
      expect(modelFromEntity.dueDate, task.dueDate);
    });
  });
}
