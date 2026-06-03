import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../habits/data/datasources/habit_local_data_source.dart';
import '../../../tasks/data/datasources/task_local_data_source.dart';
import '../../domain/usecases/calculate_streak.dart';
import '../datasources/tracking_local_data_source.dart';
import '../datasources/tracking_remote_data_source.dart';

/// Layanan sinkronisasi otomatis Offline-First.
/// Mengatur kapan data kotor lokal harus diunggah, menarik pembaruan cloud,
/// dan menyelesaikan konflik data menggunakan aturan "Last Write Wins" (Timestamp terbaru).
class SyncService {
  final HabitLocalDataSource _localHabitDS;
  final TrackingLocalDataSource _localLogDS;
  final TaskLocalDataSource _localTaskDS;
  final TrackingRemoteDataSource _remoteDS;
  final Connectivity _connectivity;
  final CalculateStreak _calculateStreak;

  SyncService({
    required HabitLocalDataSource localHabitDS,
    required TrackingLocalDataSource localLogDS,
    required TaskLocalDataSource localTaskDS,
    required TrackingRemoteDataSource remoteDS,
    required CalculateStreak calculateStreak,
    Connectivity? connectivity,
  })  : _localHabitDS = localHabitDS,
        _localLogDS = localLogDS,
        _localTaskDS = localTaskDS,
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

      // 3. Ambil & Upload Tasks lokal yang belum tersinkron
      final unsyncedTasks = await _localTaskDS.getUnsyncedTasks();
      print('📤 [SYNC] Ditemukan ${unsyncedTasks.length} tugas lokal belum tersinkron.');
      for (final task in unsyncedTasks) {
        print('   📤 Mengunggah tugas: "${task.title}" (${task.id})');
        await _remoteDS.uploadTask(userId, task);
        await _localTaskDS.markTaskAsSynced(task.id);
        print('   ✅ Tugas "${task.title}" berhasil diunggah & ditandai synced.');
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
        // Validasi keberadaan habit parent di SQLite lokal demi menjaga integritas Foreign Key
        final parentHabit = await _localHabitDS.getHabitById(remoteLog.habitId);
        if (parentHabit == null) {
          print('   ⚠️ Menemukan log yatim piatu (parent habit ${remoteLog.habitId} tidak ditemukan di lokal).');
          try {
            await _remoteDS.deleteRemoteHabitLog(userId, remoteLog.id);
            print('   🧹 Log yatim piatu (${remoteLog.id}) berhasil dibersihkan dari Cloud.');
          } catch (e) {
            print('   ❌ Gagal membersihkan log yatim piatu (${remoteLog.id}) dari Cloud: $e');
          }
          continue;
        }

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

      // 3. Tarik & Sinkronisasikan Tasks dari Cloud
      final remoteTasks = await _remoteDS.fetchRemoteTasks(userId);
      print('📥 [SYNC] Ditemukan ${remoteTasks.length} tugas di Cloud Firestore.');
      for (final remoteTask in remoteTasks) {
        final localTask = await _localTaskDS.getTaskById(remoteTask.id);
        if (localTask == null) {
          // Belum ada di SQLite lokal, langsung masukkan
          print('   📥 Memasukkan tugas baru dari cloud: "${remoteTask.title}" (${remoteTask.id})');
          await _localTaskDS.insertTask(remoteTask);
          await _localTaskDS.markTaskAsSynced(remoteTask.id);
          print('   ✅ Tugas "${remoteTask.title}" berhasil dimasukkan ke SQLite lokal.');
        } else {
          // Resolusi Konflik: Bandingkan updatedAt (Last Write Wins)
          final remoteUpdate = remoteTask.updatedAt;
          final localUpdate = localTask.updatedAt;

          if (remoteUpdate.isAfter(localUpdate)) {
            // Data cloud lebih baru, perbarui SQLite lokal
            print('   🔃 Memperbarui tugas lokal dengan versi cloud: "${remoteTask.title}"');
            await _localTaskDS.updateTask(remoteTask);
            await _localTaskDS.markTaskAsSynced(remoteTask.id);
          } else {
            print('   ⏭️ Tugas "${remoteTask.title}" sudah up-to-date di lokal.');
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
