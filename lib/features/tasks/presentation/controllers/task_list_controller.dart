import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../shared/providers.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/task.dart';

/// Controller state management for the Task list using [AsyncNotifier].
class TaskListController extends AsyncNotifier<List<Task>> {
  @override
  FutureOr<List<Task>> build() async {
    return _fetchTasks();
  }

  Future<List<Task>> _fetchTasks() async {
    final getTasksUsecase = ref.read(getTasksProvider);
    final result = await getTasksUsecase(const NoParams());

    return result.fold(
      onSuccess: (tasks) => tasks,
      onFailure: (failure) => throw Exception(failure.message),
    );
  }

  /// Refreshes the task list from local SQLite and triggers Cloud Sync.
  Future<void> refresh() async {
    state = const AsyncValue.loading();

    // Run Cloud Sync if the user is authenticated
    final authState = ref.read(authControllerProvider);
    final user = authState.valueOrNull;
    if (user != null && user.isAuthenticated) {
      try {
        await ref.read(syncServiceProvider).syncData(user.id);
      } catch (e) {
        debugPrint('Gagal sinkronisasi cloud saat pull-to-refresh tugas: $e');
      }
    }

    state = await AsyncValue.guard(() => _fetchTasks());
  }

  /// Adds a new task and triggers background cloud sync.
  Future<Result<void>> addTask(Task task) async {
    final createTaskUsecase = ref.read(createTaskProvider);
    final result = await createTaskUsecase(task);

    if (result is Success<void>) {
      await refresh();
      _triggerBackgroundSync();
    }
    return result;
  }

  /// Updates an existing task and triggers background cloud sync.
  Future<Result<void>> updateTask(Task task) async {
    final updateTaskUsecase = ref.read(updateTaskProvider);
    final result = await updateTaskUsecase(task);

    if (result is Success<void>) {
      await refresh();
      _triggerBackgroundSync();
    }
    return result;
  }

  /// Toggles task completion status.
  Future<Result<void>> toggleTaskCompletion(String id) async {
    final tasks = state.valueOrNull ?? [];
    try {
      final task = tasks.firstWhere((t) => t.id == id);
      final updatedTask = task.copyWith(
        isCompleted: !task.isCompleted,
        completedAt: !task.isCompleted ? DateTime.now() : null,
        updatedAt: DateTime.now(),
        isSynced: false,
      );
      return await updateTask(updatedTask);
    } catch (e) {
      return Failure('Tugas tidak ditemukan: $e');
    }
  }

  /// Deletes a task by ID and removes from cloud if connected.
  Future<Result<void>> removeTask(String id) async {
    final deleteTaskUsecase = ref.read(deleteTaskProvider);

    // Delete from cloud in the background if authenticated
    final authState = ref.read(authControllerProvider);
    authState.whenData((user) {
      if (user.isAuthenticated) {
        ref.read(trackingRemoteDataSourceProvider).deleteRemoteTask(user.id, id).catchError((_) {});
      }
    });

    final result = await deleteTaskUsecase(id);

    if (result is Success<void>) {
      await refresh();
    }
    return result;
  }

  /// Triggers background cloud sync.
  void _triggerBackgroundSync() {
    final authState = ref.read(authControllerProvider);
    authState.whenData((user) {
      if (user.isAuthenticated) {
        ref.read(syncServiceProvider).syncData(user.id).catchError((_) {});
      }
    });
  }
}

/// Global provider for the task list state.
final taskListProvider = AsyncNotifierProvider<TaskListController, List<Task>>(() {
  return TaskListController();
});

/// Task sorting options.
enum TaskSortOption {
  priority,
  dueDate,
  newest,
}

/// Provider for task completion status filter.
/// Values: 'Semua', 'Belum Selesai', 'Selesai'
final taskStatusFilterProvider = StateProvider<String>((ref) => 'Semua');

/// Provider for task category filter.
/// Values: 'Semua', or specific category names.
final taskCategoryFilterProvider = StateProvider<String>((ref) => 'Semua');

/// Provider for task sorting option.
final taskSortOptionProvider = StateProvider<TaskSortOption>((ref) => TaskSortOption.newest);

/// Helper to assign weights to priorities for sorting.
int _getPriorityWeight(String priority) {
  switch (priority.toLowerCase()) {
    case 'high':
      return 3;
    case 'medium':
      return 2;
    case 'low':
      return 1;
    default:
      return 0;
  }
}

/// Reactive provider that returns filtered and sorted tasks.
final filteredTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final tasksAsync = ref.watch(taskListProvider);
  final statusFilter = ref.watch(taskStatusFilterProvider);
  final categoryFilter = ref.watch(taskCategoryFilterProvider);
  final sortOption = ref.watch(taskSortOptionProvider);

  return tasksAsync.whenData((tasks) {
    var resultList = tasks;

    // 1. Status Filter
    if (statusFilter == 'Belum Selesai') {
      resultList = resultList.where((t) => !t.isCompleted).toList();
    } else if (statusFilter == 'Selesai') {
      resultList = resultList.where((t) => t.isCompleted).toList();
    }

    // 2. Category Filter
    if (categoryFilter != 'Semua') {
      resultList = resultList.where((t) => t.category == categoryFilter).toList();
    }

    // 3. Sorting
    switch (sortOption) {
      case TaskSortOption.priority:
        resultList = List.from(resultList)
          ..sort((a, b) {
            // Sort by priority descending
            final weightA = _getPriorityWeight(a.priority);
            final weightB = _getPriorityWeight(b.priority);
            final cmp = weightB.compareTo(weightA);
            if (cmp != 0) return cmp;
            // If same priority, sort by newest
            return b.createdAt.compareTo(a.createdAt);
          });
        break;
      case TaskSortOption.dueDate:
        resultList = List.from(resultList)
          ..sort((a, b) {
            // Sort by due date ascending (nulls last)
            if (a.dueDate == null && b.dueDate == null) {
              return b.createdAt.compareTo(a.createdAt);
            }
            if (a.dueDate == null) return 1;
            if (b.dueDate == null) return -1;
            final cmp = a.dueDate!.compareTo(b.dueDate!);
            if (cmp != 0) return cmp;
            return b.createdAt.compareTo(a.createdAt);
          });
        break;
      case TaskSortOption.newest:
        resultList = List.from(resultList)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return resultList;
  });
});
