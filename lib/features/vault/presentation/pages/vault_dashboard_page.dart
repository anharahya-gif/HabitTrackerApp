import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/providers/vault_provider.dart';
import '../../../../shared/providers.dart';
import '../../../habits/domain/entities/habit.dart';
import '../../../habits/presentation/controllers/habit_list_controller.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../tracking/presentation/controllers/tracking_controller.dart';

class VaultDashboardPage extends ConsumerStatefulWidget {
  const VaultDashboardPage({super.key});

  @override
  ConsumerState<VaultDashboardPage> createState() => _VaultDashboardPageState();
}

class _VaultDashboardPageState extends ConsumerState<VaultDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isUnlocked = ref.read(vaultSecurityProvider).isUnlocked;
      if (!isUnlocked) {
        context.go('/vault');
      }
    });
  }

  @override
  void dispose() {
    // Automatically lock when leaving the vault dashboard for security
    ref.read(vaultSecurityProvider.notifier).lock();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final securityState = ref.watch(vaultSecurityProvider);
    final privateHabitsAsync = ref.watch(todayPrivateHabitsProvider);
    final trackingState = ref.watch(trackingProvider);

    // Redirect to lock screen if locked
    if (!securityState.isUnlocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/vault');
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Custom amethyst palette
    final bgColor = isDark ? const Color(0xff0e0b16) : const Color(0xfff5f0fa);
    final cardColor = isDark ? const Color(0xff1f192b) : Colors.white;
    final accentPurple = const Color(0xffa586e0);
    final gradientStart = const Color(0xff6a1b9a); // Amethyst Purple
    final gradientEnd = const Color(0xffab47bc); // Soft Lavender

    // Calculate maximum clean streak of all private habits
    final habits = privateHabitsAsync.valueOrNull ?? [];
    int maxStreak = 0;
    for (final h in habits) {
      final streakAsync = ref.watch(habitStreakProvider(h.id));
      final streak = streakAsync.valueOrNull;
      if (streak != null && streak.currentStreak > maxStreak) {
        maxStreak = streak.currentStreak;
      }
    }

    final isMobile = MediaQuery.of(context).size.width < 600;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      },
      child: Theme(
        data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: accentPurple,
          secondary: accentPurple,
        ),
      ),
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              Icon(Icons.shield_outlined, color: accentPurple),
              const SizedBox(width: 10),
              Text(
                'Dailio Vault',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.lock_rounded, color: accentPurple),
              tooltip: 'Kunci Vault',
              onPressed: () {
                ref.read(vaultSecurityProvider.notifier).lock();
                context.go('/home');
              },
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await ref.read(habitListProvider.notifier).refresh();
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                // 1. Glowing Streak Dashboard Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [gradientStart, gradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: gradientStart.withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Clean Streak Saat Ini 🎯',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              maxStreak > 0 ? '$maxStreak Hari Bersih' : 'Mulai Bersih Hari Ini',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 24,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Menjaga konsistensi kebiasaan privat Anda demi masa depan yang lebih baik.',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.orangeAccent,
                          size: 44,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),

                // SOS Panic Button / Intervensi Darurat
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      context.push('/vault/sos');
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xff4a148c), // Deep violet
                            Color(0xff880e4f), // Dark maroon/pink
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.redAccent.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.bolt_rounded,
                              color: Colors.amberAccent,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SOS - Butuh Bantuan Instan?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rasakan urge kuat? Klik di sini untuk latihan penenang napas.',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white70,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // My Why Vision Board Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      context.push('/vault/my-why');
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xff2c1b4d), // Deep purple-black
                            Color(0xff4a148c), // Deep violet
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xffb388ff).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.psychology_rounded,
                              color: Color(0xffe040fb), // Light magenta
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'My Why - Papan Visi & Komitmen',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tulis komitmen & ingatkan alasan kuat Anda bertahan.',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white70,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),
                
                // 2. Private Habits Title Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kebiasaan Privat Hari Ini',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline_rounded, color: accentPurple),
                      onPressed: () {
                        // Navigate to add-habit with isPrivate parameter
                        context.push('/add-habit?isPrivate=true');
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // 3. Private Habits List
                privateHabitsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Text('Gagal memuat habit privat: $err'),
                  ),
                  data: (privateHabits) {
                    if (privateHabits.isEmpty) {
                      return Card(
                        color: cardColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: theme.colorScheme.outline.withOpacity(0.08),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(Icons.lock_open_rounded, size: 48, color: accentPurple.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              Text(
                                'Belum Ada Habit Privat',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Buat habit privat baru (seperti No PMO) yang hanya terlihat di sini.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark ? Colors.white38 : Colors.black45,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentPurple,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.add),
                                label: const Text('Buat Habit Privat'),
                                onPressed: () {
                                  context.push('/add-habit?isPrivate=true');
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    return Column(
                      children: privateHabits.map((habit) {
                        final logTodayAsync = ref.watch(habitTodayLogProvider(habit.id));
                        final streakAsync = ref.watch(habitStreakProvider(habit.id));
                        final streak = streakAsync.valueOrNull?.currentStreak ?? 0;
                        
                        return logTodayAsync.maybeWhen(
                          data: (logToday) {
                            final isDone = logToday?.status == 'done';
                            final isSkipped = logToday?.status == 'skipped';
                            
                            return Card(
                              color: cardColor,
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: theme.colorScheme.outline.withOpacity(0.08),
                                ),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Color(habit.color).withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.spa_rounded,
                                    color: Color(habit.color),
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  habit.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    decoration: isDone ? TextDecoration.lineThrough : null,
                                    color: isDone 
                                        ? theme.colorScheme.onSurface.withOpacity(0.4) 
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                                subtitle: Text(
                                  'Streak: $streak hari • ${habit.reminderTime ?? "Tanpa pengingat"}',
                                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Skip button
                                    IconButton(
                                      icon: Icon(
                                        Icons.next_plan,
                                        color: isSkipped ? AppTheme.statusSkipped : Colors.grey.withOpacity(0.5),
                                      ),
                                      onPressed: trackingState is TrackingLoading
                                          ? null
                                          : () async {
                                              final newStatus = isSkipped ? 'missed' : 'skipped';
                                              await ref.read(trackingProvider.notifier).trackHabit(
                                                habitId: habit.id,
                                                date: DateFormatter.todayString,
                                                status: newStatus,
                                              );
                                            },
                                    ),
                                    // Done check button
                                    IconButton(
                                      icon: Icon(
                                        isDone ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                                        color: isDone ? AppTheme.statusDone : Colors.grey.withOpacity(0.5),
                                      ),
                                      onPressed: trackingState is TrackingLoading
                                          ? null
                                          : () async {
                                              final newStatus = isDone ? 'missed' : 'done';
                                              await ref.read(trackingProvider.notifier).trackHabit(
                                                habitId: habit.id,
                                                date: DateFormatter.todayString,
                                                status: newStatus,
                                              );
                                            },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          orElse: () => const SizedBox.shrink(),
                        );
                      }).toList(),
                    );
                  },
                ),
                
                const SizedBox(height: 28),
                
                // 4. Vault Security Settings Section
                Text(
                  'Keamanan Vault',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Card(
                  color: cardColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.08),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Biometrics switch
                      SwitchListTile(
                        title: const Text(
                          'Autentikasi Biometrik',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          securityState.isBiometricSupported
                              ? 'Buka Ruang Privat menggunakan sidik jari/FaceID'
                              : 'Tidak didukung oleh perangkat Anda',
                          style: const TextStyle(fontSize: 11),
                        ),
                        value: securityState.isBiometricEnabled,
                        activeColor: accentPurple,
                        onChanged: securityState.isBiometricSupported
                            ? (val) {
                                ref.read(vaultSecurityProvider.notifier).setBiometricEnabled(val);
                              }
                            : null,
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      // Reset PIN
                      ListTile(
                        title: const Text(
                          'Reset Keamanan Vault',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.redAccent),
                        ),
                        subtitle: const Text(
                          'Hapus PIN dan seluruh konfigurasi pengunci Vault',
                          style: TextStyle(fontSize: 11),
                        ),
                        leading: const Icon(Icons.lock_reset_rounded, color: Colors.redAccent),
                        onTap: () {
                          _showResetConfirmDialog(context);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  void _showResetConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Reset Pengunci Vault?'),
          content: const Text(
            'Tindakan ini akan menghapus PIN dan autentikasi sidik jari untuk Ruang Privat Anda. '
            'Habit privat Anda akan tetap ada tetapi Anda perlu menyetel PIN baru untuk membukanya kembali.',
          ),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Reset'),
              onPressed: () {
                ref.read(vaultSecurityProvider.notifier).clearVaultSecurity();
                Navigator.of(ctx).pop();
                context.go('/home');
              },
            ),
          ],
        );
      },
    );
  }
}
