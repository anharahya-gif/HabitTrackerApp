/// Domain entity representing a daily journal entry with mood tracking.
class JournalEntry {
  final String id;
  final String date; // Format: YYYY-MM-DD (1 entri per hari)
  final String mood; // 'great', 'good', 'neutral', 'bad', 'terrible'
  final String? content; // Isi refleksi (opsional, max ~500 karakter)
  final DateTime createdAt;
  final DateTime updatedAt;

  const JournalEntry({
    required this.id,
    required this.date,
    required this.mood,
    this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a copy of this JournalEntry with the given fields replaced.
  JournalEntry copyWith({
    String? id,
    String? date,
    String? mood,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      mood: mood ?? this.mood,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Helper untuk mendapatkan emoji berdasarkan mood
  String get moodEmoji {
    switch (mood) {
      case 'great':
        return '😊';
      case 'good':
        return '🙂';
      case 'neutral':
        return '😐';
      case 'bad':
        return '😔';
      case 'terrible':
        return '😢';
      default:
        return '😐';
    }
  }

  /// Helper untuk mendapatkan label teks mood
  String get moodLabel {
    switch (mood) {
      case 'great':
        return 'Sangat Baik';
      case 'good':
        return 'Baik';
      case 'neutral':
        return 'Netral';
      case 'bad':
        return 'Buruk';
      case 'terrible':
        return 'Sangat Buruk';
      default:
        return 'Netral';
    }
  }
}
