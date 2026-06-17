class DhikrStep {
  final int stepNumber;
  final String title;
  final String arabic;
  final String latin;
  final String translation;
  final int targetCount;

  const DhikrStep({
    required this.stepNumber,
    required this.title,
    required this.arabic,
    required this.latin,
    required this.translation,
    required this.targetCount,
  });
}

/// Daftar urutan dzikir & doa setelah shalat fardhu secara terstruktur.
const List<DhikrStep> prayersAfterShalatSteps = [
  DhikrStep(
    stepNumber: 1,
    title: 'Istighfar',
    arabic: 'أَسْتَغْفِرُ اللهَ الْعَظِيمَ',
    latin: 'Astaghfirullahal \'adzhiim',
    translation: 'Aku memohon ampun kepada Allah Yang Maha Agung.',
    targetCount: 3,
  ),
  DhikrStep(
    stepNumber: 2,
    title: 'Dzikir Tauhid',
    arabic: 'لَا إِلَهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
    latin: 'Laa ilaaha illallaahu wahdahu laa syariikalah, lahul mulku wa lahul hamdu, wa huwa \'alaa kulli syai-in qadiir',
    translation: 'Tiada Tuhan selain Allah Yang Maha Esa, tidak ada sekutu bagi-Nya. Bagi-Nya segala kekuasaan dan bagi-Nya segala pujian, dan Dia Maha Kuasa atas segala sesuatu.',
    targetCount: 3,
  ),
  DhikrStep(
    stepNumber: 3,
    title: 'Tasbih',
    arabic: 'سُبْحَانَ اللهِ',
    latin: 'Subhanallah',
    translation: 'Maha Suci Allah.',
    targetCount: 33,
  ),
  DhikrStep(
    stepNumber: 4,
    title: 'Tahmid',
    arabic: 'الْحَمْدُ للهِ',
    latin: 'Alhamdulillah',
    translation: 'Segala puji bagi Allah.',
    targetCount: 33,
  ),
  DhikrStep(
    stepNumber: 5,
    title: 'Takbir',
    arabic: 'اللهُ أَكْبَرُ',
    latin: 'Allahu Akbar',
    translation: 'Allah Maha Besar.',
    targetCount: 33,
  ),
  DhikrStep(
    stepNumber: 6,
    title: 'Tahlil Lengkap',
    arabic: 'لَا إِلَهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
    latin: 'Laa ilaaha illallaahu wahdahu laa syariikalah, lahul mulku wa lahul hamdu, wa huwa \'alaa kulli syai-in qadiir',
    translation: 'Tiada Tuhan selain Allah Yang Maha Esa, tidak ada sekutu bagi-Nya. Bagi-Nya segala kekuasaan dan bagi-Nya segala pujian, dan Dia Maha Kuasa atas segala sesuatu.',
    targetCount: 1,
  ),
  DhikrStep(
    stepNumber: 7,
    title: 'Ayat Kursi',
    arabic: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
    latin: 'Allaahu laa ilaaha illaa huwal-hayyul-qayyuum, laa ta\'khudzuhu sinatuw wa laa nawm, lahu maa fis-samaawaati wa maa fil-ardh, man dzal-ladzii yasyfa\'u \'indahuu illaa bi-idznih, ya\'lamu maa baina aidiihim wa maa khalfahum, wa laa yuhiithuuna bisyai-im min \'ilmihii illaa bimaa syaa\', wasi\'a kursiyyuhus-samaawaati wal-ardh, wa laa ya-uuduhu hifzhuhumaa, wa huwal-\'aliyyul-\'adzhiim',
    translation: 'Allah, tidak ada Tuhan (yang berhak disembah) melainkan Dia Yang Hidup kekal lagi terus menerus mengurus (makhluk-Nya); tidak mengantuk dan tidak tidur. Kepunyaan-Nya apa yang di langit dan di bumi. Tiada yang dapat memberi syafaat di sisi Allah tanpa izin-Nya? Allah mengetahui apa-apa yang di hadapan mereka dan di belakang mereka, dan mereka tidak mengetahui apa-apa dari ilmu Allah melainkan apa yang dikehendaki-Nya. Kursi Allah meliputi langit dan bumi. Dan Allah tidak merasa berat memelihara keduanya, dan Allah Maha Tinggi lagi Maha Besar.',
    targetCount: 1,
  ),
  DhikrStep(
    stepNumber: 8,
    title: 'Doa Setelah Shalat',
    arabic: 'الْحَمْدُ للهِ رَبِّ الْعَالَمِينَ، حَمْدًا يُوَافِي نِعَمَهُ وَيُكَافِئُ مَزِيدَهُ. اللَّهُمَّ صَلِّ عَلَى سَيِّدِنَا مُحَمَّدٍ وَعَلَى آلِ سَيِّدِنَا مُحَمَّدٍ. اللَّهُمَّ إِنَّا نَسْأَلُكَ سَلَامَةً فِي الدِّينِ، وَعَافِيَةً فِي الْجَسَدِ، وَزِيَادَةً فِي الْعِلْمِ، وَبَرَكَةً فِي الرِّزْقِ، وَتَوْبَةً قَبْلَ الْمَوْتِ، وَرَحْمَةً عِنْدَ الْمَوْتِ، وَمَغْفِرَةً بَعْدَ الْمَوْتِ. اللَّهُمَّ هَوِّنْ عَلَيْنَا فِي سَكَرَاتِ الْمَوْتِ، وَالنَّجَاةَ مِنَ النَّارِ، وَالْعَفْوَ عِنْدَ الْحِسَابِ.',
    latin: 'Alhamdu lillaahi rabbil-\'aalamiin, hamday yuwaafii ni\'amahuu wa yukaafi-u maziidah. Allaahumma shalli \'alaa sayyidinaa muhammadin wa \'alaa aali sayyidinaa muhammad. Allaahumma innaa nas-aluka salaamatan fid-diin, wa \'aafiyatan fil-jasad, wa ziyaadatan fil-\'ilm, wa barakatan fir-rizq, wa tawbatan qablal-mawt, wa rahmatan \'indal-mawt, wa maghfiratan ba\'dal-mawt. Allaahumma hawwin \'alaynaa fii sakaraatil-mawt, wan-najaata minan-naar, wal-\'afwa \'indal-hisaab',
    translation: 'Segala puji bagi Allah Tuhan semesta alam, pujian yang sebanding dengan nikmat-nikmat-Nya dan menjamin tambahannya. Ya Allah, limpahkanlah rahmat kepada junjungan kami Nabi Muhammad dan keluarganya. Ya Allah, sesungguhnya kami memohon kepada-Mu keselamatan dalam agama, kesehatan jasmani, bertambahnya ilmu, keberkahan rezeki, taubat sebelum mati, rahmat ketika mati, dan ampunan setelah mati. Ya Allah, mudahkanlah kami dalam sakaratul maut, selamatkanlah kami dari api neraka, dan berilah ampunan ketika hisab.',
    targetCount: 1,
  )
];
