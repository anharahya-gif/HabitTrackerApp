import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_app/features/ibadah/domain/entities/prayer_item.dart';
import 'package:habit_tracker_app/features/ibadah/data/constants/curated_prayers.dart';
import 'package:habit_tracker_app/features/ibadah/data/constants/prayers_after_shalat.dart';

void main() {
  group('Dailio Doa & Dzikir - Entity & Constants Tests', () {
    test('should construct PrayerItem entity successfully', () {
      // Arrange & Act
      const prayer = PrayerItem(
        id: 'test_doa',
        title: 'Doa Test',
        arabic: 'اللَّهُمَّ اِغْفِرْ لِي',
        latin: 'Allaahummaghfir lii',
        translation: 'Ya Allah ampunilah aku',
        reference: 'Hadits',
        category: 'Harian',
      );

      // Assert
      expect(prayer.id, 'test_doa');
      expect(prayer.title, 'Doa Test');
      expect(prayer.arabic, 'اللَّهُمَّ اِغْفِرْ لِي');
      expect(prayer.latin, 'Allaahummaghfir lii');
      expect(prayer.translation, 'Ya Allah ampunilah aku');
      expect(prayer.reference, 'Hadits');
      expect(prayer.category, 'Harian');
    });

    test('should have a valid, non-empty curated prayers library', () {
      // Assert
      expect(curatedPrayers.isNotEmpty, true);
      expect(curatedPrayers.length, greaterThanOrEqualTo(10));

      for (var prayer in curatedPrayers) {
        expect(prayer.id.isNotEmpty, true);
        expect(prayer.title.isNotEmpty, true);
        expect(prayer.arabic.isNotEmpty, true);
        expect(prayer.latin.isNotEmpty, true);
        expect(prayer.translation.isNotEmpty, true);
        expect(prayer.reference.isNotEmpty, true);
        expect(prayer.category.isNotEmpty, true);
      }
    });

    test('should have valid shalat guided steps', () {
      // Assert
      expect(prayersAfterShalatSteps.isNotEmpty, true);
      expect(prayersAfterShalatSteps.length, equals(8));

      // First step should be Istighfar
      final firstStep = prayersAfterShalatSteps.first;
      expect(firstStep.stepNumber, 1);
      expect(firstStep.title, 'Istighfar');
      expect(firstStep.targetCount, 3);

      // Tasbih, Tahmid, Takbir should have target count of 33
      final tasbih = prayersAfterShalatSteps.firstWhere((s) => s.title == 'Tasbih');
      expect(tasbih.targetCount, 33);

      final tahmid = prayersAfterShalatSteps.firstWhere((s) => s.title == 'Tahmid');
      expect(tahmid.targetCount, 33);

      final takbir = prayersAfterShalatSteps.firstWhere((s) => s.title == 'Takbir');
      expect(takbir.targetCount, 33);
    });
  });
}
