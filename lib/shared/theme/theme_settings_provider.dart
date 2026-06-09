import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers.dart';

/// State untuk pengaturan tema aplikasi.
class ThemeSettings {
  final String preset; // 'default', 'warm_coffee', 'ocean_blue', 'forest_green'
  final int? customAccentColor; // ARGB hex value
  final String fontFamily; // 'Default', 'Inter', 'Poppins', 'Outfit', 'Lora'

  const ThemeSettings({
    required this.preset,
    this.customAccentColor,
    required this.fontFamily,
  });

  ThemeSettings copyWith({
    String? preset,
    int? customAccentColor,
    bool clearCustomAccent = false,
    String? fontFamily,
  }) {
    return ThemeSettings(
      preset: preset ?? this.preset,
      customAccentColor: clearCustomAccent ? null : (customAccentColor ?? this.customAccentColor),
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }
}

/// Notifier reaktif untuk mengelola dan menyimpan preferensi tema pengguna.
class ThemeSettingsNotifier extends StateNotifier<ThemeSettings> {
  final SharedPreferences _prefs;

  ThemeSettingsNotifier(this._prefs)
      : super(ThemeSettings(
          preset: _prefs.getString('theme_preset') ?? 'default',
          customAccentColor: _prefs.containsKey('theme_accent_color')
              ? _prefs.getInt('theme_accent_color')
              : null,
          fontFamily: _prefs.getString('theme_font_family') ?? 'Default',
        ));

  /// Mengatur preset tema aktif
  Future<void> setPreset(String preset) async {
    await _prefs.setString('theme_preset', preset);
    state = state.copyWith(preset: preset);
  }

  /// Mengatur warna aksen kustom (jika null, gunakan warna bawaan preset)
  Future<void> setCustomAccentColor(Color? color) async {
    if (color == null) {
      await _prefs.remove('theme_accent_color');
      state = state.copyWith(clearCustomAccent: true);
    } else {
      await _prefs.setInt('theme_accent_color', color.value);
      state = state.copyWith(customAccentColor: color.value);
    }
  }

  /// Mengatur jenis font aktif
  Future<void> setFontFamily(String fontFamily) async {
    await _prefs.setString('theme_font_family', fontFamily);
    state = state.copyWith(fontFamily: fontFamily);
  }
}

/// Provider global untuk mengakses pengaturan tema yang aktif.
final themeSettingsProvider = StateNotifierProvider<ThemeSettingsNotifier, ThemeSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeSettingsNotifier(prefs);
});
