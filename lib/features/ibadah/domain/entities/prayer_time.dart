/// Entitas domain murni untuk jadwal waktu shalat harian.
class PrayerTime {
  final String id;
  final String date;          // format YYYY-MM-DD
  final String city;          // nama kota pencarian
  final String fajr;          // format HH:MM
  final String dhuhr;         // format HH:MM
  final String asr;           // format HH:MM
  final String maghrib;       // format HH:MM
  final String isha;          // format HH:MM
  final DateTime updatedAt;

  const PrayerTime({
    required this.id,
    required this.date,
    required this.city,
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.updatedAt,
  });

  PrayerTime copyWith({
    String? id,
    String? date,
    String? city,
    String? fajr,
    String? dhuhr,
    String? asr,
    String? maghrib,
    String? isha,
    DateTime? updatedAt,
  }) {
    return PrayerTime(
      id: id ?? this.id,
      date: date ?? this.date,
      city: city ?? this.city,
      fajr: fajr ?? this.fajr,
      dhuhr: dhuhr ?? this.dhuhr,
      asr: asr ?? this.asr,
      maghrib: maghrib ?? this.maghrib,
      isha: isha ?? this.isha,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
