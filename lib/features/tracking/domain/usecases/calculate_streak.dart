import 'dart:convert';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../habits/domain/entities/habit_streak.dart';
import '../../../habits/domain/repositories/habit_repository.dart';
import '../entities/habit_log.dart';
import '../repositories/tracking_repository.dart';

/// Usecase untuk mengalkulasi ulang statistik streak (current streak & best streak)
/// dari suatu habit berdasarkan histori logs, lalu menyimpan hasilnya ke database.
class CalculateStreak implements UseCase<HabitStreak, String> {
  final TrackingRepository _trackingRepository;
  final HabitRepository _habitRepository;

  CalculateStreak(this._trackingRepository, this._habitRepository);

  @override
  Future<Result<HabitStreak>> call(String habitId) async {
    try {
      if (habitId.trim().isEmpty) {
        return const Failure('ID Habit tidak boleh kosong.');
      }

      // 1. Ambil data Habit
      final habitResult = await _habitRepository.getHabitById(habitId);
      if (habitResult is Failure) {
        return Failure((habitResult as Failure).message, (habitResult as Failure).exception);
      }
      final habit = (habitResult as Success).data;
      if (habit == null) {
        return const Failure('Habit tidak ditemukan.');
      }

      // 2. Ambil histori log habit
      final logsResult = await _trackingRepository.getLogsForHabit(habitId);
      if (logsResult is Failure<List<HabitLog>>) {
        return Failure(logsResult.message, logsResult.exception);
      }

      final logs = (logsResult as Success<List<HabitLog>>).data;

      // 3. Ambil data streak lama untuk mengetahui best_streak yang ada
      final streakResult = await _habitRepository.getHabitStreak(habitId);
      int previousBestStreak = 0;
      if (streakResult is Success<HabitStreak?> && streakResult.data != null) {
        previousBestStreak = streakResult.data!.bestStreak;
      }

      if (logs.isEmpty) {
        final newStreak = HabitStreak(
          habitId: habitId,
          currentStreak: 0,
          bestStreak: previousBestStreak,
          lastCompletedDate: null,
        );
        final saveResult = await _habitRepository.updateHabitStreak(newStreak);
        if (saveResult is Failure<void>) {
          return Failure(saveResult.message, saveResult.exception);
        }
        return Success(newStreak);
      }

      // Urutkan logs berdasarkan tanggal descending (terbaru ke terlama)
      final sortedLogs = List<HabitLog>.from(logs)
        ..sort((a, b) => b.date.compareTo(a.date));

      // Cari log 'done' terbaru untuk menentukan lastCompletedDate
      String? lastCompletedDate;
      final doneLogs = sortedLogs.where((l) => l.status == 'done').toList();
      if (doneLogs.isNotEmpty) {
        lastCompletedDate = doneLogs.first.date;
      }

      int currentStreak = 0;
      final todayStr = DateFormatter.todayString;

      // Parse Config
      Map<String, dynamic> config = {};
      if (habit.frequencyConfig != null && habit.frequencyConfig!.isNotEmpty) {
        try {
          config = jsonDecode(habit.frequencyConfig!) as Map<String, dynamic>;
        } catch (e) {
          // ignore
        }
      }

      if (habit.type == 'specific_days') {
        final days = List<int>.from(config['days'] ?? [1, 3, 5]);
        int streakVal = 0;
        bool isBroken = false;
        DateTime pointer = DateTime.now();

        while (!isBroken) {
          final dateStr = DateFormatter.formatDate(pointer);
          final weekday = pointer.weekday; // 1 = Mon, 7 = Sun

          if (days.contains(weekday)) {
            final dateLog = sortedLogs.firstWhere(
              (l) => l.date == dateStr,
              orElse: () => const HabitLog(id: '', habitId: '', date: '', status: ''),
            );

            if (dateLog.date.isNotEmpty) {
              if (dateLog.status == 'done') {
                streakVal++;
              } else if (dateLog.status == 'skipped') {
                // skipped preserves streak but doesn't increment count
              } else {
                isBroken = true;
              }
            } else {
              // Kosong (belum di-log)
              if (dateStr == todayStr) {
                // Hari ini boleh kosong (ongoing)
              } else {
                isBroken = true;
              }
            }
          }

          pointer = pointer.subtract(const Duration(days: 1));
          
          // Safety break if we are past the oldest log
          if (sortedLogs.isNotEmpty) {
            final oldestDate = sortedLogs.last.date;
            if (DateFormatter.formatDate(pointer).compareTo(oldestDate) < 0) {
              break;
            }
          } else {
            break;
          }
        }
        currentStreak = streakVal;

      } else if (habit.type == 'interval') {
        final intervalDays = config['interval_days'] as int? ?? 2;
        final activeLogs = sortedLogs.where((l) => l.status == 'done' || l.status == 'skipped').toList();

        if (activeLogs.isEmpty) {
          currentStreak = 0;
        } else {
          final mostRecent = activeLogs.first;
          final daysSinceLast = DateFormatter.daysBetween(mostRecent.date, todayStr);

          if (daysSinceLast > intervalDays) {
            currentStreak = 0;
          } else {
            int streakVal = 0;
            for (int i = 0; i < activeLogs.length; i++) {
              final log = activeLogs[i];
              if (i > 0) {
                final prevLog = activeLogs[i - 1];
                final gap = DateFormatter.daysBetween(log.date, prevLog.date);
                if (gap > intervalDays) {
                  break;
                }
              }
              if (log.status == 'done') {
                streakVal++;
              }
            }
            currentStreak = streakVal;
          }
        }

      } else if (habit.type == 'flexible_weekly' || habit.type == 'weekly') {
        final targetCount = habit.type == 'weekly' ? 1 : (config['target_count'] as int? ?? 3);

        DateTime getMonday(DateTime date) {
          return DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));
        }

        int countCompletionsInWeek(DateTime monday) {
          final sunday = monday.add(const Duration(days: 6));
          final mondayStr = DateFormatter.formatDate(monday);
          final sundayStr = DateFormatter.formatDate(sunday);
          
          return sortedLogs.where((l) => 
            l.status == 'done' && 
            l.date.compareTo(mondayStr) >= 0 && 
            l.date.compareTo(sundayStr) <= 0
          ).length;
        }

        final today = DateTime.now();
        final currentMonday = getMonday(today);

        // Check current week status
        final currentWeekCompletions = countCompletionsInWeek(currentMonday);
        final remainingDaysInCurrentWeek = 7 - today.weekday; // including today if not complete

        bool isCurrentWeekFailed = false;
        bool isCurrentWeekSuccess = currentWeekCompletions >= targetCount;

        if (!isCurrentWeekSuccess) {
          if (currentWeekCompletions + remainingDaysInCurrentWeek + 1 < targetCount) {
            isCurrentWeekFailed = true;
          }
        }

        if (isCurrentWeekFailed) {
          currentStreak = 0;
        } else {
          int successfulWeeks = isCurrentWeekSuccess ? 1 : 0;
          DateTime weekMonday = currentMonday.subtract(const Duration(days: 7));
          bool isBroken = false;

          while (!isBroken) {
            final completions = countCompletionsInWeek(weekMonday);
            if (completions >= targetCount) {
              successfulWeeks++;
            } else {
              // Streak broken in past week
              isBroken = true;
            }
            weekMonday = weekMonday.subtract(const Duration(days: 7));

            // Safety limit: don't loop past the oldest log's week
            if (sortedLogs.isNotEmpty) {
              final oldestDate = DateFormatter.parseDate(sortedLogs.last.date);
              final oldestMonday = getMonday(oldestDate);
              if (weekMonday.isBefore(oldestMonday)) {
                break;
              }
            } else {
              break;
            }
          }
          currentStreak = successfulWeeks;
        }

      } else {
        // Daily (Default behavior)
        int streakVal = 0;
        bool isBroken = false;
        DateTime pointer = DateTime.now();

        while (!isBroken) {
          final dateStr = DateFormatter.formatDate(pointer);
          final dateLog = sortedLogs.firstWhere(
            (l) => l.date == dateStr,
            orElse: () => const HabitLog(id: '', habitId: '', date: '', status: ''),
          );

          if (dateLog.date.isNotEmpty) {
            if (dateLog.status == 'done') {
              streakVal++;
            } else if (dateLog.status == 'skipped') {
              // skip keeps streak alive but doesn't increase count
            } else {
              isBroken = true;
            }
          } else {
            if (dateStr == todayStr) {
              // Hari ini boleh kosong
            } else {
              isBroken = true;
            }
          }

          pointer = pointer.subtract(const Duration(days: 1));
          
          if (sortedLogs.isNotEmpty) {
            final oldestDate = sortedLogs.last.date;
            if (DateFormatter.formatDate(pointer).compareTo(oldestDate) < 0) {
              break;
            }
          } else {
            break;
          }
        }
        currentStreak = streakVal;
      }

      // Hitung best streak baru
      int bestStreak = previousBestStreak;
      if (currentStreak > bestStreak) {
        bestStreak = currentStreak;
      }

      final newStreak = HabitStreak(
        habitId: habitId,
        currentStreak: currentStreak,
        bestStreak: bestStreak,
        lastCompletedDate: lastCompletedDate,
      );

      final saveStreakResult = await _habitRepository.updateHabitStreak(newStreak);
      if (saveStreakResult is Failure<void>) {
        return Failure(saveStreakResult.message, saveStreakResult.exception);
      }

      return Success(newStreak);
    } catch (e) {
      return Failure('Gagal menghitung statistik streak habit.', e);
    }
  }
}
