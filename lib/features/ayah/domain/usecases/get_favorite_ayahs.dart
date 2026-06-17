import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/daily_ayah.dart';
import '../repositories/ayah_repository.dart';

class GetFavoriteAyahs implements UseCase<List<DailyAyah>, NoParams> {
  final AyahRepository _repository;

  GetFavoriteAyahs(this._repository);

  @override
  Future<Result<List<DailyAyah>>> call(NoParams params) async {
    try {
      final list = await _repository.getFavoriteAyahs();
      return Success(list);
    } catch (e) {
      return Failure('Gagal mengambil daftar ayat favorit: $e', e);
    }
  }
}
