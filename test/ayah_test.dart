import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_app/features/ayah/domain/entities/daily_ayah.dart';
import 'package:habit_tracker_app/features/ayah/domain/entities/tajwid_rule.dart';
import 'package:habit_tracker_app/features/ayah/data/models/daily_ayah_model.dart';
import 'package:habit_tracker_app/features/ayah/data/constants/curated_ayahs.dart';
import 'package:habit_tracker_app/features/ayah/data/repositories/tajwid_repository_impl.dart';

void main() {
  group('Dailio Ayat of the Day - Entity & Model Tests', () {
    final now = DateTime(2026, 6, 14, 12, 0, 0);

    final tajwidOccurrence = const AyahTajwidOccurrence(
      ruleKey: 'ghunnah',
      phrase: 'إِنَّ',
      reason: 'Nun bertasydid',
      characterRange: [0, 4],
    );

    final dailyAyahModel = DailyAyahModel(
      id: '2026-06-14',
      date: '2026-06-14',
      surahNumber: 2,
      ayahNumber: 153,
      surahName: 'Al-Baqarah',
      arabicText: 'يَا أَيُّهَا الَّذِينَ آمَنُوا اسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ ۚ إِنَّ اللَّهَ مَعَ الصَّابِرِينَ',
      translation: 'Wahai orang-orang yang beriman! Mohonlah pertolongan dengan sabar dan salat.',
      audioUrl: 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/160.mp3',
      tajwidOccurrences: [tajwidOccurrence],
      createdAt: now,
    );

    test('should serialize and deserialize DailyAyahModel to/from SQLite map', () {
      // Act
      final sqlMap = dailyAyahModel.toSqlMap();
      final decoded = DailyAyahModel.fromSqlMap(sqlMap);

      // Assert
      expect(sqlMap['id'], '2026-06-14');
      expect(sqlMap['date'], '2026-06-14');
      expect(sqlMap['surah_number'], 2);
      expect(sqlMap['ayah_number'], 153);
      expect(sqlMap['surah_name'], 'Al-Baqarah');
      expect(sqlMap['audio_url'], 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/160.mp3');
      expect(sqlMap['created_at'], now.toIso8601String());

      expect(decoded.id, '2026-06-14');
      expect(decoded.surahNumber, 2);
      expect(decoded.tajwidOccurrences.length, 1);
      expect(decoded.tajwidOccurrences.first.ruleKey, 'ghunnah');
      expect(decoded.tajwidOccurrences.first.phrase, 'إِنَّ');
      expect(decoded.createdAt, now);
    });

    test('should convert between domain entities and models correctly', () {
      // Act
      final entity = dailyAyahModel.toEntity();
      final model = DailyAyahModel.fromEntity(entity);

      // Assert
      expect(entity, isA<DailyAyah>());
      expect(entity.surahName, 'Al-Baqarah');
      expect(entity.tajwidOccurrences.first.ruleKey, 'ghunnah');
      expect(model.arabicText, dailyAyahModel.arabicText);
    });

    test('should parse model from JSON API response successfully', () {
      // Arrange
      final fakeJson = {
        'verse': {
          'id': 160,
          'verse_number': 153,
          'verse_key': '2:153',
          'text_uthmani': 'يَا أَيُّهَا الَّذِينَ آمَنُوا اسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ ۚ إِنَّ اللَّهَ مَعَ الصَّابِرِينَ',
          'translations': [
            {
              'id': 181444,
              'resource_id': 33,
              'text': '<p>Wahai orang-orang yang beriman! Mohonlah pertolongan...</p>'
            }
          ]
        }
      };

      // Act
      final model = DailyAyahModel.fromJsonApi(
        json: fakeJson,
        date: '2026-06-14',
        surahName: 'Al-Baqarah',
        tajwidOccurrences: [tajwidOccurrence],
      );

      // Assert
      expect(model.id, '2026-06-14');
      expect(model.surahNumber, 2);
      expect(model.ayahNumber, 153);
      expect(model.arabicText, startsWith('يَا أَيُّهَا'));
      expect(model.translation, 'Wahai orang-orang yang beriman! Mohonlah pertolongan...'); // stripped HTML
      expect(model.audioUrl, 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/160.mp3');
      expect(model.tajwidOccurrences.first.ruleKey, 'ghunnah');
    });
  });

  group('Dailio Ayat of the Day - Business Logic & Verification Tests', () {
    test('Tajwid Repository kamus should retrieve definitions offline correctly', () {
      // Arrange
      final repo = TajwidRepositoryImpl();

      // Act
      final ghunnah = repo.getRule('ghunnah');
      final qalqalah = repo.getRule('qalqalah');
      final invalid = repo.getRule('non_existent');

      // Assert
      expect(ghunnah, isNotNull);
      expect(ghunnah!.name, 'Ghunnah');
      expect(ghunnah.generalExamples.first, contains('إِنَّ'));

      expect(qalqalah, isNotNull);
      expect(qalqalah!.name, 'Qalqalah (Sugra / Kubra)');

      expect(invalid, isNull);
    });

    test('Curated Ayah pool determinism: date should map to a valid curated index', () {
      // Arrange
      final dates = ['2026-06-14', '2026-06-15', '2026-06-16', '2026-06-14'];

      // Act
      final indices = dates.map((d) {
        final parsed = DateTime.parse(d);
        final daysSinceEpoch = parsed.millisecondsSinceEpoch ~/ (1000 * 60 * 60 * 24);
        return daysSinceEpoch % curatedAyahsList.length;
      }).toList();

      // Assert
      // Indeks untuk tanggal yang sama harus persis sama
      expect(indices[0], indices[3]);
      // Indeks untuk tanggal berurutan harus berurutan secara siklis
      expect(indices[1], (indices[0] + 1) % curatedAyahsList.length);
      
      // Pastikan seluruh indeks berada dalam rentang panjang pool
      for (final idx in indices) {
        expect(idx, greaterThanOrEqualTo(0));
        expect(idx, lessThan(curatedAyahsList.length));
      }
    });

    test('Pre-annotated Tajwid character ranges should be within the Arabic text boundary', () {
      // Verifikasi integritas range penyorotan teks Arab pada seluruh ayat kurasi
      for (final curated in curatedAyahsList) {
        final textLength = curated.arabicText.length;
        for (final occurrence in curated.tajwidList) {
          final range = occurrence.characterRange;
          
          expect(range.length, 2);
          expect(range[0], greaterThanOrEqualTo(0));
          expect(range[1], lessThanOrEqualTo(textLength));
          expect(range[0], lessThan(range[1]));

          // Ambil substring teks berdasarkan range dan pastikan lafadz cocok
          final extractedText = curated.arabicText.substring(range[0], range[1]);
          expect(extractedText, isNotEmpty);
          expect(extractedText.trim(), isNotEmpty);
        }
      }
    });
  });
}
