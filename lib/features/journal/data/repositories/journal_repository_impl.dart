import '../../../../core/errors/failure.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/repositories/journal_repository.dart';
import '../datasources/journal_local_data_source.dart';
import '../models/journal_entry_model.dart';

/// Implementasi konkrit dari [JournalRepository] menggunakan [JournalLocalDataSource].
class JournalRepositoryImpl implements JournalRepository {
  final JournalLocalDataSource _localDataSource;

  JournalRepositoryImpl(this._localDataSource);

  @override
  Future<Result<void>> saveEntry(JournalEntry entry) async {
    try {
      final model = JournalEntryModel.fromEntity(entry);
      await _localDataSource.insertOrUpdate(model);
      return const Success(null);
    } catch (e) {
      return Failure('Gagal menyimpan catatan harian: ${e.toString()}', e);
    }
  }

  @override
  Future<Result<JournalEntry?>> getEntryForDate(String date) async {
    try {
      final entry = await _localDataSource.getByDate(date);
      return Success(entry);
    } catch (e) {
      return Failure('Gagal mengambil catatan harian tanggal $date: ${e.toString()}', e);
    }
  }

  @override
  Future<Result<List<JournalEntry>>> getAllEntries() async {
    try {
      final entries = await _localDataSource.getAll();
      return Success(entries);
    } catch (e) {
      return Failure('Gagal mengambil semua catatan harian: ${e.toString()}', e);
    }
  }

  @override
  Future<Result<void>> deleteEntry(String id) async {
    try {
      await _localDataSource.delete(id);
      return const Success(null);
    } catch (e) {
      return Failure('Gagal menghapus catatan harian: ${e.toString()}', e);
    }
  }
}
