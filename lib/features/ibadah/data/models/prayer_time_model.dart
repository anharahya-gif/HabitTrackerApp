import '../../domain/entities/prayer_time.dart';

/// Model data PrayerTime untuk serialisasi SQLite dan API parsing.
class PrayerTimeModel extends PrayerTime {
  const PrayerTimeModel({
    required super.id,
    required super.date,
    required super.city,
    required super.fajr,
    required super.dhuhr,
    required super.asr,
    required super.maghrib,
    required super.isha,
    required super.updatedAt,
  });

  /// Mengonversi dari Map SQLite ke Model
  factory PrayerTimeModel.fromSqlMap(Map<String, dynamic> map) {
    return PrayerTimeModel(
      id: map['id'] as String,
      date: map['date'] as String,
      city: map['city'] as String,
      fajr: map['fajr'] as String,
      dhuhr: map['dhuhr'] as String,
      asr: map['asr'] as String,
      maghrib: map['maghrib'] as String,
      isha: map['isha'] as String,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Mengonversi Model ke Map SQLite
  Map<String, dynamic> toSqlMap() {
    return {
      'id': id,
      'date': date,
      'city': city,
      'fajr': fajr,
      'dhuhr': dhuhr,
      'asr': asr,
      'maghrib': maghrib,
      'isha': isha,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Mengonversi dari Entitas ke Model
  factory PrayerTimeModel.fromEntity(PrayerTime entity) {
    return PrayerTimeModel(
      id: entity.id,
      date: entity.date,
      city: entity.city,
      fajr: entity.fajr,
      dhuhr: entity.dhuhr,
      asr: entity.asr,
      maghrib: entity.maghrib,
      isha: entity.isha,
      updatedAt: entity.updatedAt,
    );
  }

  /// Mengonversi dari data JSON API Aladhan (timings) ke Model
  factory PrayerTimeModel.fromApiMap(Map<String, dynamic> timings, String date, String city) {
    String cleanTime(String raw) {
      // Menghapus info zona waktu jika ada (misal: "04:35 (WIB)" -> "04:35")
      return raw.split(' ')[0].trim();
    }

    return PrayerTimeModel(
      id: '${city.replaceAll(' ', '_').toLowerCase()}_$date',
      date: date,
      city: city,
      fajr: cleanTime(timings['Fajr'] as String),
      dhuhr: cleanTime(timings['Dhuhr'] as String),
      asr: cleanTime(timings['Asr'] as String),
      maghrib: cleanTime(timings['Maghrib'] as String),
      isha: cleanTime(timings['Isha'] as String),
      updatedAt: DateTime.now(),
    );
  }

  /// Mengonversi ke objek domain entitas murni [PrayerTime]
  PrayerTime toEntity() {
    return PrayerTime(
      id: id,
      date: date,
      city: city,
      fajr: fajr,
      dhuhr: dhuhr,
      asr: asr,
      maghrib: maghrib,
      isha: isha,
      updatedAt: updatedAt,
    );
  }
}
