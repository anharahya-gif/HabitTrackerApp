import 'tajwid_rule.dart';

class DailyAyah {
  final String id;
  final String date;
  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final String arabicText;
  final String translation;
  final String? audioUrl;
  final List<AyahTajwidOccurrence> tajwidOccurrences;
  final DateTime createdAt;

  const DailyAyah({
    required this.id,
    required this.date,
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.arabicText,
    required this.translation,
    this.audioUrl,
    required this.tajwidOccurrences,
    required this.createdAt,
  });
}
