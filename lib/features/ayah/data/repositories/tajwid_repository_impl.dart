import '../../domain/entities/tajwid_rule.dart';
import '../../domain/repositories/tajwid_repository.dart';

class TajwidRepositoryImpl implements TajwidRepository {
  static const Map<String, TajwidRule> _rulesMap = {
    'ghunnah': TajwidRule(
      key: 'ghunnah',
      name: 'Ghunnah',
      definition: 'Membaca huruf dengan mendengungkan suara ke dalam rongga hidung.',
      instruction: 'Dengungkan suara dengan menahan nafas selama 2-3 ketukan (harakat).',
      generalExamples: ['إِنَّ (Inna)', 'ثُمَّ (Thumma)', 'عَمَّ (Amma)'],
    ),
    'ikhfa': TajwidRule(
      key: 'ikhfa',
      name: 'Ikhfa Haqiqi',
      definition: 'Menyamarkan suara Nun Sukun (نْ) atau Tanwin ( ً  ٍ  ٌ ) ketika bertemu salah satu dari 15 huruf Ikhfa.',
      instruction: 'Samarkan suara Nun/Tanwin menjadi samar-samar mendekati bunyi huruf berikutnya sambil didengungkan selama 2 harakat.',
      generalExamples: ['مِنْ دُونِ (Min duuni)', 'عَنْ صَلَاتِهِمْ (An shalaatihim)', 'أَنْفُسَكُمْ (Anfusakum)'],
    ),
    'idgham': TajwidRule(
      key: 'idgham',
      name: 'Idgham (Bighunnah / Bilaghunnah)',
      definition: 'Memasukkan atau meleburkan suara Nun Sukun (نْ) atau Tanwin ke dalam huruf berikutnya.',
      instruction: 'Bighunnah: Leburkan dengan mendengung selama 2 harakat (ketika bertemu ي, ن, م, و). Bilaghunnah: Leburkan secara langsung tanpa mendengung (ketika bertemu ل, ر).',
      generalExamples: ['مَنْ يَقُولُ (May yaquulu - Bighunnah)', 'مِنْ رَبِّهِمْ (Mir rabbihim - Bilaghunnah)'],
    ),
    'iqlab': TajwidRule(
      key: 'iqlab',
      name: 'Iqlab',
      definition: 'Mengubah bunyi Nun Sukun (نْ) atau Tanwin menjadi bunyi Mim (م) ketika bertemu huruf Ba (ب).',
      instruction: 'Ganti bunyi Nun/Tanwin menjadi suara Mim yang samar disertai dengungan ringan selama 2 harakat.',
      generalExamples: ['مِنْ بَعْدِ (Mim ba\'di)', 'سَمِيعٌ بَصِيرٌ (Samii\'um bashiir)'],
    ),
    'qalqalah': TajwidRule(
      key: 'qalqalah',
      name: 'Qalqalah (Sugra / Kubra)',
      definition: 'Membaca huruf dengan memantulkan suara ketika sukun (mati asli) atau waqaf (dimatikan karena berhenti). Hurufnya: ق, ط, ب, ج, د.',
      instruction: 'Sugra: Pantulkan secara ringan di tengah kata. Kubra: Pantulkan dengan lebih kuat dan jelas di akhir kalimat/saat waqaf.',
      generalExamples: ['يَقْتُلُونَ (Yaqtuluuna - Sugra)', 'قُلْ هُوَ اللهُ أَحَدٌ (Ahad - Kubra)'],
    ),
    'mad_thabii': TajwidRule(
      key: 'mad_thabii',
      name: 'Mad Thabi\'i / Asli',
      definition: 'Membaca panjang dua harakat ketika ada huruf Alif setelah Fathah, Ya setelah Kasrah, atau Wawu setelah Dhummah.',
      instruction: 'Panjangkan suara bacaan sepanjang 2 harakat (sekitar 1 alif atau 2 ketukan sedang).',
      generalExamples: ['قَالَ (Qaala)', 'قِيلَ (Qiila)', 'يَقُولُ (Yaquulu)'],
    ),
    'mad_wajib': TajwidRule(
      key: 'mad_wajib',
      name: 'Mad Wajib Muttashil',
      definition: 'Apabila Mad Asli bertemu dengan huruf Hamzah (ء) dalam satu kata/lafadz yang sama.',
      instruction: 'Wajib dipanjangkan sebanyak 4-5 harakat (sekitar 2 sampai 2.5 alif).',
      generalExamples: ['جَاءَ (Jaa-a)', 'السَّمَاءِ (As-samaa-i)', 'سُوءَ (Suu-a)'],
    ),
  };

  @override
  TajwidRule? getRule(String key) {
    return _rulesMap[key.toLowerCase()];
  }

  @override
  List<TajwidRule> getAllRules() {
    return _rulesMap.values.toList();
  }
}
