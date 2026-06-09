import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_app/core/errors/failure.dart';
import 'package:habit_tracker_app/core/utils/date_formatter.dart';
import 'package:habit_tracker_app/features/habits/domain/entities/habit.dart';
import 'package:habit_tracker_app/features/habits/domain/entities/habit_streak.dart';
import 'package:habit_tracker_app/features/habits/domain/repositories/habit_repository.dart';
import 'package:habit_tracker_app/features/tracking/domain/entities/habit_log.dart';
import 'package:habit_tracker_app/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:habit_tracker_app/features/tracking/domain/usecases/calculate_streak.dart';

class MockHabitRepository implements HabitRepository {
  final Map<String, Habit> habits = {};
  final Map<String, HabitStreak> streaks = {};

  @override
  Future<Result<void>> createHabit(Habit habit) async {
    habits[habit.id] = habit;
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteHabit(String id) async => const Success(null);

  @override
  Future<Result<Habit?>> getHabitById(String id) async => Success(habits[id]);

  @override
  Future<Result<HabitStreak?>> getHabitStreak(String habitId) async => Success(streaks[habitId]);

  @override
  Future<Result<List<Habit>>> getHabits() async => Success(habits.values.toList());

  @override
  Future<Result<void>> toggleArchiveHabit(String id, bool isArchived) async => const Success(null);

  @override
  Future<Result<void>> updateHabit(Habit habit) async {
    habits[habit.id] = habit;
    return const Success(null);
  }

  @override
  Future<Result<void>> updateHabitStreak(HabitStreak streak) async {
    streaks[streak.habitId] = streak;
    return const Success(null);
  }
}

class MockTrackingRepository implements TrackingRepository {
  final Map<String, List<HabitLog>> logs = {};

  @override
  Future<Result<void>> deleteLog(String id) async => const Success(null);

  @override
  Future<Result<List<HabitLog>>> getAllLogs() async => const Success([]);

  @override
  Future<Result<HabitLog?>> getLogForHabitAndDate(String habitId, String date) async {
    final list = logs[habitId] ?? [];
    final match = list.where((l) => l.date == date);
    return Success(match.isEmpty ? null : match.first);
  }

  @override
  Future<Result<List<HabitLog>>> getLogsForHabit(String habitId) async => Success(logs[habitId] ?? []);

  @override
  Future<Result<void>> saveLog(HabitLog log) async {
    final list = logs[log.habitId] ?? [];
    list.removeWhere((l) => l.date == log.date);
    list.add(log);
    logs[log.habitId] = list;
    return const Success(null);
  }
}

void main() {
  late MockHabitRepository habitRepo;
  late MockTrackingRepository trackingRepo;
  late CalculateStreak calculateStreak;

  setUp(() {
    habitRepo = MockHabitRepository();
    trackingRepo = MockTrackingRepository();
    calculateStreak = CalculateStreak(trackingRepo, habitRepo);
  });

  group('CalculateStreak Usecase Tests with Custom Frequencies', () {
    test('1. Daily Habit Streak', () async {
      // Create a daily habit
      final habit = Habit(
        id: 'h-daily',
        name: 'Olahraga',
        category: 'Kesehatan',
        type: 'daily',
        color: 0xFFFFFFFF,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      );
      await habitRepo.createHabit(habit);

      // Log 3 consecutive days prior to today
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final dayBefore = today.subtract(const Duration(days: 2));
      final threeDaysAgo = today.subtract(const Duration(days: 3));

      await trackingRepo.saveLog(HabitLog(id: '1', habitId: habit.id, date: DateFormatter.formatDate(threeDaysAgo), status: 'done'));
      await trackingRepo.saveLog(HabitLog(id: '2', habitId: habit.id, date: DateFormatter.formatDate(dayBefore), status: 'done'));
      await trackingRepo.saveLog(HabitLog(id: '3', habitId: habit.id, date: DateFormatter.formatDate(yesterday), status: 'done'));

      final result = await calculateStreak(habit.id);
      expect(result is Success<HabitStreak>, true);
      final streak = (result as Success<HabitStreak>).data;
      expect(streak.currentStreak, 3);
      expect(streak.bestStreak, 3);

      // Complete today
      await trackingRepo.saveLog(HabitLog(id: '4', habitId: habit.id, date: DateFormatter.formatDate(today), status: 'done'));
      final result2 = await calculateStreak(habit.id);
      expect((result2 as Success<HabitStreak>).data.currentStreak, 4);

      // Skip yesterday but keep done dayBefore and today
      // Let's clear logs first and add them back
      trackingRepo.logs[habit.id] = [];
      await trackingRepo.saveLog(HabitLog(id: '5', habitId: habit.id, date: DateFormatter.formatDate(dayBefore), status: 'done'));
      await trackingRepo.saveLog(HabitLog(id: '6', habitId: habit.id, date: DateFormatter.formatDate(yesterday), status: 'skipped'));
      await trackingRepo.saveLog(HabitLog(id: '7', habitId: habit.id, date: DateFormatter.formatDate(today), status: 'done'));

      final result3 = await calculateStreak(habit.id);
      // streak should be 2 because skipped preserves the streak but doesn't increase the count
      expect((result3 as Success<HabitStreak>).data.currentStreak, 2);
    });

    test('2. Specific Days (Mon, Wed, Fri) Streak', () async {
      // Create specific days habit
      final habit = Habit(
        id: 'h-specific',
        name: 'Les Musik',
        category: 'Mental/Pikiran',
        type: 'specific_days',
        color: 0xFFFFFFFF,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        frequencyConfig: jsonEncode({'days': [1, 3, 5]}), // Mon, Wed, Fri
      );
      await habitRepo.createHabit(habit);

      // Let's simulate logs on the scheduled weekdays
      // Find past Monday, Wednesday, Friday
      final now = DateTime.now();
      // We find dates of past Mon, Wed, Fri
      List<DateTime> pastDays = [];
      for (int i = 1; i <= 14; i++) {
        final d = now.subtract(Duration(days: i));
        if (d.weekday == 1 || d.weekday == 3 || d.weekday == 5) {
          pastDays.add(d);
        }
      }

      // Log 'done' for the most recent 3 scheduled days
      for (int i = 0; i < 3; i++) {
        await trackingRepo.saveLog(HabitLog(
          id: 's-$i',
          habitId: habit.id,
          date: DateFormatter.formatDate(pastDays[i]),
          status: 'done',
        ));
      }

      final result = await calculateStreak(habit.id);
      expect(result is Success<HabitStreak>, true);
      // The current streak should be 3 because all past scheduled days were completed
      expect((result as Success<HabitStreak>).data.currentStreak, 3);
    });

    test('3. Interval Days (N=2) Streak', () async {
      // Create interval habit
      final habit = Habit(
        id: 'h-interval',
        name: 'Minum Vitamin',
        category: 'Kesehatan',
        type: 'interval',
        color: 0xFFFFFFFF,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        frequencyConfig: jsonEncode({'interval_days': 2}),
      );
      await habitRepo.createHabit(habit);

      // Log every 2 days
      final today = DateTime.now();
      final twoDaysAgo = today.subtract(const Duration(days: 2));
      final fourDaysAgo = today.subtract(const Duration(days: 4));

      await trackingRepo.saveLog(HabitLog(id: 'i1', habitId: habit.id, date: DateFormatter.formatDate(fourDaysAgo), status: 'done'));
      await trackingRepo.saveLog(HabitLog(id: 'i2', habitId: habit.id, date: DateFormatter.formatDate(twoDaysAgo), status: 'done'));
      await trackingRepo.saveLog(HabitLog(id: 'i3', habitId: habit.id, date: DateFormatter.formatDate(today), status: 'done'));

      final result = await calculateStreak(habit.id);
      expect(result is Success<HabitStreak>, true);
      expect((result as Success<HabitStreak>).data.currentStreak, 3);

      // If gap exceeds interval (e.g. log yesterday but not today, and last done was 4 days ago)
      trackingRepo.logs[habit.id] = [];
      await trackingRepo.saveLog(HabitLog(id: 'i4', habitId: habit.id, date: DateFormatter.formatDate(today.subtract(const Duration(days: 4))), status: 'done'));
      // No logs for 3 days
      final result2 = await calculateStreak(habit.id);
      expect((result2 as Success<HabitStreak>).data.currentStreak, 0);
    });

    test('4. Flexible Weekly Streak', () async {
      // Create flexible weekly habit (3x per week)
      final habit = Habit(
        id: 'h-flex-weekly',
        name: 'Gym',
        category: 'Kebugaran',
        type: 'flexible_weekly',
        color: 0xFFFFFFFF,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        frequencyConfig: jsonEncode({'target_count': 3}),
      );
      await habitRepo.createHabit(habit);

      DateTime getMonday(DateTime date) {
        return DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));
      }

      final today = DateTime.now();
      final currentMonday = getMonday(today);
      final lastMonday = currentMonday.subtract(const Duration(days: 7));

      // Log 3 times last week
      await trackingRepo.saveLog(HabitLog(id: 'fw1', habitId: habit.id, date: DateFormatter.formatDate(lastMonday.add(const Duration(days: 0))), status: 'done'));
      await trackingRepo.saveLog(HabitLog(id: 'fw2', habitId: habit.id, date: DateFormatter.formatDate(lastMonday.add(const Duration(days: 2))), status: 'done'));
      await trackingRepo.saveLog(HabitLog(id: 'fw3', habitId: habit.id, date: DateFormatter.formatDate(lastMonday.add(const Duration(days: 4))), status: 'done'));

      // Log 3 times current week
      await trackingRepo.saveLog(HabitLog(id: 'fw4', habitId: habit.id, date: DateFormatter.formatDate(currentMonday.add(const Duration(days: 0))), status: 'done'));
      await trackingRepo.saveLog(HabitLog(id: 'fw5', habitId: habit.id, date: DateFormatter.formatDate(currentMonday.add(const Duration(days: 2))), status: 'done'));
      await trackingRepo.saveLog(HabitLog(id: 'fw6', habitId: habit.id, date: DateFormatter.formatDate(currentMonday.add(const Duration(days: 4))), status: 'done'));

      final result = await calculateStreak(habit.id);
      expect(result is Success<HabitStreak>, true);
      // Streak should be 2 (2 successful weeks)
      expect((result as Success<HabitStreak>).data.currentStreak, 2);
    });
  });
}
