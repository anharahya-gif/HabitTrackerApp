import 'dart:convert';
import '../../domain/entities/daily_ayah.dart';
import '../../domain/entities/tajwid_rule.dart';

class DailyAyahModel extends DailyAyah {
  const DailyAyahModel({
    required super.id,
    required super.date,
    required super.surahNumber,
    required super.ayahNumber,
    required super.surahName,
    required super.arabicText,
    required super.translation,
    super.audioUrl,
    required super.tajwidOccurrences,
    required super.createdAt,
  });

  /// Factory untuk membuat model dari objek Entity domain
  factory DailyAyahModel.fromEntity(DailyAyah entity) {
    return DailyAyahModel(
      id: entity.id,
      date: entity.date,
      surahNumber: entity.surahNumber,
      ayahNumber: entity.ayahNumber,
      surahName: entity.surahName,
      arabicText: entity.arabicText,
      translation: entity.translation,
      audioUrl: entity.audioUrl,
      tajwidOccurrences: entity.tajwidOccurrences,
      createdAt: entity.createdAt,
    );
  }

  /// Membuat entitas domain murni
  DailyAyah toEntity() {
    return DailyAyah(
      id: id,
      date: date,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      surahName: surahName,
      arabicText: arabicText,
      translation: translation,
      audioUrl: audioUrl,
      tajwidOccurrences: tajwidOccurrences,
      createdAt: createdAt,
    );
  }

  /// Deserialisasi dari Map SQLite
  factory DailyAyahModel.fromSqlMap(Map<String, dynamic> map) {
    final tajwidStr = map['tajwid_json'] as String?;
    List<AyahTajwidOccurrence> occurrences = [];
    if (tajwidStr != null && tajwidStr.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(tajwidStr);
        occurrences = decoded
            .map((item) => AyahTajwidOccurrence.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    return DailyAyahModel(
      id: map['id'] as String,
      date: map['date'] as String,
      surahNumber: map['surah_number'] as int,
      ayahNumber: map['ayah_number'] as int,
      surahName: map['surah_name'] as String,
      arabicText: map['arabic_text'] as String,
      translation: map['translation'] as String,
      audioUrl: map['audio_url'] as String?,
      tajwidOccurrences: occurrences,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Serialisasi ke Map SQLite
  Map<String, dynamic> toSqlMap() {
    final tajwidJsonList = tajwidOccurrences.map((o) => o.toJson()).toList();
    final tajwidStr = jsonEncode(tajwidJsonList);

    return {
      'id': id,
      'date': date,
      'surah_number': surahNumber,
      'ayah_number': ayahNumber,
      'surah_name': surahName,
      'arabic_text': arabicText,
      'translation': translation,
      'audio_url': audioUrl,
      'tajwid_json': tajwidStr,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Parser untuk respons API Quran.com v4
  /// HTTP GET https://api.quran.com/api/v4/verses/by_key/{chapter}:{verse}?language=id&translations=33&fields=text_uthmani
  factory DailyAyahModel.fromJsonApi({
    required Map<String, dynamic> json,
    required String date,
    required String surahName,
    required List<AyahTajwidOccurrence> tajwidOccurrences,
  }) {
    final verseObj = json['verse'] as Map<String, dynamic>;
    final keyParts = (verseObj['verse_key'] as String).split(':');
    final surahNum = int.parse(keyParts[0]);
    final ayahNum = int.parse(keyParts[1]);

    // Ambil teks Arab Uthmani
    final arabic = verseObj['text_uthmani'] as String;

    // Ambil terjemahan bahasa Indonesia (id: 33)
    final translationsList = verseObj['translations'] as List<dynamic>;
    String translationStr = '';
    if (translationsList.isNotEmpty) {
      // Hilangkan tag HTML jika ada di terjemahan (misal tag footnote atau bold)
      final rawText = translationsList.first['text'] as String;
      translationStr = rawText.replaceAll(RegExp(r'<[^>]*>'), '');
    }

    // Alamat audio publik dari cdn.islamic.network (Alafasy) menggunakan nomor absolut ayah
    // API Quran.com mengembalikan 'id' absolut ayat (1 sampai 6236)
    final absoluteAyahId = verseObj['id'] as int;
    final audio = 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$absoluteAyahId.mp3';

    return DailyAyahModel(
      id: date,
      date: date,
      surahNumber: surahNum,
      ayahNumber: ayahNum,
      surahName: surahName,
      arabicText: arabic,
      translation: translationStr,
      audioUrl: audio,
      tajwidOccurrences: tajwidOccurrences,
      createdAt: DateTime.now(),
    );
  }
}
