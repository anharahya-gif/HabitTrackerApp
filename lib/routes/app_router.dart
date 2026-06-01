import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/habits/presentation/pages/add_habit_page.dart';
import '../features/habits/presentation/pages/habit_detail_page.dart';
import '../features/habits/presentation/pages/habit_list_page.dart';

/// Konfigurasi navigasi global menggunakan go_router.
/// Menyediakan rute:
/// - `/` (Halaman utama daftar habit)
/// - `/add-habit` (Form tambah habit baru)
/// - `/habit/:id` (Halaman detail habit dengan parameter ID dinamis)
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: 'home',
        builder: (BuildContext context, GoRouterState state) {
          return const HabitListPage();
        },
      ),
      GoRoute(
        path: '/add-habit',
        name: 'add_habit',
        builder: (BuildContext context, GoRouterState state) {
          return const AddHabitPage();
        },
      ),
      GoRoute(
        path: '/habit/:id',
        name: 'habit_detail',
        builder: (BuildContext context, GoRouterState state) {
          final habitId = state.pathParameters['id'] ?? '';
          return HabitDetailPage(habitId: habitId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Halaman tidak ditemukan: ${state.error}',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    ),
  );
}
