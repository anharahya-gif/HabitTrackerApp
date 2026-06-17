import '../../domain/entities/tajwid_rule.dart';

class CuratedAyahData {
  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final String arabicText;
  final String translation;
  final String audioUrl;
  final List<AyahTajwidOccurrence> tajwidList;

  const CuratedAyahData({
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.arabicText,
    required this.translation,
    required this.audioUrl,
    required this.tajwidList,
  });
}

/// Daftar 10 ayat inspiratif inti yang digunakan untuk Ayat of the Day.
/// Di-pre-annotate secara lengkap dengan analisis tajwid (luring 100%).
final List<CuratedAyahData> _coreCuratedAyahs = [
  // 1. QS. Al-Baqarah (2) : 153
  CuratedAyahData(
    surahNumber: 2,
    ayahNumber: 153,
    surahName: 'Al-Baqarah',
    arabicText: 'يَا أَيُّهَا الَّذِينَ آمَنُوا اسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ ۚ إِنَّ اللَّهَ مَعَ الصَّابِرِينَ',
    translation: 'Wahai orang-orang yang beriman! Mohonlah pertolongan (kepada Allah) dengan sabar dan salat. Sungguh, Allah beserta orang-orang yang sabar.',
    audioUrl: 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/160.mp3',
    tajwidList: [
      AyahTajwidOccurrence(
        ruleKey: 'mad_thabii',
        phrase: 'آمَنُوا',
        reason: 'Huruf Alif mad setelah Fathah dan Wawu sukun setelah Dhummah.',
        characterRange: [14, 20],
      ),
      AyahTajwidOccurrence(
        ruleKey: 'qalqalah',
        phrase: 'بِالصَّبْرِ',
        reason: 'Huruf Qalqalah Ba (ب) bertanda sukun di tengah kata (Qalqalah Sugra).',
        characterRange: [32, 41],
      ),
      AyahTajwidOccurrence(
        ruleKey: 'ghunnah',
        phrase: 'إِنَّ',
        reason: 'Huruf Nun bertasydid (نّ) dibaca mendengung dan ditahan.',
        characterRange: [55, 59],
      ),
      AyahTajwidOccurrence(
        ruleKey: 'mad_thabii',
        phrase: 'الصَّابِرِينَ',
        reason: 'Huruf Alif setelah Fathah dan Ya sukun setelah Kasrah di akhir kata.',
        characterRange: [69, 81],
      ),
    ],
  ),
  // 2. QS. Ibrahim (14) : 7
  CuratedAyahData(
    surahNumber: 14,
    ayahNumber: 7,
    surahName: 'Ibrahim',
    arabicText: 'وَإِذْ تَأَذَّنَ رَبُّكُمْ لَئِنْ شَكَرْتُمْ لَأَزِيدَنَّكُمْ ۖ وَلَئِنْ كَفَرْتُمْ إِنَّ عَذَابِي لَشَدِيدٌ',
    translation: 'Dan (ingatlah) ketika Tuhanmu memaklumkan, "Sesungguhnya jika kamu bersyukur, niscaya Aku akan menambah (nikmat) kepadamu, tetapi jika kamu mengingkari (nikmat-Ku), maka pasti azab-Ku sangat berat."',
    audioUrl: 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/1709.mp3',
    tajwidList: [
      AyahTajwidOccurrence(
        ruleKey: 'ikhfa',
        phrase: 'لَئِنْ شَكَرْتُمْ',
        reason: 'Nun Sukun (نْ) bertemu dengan salah satu huruf Ikhfa yaitu Syin (ش).',
        characterRange: [23, 36],
      ),
      AyahTajwidOccurrence(
        ruleKey: 'ghunnah',
        phrase: 'لَأَزِيدَنَّكُمْ',
        reason: 'Huruf Nun bertasydid (نّ) dibaca mendengung dan ditahan.',
        characterRange: [37, 49],
      ),
      AyahTajwidOccurrence(
        ruleKey: 'ghunnah',
        phrase: 'إِنَّ',
        reason: 'Huruf Nun bertasydid (نّ) dibaca mendengung.',
        characterRange: [65, 69],
      ),
      AyahTajwidOccurrence(
        ruleKey: 'mad_thabii',
        phrase: 'عَذَابِي',
        reason: 'Huruf Alif setelah Fathah dan Ya sukun setelah Kasrah.',
        characterRange: [70, 77],
      ),
    ],
  ),
  // 3. QS. Ash-Sharh (94) : 5
  CuratedAyahData(
    surahNumber: 94,
    ayahNumber: 5,
    surahName: 'Ash-Sharh',
    arabicText: 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا',
    translation: 'Maka sesungguhnya beserta kesulitan ada kemudahan,',
    audioUrl: 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/6084.mp3',
    tajwidList: [
      AyahTajwidOccurrence(
        ruleKey: 'ghunnah',
        phrase: 'فَإِنَّ',
        reason: 'Huruf Nun bertasydid (نّ) dibaca mendengung ditahan 2 harakat.',
        characterRange: [0, 6],
      ),
      AyahTajwidOccurrence(
        ruleKey: 'mad_thabii',
        phrase: 'يُسْرًا',
        reason: 'Fathatain bertemu Alif di akhir kata (dibaca Mad Iwadh, setara Mad Thabi\'i).',
        characterRange: [20, 26],
      ),
    ],
  ),
  // 4. QS. Ash-Sharh (94) : 6
  CuratedAyahData(
    surahNumber: 94,
    ayahNumber: 6,
    surahName: 'Ash-Sharh',
    arabicText: 'إِنَّ مَعَ الْعُسْرِ يُسْرًا',
    translation: 'sesungguhnya beserta kesulitan itu ada kemudahan.',
    audioUrl: 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/6085.mp3',
    tajwidList: [
      AyahTajwidOccurrence(
        ruleKey: 'ghunnah',
        phrase: 'إِنَّ',
        reason: 'Huruf Nun bertasydid (نّ) dibaca mendengung ditahan 2 harakat.',
        characterRange: [0, 4],
      ),
      AyahTajwidOccurrence(
        ruleKey: 'mad_thabii',
        phrase: 'يُسْرًا',
        reason: 'Tanwin Fathah bertemu Alif di akhir kata (Mad Iwadh).',
        characterRange: [18, 24],
      ),
    ],
  ),
  // 5. QS. Ar-Ra\'d (13) : 11
  CuratedAyahData(
    surahNumber: 13,
    ayahNumber: 11,
    surahName: 'Ar-Ra\'d',
    arabicText: 'إِنَّ اللَّهَ لَا يُغَيِّرُ مَا بِقَوْمٍ حَتَّىٰ يُغَيِّرُوا مَا بِأَنْفُسِهِمْ',
    translation: 'Sesungguhnya Allah tidak mengubah keadaan suatu kaum sebelum mereka mengubah keadaan diri mereka sendiri.',
    audioUrl: 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/1718.mp3',
    tajwidList: [
      AyahTajwidOccurrence(
        ruleKey: 'ghunnah',
        phrase: 'إِنَّ',
        reason: 'Huruf Nun bertasydid (نّ) dibaca mendengung.',
        characterRange: [0, 4],
      ),
      AyahTajwidOccurrence(
        ruleKey: 'mad_thabii',
        phrase: 'لَا',
        reason: 'Huruf Alif mad setelah Fathah.',
        characterRange: [11, 14],
      ),
      AyahTajwidOccurrence(
        ruleKey: 'mad_thabii',
        phrase: 'مَا',
        reason: 'Huruf Alif setelah Fathah.',
        characterRange: [23, 26],
      ),
      AyahTajwidOccurrence(
        ruleKey: 'ikhfa',
        phrase: 'بِأَنْفُسِهِمْ',
        reason: 'Nun Sukun (نْ) bertemu dengan huruf Ikhfa yaitu Fa (ف).',
        characterRange: [48, 60],
      ),
    ],
  ),
  // 6. QS. An-Najm (53) : 39
  CuratedAyahData(
    surahNumber: 53,
    ayahNumber: 39,
    surahName: 'An-Najm',
    arabicText: 'وَأَنْ لَيْسَ لِلْإِنْسَانِ إِلَّا مَا سَعَىٰ',
    translation: 'Dan bahwa manusia hanya memperoleh apa yang telah diusahakannya,',
    audioUrl: 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/4823.mp3',
    tajwidList: [
      AyahTajwidOccurrence(
        ruleKey: 'ikhfa',
        phrase: 'لِلْإِنْسَانِ',
        reason: 'Nun Sukun (نْ) bertemu dengan huruf Ikhfa yaitu Sin (س).',
        characterRange: [14, 25],
      ),
      AyahTajwidOccurrence(
        ruleKey: 'mad_thabii',
        phrase: 'إِلَّا',
        reason: 'Huruf Alif setelah Fathah.',
        characterRange: [26, 31],
      ),
      AyahTajwidOccurrence(
        ruleKey: 'mad_thabii',
        phrase: 'مَا',
        reason: 'Huruf Alif setelah Fathah.',
        characterRange: [32, 35],
      ),
    ],
  ),
  // 7. QS. At-Talaq (65) : 3
  CuratedAyahData(
    surahNumber: 65,
    ayahNumber: 3,
    surahName: 'At-Talaq',
    arabicText: 'وَيَرْزُقْهُ مِنْ حَيْثُ لَا يَحْتَسِبُ ۚ وَمَنْ يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ',
    translation: 'Dan Dia memberinya rezeki dari arah yang tidak disangka-sangkanya. Dan barangsiapa bertawakal kepada Allah, niscaya Allah akan mencukupkan (keperluan)nya.',
    audioUrl: 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/5212.mp3',
    tajwidList: [
      AyahTajwidOccurrence(
        ruleKey: 'qalqalah',
        phrase: 'وَيَرْزُقْهُ',
        reason: 'Huruf Qalqalah Qaf (ق) sukun berada di tengah kata (Qalqalah Sugra).',
        characterRange: [0, 9],
      ),
      AyahTajwidOccurrence(
        ruleKey: 'mad_thabii',
        phrase: 'لَا',
        reason: 'Alif sukun setelah Fathah.',
        characterRange: [20, 23],
      ),
      AyahTajwidOccurrence(
        ruleKey: 'idgham',
        phrase: 'وَمَنْ يَتَوَكَّلْ',
        reason: 'Nun Sukun (نْ) bertemu huruf Idgham Bighunnah yaitu Ya (ي).',
        characterRange: [38, 51],
      ),
    ],
  ),
  // 8. QS. Al-Baqarah (2) : 286
  CuratedAyahData(
    surahNumber: 2,
    ayahNumber: 286,
    surahName: 'Al-Baqarah',
    arabicText: 'لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا',
    translation: 'Allah tidak membebani seseorang melainkan sesuai dengan kesanggupannya.',
    audioUrl: 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/293.mp3',
    tajwidList: [
      AyahTajwidOccurrence(
        ruleKey: 'mad_thabii',
        phrase: 'لَا',
        reason: 'Huruf Alif setelah Fathah.',
        characterRange: [0, 3],
      ),
      AyahTajwidOccurrence(
        ruleKey: 'mad_thabii',
        phrase: 'إِلَّا',
        reason: 'Huruf Alif setelah Fathah.',
        characterRange: [21, 26],
      ),
      AyahTajwidOccurrence(
        ruleKey: 'mad_thabii',
        phrase: 'وُسْعَهَا',
        reason: 'Huruf Alif setelah Fathah di akhir kata.',
        characterRange: [27, 35],
      ),
    ],
  ),
  // 9. QS. Al-Ankabut (29) : 69
  CuratedAyahData(
    surahNumber: 29,
    ayahNumber: 69,
    surahName: 'Al-Ankabut',
    arabicText: 'وَالَّذِينَ جَاهَدُوا فِينَا لَنَهْدِيَنَّهُمْ سُبُلَنَا ۚ وَإِنَّ اللَّهَ لَمَعَ الْمُحْسِنِينَ',
    translation: 'Dan orang-orang yang berjihad untuk (mencari keridhaan) Kami, Kami akan tunjukkan kepada mereka jalan-jalan Kami. Dan sungguh, Allah beserta orang-orang yang berbuat baik.',
    audioUrl: 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/3362.mp3',
    tajwidList: [
      AyahTajwidOccurrence(
        ruleKey: 'mad_thabii',
        phrase: 'جَاهَدُوا',
        reason: 'Huruf Alif setelah Fathah dan Wawu setelah Dhummah.',
        characterRange: [11, 19],
      ),
      AyahTajwidOccurrence(
        ruleKey: 'mad_thabii',
        phrase: 'فِينَا',
        reason: 'Huruf Ya sukun setelah Kasrah dan Alif setelah Fathah.',
        characterRange: [20, 25],
      ),
      AyahTajwidOccurrence(
        ruleKey: 'ghunnah',
        phrase: 'لَنَهْدِيَنَّهُمْ',
        reason: 'Huruf Nun bertasydid (نّ) dibaca mendengung.',
        characterRange: [26, 39],
      ),
      AyahTajwidOccurrence(
        ruleKey: 'ghunnah',
        phrase: 'وَإِنَّ',
        reason: 'Huruf Nun bertasydid (نّ) dibaca mendengung.',
        characterRange: [49, 55],
      ),
    ],
  ),
  // 10. QS. Al-Asr (103) : 1-3 (Gabungan Ayat 1-3)
  CuratedAyahData(
    surahNumber: 103,
    ayahNumber: 3,
    surahName: 'Al-Asr',
    arabicText: 'إِلَّا الَّذِينَ آمَنُوا وَعَمِلُوا الصَّالِحَاتِ وَتَوَاصَوْا بِالْحَقِّ وَتَوَاصَوْا بِالصَّبْرِ',
    translation: 'kecuali orang-orang yang beriman dan melakukan kebajikan serta saling menasihati untuk kebenaran dan saling menasihati untuk kesabaran.',
    audioUrl: 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/6182.mp3',
    tajwidList: [
      AyahTajwidOccurrence(
        ruleKey: 'mad_thabii',
        phrase: 'آمَنُوا',
        reason: 'Alif setelah Fathah dan Wawu sukun setelah Dhummah.',
        characterRange: [12, 18],
      ),
      AyahTajwidOccurrence(
        ruleKey: 'mad_thabii',
        phrase: 'الصَّالِحَاتِ',
        reason: 'Dua huruf Alif setelah Fathah secara berturut-turut.',
        characterRange: [28, 40],
      ),
      AyahTajwidOccurrence(
        ruleKey: 'qalqalah',
        phrase: 'بِالْحَقِّ',
        reason: 'Huruf Qaf bertasydid sukun karena Waqaf (Qalqalah Kubra).',
        characterRange: [51, 59],
      ),
      AyahTajwidOccurrence(
        ruleKey: 'qalqalah',
        phrase: 'بِالصَّبْرِ',
        reason: 'Huruf Qalqalah Ba (ب) sukun di tengah kata (Qalqalah Sugra).',
        characterRange: [71, 80],
      ),
    ],
  ),
];

/// Kumpulan 30 ayat kurasi untuk setiap tanggal harian (berulang secara siklis).
final List<CuratedAyahData> curatedAyahsList = List.generate(30, (index) {
  return _coreCuratedAyahs[index % _coreCuratedAyahs.length];
});
