import '../errors/failure.dart';

/// Abstraksi dasar untuk semua Use Cases di aplikasi.
/// [Type] adalah tipe data output sukses.
/// [Params] adalah tipe parameter input yang dibutuhkan Use Case.
abstract class UseCase<Type, Params> {
  const UseCase();

  /// Fungsi utama eksekusi use case.
  Future<Result<Type>> call(Params params);
}

/// Digunakan sebagai parameter ketika Use Case tidak memerlukan parameter input.
class NoParams {
  const NoParams();
}
