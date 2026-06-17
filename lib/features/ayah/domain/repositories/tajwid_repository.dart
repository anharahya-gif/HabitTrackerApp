import '../entities/tajwid_rule.dart';

abstract class TajwidRepository {
  /// Mendapatkan aturan tajwid berdasarkan ruleKey (kunci unik)
  TajwidRule? getRule(String key);

  /// Mendapatkan seluruh daftar aturan tajwid yang didukung
  List<TajwidRule> getAllRules();
}
