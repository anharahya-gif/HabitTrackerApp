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

final googleCalendarServiceProvider = Provider<GoogleCalendarService>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return GoogleCalendarService(authRepository: authRepository);
});

// ==========================================
// 1. DATABASE & DATA SOURCES PROVIDERS
// ==========================================

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
