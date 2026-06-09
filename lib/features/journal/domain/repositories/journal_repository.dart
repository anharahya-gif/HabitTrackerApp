import '../../../../core/errors/failure.dart';
import '../entities/journal_entry.dart';

/// Kontrak repositori untuk fitur Catatan Jurnal & Mood Tracker.
abstract class JournalRepository {
  Future<Result<void>> saveEntry(JournalEntry entry);
  Future<Result<JournalEntry?>> getEntryForDate(String date);
  Future<Result<List<JournalEntry>>> getAllEntries();
  Future<Result<void>> deleteEntry(String id);
}
