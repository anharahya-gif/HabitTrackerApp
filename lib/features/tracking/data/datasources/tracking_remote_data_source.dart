import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/errors/exception.dart';
import '../../../habits/data/models/habit_model.dart';
import '../../../tasks/data/models/task_model.dart';
import '../models/habit_log_model.dart';

/// Data source remote untuk berinteraksi langsung dengan Firebase Cloud Firestore.
/// Semua operasi data dibatasi per user_id di cloud demi keamanan.
class TrackingRemoteDataSource {
  final FirebaseFirestore _firestore;

  TrackingRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ==========================================================
  // OPERASI HABIT CLOUD
  // ==========================================================

  /// Mengunggah atau memperbarui data Habit ke Firestore.
  /// Lokasi: users/{userId}/habits/{habitId}
  Future<void> uploadHabit(String userId, HabitModel habit) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .doc(habit.id);

      // Konversi data ke format Firestore (menggunakan tipe native Firestore seperti boolean)
      final data = {
        'id': habit.id,
        'name': habit.name,
        'description': habit.description,
        'category': habit.category,
        'type': habit.type,
        'created_at': habit.createdAt.toIso8601String(),
        'is_archived': habit.isArchived, // Native boolean di Firestore
        'reminder_time': habit.reminderTime,
        'color': habit.color,
        'updated_at': habit.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'start_time': habit.startTime,
        'end_time': habit.endTime,
        'reminder_type': habit.reminderType,
        'alarm_sound': habit.alarmSound,
      };

      await docRef.set(data, SetOptions(merge: true));
    } catch (e) {
      throw ServerException('Gagal mengunggah habit ke Firebase: $e');
    }
  }

  /// Mengambil seluruh habit milik pengguna dari Firestore.
  Future<List<HabitModel>> fetchRemoteHabits(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return HabitModel(
          id: data['id'] as String,
          name: data['name'] as String,
          description: data['description'] as String?,
          category: data['category'] as String,
          type: data['type'] as String,
          createdAt: DateTime.parse(data['created_at'] as String),
          isArchived: data['is_archived'] as bool? ?? false,
          reminderTime: data['reminder_time'] as String?,
          color: data['color'] as int,
          isSynced: true, // Data yang ditarik dari cloud sudah otomatis sinkron
          updatedAt: data['updated_at'] != null && (data['updated_at'] as String).isNotEmpty
              ? DateTime.parse(data['updated_at'] as String)
              : DateTime.now(),
          startTime: data['start_time'] as String?,
          endTime: data['end_time'] as String?,
          reminderType: data['reminder_type'] as String? ?? 'notification',
          alarmSound: data['alarm_sound'] as String?,
        );
      }).toList();
    } catch (e) {
      throw ServerException('Gagal mengambil data habit dari Firebase: $e');
    }
  }

  /// Menghapus habit dari Firestore.
  Future<void> deleteRemoteHabit(String userId, String habitId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .doc(habitId)
          .delete();
    } catch (e) {
      throw ServerException('Gagal menghapus habit dari Firebase: $e');
    }
  }

  // ==========================================================
  // OPERASI HABIT LOGS CLOUD
  // ==========================================================

  /// Mengunggah atau memperbarui log harian Habit ke Firestore.
  /// Lokasi: users/{userId}/logs/{logId}
  Future<void> uploadHabitLog(String userId, HabitLogModel log) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('logs')
          .doc(log.id);

      final data = {
        'id': log.id,
        'habit_id': log.habitId,
        'date': log.date,
        'status': log.status,
        'completed_at': log.completedAt?.toIso8601String(),
        'updated_at': log.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      };

      await docRef.set(data, SetOptions(merge: true));
    } catch (e) {
      throw ServerException('Gagal mengunggah log habit ke Firebase: $e');
    }
  }

  /// Mengambil seluruh riwayat log habit milik pengguna dari Firestore.
  Future<List<HabitLogModel>> fetchRemoteHabitLogs(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('logs')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return HabitLogModel(
          id: data['id'] as String,
          habitId: data['habit_id'] as String,
          date: data['date'] as String,
          status: data['status'] as String,
          completedAt: data['completed_at'] != null
              ? DateTime.parse(data['completed_at'] as String)
              : null,
          isSynced: true,
          updatedAt: data['updated_at'] != null && (data['updated_at'] as String).isNotEmpty
              ? DateTime.parse(data['updated_at'] as String)
              : DateTime.now(),
        );
      }).toList();
    } catch (e) {
      throw ServerException('Gagal mengambil data logs dari Firebase: $e');
    }
  }

  /// Menghapus log habit tertentu dari Firestore.
  Future<void> deleteRemoteHabitLog(String userId, String logId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('logs')
          .doc(logId)
          .delete();
    } catch (e) {
      throw ServerException('Gagal menghapus log dari Firebase: $e');
    }
  }

  // ==========================================================
  // OPERASI TASK CLOUD
  // ==========================================================

  /// Mengunggah atau memperbarui data Task ke Firestore.
  /// Lokasi: users/{userId}/tasks/{taskId}
  Future<void> uploadTask(String userId, TaskModel task) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(task.id);

      await docRef.set(task.toFirestoreMap(), SetOptions(merge: true));
    } catch (e) {
      throw ServerException('Gagal mengunggah tugas ke Firebase: $e');
    }
  }

  /// Mengambil seluruh tugas milik pengguna dari Firestore.
  Future<List<TaskModel>> fetchRemoteTasks(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .get();

      return querySnapshot.docs.map((doc) {
        return TaskModel.fromFirestoreMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      throw ServerException('Gagal mengambil data tugas dari Firebase: $e');
    }
  }

  /// Menghapus tugas dari Firestore.
  Future<void> deleteRemoteTask(String userId, String taskId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .delete();
    } catch (e) {
      throw ServerException('Gagal menghapus tugas dari Firebase: $e');
    }
  }
}
