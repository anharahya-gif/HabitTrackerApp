import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../habits/data/datasources/habit_local_data_source.dart';
import '../../domain/usecases/calculate_streak.dart';
import '../datasources/tracking_local_data_source.dart';
import '../datasources/tracking_remote_data_source.dart';

/// Layanan sinkronisasi otomatis Offline-First.
/// Mengatur kapan data kotor lokal harus diunggah, menarik pembaruan cloud,
/// dan menyelesaikan konflik data menggunakan aturan "Last Write Wins" (Timestamp terbaru).
class SyncService {
  final HabitLocalDataSource _localHabitDS;
  final TrackingLocalDataSource _localLogDS;
  final TrackingRemoteDataSource _remoteDS;
  final Connectivity _connectivity;
  final CalculateStreak _calculateStreak;

  SyncService({
    required HabitLocalDataSource localHabitDS,
    required TrackingLocalDataSource localLogDS,
    required TrackingRemoteDataSource remoteDS,
    required CalculateStreak calculateStreak,
    Connectivity? connectivity,
  })  : _localHabitDS = localHabitDS,
        _localLogDS = localLogDS,
        _remoteDS = remoteDS,
        _calculateStreak = calculateStreak,
        _connectivity = connectivity ?? Connectivity();

  /// Menjalankan sinkronisasi data lokal SQLite dengan Cloud Firestore.
  Future<void> syncData(String userId) async {
    print('🔄 [SYNC] Memulai sinkronisasi untuk userId: $userId');

    // 1. Periksa Koneksi Internet
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      print('❌ [SYNC] Tidak ada koneksi internet. Sinkronisasi dibatalkan.');
      return;
    }
    print('✅ [SYNC] Koneksi internet aktif: $connectivityResult');

    try {
      // ==========================================================
      // FASE A: UPLOAD DATA LOKAL KOTOR (is_synced = 0)
      // ==========================================================

      // 1. Ambil & Upload Habits lokal yang belum tersinkron
      final unsyncedHabits = await _localHabitDS.getUnsyncedHabits();
      print('📤 [SYNC] Ditemukan ${unsyncedHabits.length} habit lokal belum tersinkron.');
      for (final habit in unsyncedHabits) {
        print('   📤 Mengunggah habit: "${habit.name}" (${habit.id})');
        await _remoteDS.uploadHabit(userId, habit);
        await _localHabitDS.markHabitAsSynced(habit.id);
        print('   ✅ Habit "${habit.name}" berhasil diunggah & ditandai synced.');
      }

      // 2. Ambil & Upload Logs lokal yang belum tersinkron
      final unsyncedLogs = await _localLogDS.getUnsyncedLogs();
      print('📤 [SYNC] Ditemukan ${unsyncedLogs.length} log lokal belum tersinkron.');
      for (final log in unsyncedLogs) {
        print('   📤 Mengunggah log: habitId=${log.habitId}, date=${log.date}');
        await _remoteDS.uploadHabitLog(userId, log);
        await _localLogDS.markLogAsSynced(log.id);
        print('   ✅ Log berhasil diunggah & ditandai synced.');
      }

      // ==========================================================
      // FASE B: TARIK PEMBARUAN DARI CLOUD (PULL DATA)
      // ==========================================================

      // 1. Tarik & Sinkronisasikan Habits dari Cloud
      final remoteHabits = await _remoteDS.fetchRemoteHabits(userId);
      print('📥 [SYNC] Ditemukan ${remoteHabits.length} habit di Cloud Firestore.');
      for (final remoteHabit in remoteHabits) {
        final localHabit = await _localHabitDS.getHabitById(remoteHabit.id);
        if (localHabit == null) {
          // Belum ada di SQLite lokal, langsung masukkan
          print('   📥 Memasukkan habit baru dari cloud: "${remoteHabit.name}" (${remoteHabit.id})');
          await _localHabitDS.insertHabit(remoteHabit);
          await _localHabitDS.markHabitAsSynced(remoteHabit.id);
          print('   ✅ Habit "${remoteHabit.name}" berhasil dimasukkan ke SQLite lokal.');
        } else {
          // Resolusi Konflik: Bandingkan updatedAt (Last Write Wins)
          final remoteUpdate = remoteHabit.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final localUpdate = localHabit.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

          if (remoteUpdate.isAfter(localUpdate)) {
            // Data cloud lebih baru, perbarui SQLite lokal
            print('   🔃 Memperbarui habit lokal dengan versi cloud: "${remoteHabit.name}"');
            await _localHabitDS.updateHabit(remoteHabit);
            await _localHabitDS.markHabitAsSynced(remoteHabit.id);
          } else {
            print('   ⏭️ Habit "${remoteHabit.name}" sudah up-to-date di lokal.');
          }
        }
      }

      // 2. Tarik & Sinkronisasikan Logs dari Cloud
      final remoteLogs = await _remoteDS.fetchRemoteHabitLogs(userId);
      print('📥 [SYNC] Ditemukan ${remoteLogs.length} log di Cloud Firestore.');
      for (final remoteLog in remoteLogs) {
        final localLog = await _localLogDS.getLogForHabitAndDate(
          remoteLog.habitId,
          remoteLog.date,
        );
        if (localLog == null) {
          // Belum ada di lokal, masukkan langsung
          print('   📥 Memasukkan log baru dari cloud: habitId=${remoteLog.habitId}, date=${remoteLog.date}');
          await _localLogDS.insertOrUpdateLog(remoteLog);
          await _localLogDS.markLogAsSynced(remoteLog.id);
        } else {
          // Resolusi Konflik: Bandingkan updatedAt (Last Write Wins)
          final remoteUpdate = remoteLog.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final localUpdate = localLog.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

          if (remoteUpdate.isAfter(localUpdate)) {
            // Data cloud lebih baru, perbarui SQLite lokal
            await _localLogDS.insertOrUpdateLog(remoteLog);
            await _localLogDS.markLogAsSynced(remoteLog.id);
          }
        }
      }

      // ==========================================================
      // FASE C: HITUNG ULANG STREAK UNTUK SEMUA HABIT
      // ==========================================================
      final allLocalHabits = await _localHabitDS.getAllHabits();
      print('🔥 [SYNC] Menghitung ulang streak untuk ${allLocalHabits.length} habit...');
      for (final habit in allLocalHabits) {
        await _calculateStreak(habit.id);
        print('   🔥 Streak dihitung ulang untuk: "${habit.name}"');
      }

      print('🎉 [SYNC] Sinkronisasi selesai dengan sukses!');
    } catch (e, stackTrace) {
      print('💥 [SYNC] GAGAL melakukan Cloud Sync!');
      print('💥 [SYNC] Error: $e');
      print('💥 [SYNC] StackTrace: $stackTrace');
      throw Exception('Gagal melakukan Cloud Sync: $e');
    }
  }
}
