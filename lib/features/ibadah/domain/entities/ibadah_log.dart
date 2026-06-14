/// Entitas domain murni untuk pencatatan ibadah harian.
class IbadahLog {
  final String id;
  final String date;          // format YYYY-MM-DD
  final String subuh;         // 'belum', 'munfarid', 'berjamaah', 'qadha', 'terlewat'
  final String dzuhur;
  final String ashar;
  final String maghrib;
  final String isya;
  final int quranPages;       // jumlah halaman dibaca
  final int dhikrCount;       // jumlah hitungan dzikir
  final int duha;             // 0: belum, 1: sudah
  final int tahajjud;         // 0: belum, 1: sudah
  final int sedekah;          // 0: belum, 1: sudah
  final DateTime updatedAt;

  const IbadahLog({
    required this.id,
    required this.date,
    this.subuh = 'belum',
    this.dzuhur = 'belum',
    this.ashar = 'belum',
    this.maghrib = 'belum',
    this.isya = 'belum',
    this.quranPages = 0,
    this.dhikrCount = 0,
    this.duha = 0,
    this.tahajjud = 0,
    this.sedekah = 0,
    required this.updatedAt,
  });

  IbadahLog copyWith({
    String? id,
    String? date,
    String? subuh,
    String? dzuhur,
    String? ashar,
    String? maghrib,
    String? isya,
    int? quranPages,
    int? dhikrCount,
    int? duha,
    int? tahajjud,
    int? sedekah,
    DateTime? updatedAt,
  }) {
    return IbadahLog(
      id: id ?? this.id,
      date: date ?? this.date,
      subuh: subuh ?? this.subuh,
      dzuhur: dzuhur ?? this.dzuhur,
      ashar: ashar ?? this.ashar,
      maghrib: maghrib ?? this.maghrib,
      isya: isya ?? this.isya,
      quranPages: quranPages ?? this.quranPages,
      dhikrCount: dhikrCount ?? this.dhikrCount,
      duha: duha ?? this.duha,
      tahajjud: tahajjud ?? this.tahajjud,
      sedekah: sedekah ?? this.sedekah,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
