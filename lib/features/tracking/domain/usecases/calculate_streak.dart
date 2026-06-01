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

      // 1. Ambil histori log habit
      final logsResult = await _trackingRepository.getLogsForHabit(habitId);
      if (logsResult is Failure<List<HabitLog>>) {
        return Failure(logsResult.message, logsResult.exception);
      }

      final logs = (logsResult as Success<List<HabitLog>>).data;

      // 2. Ambil data streak lama untuk mengetahui best_streak yang ada
      final streakResult = await _habitRepository.getHabitStreak(habitId);
      int previousBestStreak = 0;
      if (streakResult is Success<HabitStreak?> && streakResult.data != null) {
        previousBestStreak = streakResult.data!.bestStreak;
      }

      if (logs.isEmpty) {
        // Jika tidak ada logs, streak direset ke 0
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

      // Algoritma Streak:
      // - Urutkan logs berdasarkan tanggal descending (terbaru ke terlama)
      final sortedLogs = List<HabitLog>.from(logs)
        ..sort((a, b) => b.date.compareTo(a.date));

      int currentStreak = 0;
      String? lastCompletedDate;
      
      // Ambil tanggal hari ini dan kemarin
      final todayStr = DateFormatter.todayString;
      final yesterdayStr = DateFormatter.formatDate(
        DateTime.now().subtract(const Duration(days: 1)),
      );



      // Jika tidak ada log 'done' atau 'skipped' hari ini atau kemarin, current streak terputus (dianggap 0).
      // Kecuali jika log terbaru adalah sebelum kemarin tapi berstatus 'skipped' (skip memperpanjang masa aktif streak).
      // Untuk mempermudah perhitungan streak yang konsisten:
      // Kita berjalan mundur hari demi hari mulai dari hari terakhir yang berstatus 'done'.
      
      // Cari log 'done' terbaru untuk menentukan lastCompletedDate
      final doneLogs = sortedLogs.where((l) => l.status == 'done').toList();
      if (doneLogs.isNotEmpty) {
        lastCompletedDate = doneLogs.first.date;
      }

      // Perhitungan current streak:
      // Mulai dari hari ini (atau kemarin jika hari ini belum diisi), lalu melangkah mundur ke belakang.
      // Jika menemukan 'done': streak++
      // Jika menemukan 'skipped': streak tidak bertambah, tapi pencarian berlanjut (tidak memutus streak).
      // Jika menemukan 'missed' atau hari tersebut kosong (tidak diisi log tapi sudah terlewat): streak terputus!
      
      String currentDatePointer = todayStr;
      
      // Jika hari ini belum log dan kemarin juga belum log, streak terputus.
      // Jika hari ini belum log tapi kemarin 'done'/'skipped', kita mulai penelusuran dari kemarin.
      final todayLog = sortedLogs.firstWhere(
        (l) => l.date == todayStr,
        orElse: () => const HabitLog(id: '', habitId: '', date: '', status: ''),
      );

      if (todayLog.date.isEmpty) {
        // Hari ini belum di-log, mulai dari kemarin
        currentDatePointer = yesterdayStr;
      }

      bool isBroken = false;
      while (!isBroken) {
        final dateLog = sortedLogs.firstWhere(
          (l) => l.date == currentDatePointer,
          orElse: () => const HabitLog(id: '', habitId: '', date: '', status: ''),
        );

        if (dateLog.date.isNotEmpty) {
          if (dateLog.status == 'done') {
            currentStreak++;
          } else if (dateLog.status == 'skipped') {
            // Skipped mempertahankan streak, tidak memutus, tidak menambah.
          } else if (dateLog.status == 'missed') {
            isBroken = true;
          }
        } else {
          // Jika tanggal tersebut kosong (tidak ada log):
          // Jika pointer menunjuk ke hari ini dan belum diisi, kita toleransi (boleh dilewati).
          // Tapi jika pointer menunjuk ke hari kemarin atau sebelumnya dan kosong, streak terputus.
          if (currentDatePointer != todayStr) {
            isBroken = true;
          }
        }

        // Mundur 1 hari
        final currentDT = DateFormatter.parseDate(currentDatePointer);
        currentDatePointer = DateFormatter.formatDate(
          currentDT.subtract(const Duration(days: 1)),
        );
        
        // Pengaman: Jika sudah melampaui log terlama, hentikan loop
        if (sortedLogs.isNotEmpty) {
          final oldestDate = sortedLogs.last.date;
          if (currentDatePointer.compareTo(oldestDate) < 0) {
            break;
          }
        } else {
          break;
        }
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

      // Simpan streak ke database via repository
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
