import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database_helper.dart';
import '../core/utils/date_formatter.dart';
import '../features/habits/data/datasources/habit_local_data_source.dart';
import '../features/habits/data/repositories/habit_repository_impl.dart';
import '../features/habits/domain/entities/habit_streak.dart';
import '../features/habits/domain/repositories/habit_repository.dart';
import '../features/habits/domain/usecases/create_habit.dart';
import '../features/habits/domain/usecases/delete_habit.dart';
import '../features/habits/domain/usecases/get_habit_by_id.dart';
import '../features/habits/domain/usecases/get_habits.dart';
import '../features/habits/domain/usecases/update_habit.dart';
import '../features/tracking/data/datasources/tracking_local_data_source.dart';
import '../features/tracking/data/datasources/tracking_remote_data_source.dart';
import '../features/tracking/data/services/sync_service.dart';
import '../features/tracking/data/repositories/tracking_repository_impl.dart';
import '../features/tracking/domain/entities/habit_log.dart';
import '../features/tracking/domain/repositories/tracking_repository.dart';
import '../features/tracking/domain/usecases/calculate_streak.dart';
import '../features/tracking/domain/usecases/get_logs_for_habit.dart';
import '../features/tracking/domain/usecases/track_habit_day.dart';
import '../features/tasks/data/datasources/task_local_data_source.dart';
import '../features/tasks/data/repositories/task_repository_impl.dart';
import '../features/tasks/domain/repositories/task_repository.dart';
import '../features/tasks/domain/usecases/create_task.dart';
import '../features/tasks/domain/usecases/get_tasks.dart';
import '../features/tasks/domain/usecases/update_task.dart';
import '../features/tasks/domain/usecases/delete_task.dart';
import '../features/dashboard/data/services/google_calendar_service.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/journal/data/datasources/journal_local_data_source.dart';
import '../features/journal/data/repositories/journal_repository_impl.dart';
import '../features/journal/domain/repositories/journal_repository.dart';
import '../core/services/backup_service.dart';
import '../core/services/google_drive_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

final googleCalendarServiceProvider = Provider<GoogleCalendarService>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return GoogleCalendarService(authRepository: authRepository);
});

final googleDriveServiceProvider = Provider<GoogleDriveService>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return GoogleDriveService(authRepository: authRepository);
});

// ==========================================
// 1. DATABASE & DATA SOURCES PROVIDERS
// ==========================================

/// Provider untuk mengakses SharedPreferences secara sinkron (wajib di-override di main.dart)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in ProviderScope');
});

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

final habitLocalDataSourceProvider = Provider<HabitLocalDataSource>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return HabitLocalDataSource(dbHelper);
});

final trackingLocalDataSourceProvider = Provider<TrackingLocalDataSource>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return TrackingLocalDataSource(dbHelper);
});

final taskLocalDataSourceProvider = Provider<TaskLocalDataSource>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return TaskLocalDataSource(dbHelper);
});

final journalLocalDataSourceProvider = Provider<JournalLocalDataSource>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return JournalLocalDataSource(dbHelper);
});

final trackingRemoteDataSourceProvider = Provider<TrackingRemoteDataSource>((ref) {
  return TrackingRemoteDataSource();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final localHabitDS = ref.watch(habitLocalDataSourceProvider);
  final localLogDS = ref.watch(trackingLocalDataSourceProvider);
  final localTaskDS = ref.watch(taskLocalDataSourceProvider);
  final remoteDS = ref.watch(trackingRemoteDataSourceProvider);
  final calculateStreak = ref.watch(calculateStreakProvider);
  return SyncService(
    localHabitDS: localHabitDS,
    localLogDS: localLogDS,
    localTaskDS: localTaskDS,
    remoteDS: remoteDS,
    calculateStreak: calculateStreak,
  );
});


// ==========================================
// 2. REPOSITORIES PROVIDERS
// ==========================================

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final localDataSource = ref.watch(habitLocalDataSourceProvider);
  return HabitRepositoryImpl(localDataSource);
});

final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  final localDataSource = ref.watch(trackingLocalDataSourceProvider);
  return TrackingRepositoryImpl(localDataSource);
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final localDataSource = ref.watch(taskLocalDataSourceProvider);
  return TaskRepositoryImpl(localDataSource);
});

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  final localDataSource = ref.watch(journalLocalDataSourceProvider);
  return JournalRepositoryImpl(localDataSource);
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService();
});

// ==========================================
// 3. USE CASES PROVIDERS
// ==========================================

// Habits Usecases
final createHabitProvider = Provider<CreateHabit>((ref) {
  final repository = ref.watch(habitRepositoryProvider);
  return CreateHabit(repository);
});

final getHabitsProvider = Provider<GetHabits>((ref) {
  final repository = ref.watch(habitRepositoryProvider);
  return GetHabits(repository);
});

final getHabitByIdProvider = Provider<GetHabitById>((ref) {
  final repository = ref.watch(habitRepositoryProvider);
  return GetHabitById(repository);
});

final updateHabitProvider = Provider<UpdateHabit>((ref) {
  final repository = ref.watch(habitRepositoryProvider);
  return UpdateHabit(repository);
});

final deleteHabitProvider = Provider<DeleteHabit>((ref) {
  final repository = ref.watch(habitRepositoryProvider);
  return DeleteHabit(repository);
});

// Tasks Usecases
final createTaskProvider = Provider<CreateTask>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return CreateTask(repository);
});

final getTasksProvider = Provider<GetTasks>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return GetTasks(repository);
});

final updateTaskProvider = Provider<UpdateTask>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return UpdateTask(repository);
});

final deleteTaskProvider = Provider<DeleteTask>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return DeleteTask(repository);
});

// Tracking Usecases
final calculateStreakProvider = Provider<CalculateStreak>((ref) {
  final trackingRepository = ref.watch(trackingRepositoryProvider);
  final habitRepository = ref.watch(habitRepositoryProvider);
  return CalculateStreak(trackingRepository, habitRepository);
});

final trackHabitDayProvider = Provider<TrackHabitDay>((ref) {
  final trackingRepository = ref.watch(trackingRepositoryProvider);
  final calculateStreak = ref.watch(calculateStreakProvider);
  return TrackHabitDay(trackingRepository, calculateStreak);
});

final getLogsForHabitProvider = Provider<GetLogsForHabit>((ref) {
  final repository = ref.watch(trackingRepositoryProvider);
  return GetLogsForHabit(repository);
});

// ==========================================
// 4. PRESENTATION UTILITY PROVIDERS (REACTIVE FAMILIES)
// ==========================================

final habitStreakProvider = FutureProvider.family<HabitStreak?, String>((ref, habitId) async {
  final repository = ref.watch(habitRepositoryProvider);
  final result = await repository.getHabitStreak(habitId);
  return result.fold(
    onSuccess: (streak) => streak,
    onFailure: (_) => null,
  );
});

final habitTodayLogProvider = FutureProvider.family<HabitLog?, String>((ref, habitId) async {
  final repository = ref.watch(trackingRepositoryProvider);
  final todayStr = DateFormatter.todayString;
  final result = await repository.getLogForHabitAndDate(habitId, todayStr);
  return result.fold(
    onSuccess: (log) => log,
    onFailure: (_) => null,
  );
});

final habitWeeklyCompletionsProvider = FutureProvider.family<int, String>((ref, habitId) async {
  final repository = ref.watch(trackingRepositoryProvider);
  final result = await repository.getLogsForHabit(habitId);
  return result.fold(
    onSuccess: (logs) {
      final now = DateTime.now();
      final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      final mondayStr = DateFormatter.formatDate(monday);
      final sundayStr = DateFormatter.formatDate(sunday);
      
      return logs.where((l) => 
        l.status == 'done' && 
        l.date.compareTo(mondayStr) >= 0 && 
        l.date.compareTo(sundayStr) <= 0
      ).length;
    },
    onFailure: (_) => 0,
  );
});

class AutoBackupNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;
  AutoBackupNotifier(this._prefs) : super(_prefs.getString('auto_backup_frequency') ?? 'off');

  Future<void> setFrequency(String val) async {
    await _prefs.setString('auto_backup_frequency', val);
    state = val;
  }
}

final autoBackupFrequencyProvider = StateNotifierProvider<AutoBackupNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AutoBackupNotifier(prefs);
});

class LastBackupTimeNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;
  LastBackupTimeNotifier(this._prefs) : super(_prefs.getString('last_backup_time') ?? 'Belum pernah');

  Future<void> updateLastBackupTime() async {
    final nowStr = DateTime.now().toIso8601String();
    await _prefs.setString('last_backup_time', nowStr);
    state = nowStr;
  }

  Future<void> setLastBackupTime(String val) async {
    await _prefs.setString('last_backup_time', val);
    state = val;
  }
}

final lastBackupTimeProvider = StateNotifierProvider<LastBackupTimeNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LastBackupTimeNotifier(prefs);
});

/// Provider pemicu auto-backup terjadwal ke Google Drive di latar belakang.
final autoBackupTriggerProvider = Provider<void>((ref) {
  final authState = ref.watch(authControllerProvider);
  final user = authState.valueOrNull;
  if (user == null || user.isGuest || user.id == 'demo_user_google_123') return;

  final freq = ref.watch(autoBackupFrequencyProvider);
  if (freq == 'off') return;

  final lastBackupStr = ref.watch(lastBackupTimeProvider);

  // Jalankan asinkron setelah build selesai untuk menghindari side-effects selama fasa render
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final now = DateTime.now();
    bool shouldBackup = false;

    if (lastBackupStr == 'Belum pernah') {
      shouldBackup = true;
    } else {
      try {
        final lastBackup = DateTime.parse(lastBackupStr);
        final diff = now.difference(lastBackup);
        if (freq == 'daily' && diff.inDays >= 1) {
          shouldBackup = true;
        } else if (freq == 'weekly' && diff.inDays >= 7) {
          shouldBackup = true;
        }
      } catch (_) {
        shouldBackup = true;
      }
    }

    if (shouldBackup) {
      debugPrint('Auto-Backup: Memulai pengunggahan terjadwal otomatis...');
      try {
        final hasScope = await ref.read(authRepositoryProvider).requestDriveScope();
        if (hasScope) {
          final backupData = await ref.read(backupServiceProvider).exportBackup();
          final success = await ref.read(googleDriveServiceProvider).uploadBackup(backupData);
          if (success) {
            await ref.read(lastBackupTimeProvider.notifier).updateLastBackupTime();
            debugPrint('Auto-Backup: Sukses mencadangkan ke Google Drive.');
          } else {
            debugPrint('Auto-Backup: Gagal mengunggah berkas.');
          }
        } else {
          debugPrint('Auto-Backup: Otorisasi Google Drive belum diberikan.');
        }
      } catch (e) {
        debugPrint('Auto-Backup: Gagal melakukan sinkronisasi otomatis: $e');
      }
    }
  });
});
