import '../../domain/entities/ibadah_log.dart';

/// Model data IbadahLog untuk serialisasi SQLite.
class IbadahLogModel extends IbadahLog {
  const IbadahLogModel({
    required super.id,
    required super.date,
    super.subuh,
    super.dzuhur,
    super.ashar,
    super.maghrib,
    super.isya,
    super.quranPages,
    super.dhikrCount,
    super.duha,
    super.tahajjud,
    super.sedekah,
    required super.updatedAt,
  });

  /// Mengonversi dari Map SQLite ke Model
  factory IbadahLogModel.fromSqlMap(Map<String, dynamic> map) {
    return IbadahLogModel(
      id: map['id'] as String,
      date: map['date'] as String,
      subuh: map['subuh'] as String,
      dzuhur: map['dzuhur'] as String,
      ashar: map['ashar'] as String,
      maghrib: map['maghrib'] as String,
      isya: map['isya'] as String,
      quranPages: map['quran_pages'] as int,
      dhikrCount: map['dhikr_count'] as int,
      duha: map['duha'] as int,
      tahajjud: map['tahajjud'] as int,
      sedekah: map['sedekah'] as int,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Mengonversi Model ke Map SQLite
  Map<String, dynamic> toSqlMap() {
    return {
      'id': id,
      'date': date,
      'subuh': subuh,
      'dzuhur': dzuhur,
      'ashar': ashar,
      'maghrib': maghrib,
      'isya': isya,
      'quran_pages': quranPages,
      'dhikr_count': dhikrCount,
      'duha': duha,
      'tahajjud': tahajjud,
      'sedekah': sedekah,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Mengonversi dari Entitas ke Model
  factory IbadahLogModel.fromEntity(IbadahLog entity) {
    return IbadahLogModel(
      id: entity.id,
      date: entity.date,
      subuh: entity.subuh,
      dzuhur: entity.dzuhur,
      ashar: entity.ashar,
      maghrib: entity.maghrib,
      isya: entity.isya,
      quranPages: entity.quranPages,
      dhikrCount: entity.dhikrCount,
      duha: entity.duha,
      tahajjud: entity.tahajjud,
      sedekah: entity.sedekah,
      updatedAt: entity.updatedAt,
    );
  }

  /// Mengonversi ke objek domain entitas murni [IbadahLog]
  IbadahLog toEntity() {
    return IbadahLog(
      id: id,
      date: date,
      subuh: subuh,
      dzuhur: dzuhur,
      ashar: ashar,
      maghrib: maghrib,
      isya: isya,
      quranPages: quranPages,
      dhikrCount: dhikrCount,
      duha: duha,
      tahajjud: tahajjud,
      sedekah: sedekah,
      updatedAt: updatedAt,
    );
  }
}
