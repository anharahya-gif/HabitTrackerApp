import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/csv_habit_helper.dart';
import '../../../../core/utils/csv_task_helper.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../habits/domain/entities/habit.dart';
import '../../../habits/presentation/controllers/habit_list_controller.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/presentation/controllers/task_list_controller.dart';
import '../../domain/entities/app_user.dart';
import '../controllers/auth_controller.dart';
import '../../../../shared/providers.dart';
import '../../../../core/utils/dummy_seeder.dart';
import '../../../../core/utils/notification_service.dart';
import '../../../../shared/widgets/collapsible_sidebar.dart';
import '../../../dashboard/presentation/controllers/analytics_controller.dart';
import '../../../dashboard/presentation/widgets/perfect_week_badge_widget.dart';
import '../../../dashboard/presentation/widgets/habit_adherence_chart.dart';
import '../../../dashboard/presentation/widgets/task_velocity_chart.dart';
import '../../../dashboard/presentation/controllers/gamification_controller.dart';

/// Halaman Profil Pengguna Dailio berdesain premium.
/// Mendukung login Google reaktif, keluar akun, info sinkronisasi SQLite lokal,
/// serta penyediaan fitur Demo Bypass saat verifikasi asli di emulator terkendala.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  // Dapatkan ikon emoji sesuai tahap pertumbuhan tanaman
  String _getPlantEmoji(int stage) {
    switch (stage) {
      case -1:
        return '🥀'; // Mati
      case 0:
        return '🫘'; // Benih
      case 1:
        return '🌱'; // Kecambah
      case 2:
        return '🪴'; // Sapling / Bibit di Pot
      case 3:
        return '🌳'; // Tanaman Dewasa
      case 4:
        return '🌻'; // Mekar Sempurna (Bunga Matahari)
      default:
        return '🫘';
    }
  }

  // Dapatkan nama tahap pertumbuhan tanaman
  String _getStageName(int stage) {
    switch (stage) {
      case -1:
        return 'Mati Kering';
      case 0:
        return 'Benih';
      case 1:
        return 'Kecambah';
      case 2:
        return 'Bibit Muda';
      case 3:
        return 'Tanaman Rindang';
      case 4:
        return 'Mekar Sempurna';
      default:
        return 'Benih';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final analyticsAsync = ref.watch(analyticsControllerProvider);
    final game = ref.watch(gamificationProvider);

    final isMobile = MediaQuery.of(context).size.width < 600;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xff111318)
            : Theme.of(context).scaffoldBackgroundColor,
        drawer: isMobile ? const CollapsibleSidebar(isDrawer: true) : null,
        appBar: AppBar(
          title: const Text('Profil Dailio'),
          leading: isMobile
              ? Builder(
                  builder: (context) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.menu_rounded, size: 20),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        style: IconButton.styleFrom(
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        ),
        body: authState.when(
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentPrimary)),
                SizedBox(height: 16),
                Text('Memproses autentikasi...', style: TextStyle(color: Color(0xff94a3b8))),
              ],
            ),
          ),
          error: (error, _) => _buildErrorScreen(context, ref, error.toString()),
          data: (user) {
            final habits = ref.watch(habitListProvider).valueOrNull ?? [];
            final tasks = ref.watch(taskListProvider).valueOrNull ?? [];
            return _buildProfileContent(context, ref, user, habits, tasks, analyticsAsync, game);
          },
        ),
      ),
    );
  }

  /// Membangun antarmuka konten profil utama
  Widget _buildProfileContent(
      BuildContext context, 
      WidgetRef ref, 
      AppUser user, 
      List<Habit> habits, 
      List<Task> tasks,
      AsyncValue<AnalyticsState> analyticsAsync,
      GamificationState game) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xff1a1d24) : theme.colorScheme.surface;
    final textPrimary = isDark ? const Color(0xffe2e8f0) : theme.colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xff94a3b8) : theme.colorScheme.onSurface.withOpacity(0.6);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),

          // 1. Tampilan Avatar & Info Akun Utama
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                // Container Avatar Lingkaran Ganda
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: user.isAuthenticated 
                          ? AppTheme.statusDone.withOpacity(0.3) 
                          : AppTheme.accentPrimary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: cardColor,
                    backgroundImage: user.photoUrl != null 
                        ? NetworkImage(user.photoUrl!) 
                        : null,
                    child: user.photoUrl == null
                        ? Icon(
                            user.isGuest ? Icons.person_outline : Icons.spa_outlined,
                            size: 48,
                            color: user.isGuest ? AppTheme.accentPrimary : AppTheme.statusDone,
                          )
                        : null,
                  ),
                ),
                // Badge Indikator Status Akun di atas Avatar
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: user.isAuthenticated ? AppTheme.statusDone : AppTheme.accentPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? const Color(0xff111318) : theme.scaffoldBackgroundColor, width: 2),
                  ),
                  child: Icon(
                    user.isAuthenticated ? Icons.verified : Icons.lock_outline,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Nama Pengguna
          Text(
            user.displayName,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),

          // Email Pengguna
          Text(
            user.email,
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // 1.2. Level & XP Progress Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.amber.withOpacity(0.15),
              ),
              gradient: LinearGradient(
                colors: [
                  isDark ? const Color(0xff1e293b) : Colors.amber.shade50,
                  cardColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.emoji_events_rounded,
                            color: Colors.amber,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Level ${game.level}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Gelar: Pejuang Konsistensi',
                              style: TextStyle(
                                fontSize: 11,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      '${game.xp} / ${game.level * 100} XP',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: game.xp / (game.level * 100),
                    backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 1.3. Dailio Garden Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (game.plantStage == -1
                    ? AppTheme.statusMissed
                    : (game.wiltDays > 0 ? AppTheme.statusSkipped : AppTheme.statusDone)).withOpacity(0.12),
              ),
              gradient: LinearGradient(
                colors: [
                  isDark ? const Color(0xff0f172a) : Colors.green.shade50,
                  cardColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                // Plant Emoji inside round container
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xff1e293b) : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (game.plantStage == -1
                            ? AppTheme.statusMissed
                            : (game.wiltDays > 0 ? AppTheme.statusSkipped : AppTheme.statusDone)).withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _getPlantEmoji(game.plantStage),
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Plant Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Taman Dailio: ${game.plantType}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status: ${game.plantStage == -1 ? "Mati" : (game.wiltDays > 0 ? "Layu" : "Subur")}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: game.plantStage == -1
                              ? AppTheme.statusMissed
                              : (game.wiltDays > 0 ? AppTheme.statusSkipped : AppTheme.statusDone),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Fase: ${_getStageName(game.plantStage)} (${(game.plantProgress * 100).toStringAsFixed(0)}%)',
                        style: TextStyle(
                          fontSize: 11,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 1.5. Visualisasi Statistik & Analytics (Interactive Charts & Perfect Week Badge)
          analyticsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentPrimary),
                ),
              ),
            ),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Gagal memuat analitik: $error',
                  style: const TextStyle(color: AppTheme.statusMissed, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (analyticsState) {
              return Column(
                children: [
                  // Perfect Week Badge
                  PerfectWeekBadgeWidget(
                    hasBadge: analyticsState.hasPerfectWeekBadge,
                    totalCount: analyticsState.perfectWeeksCount,
                  ),
                  const SizedBox(height: 24),

                  // Habit Adherence rate chart
                  HabitAdherenceChart(data: analyticsState.adherenceData),
                  const SizedBox(height: 24),

                  // Task velocity chart
                  TaskVelocityChart(
                    categoryCounts: analyticsState.taskCategoryCounts,
                    totalCompleted: analyticsState.totalTasksCompleted,
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),

          // 2. Banner Status Integrasi & Database
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: user.isAuthenticated 
                    ? AppTheme.statusDone.withOpacity(0.12)
                    : AppTheme.accentPrimary.withOpacity(0.12),
              ),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: user.isAuthenticated 
                        ? AppTheme.statusDone.withOpacity(0.1)
                        : AppTheme.accentPrimary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    user.isAuthenticated ? Icons.cloud_done_outlined : Icons.storage_outlined,
                    color: user.isAuthenticated ? AppTheme.statusDone : AppTheme.accentPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Keterangan Teks
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.isAuthenticated ? 'Cloud Sinkronisasi Aktif' : 'Mode Tamu (Guest Mode)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.isAuthenticated 
                            ? 'Seluruh data habit Anda tersimpan di cloud & siap diakses dari HP mana pun.'
                            : 'Aplikasi berjalan offline. Data habit Anda tersimpan dengan aman di SQLite lokal Anda.',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                          height: 1.4,
                        ),
                      ),
                      if (user.isAuthenticated) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 36,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Sedang menyelaraskan data dengan cloud...'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                              try {
                                await ref.read(syncServiceProvider).syncData(user.id);
                                
                                // Refresh data lokal di UI setelah sukses ditarik/unggah
                                ref.read(habitListProvider.notifier).refresh();
                                ref.read(taskListProvider.notifier).refresh();
                                
                                // Invalidate semua streak & log provider agar UI terupdate
                                final habits = ref.read(habitListProvider).valueOrNull ?? [];
                                for (final h in habits) {
                                  ref.invalidate(habitStreakProvider(h.id));
                                  ref.invalidate(habitTodayLogProvider(h.id));
                                }


                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Sinkronisasi sukses! Data aman di cloud. 🌱'),
                                    backgroundColor: AppTheme.statusDone,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal sinkronisasi: $e'),
                                    backgroundColor: AppTheme.statusMissed,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.statusDone.withOpacity(0.15),
                              foregroundColor: AppTheme.statusDone,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            icon: const Icon(Icons.sync, size: 16),
                            label: const Text(
                              'Sinkronkan Sekarang',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2.5. Cadangan Data Lokal (.xml) Ekspor & Impor
          // _buildBackupSection(context, ref, habits, tasks),

          if (kDebugMode) ...[
            const SizedBox(height: 24),
            // Tombol Seeder Dummy Sementara
            _buildDummySeederButton(context, ref),
          ],

          const SizedBox(height: 32),

          // 3. Tombol Aksi Autentikasi Utama
          if (user.isGuest) ...[
            // Tombol Login Google Asli
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(authControllerProvider.notifier).signInWithGoogle(useDemoBypass: false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xff0f172a),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                icon: const GoogleLogoIcon(size: 20),
                label: const Text(
                  'Hubungkan Akun Google',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Tombol Simulasi Akun Demo (Bypass)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(authControllerProvider.notifier).signInWithGoogle(useDemoBypass: true);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.statusDone,
                  side: const BorderSide(color: AppTheme.statusDone, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.bolt, size: 20),
                label: const Text(
                  'Simulasi dengan Akun Demo Dailio',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ] else ...[
            // Tombol Sign Out / Keluar Akun
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: () {
                  _showConfirmSignOutDialog(context, ref);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.statusMissed,
                  side: BorderSide(color: AppTheme.statusMissed.withOpacity(0.5), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.logout_outlined, size: 20),
                label: const Text(
                  'Keluar dari Akun',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 48),
          
          // Footer
          const Column(
            children: [
              Text(
                'Dailio — Grow Through Consistency. 🌿',
                style: TextStyle(color: Color(0xff475569), fontSize: 11, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 4),
              Text(
                'Versi 1.0.0 (Guest Mode Pluggable)',
                style: TextStyle(color: Color(0xff334155), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Tombol Seeder Dummy Sementara untuk kemudahan verifikasi calendar & time log
  Widget _buildDummySeederButton(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff1e293b),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amber.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.science_outlined, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                'Menu Developer (Testing)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Hasilkan 1 habit olahraga pagi beserta riwayat 40 hari penuh centang secara otomatis untuk menguji kalender.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: () async {
                final localHabitDS = ref.read(habitLocalDataSourceProvider);
                final localLogDS = ref.read(trackingLocalDataSourceProvider);
                final calculateStreak = ref.read(calculateStreakProvider);

                try {
                  await DummySeeder.seedDummyHabit(
                    habitLocalDS: localHabitDS,
                    trackingLocalDS: localLogDS,
                    calculateStreak: calculateStreak,
                  );
                  
                  // Segarkan data UI utama
                  await ref.read(habitListProvider.notifier).refresh();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Habit dummy "Olahraga Pagi 🏃" berhasil di-generate! 🌱'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal men-generate: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.withOpacity(0.15),
                foregroundColor: Colors.amber,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.bolt, size: 16),
              label: const Text(
                'Generate Habit Dummy & Riwayat',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  await NotificationService.showTestNotification();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notifikasi instan terkirim! Silakan cek bilah status HP Anda. 🔔'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal mengirim notifikasi: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.withOpacity(0.15),
                foregroundColor: Colors.blue,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.notifications_active, size: 16),
              label: const Text(
                'Test Kirim Notifikasi Instan',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Menampilkan layar error dengan opsi alternatif Demo Bypass
  Widget _buildErrorScreen(BuildContext context, WidgetRef ref, String errorMessage) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          // Ikon Peringatan
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.statusMissed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.statusMissed,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          
          const Text(
            'Konfigurasi Diperlukan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xffe2e8f0),
            ),
          ),
          const SizedBox(height: 8),
          
          // Detail Error
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xff1a1d24),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              errorMessage,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xff94a3b8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),

          // Pilihan 1: Gunakan Simulasi Demo (Sangat Direkomendasikan untuk uji coba)
          const Text(
            'Rekomendasi Uji Coba UI:',
            style: TextStyle(color: Color(0xff64748b), fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                ref.read(authControllerProvider.notifier).signInWithGoogle(useDemoBypass: true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statusDone,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.bolt),
              label: const Text(
                'Simulasi dengan Akun Demo Dailio',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Pilihan 2: Kembali ke Guest Mode / Halaman utama
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () {
                // Clear error dengan cara memicu logout (mengembalikan status ke Guest)
                ref.read(authControllerProvider.notifier).signOut();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xff94a3b8),
                side: const BorderSide(color: Color(0xff2e3342)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Tetap di Guest Mode (Offline)'),
            ),
          ),
        ],
      ),
    );
  }

  /// Menampilkan dialog konfirmasi sign out
  void _showConfirmSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xff1a1d24),
          title: const Text('Keluar dari Akun?', style: TextStyle(color: Color(0xffe2e8f0))),
          content: const Text(
            'Apakah Anda yakin ingin keluar? Dailio akan otomatis kembali ke Guest Mode lokal.',
            style: TextStyle(color: Color(0xff94a3b8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal', style: TextStyle(color: Color(0xff64748b))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(authControllerProvider.notifier).signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statusMissed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }

//   /// Membangun kartu cadangan lokal untuk melakukan ekspor & impor CSV
//   Widget _buildBackupSection(BuildContext context, WidgetRef ref, List<Habit> habits, List<Task> tasks) {
//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;
//     final cardColor = isDark ? const Color(0xff1a1d24) : theme.colorScheme.surface;
//     final borderColor = isDark ? const Color(0xff2e3342) : const Color(0xffe2e8f0);
//     final textPrimary = isDark ? const Color(0xffe2e8f0) : theme.colorScheme.onSurface;
//     final textSecondary = isDark ? const Color(0xff94a3b8) : theme.colorScheme.onSurface.withOpacity(0.6);

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: cardColor,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(
//           color: borderColor,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               const Icon(Icons.table_chart_outlined, color: AppTheme.statusSkipped, size: 20),
//               const SizedBox(width: 8),
//               Text(
//                 'Cadangan Data Lokal',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 15,
//                   color: textPrimary,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 4),
//           Text(
//             'Ekspor atau impor data Dailio Anda secara mandiri menggunakan file format .csv (Excel).',
//             style: TextStyle(
//               fontSize: 12,
//               color: textSecondary,
//               height: 1.4,
//             ),
//           ),
//           const SizedBox(height: 20),
          
//           // --- HABITS SECTION ---
//           Text(
//             'Data Kebiasaan (Habits)',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 13,
//               color: textPrimary,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Row(
//             children: [
//               // Tombol Ekspor Habits
//               Expanded(
//                 child: SizedBox(
//                   height: 40,
//                   child: OutlinedButton.icon(
//                     onPressed: () => _exportHabits(context, habits),
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: AppTheme.accentPrimary,
//                       side: BorderSide(color: borderColor),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     icon: const Icon(Icons.upload_outlined, size: 16),
//                     label: const Text(
//                       'Ekspor (.csv)',
//                       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
              
//               // Tombol Impor Habits
//               Expanded(
//                 child: SizedBox(
//                   height: 40,
//                   child: ElevatedButton.icon(
//                     onPressed: () => _importHabits(context, ref),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppTheme.accentPrimary,
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     icon: const Icon(Icons.download_outlined, size: 16),
//                     label: const Text(
//                       'Impor (.csv)',
//                       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
          
//           const SizedBox(height: 20),
//           Divider(color: borderColor),
//           const SizedBox(height: 12),

//           // --- TASKS SECTION ---
//           Text(
//             'Data Tugas (Tasks)',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 13,
//               color: textPrimary,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Row(
//             children: [
//               // Tombol Ekspor Tasks
//               Expanded(
//                 child: SizedBox(
//                   height: 40,
//                   child: OutlinedButton.icon(
//                     onPressed: () => _exportTasks(context, tasks),
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: AppTheme.statusSkipped,
//                       side: BorderSide(color: borderColor),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     icon: const Icon(Icons.upload_outlined, size: 16),
//                     label: const Text(
//                       'Ekspor (.csv)',
//                       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
              
//               // Tombol Impor Tasks
//               Expanded(
//                 child: SizedBox(
//                   height: 40,
//                   child: ElevatedButton.icon(
//                     onPressed: () => _importTasks(context, ref),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppTheme.statusSkipped,
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     icon: const Icon(Icons.download_outlined, size: 16),
//                     label: const Text(
//                       'Impor (.csv)',
//                       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   /// Proses mengekspor habit lokal ke file CSV dan membagikannya via Share Sheet
//   Future<void> _exportHabits(BuildContext context, List<Habit> habits) async {
//     if (habits.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Anda belum memiliki kebiasaan aktif untuk diekspor.'),
//           backgroundColor: AppTheme.statusSkipped,
//         ),
//       );
//       return;
//     }

//     try {
//       // 1. Generate konten CSV
//       final csvString = CsvHabitHelper.habitsToCsv(habits);

//       // 2. Simpan di direktori temporer HP
//       final directory = await getTemporaryDirectory();
//       final file = File('${directory.path}/dailio_habits_backup.csv');
//       await file.writeAsString(csvString);

//       // 3. Share file CSV menggunakan Share Sheet native OS
//       await Share.shareXFiles(
//         [XFile(file.path)],
//         subject: 'Dailio Habits Backup (.csv)',
//         text: 'Berikut adalah file backup daftar kebiasaan Dailio saya! 🌱',
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Gagal mengekspor data: $e'),
//           backgroundColor: AppTheme.statusMissed,
//         ),
//       );
//     }
//   }

//   /// Proses mengimpor file CSV dari storage lokal dan memasukkannya ke database SQLite
//   Future<void> _importHabits(BuildContext context, WidgetRef ref) async {
//     try {
//       // 1. Buka File Picker bawaan OS untuk menyaring berkas .csv
//       final result = await FilePicker.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['csv'],
//       );

//       if (result == null || result.files.single.path == null) {
//         // Proses dibatalkan oleh user
//         return;
//       }

//       // 2. Baca isi file CSV
//       final file = File(result.files.single.path!);
//       final csvContent = await file.readAsString();

//       // 3. Parsing CSV ke List<Habit>
//       final importedHabits = CsvHabitHelper.csvToHabits(csvContent);

//       if (importedHabits.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('File CSV kosong atau tidak sesuai dengan format ekspor Dailio.'),
//             backgroundColor: AppTheme.statusSkipped,
//           ),
//         );
//         return;
//       }

//       // 4. Masukkan ke dalam SQLite menggunakan controller HabitList secara paralel/sekuensial
//       int successCount = 0;
//       for (final habit in importedHabits) {
//         final res = await ref.read(habitListProvider.notifier).addHabit(habit);
//         if (res is Success<void>) {
//           successCount++;
//         }
//       }

//       // 5. Beri feedback visual SnackBar
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Berhasil memulihkan $successCount dari ${importedHabits.length} kebiasaan! 🎉'),
//           backgroundColor: AppTheme.statusDone,
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Gagal mengimpor data. Pastikan format CSV sesuai.\nError: $e'),
//           backgroundColor: AppTheme.statusMissed,
//         ),
//       );
//     }
//   }

//   /// Proses mengekspor tasks lokal ke file CSV dan membagikannya via Share Sheet
//   Future<void> _exportTasks(BuildContext context, List<Task> tasks) async {
//     if (tasks.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Anda belum memiliki tugas untuk diekspor.'),
//           backgroundColor: AppTheme.statusSkipped,
//         ),
//       );
//       return;
//     }

//     try {
//       final csvString = CsvTaskHelper.tasksToCsv(tasks);

//       final directory = await getTemporaryDirectory();
//       final file = File('${directory.path}/dailio_tasks_backup.csv');
//       await file.writeAsString(csvString);

//       await Share.shareXFiles(
//         [XFile(file.path)],
//         subject: 'Dailio Tasks Backup (.csv)',
//         text: 'Berikut adalah file backup daftar tugas Dailio saya! 📋',
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Gagal mengekspor data: $e'),
//           backgroundColor: AppTheme.statusMissed,
//         ),
//       );
//     }
//   }

//   /// Proses mengimpor file CSV tugas dari storage lokal dan memasukkannya ke database SQLite
//   Future<void> _importTasks(BuildContext context, WidgetRef ref) async {
//     try {
//       final result = await FilePicker.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['csv'],
//       );

//       if (result == null || result.files.single.path == null) {
//         return;
//       }

//       final file = File(result.files.single.path!);
//       final csvContent = await file.readAsString();

//       final importedTasks = CsvTaskHelper.csvToTasks(csvContent);

//       if (importedTasks.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('File CSV kosong atau tidak sesuai dengan format ekspor tugas Dailio.'),
//             backgroundColor: AppTheme.statusSkipped,
//           ),
//         );
//         return;
//       }

//       int successCount = 0;
//       for (final task in importedTasks) {
//         final res = await ref.read(taskListProvider.notifier).addTask(task);
//         if (res is Success<void>) {
//           successCount++;
//         }
//       }

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Berhasil memulihkan $successCount dari ${importedTasks.length} tugas! 🎉'),
//           backgroundColor: AppTheme.statusDone,
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Gagal mengimpor data. Pastikan format CSV sesuai.\nError: $e'),
//           backgroundColor: AppTheme.statusMissed,
//         ),
//       );
//     }
//   }
}

/// Widget Kustom Logo Google Presisi Tinggi demi Keunggulan Visual
class GoogleLogoIcon extends StatelessWidget {
  final double size;

  const GoogleLogoIcon({super.key, this.size = 20.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: const _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double r = w / 2;
    final double cx = r;
    final double cy = r;

    final double outerRadius = r;
    final double innerRadius = outerRadius * 0.58;
    final double thickness = outerRadius - innerRadius;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    Path getRingSector(double startAngle, double sweepAngle) {
      final path = Path();
      // Outer arc
      path.addArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: outerRadius),
        startAngle,
        sweepAngle,
      );
      final double endAngle = startAngle + sweepAngle;
      // Line to inner arc
      path.lineTo(
        cx + innerRadius * math.cos(endAngle),
        cy + innerRadius * math.sin(endAngle),
      );
      // Inner arc (reversed)
      path.arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: innerRadius),
        endAngle,
        -sweepAngle,
        false,
      );
      path.close();
      return path;
    }

    // Google Logo Colors
    const Color blue = Color(0xFF4285F4);
    const Color red = Color(0xFFEA4335);
    const Color yellow = Color(0xFFFBBC05);
    const Color green = Color(0xFF34A853);

    // 1. Red (Top Segment)
    paint.color = red;
    canvas.drawPath(
      getRingSector(
        -140 * math.pi / 180,
        105 * math.pi / 180,
      ),
      paint,
    );

    // 2. Yellow (Left Segment)
    paint.color = yellow;
    canvas.drawPath(
      getRingSector(
        135 * math.pi / 180,
        85 * math.pi / 180,
      ),
      paint,
    );

    // 3. Green (Bottom Segment)
    paint.color = green;
    canvas.drawPath(
      getRingSector(
        45 * math.pi / 180,
        90 * math.pi / 180,
      ),
      paint,
    );

    // 4. Blue (Right Segment & Bar)
    paint.color = blue;
    final Path bluePath = Path();
    
    // Blue upper arc: -35 to 0 degrees
    bluePath.addPath(
      getRingSector(
        -35 * math.pi / 180,
        35 * math.pi / 180,
      ),
      Offset.zero,
    );

    // Blue lower arc: 0 to 45 degrees
    bluePath.addPath(
      getRingSector(
        0 * math.pi / 180,
        45 * math.pi / 180,
      ),
      Offset.zero,
    );

    // Horizontal bar: y = cy to cy + thickness, x = cx to cx + outerRadius
    bluePath.addRect(
      Rect.fromLTRB(cx, cy - 0.2, cx + outerRadius, cy + thickness),
    );

    canvas.drawPath(bluePath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
