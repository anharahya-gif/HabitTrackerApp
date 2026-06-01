/// Eksepsi kustom untuk merepresentasikan kesalahan pada data layer (e.g. SQLite).
class DatabaseException implements Exception {
  final String message;
  final Object? originalException;

  const DatabaseException(this.message, [this.originalException]);

  @override
  String toString() => 'DatabaseException: $message (${originalException ?? ''})';
}

/// Eksepsi kustom untuk kesalahan validasi input data lokal.
class CacheException implements Exception {
  final String message;

  const CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}
