import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'routes/app_router.dart';
import 'shared/theme/app_theme.dart';
import 'shared/theme/theme_settings_provider.dart';
import 'shared/providers.dart';
import 'core/utils/notification_service.dart';
import 'core/utils/home_widget_service.dart';

void main() async {
  // Memastikan framework binding Flutter diinisialisasi sebelum proses sinkronisasi database dijalankan
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi SharedPreferences secara awal
  final sharedPrefs = await SharedPreferences.getInstance();

  // Inisialisasi Firebase Cloud
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inisialisasi Layanan Notifikasi Lokal
  await NotificationService.initialize();
  // Jalankan perizinan secara asinkron di latar belakang agar tidak menghalangi pemanggilan runApp()
  NotificationService.requestPermissions().catchError((e) {
    debugPrint('Gagal meminta izin notifikasi saat startup: $e');
  });

  // Inisialisasi Home Screen Widget Service
  await HomeWidgetService.initialize();
  HomeWidgetService.refreshWidget().catchError((e) {
    debugPrint('Gagal refresh home widget saat startup: $e');
  });
  
  runApp(
    // Membungkus seluruh aplikasi dengan ProviderScope untuk state management Riverpod
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  StreamSubscription<String>? _alarmSubscription;

  @override
  void initState() {
    super.initState();
    // Mendengarkan pemicu alarm saat aplikasi aktif (foreground/background)
    _alarmSubscription = NotificationService.alarmTriggerController.stream.listen((habitId) {
      if (mounted) {
        // Navigasi langsung ke layar alarm khusus
        AppRouter.router.go('/alarm/$habitId');
      }
    });
  }

  @override
  void dispose() {
    _alarmSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final themeSettings = ref.watch(themeSettingsProvider);

    final customAccent = themeSettings.customAccentColor != null 
        ? Color(themeSettings.customAccentColor!) 
        : null;

    return MaterialApp.router(
      title: 'Dailio',
      debugShowCheckedModeBanner: false,
      
      // Integrasi Tema Premium Light & Dark Mode yang Dinamis
      theme: AppTheme.buildTheme(
        brightness: Brightness.light,
        preset: themeSettings.preset,
        customAccent: customAccent,
        fontFamily: themeSettings.fontFamily,
      ),
      darkTheme: AppTheme.buildTheme(
        brightness: Brightness.dark,
        preset: themeSettings.preset,
        customAccent: customAccent,
        fontFamily: themeSettings.fontFamily,
      ),
      themeMode: themeMode,

      // Integrasi Navigasi GoRouter Terpusat
      routerConfig: AppRouter.router,
    );
  }
}
