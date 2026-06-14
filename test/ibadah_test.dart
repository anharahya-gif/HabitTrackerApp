import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_app/features/ibadah/domain/entities/ibadah_log.dart';
import 'package:habit_tracker_app/features/ibadah/domain/entities/prayer_time.dart';
import 'package:habit_tracker_app/features/ibadah/data/models/ibadah_log_model.dart';
import 'package:habit_tracker_app/features/ibadah/data/models/prayer_time_model.dart';

void main() {
  group('Dailio Ibadah Hub - Entity & Model Tests', () {
    final now = DateTime(2026, 6, 14, 12, 0, 0);

    final ibadahLog = IbadahLogModel(
      id: 'log-1',
      date: '2026-06-14',
      subuh: 'berjamaah',
      dzuhur: 'munfarid',
      ashar: 'belum',
      maghrib: 'terlewat',
      isya: 'qadha',
      quranPages: 5,
      dhikrCount: 33,
      duha: 1,
      tahajjud: 0,
      sedekah: 1,
      updatedAt: now,
    );

    final prayerTime = PrayerTimeModel(
      id: 'jakarta_2026-06-14',
      date: '2026-06-14',
      city: 'Jakarta',
      fajr: '04:35',
      dhuhr: '11:58',
      asr: '15:20',
      maghrib: '17:58',
      isha: '19:12',
      updatedAt: now,
    );

    test('should serialize and deserialize IbadahLog Model to/from SQLite map', () {
      // Act
      final sqlMap = ibadahLog.toSqlMap();
      final decoded = IbadahLogModel.fromSqlMap(sqlMap);

      // Assert
      expect(sqlMap['id'], 'log-1');
      expect(sqlMap['date'], '2026-06-14');
      expect(sqlMap['subuh'], 'berjamaah');
      expect(sqlMap['dzuhur'], 'munfarid');
      expect(sqlMap['ashar'], 'belum');
      expect(sqlMap['quran_pages'], 5);
      expect(sqlMap['dhikr_count'], 33);
      expect(sqlMap['duha'], 1);
      expect(sqlMap['tahajjud'], 0);
      expect(sqlMap['sedekah'], 1);
      expect(sqlMap['updated_at'], now.toIso8601String());

      expect(decoded.id, 'log-1');
      expect(decoded.subuh, 'berjamaah');
      expect(decoded.dhikrCount, 33);
      expect(decoded.duha, 1);
      expect(decoded.updatedAt, now);
    });

    test('should serialize and deserialize PrayerTime Model to/from SQLite map', () {
      // Act
      final sqlMap = prayerTime.toSqlMap();
      final decoded = PrayerTimeModel.fromSqlMap(sqlMap);

      // Assert
      expect(sqlMap['id'], 'jakarta_2026-06-14');
      expect(sqlMap['date'], '2026-06-14');
      expect(sqlMap['city'], 'Jakarta');
      expect(sqlMap['fajr'], '04:35');
      expect(sqlMap['dhuhr'], '11:58');
      expect(sqlMap['updated_at'], now.toIso8601String());

      expect(decoded.id, 'jakarta_2026-06-14');
      expect(decoded.fajr, '04:35');
      expect(decoded.maghrib, '17:58');
    });

    test('should convert between domain entities and models correctly', () {
      // Act
      final ibadahEntity = ibadahLog.toEntity();
      final ibadahModel = IbadahLogModel.fromEntity(ibadahEntity);

      final prayerEntity = prayerTime.toEntity();
      final prayerModel = PrayerTimeModel.fromEntity(prayerEntity);

      // Assert
      expect(ibadahEntity, isA<IbadahLog>());
      expect(ibadahEntity.subuh, 'berjamaah');
      expect(ibadahModel.quranPages, 5);

      expect(prayerEntity, isA<PrayerTime>());
      expect(prayerEntity.city, 'Jakarta');
      expect(prayerModel.isha, '19:12');
    });

    test('should copyWith updated parameters correctly', () {
      // Act
      final updatedLog = ibadahLog.copyWith(
        subuh: 'terlewat',
        quranPages: 10,
      );

      // Assert
      expect(updatedLog.id, ibadahLog.id);
      expect(updatedLog.subuh, 'terlewat');
      expect(updatedLog.quranPages, 10);
      expect(updatedLog.dzuhur, ibadahLog.dzuhur);
    });
  });

  group('Dailio Ibadah Hub - Business Logic Tests', () {
    // Simulasi logika penguncian shalat
    bool checkPrayerLocked(String prayerTimeStr, String selectedDateStr, DateTime currentTime) {
      const todayStr = '2026-06-14';
      if (selectedDateStr.compareTo(todayStr) > 0) return true; // Masa depan -> lock
      if (selectedDateStr.compareTo(todayStr) < 0) return false; // Masa lalu -> unlock

      final timeParts = prayerTimeStr.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final prayerDateTime = DateTime(
        currentTime.year,
        currentTime.month,
        currentTime.day,
        hour,
        minute,
      );

      return currentTime.isBefore(prayerDateTime);
    }

    test('Prayer locking rules: should lock future prayers and unlock past prayers for today', () {
      final selectedDate = '2026-06-14';
      // Waktu saat ini: pukul 12:00 siang
      final currentTime = DateTime(2026, 6, 14, 12, 0, 0);

      // Subuh (04:35) -> sudah lewat, harus unlocked
      expect(checkPrayerLocked('04:35', selectedDate, currentTime), isFalse);

      // Dzuhur (11:58) -> sudah lewat, harus unlocked
      expect(checkPrayerLocked('11:58', selectedDate, currentTime), isFalse);

      // Ashar (15:20) -> belum masuk, harus locked
      expect(checkPrayerLocked('15:20', selectedDate, currentTime), isTrue);

      // Maghrib (17:58) -> belum masuk, harus locked
      expect(checkPrayerLocked('17:58', selectedDate, currentTime), isTrue);
    });

    test('Prayer locking rules: should unlock all prayers for past dates', () {
      final pastDate = '2026-06-13';
      final currentTime = DateTime(2026, 6, 14, 12, 0, 0);

      // Seluruh shalat di tanggal kemarin harus bisa diisi untuk melengkapi riwayat/qadha
      expect(checkPrayerLocked('04:35', pastDate, currentTime), isFalse);
      expect(checkPrayerLocked('15:20', pastDate, currentTime), isFalse);
      expect(checkPrayerLocked('19:12', pastDate, currentTime), isFalse);
    });

    test('Prayer countdown: should calculate countdown to next prayer correctly', () {
      // API Timings
      final fajr = '04:35';
      final dhuhr = '11:58';
      final asr = '15:20';

      DateTime parseTime(String hhMm, DateTime baseTime, {bool tomorrow = false}) {
        final parts = hhMm.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        var dt = DateTime(baseTime.year, baseTime.month, baseTime.day, hour, minute);
        if (tomorrow) {
          dt = dt.add(const Duration(days: 1));
        }
        return dt;
      }

      String getCountdown(DateTime now, DateTime target) {
        final diff = target.difference(now);
        final hours = diff.inHours;
        final minutes = diff.inMinutes % 60;
        return hours > 0 ? '${hours}j ${minutes}m' : '${minutes}m';
      }

      // Skenario 1: Sekarang Pukul 10:00 Pagi (Menuju Dzuhur)
      final time1 = DateTime(2026, 6, 14, 10, 0, 0);
      final target1 = parseTime(dhuhr, time1);
      expect(getCountdown(time1, target1), '1j 58m');

      // Skenario 2: Sekarang Pukul 15:00 Sore (Menuju Ashar)
      final time2 = DateTime(2026, 6, 14, 15, 0, 0);
      final target2 = parseTime(asr, time2);
      expect(getCountdown(time2, target2), '20m');

      // Skenario 3: Sekarang Pukul 21:00 Malam (Menuju Subuh Esok Hari)
      final time3 = DateTime(2026, 6, 14, 21, 0, 0);
      final target3 = parseTime(fajr, time3, tomorrow: true);
      expect(getCountdown(time3, target3), '7j 35m');
    });
  });
}
