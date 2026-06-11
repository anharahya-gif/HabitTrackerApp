import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/vision_item.dart';
import '../../data/models/vision_item_model.dart';
import '../../../../shared/providers.dart';

/// Controller untuk mengelola state daftar papan visi / surat komitmen "My Why".
/// Menggunakan [AsyncNotifier] untuk menangani state pemuatan asinkron secara reaktif.
class VisionBoardController extends AsyncNotifier<List<VisionItem>> {
  @override
  FutureOr<List<VisionItem>> build() async {
    return _fetchVisionItems();
  }

  Future<List<VisionItem>> _fetchVisionItems() async {
    final localDataSource = ref.read(visionLocalDataSourceProvider);
    final models = await localDataSource.getVisionItems();
    return models.map((m) => m.toEntity()).toList();
  }

  /// Menambahkan item komitmen baru.
  Future<void> addVisionItem(VisionItem item) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final localDataSource = ref.read(visionLocalDataSourceProvider);
      await localDataSource.insertVisionItem(VisionItemModel.fromEntity(item));
      return _fetchVisionItems();
    });
  }

  /// Memperbarui item komitmen yang sudah ada.
  Future<void> updateVisionItem(VisionItem item) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final localDataSource = ref.read(visionLocalDataSourceProvider);
      await localDataSource.updateVisionItem(VisionItemModel.fromEntity(item));
      return _fetchVisionItems();
    });
  }

  /// Menghapus item komitmen berdasarkan ID.
  Future<void> removeVisionItem(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final localDataSource = ref.read(visionLocalDataSourceProvider);
      await localDataSource.deleteVisionItem(id);
      return _fetchVisionItems();
    });
  }
}

/// Provider global untuk memantau dan mengendalikan state Papan Visi "My Why".
final visionBoardProvider = AsyncNotifierProvider<VisionBoardController, List<VisionItem>>(() {
  return VisionBoardController();
});
