import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/urge_log.dart';
import '../../data/models/urge_log_model.dart';
import '../../../../shared/providers.dart';

/// Controller untuk mengelola state daftar catatan pemicu hasrat (Urge Logs).
/// Menggunakan [AsyncNotifier] agar UI terhubung secara reaktif dan otomatis terupdate saat log ditambahkan/dihapus.
class UrgeLogController extends AsyncNotifier<List<UrgeLog>> {
  @override
  FutureOr<List<UrgeLog>> build() async {
    return _fetchUrgeLogs();
  }

  Future<List<UrgeLog>> _fetchUrgeLogs() async {
    final localDataSource = ref.read(urgeLocalDataSourceProvider);
    final models = await localDataSource.getUrgeLogs();
    return models.map((m) => m.toEntity()).toList();
  }

  /// Menambahkan catatan pemicu/urge baru ke SQLite.
  Future<void> addUrgeLog(UrgeLog log) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final localDataSource = ref.read(urgeLocalDataSourceProvider);
      await localDataSource.insertUrgeLog(UrgeLogModel.fromEntity(log));
      return _fetchUrgeLogs();
    });
  }

  /// Menghapus catatan pemicu/urge berdasarkan ID.
  Future<void> removeUrgeLog(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final localDataSource = ref.read(urgeLocalDataSourceProvider);
      await localDataSource.deleteUrgeLog(id);
      return _fetchUrgeLogs();
    });
  }
}

/// Provider global untuk memantau dan memperbarui Urge Logs.
final urgeLogProvider = AsyncNotifierProvider<UrgeLogController, List<UrgeLog>>(() {
  return UrgeLogController();
});
