import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/daily_ayah.dart';
import '../repositories/ayah_repository.dart';

class GetDailyAyah implements UseCase<DailyAyah, String> {
  final AyahRepository _repository;

  GetDailyAyah(this._repository);

  /// [params] — tanggal harian dalam format YYYY-MM-DD
  @override
  Future<Result<DailyAyah>> call(String params) async {
    if (params.trim().isEmpty) {
      return const Failure('Tanggal tidak boleh kosong.');
    }
    try {
      final dailyAyah = await _repository.getDailyAyah(params);
      return Success(dailyAyah);
    } catch (e) {
      return Failure('Gagal mengambil Ayat Hari Ini: $e', e);
    }
  }
}
