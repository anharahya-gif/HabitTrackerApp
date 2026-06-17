import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/daily_ayah_model.dart';
import '../../domain/entities/tajwid_rule.dart';

class AyahRemoteDataSource {
  final http.Client _client;

  AyahRemoteDataSource(this._client);

  /// Mengambil data ayat dari Quran.com API v4 beserta teks Uthmani dan terjemahan Indonesia.
  ///
  /// [surah] — nomor surah (1 - 114)
  /// [ayah] — nomor ayat di surah tersebut
  /// [date] — tanggal harian untuk id cache
  /// [surahName] — nama surah pendukung detail
  /// [occurrences] — data tajwid yang di-pre-annotate secara lokal
  Future<DailyAyahModel> fetchAyah(
    int surah,
    int ayah,
    String date,
    String surahName,
    List<AyahTajwidOccurrence> occurrences,
  ) async {
    final url = Uri.parse(
      'https://api.quran.com/api/v4/verses/by_key/$surah:$ayah?language=id&translations=33&fields=text_uthmani',
    );

    final response = await _client.get(url).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return DailyAyahModel.fromJsonApi(
        json: decoded,
        date: date,
        surahName: surahName,
        tajwidOccurrences: occurrences,
      );
    } else {
      throw Exception('Gagal memuat ayat dari API: Status ${response.statusCode}');
    }
  }
}
