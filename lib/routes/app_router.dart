import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/habits/presentation/pages/add_habit_page.dart';
import '../features/habits/presentation/pages/edit_habit_page.dart';
import '../features/habits/presentation/pages/habit_detail_page.dart';
import '../features/habits/presentation/pages/habit_list_page.dart';
import '../features/habits/presentation/pages/splash_page.dart';
import '../features/auth/presentation/pages/profile_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/tasks/presentation/pages/task_list_page.dart';
import '../shared/widgets/main_layout_shell.dart';

/// Konfigurasi navigasi global menggunakan go_router.
/// Menyediakan rute:
/// - `/` (Halaman Splash Screen Dailio)
/// - `/home` (Halaman utama daftar habit)
/// - `/add-habit` (Form tambah habit baru)
/// - `/habit/:id` (Halaman detail habit dengan parameter ID dinamis)
/// - `/profile` (Halaman profil pengguna reaktif)
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (BuildContext context, GoRouterState state) {
          return const SplashPage();
        },
      ),
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return MainLayoutShell(child: child);
        },
        routes: <RouteBase>[
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (BuildContext context, GoRouterState state) {
              return const DashboardPage();
            },
          ),
          GoRoute(
            path: '/habits',
            name: 'habits',
            builder: (BuildContext context, GoRouterState state) {
              return const HabitListPage();
            },
          ),
          GoRoute(
            path: '/tasks',
            name: 'tasks',
            builder: (BuildContext context, GoRouterState state) {
              return const TaskListPage();
            },
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (BuildContext context, GoRouterState state) {
              return const ProfilePage();
            },
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (BuildContext context, GoRouterState state) {
              return const SettingsPage();
            },
          ),
        ],
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
      GoRoute(
        path: '/edit-habit/:id',
        name: 'edit_habit',
        builder: (BuildContext context, GoRouterState state) {
          final habitId = state.pathParameters['id'] ?? '';
          return EditHabitPage(habitId: habitId);
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
