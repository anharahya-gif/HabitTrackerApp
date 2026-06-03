import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' hide DatabaseException;
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/exception.dart';
import '../models/task_model.dart';

/// Local data source for interacting with the SQLite database for Task operations.
class TaskLocalDataSource {
  final DatabaseHelper _dbHelper;

  TaskLocalDataSource(this._dbHelper);

  // In-memory mock data for web platform compatibility
  static final List<TaskModel> _webTasks = [];

  /// Inserts a new Task into the database.
  Future<void> insertTask(TaskModel task) async {
    if (kIsWeb) {
      _webTasks.add(task);
      return;
    }

    try {
      final db = await _dbHelper.database;
      await db.insert(
        'tasks',
        task.toSqlMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw DatabaseException('Gagal menyimpan tugas baru ke database.', e);
    }
  }

  /// Retrieves all tasks from the database.
  Future<List<TaskModel>> getAllTasks() async {
    if (kIsWeb) {
      return List.from(_webTasks);
    }

    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'tasks',
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => TaskModel.fromSqlMap(map)).toList();
    } catch (e) {
      throw DatabaseException('Gagal mengambil daftar tugas.', e);
    }
  }

  /// Retrieves a specific task by its ID.
  Future<TaskModel?> getTaskById(String id) async {
    if (kIsWeb) {
      try {
        return _webTasks.firstWhere((t) => t.id == id);
      } catch (_) {
        return null;
      }
    }

    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'tasks',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return TaskModel.fromSqlMap(maps.first);
    } catch (e) {
      throw DatabaseException('Gagal mengambil detail tugas dengan ID: $id.', e);
    }
  }

  /// Updates an existing task.
  Future<void> updateTask(TaskModel task) async {
    if (kIsWeb) {
      final index = _webTasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _webTasks[index] = task;
      }
      return;
    }

    try {
      final db = await _dbHelper.database;
      final rowsAffected = await db.update(
        'tasks',
        task.toSqlMap(),
        where: 'id = ?',
        whereArgs: [task.id],
      );
      if (rowsAffected == 0) {
        throw DatabaseException('Tugas tidak ditemukan untuk diperbarui.');
      }
    } catch (e) {
      throw DatabaseException('Gagal memperbarui tugas.', e);
    }
  }

  /// Deletes a task by its ID.
  Future<void> deleteTask(String id) async {
    if (kIsWeb) {
      _webTasks.removeWhere((t) => t.id == id);
      return;
    }

    try {
      final db = await _dbHelper.database;
      final rowsAffected = await db.delete(
        'tasks',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rowsAffected == 0) {
        throw DatabaseException('Tugas tidak ditemukan untuk dihapus.');
      }
    } catch (e) {
      throw DatabaseException('Gagal menghapus tugas dari database.', e);
    }
  }

  /// Retrieves tasks that are not synchronized with the cloud.
  Future<List<TaskModel>> getUnsyncedTasks() async {
    if (kIsWeb) {
      return _webTasks.where((t) => !t.isSynced).toList();
    }

    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'tasks',
        where: 'is_synced = ?',
        whereArgs: [0],
      );
      return maps.map((map) => TaskModel.fromSqlMap(map)).toList();
    } catch (e) {
      throw DatabaseException('Gagal mengambil daftar tugas yang belum tersinkronisasi.', e);
    }
  }

  /// Marks a task as synchronized in SQLite.
  Future<void> markTaskAsSynced(String id) async {
    if (kIsWeb) {
      final index = _webTasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        _webTasks[index] = TaskModel.fromEntity(
          _webTasks[index].copyWith(isSynced: true),
        );
      }
      return;
    }

    try {
      final db = await _dbHelper.database;
      await db.update(
        'tasks',
        {'is_synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException('Gagal menandai sinkronisasi tugas di SQLite.', e);
    }
  }
}
