import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers.dart';
import '../../domain/entities/journal_entry.dart';
import '../../../../core/errors/failure.dart';

/// Controller for managing the daily journal entries state using [AsyncNotifier].
class JournalController extends AsyncNotifier<List<JournalEntry>> {
  @override
  FutureOr<List<JournalEntry>> build() async {
    return _fetchJournalEntries();
  }

  Future<List<JournalEntry>> _fetchJournalEntries() async {
    final repository = ref.read(journalRepositoryProvider);
    final result = await repository.getAllEntries();
    return result.fold(
      onSuccess: (entries) => entries,
      onFailure: (failure) => throw Exception(failure.message),
    );
  }

  /// Saves or updates a journal entry.
  Future<Result<void>> saveJournal(JournalEntry entry) async {
    final repository = ref.read(journalRepositoryProvider);
    final result = await repository.saveEntry(entry);
    if (result is Success<void>) {
      // Reload the state
      state = await AsyncValue.guard(() => _fetchJournalEntries());
    }
    return result;
  }

  /// Deletes a journal entry.
  Future<Result<void>> deleteJournal(String id) async {
    final repository = ref.read(journalRepositoryProvider);
    final result = await repository.deleteEntry(id);
    if (result is Success<void>) {
      // Reload the state
      state = await AsyncValue.guard(() => _fetchJournalEntries());
    }
    return result;
  }
}

/// Global provider for the Journal list.
final journalControllerProvider = AsyncNotifierProvider<JournalController, List<JournalEntry>>(() {
  return JournalController();
});

/// Provider that returns the journal entry for today, if it exists.
final todayJournalProvider = Provider<JournalEntry?>((ref) {
  final journalState = ref.watch(journalControllerProvider).valueOrNull ?? [];
  final now = DateTime.now();
  final todayDateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  try {
    return journalState.firstWhere((e) => e.date == todayDateStr);
  } catch (_) {
    return null;
  }
});
