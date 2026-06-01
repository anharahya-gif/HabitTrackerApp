/// Representasi hasil operasi yang bisa sukses atau gagal.
/// Menggunakan Dart 3 Sealed Class untuk pattern matching yang type-safe.
sealed class Result<T> {
  const Result();

  /// Menjalankan fungsi [onSuccess] jika berhasil, atau [onFailure] jika gagal.
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure<T> failure) onFailure,
  }) {
    if (this is Success<T>) {
      return onSuccess((this as Success<T>).data);
    } else if (this is Failure<T>) {
      return onFailure(this as Failure<T>);
    }
    throw StateError('Unknown Result type');
  }
}

/// Menandakan operasi berhasil dengan membawa data hasil bertipe [T].
class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

/// Menandakan operasi gagal dengan membawa pesan error dan opsional exception asli.
class Failure<T> extends Result<T> {
  final String message;
  final Object? exception;
  const Failure(this.message, [this.exception]);
}

/// Base Failure Class untuk mengelompokkan jenis error di domain layer.
abstract class AppFailure {
  final String message;
  const AppFailure(this.message);
}

class DatabaseFailure extends AppFailure {
  const DatabaseFailure(super.message);
}

class CacheFailure extends AppFailure {
  const CacheFailure(super.message);
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}
