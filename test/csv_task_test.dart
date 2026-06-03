import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_app/core/utils/csv_task_helper.dart';
import 'package:habit_tracker_app/features/tasks/domain/entities/task.dart';

void main() {
  group('CsvTaskHelper Tests', () {
    final now = DateTime(2026, 6, 3, 12, 0, 0);
    final dueDate = DateTime(2026, 6, 5, 23, 59, 0);

    final tasks = [
      Task(
        id: 'task-1',
        title: 'Beli Susu, Roti',
        description: 'Beli susu segar & roti gandum di minimarket.',
        dueDate: dueDate,
        priority: 'low',
        category: 'Belanja',
        isCompleted: false,
        completedAt: null,
        createdAt: now,
        updatedAt: now,
        isSynced: false,
      ),
      Task(
        id: 'task-2',
        title: 'Kerjakan PR "Matematika"',
        description: 'PR Aljabar bab 3, halaman 45-50.',
        dueDate: null,
        priority: 'high',
        category: 'Belajar',
        isCompleted: true,
        completedAt: now,
        createdAt: now,
        updatedAt: now.add(const Duration(hours: 2)),
        isSynced: true,
      ),
    ];

    test('should convert tasks to CSV string correctly', () {
      // Act
      final csvString = CsvTaskHelper.tasksToCsv(tasks);

      // Assert
      expect(csvString, contains('id,title,description,due_date,priority,category,is_completed,completed_at,created_at,updated_at'));
      expect(csvString, contains('task-1'));
      expect(csvString, contains('"Beli Susu, Roti"')); // escaped because of comma
      expect(csvString, contains('"Kerjakan PR ""Matematika"""')); // escaped because of quotes
      expect(csvString, contains('PR Aljabar bab 3'));
    });

    test('should parse CSV string back to tasks correctly', () {
      // Arrange
      final csvString = CsvTaskHelper.tasksToCsv(tasks);

      // Act
      final decodedTasks = CsvTaskHelper.csvToTasks(csvString);

      // Assert
      expect(decodedTasks.length, 2);
      
      final task1 = decodedTasks[0];
      expect(task1.id, 'task-1');
      expect(task1.title, 'Beli Susu, Roti');
      expect(task1.description, 'Beli susu segar & roti gandum di minimarket.');
      expect(task1.dueDate, dueDate);
      expect(task1.priority, 'low');
      expect(task1.category, 'Belanja');
      expect(task1.isCompleted, false);
      expect(task1.completedAt, isNull);

      final task2 = decodedTasks[1];
      expect(task2.id, 'task-2');
      expect(task2.title, 'Kerjakan PR "Matematika"');
      expect(task2.description, 'PR Aljabar bab 3, halaman 45-50.');
      expect(task2.dueDate, isNull);
      expect(task2.priority, 'high');
      expect(task2.category, 'Belajar');
      expect(task2.isCompleted, true);
      expect(task2.completedAt, now);
    });

    test('should handle empty or invalid CSV string gracefully', () {
      // Act & Assert
      expect(CsvTaskHelper.csvToTasks(''), isEmpty);
      expect(CsvTaskHelper.csvToTasks('invalid,header,row'), isEmpty);
    });
  });
}
