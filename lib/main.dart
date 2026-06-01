import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routes/app_router.dart';
import 'shared/theme/app_theme.dart';

void main() {
  // Memastikan framework binding Flutter diinisialisasi sebelum proses sinkronisasi database dijalankan
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    // Membungkus seluruh aplikasi dengan ProviderScope untuk state management Riverpod
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Dailio',
      debugShowCheckedModeBanner: false,
      
      // Integrasi Tema Premium Light & Dark Mode
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Default menggunakan Dark Mode yang premium

      // Integrasi Navigasi GoRouter Terpusat
      routerConfig: AppRouter.router,
    );
  }
}
