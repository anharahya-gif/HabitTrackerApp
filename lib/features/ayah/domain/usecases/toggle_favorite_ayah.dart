import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/daily_ayah.dart';
import '../repositories/ayah_repository.dart';

class ToggleFavoriteAyahParams {
  final DailyAyah ayah;
  final bool isFavorite;

  const ToggleFavoriteAyahParams({
    required this.ayah,
    required this.isFavorite,
  });
}

class ToggleFavoriteAyah implements UseCase<void, ToggleFavoriteAyahParams> {
  final AyahRepository _repository;

  ToggleFavoriteAyah(this._repository);

  @override
  Future<Result<void>> call(ToggleFavoriteAyahParams params) async {
    try {
      await _repository.toggleFavoriteAyah(params.ayah, params.isFavorite);
      return const Success(null);
    } catch (e) {
      return Failure('Gagal memperbarui status favorit: $e', e);
    }
  }
}
