import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../../features/habits/domain/entities/habit.dart';
import '../../features/habits/domain/entities/habit_streak.dart';
import '../../features/tracking/domain/entities/habit_log.dart';

/// Service untuk menyinkronkan data habit ke Android Home Screen Widget
/// melalui SharedPreferences via package `home_widget`.
class HomeWidgetService {
  /// Nama provider widget Android (harus cocok dengan class name di Kotlin)
  static const String _androidWidgetName = 'DailioWidgetProvider';

  /// Key SharedPreferences untuk data widget
  static const String _keyStreak = 'streak';
  static const String _keyCompleted = 'completed';
  static const String _keyTotal = 'total';
  static const String _keyHabitsJson = 'habits_json';
  static const String _keyAyahTranslation = 'ayah_translation';
  static const String _keyAyahReference = 'ayah_reference';

  /// Inisialisasi home widget (panggil sekali saat app startup)
  static Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      // Set app group ID (diperlukan untuk iOS, opsional untuk Android)
      await HomeWidget.setAppGroupId('group.com.anhar.dailio');
    } catch (e) {
      debugPrint('HomeWidgetService: Gagal inisialisasi - $e');
    }
  }

  /// Menyimpan data habit terkini ke SharedPreferences dan memicu refresh widget.
  ///
  /// [habits] — seluruh daftar habit aktif (non-archived)
  /// [streaks] — map dari habitId ke HabitStreak
  /// [todayLogs] — map dari habitId ke HabitLog hari ini
  static Future<void> updateWidgetData({
    required List<Habit> habits,
    required Map<String, HabitStreak?> streaks,
    required Map<String, HabitLog?> todayLogs,
  }) async {
    if (kIsWeb) return;

    try {
      // 1. Hitung streak tertinggi saat ini
      int maxStreak = 0;
      for (final streak in streaks.values) {
        if (streak != null && streak.currentStreak > maxStreak) {
          maxStreak = streak.currentStreak;
        }
      }

      // 2. Hitung jumlah habit yang sudah selesai hari ini
      int completedCount = 0;
      for (final log in todayLogs.values) {
        if (log != null && log.status == 'done') {
          completedCount++;
        }
      }

      // 3. Buat JSON array daftar habit dengan status
      final habitsList = habits.map((habit) {
        final log = todayLogs[habit.id];
        final isDone = log != null && log.status == 'done';
        return {
          'name': habit.name,
          'done': isDone,
        };
      }).toList();

      final habitsJson = jsonEncode(habitsList);

      // 4. Simpan ke SharedPreferences via home_widget
      await HomeWidget.saveWidgetData<int>(_keyStreak, maxStreak);
      await HomeWidget.saveWidgetData<int>(_keyCompleted, completedCount);
      await HomeWidget.saveWidgetData<int>(_keyTotal, habits.length);
      await HomeWidget.saveWidgetData<String>(_keyHabitsJson, habitsJson);

      // 5. Trigger update pada semua widget
      await _triggerWidgetUpdate();

      debugPrint('HomeWidgetService: Widget data updated - $completedCount/${habits.length} done, streak: $maxStreak');
    } catch (e) {
      debugPrint('HomeWidgetService: Gagal memperbarui widget data - $e');
    }
  }

  /// Trigger refresh widget tanpa mengubah data (berguna saat app startup)
  static Future<void> refreshWidget() async {
    if (kIsWeb) return;
    try {
      await _triggerWidgetUpdate();
    } catch (e) {
      debugPrint('HomeWidgetService: Gagal refresh widget - $e');
    }
  }

  /// Trigger update pada semua varian widget Android (Small, Medium, Large)
  static Future<void> _triggerWidgetUpdate() async {
    // Update semua 3 varian widget
    await HomeWidget.updateWidget(
      name: 'DailioWidgetSmall',
      androidName: 'DailioWidgetSmall',
    );
    await HomeWidget.updateWidget(
      name: 'DailioWidgetMedium',
      androidName: 'DailioWidgetMedium',
    );
    await HomeWidget.updateWidget(
      name: 'DailioWidgetLarge',
      androidName: 'DailioWidgetLarge',
    );
  }

  /// Menyimpan data Ayat Hari Ini ke SharedPreferences dan memicu refresh widget.
  static Future<void> updateAyahData(String translation, String reference) async {
    if (kIsWeb) return;
    try {
      await HomeWidget.saveWidgetData<String>(_keyAyahTranslation, translation);
      await HomeWidget.saveWidgetData<String>(_keyAyahReference, reference);
      await _triggerWidgetUpdate();
      debugPrint('HomeWidgetService: Ayah data updated - $reference');
    } catch (e) {
      debugPrint('HomeWidgetService: Gagal memperbarui widget data ayat - $e');
    }
  }
}
