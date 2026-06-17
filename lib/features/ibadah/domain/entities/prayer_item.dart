/// Entitas domain murni untuk memetakan item doa.
class PrayerItem {
  final String id;
  final String title;
  final String arabic;
  final String latin;
  final String translation;
  final String reference;
  final String category; // e.g. 'Harian', 'Shalat & Ibadah', 'Perlindungan', 'Kemudahan', 'Qur\'an & Hadits'

  const PrayerItem({
    required this.id,
    required this.title,
    required this.arabic,
    required this.latin,
    required this.translation,
    required this.reference,
    required this.category,
  });
}
