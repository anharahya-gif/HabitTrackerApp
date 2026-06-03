import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/notification_service.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../tracking/presentation/controllers/tracking_controller.dart';
import '../controllers/habit_detail_controller.dart';

/// Halaman Alarm khusus yang ditampilkan di atas lockscreen atau saat aplikasi terbuka.
/// Menyajikan informasi habit, jam besar, dan tombol Snooze/Dismiss yang premium.
class AlarmScreen extends ConsumerStatefulWidget {
  final String habitId;

  const AlarmScreen({super.key, required this.habitId});

  @override
  ConsumerState<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends ConsumerState<AlarmScreen> with SingleTickerProviderStateMixin {
  late DateTime _currentTime;
  late Timer _clockTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    
    // Update jam digital setiap detik
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    // Inisialisasi animasi denyut nadi lingkaran bercahaya di latar belakang
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatTwoDigits(int number) => number.toString().padLeft(2, '0');

  Future<void> _handleDismiss(WidgetRef ref, String habitId) async {
    // 1. Matikan alarm yang sedang berdering
    await NotificationService.stopAlarm(habitId);

    // 2. Tandai habit sebagai Selesai (done) untuk hari ini
    final dateStr = DateTime.now().toIso8601String().split('T')[0];
    await ref.read(trackingProvider.notifier).trackHabit(
      habitId: habitId,
      date: dateStr,
      status: 'done',
    );

    // 3. Kembali ke halaman Dashboard utama
    if (mounted) {
      context.go('/home');
    }
  }

  Future<void> _handleSnooze(WidgetRef ref, dynamic habit) async {
    // 1. Matikan alarm yang sedang berdering
    await NotificationService.stopAlarm(habit.id);

    // 2. Jadwalkan ulang alarm tunda untuk 10 menit ke depan
    await NotificationService.scheduleSnooze(habit, 10);

    // 3. Kembali ke halaman Dashboard utama
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(habitDetailProvider(widget.habitId));

    final timeStr = '${_formatTwoDigits(_currentTime.hour)}:${_formatTwoDigits(_currentTime.minute)}';
    final secondsStr = _formatTwoDigits(_currentTime.second);

    return PopScope(
      canPop: false, // Mencegah user membatalkan layar dengan tombol Back
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0D11), // Hitam pekat agar kontras di malam hari
        body: detailAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.accentPrimary),
          ),
          error: (err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppTheme.statusMissed, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Gagal memuat detail alarm: $err',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    NotificationService.stopAlarm(widget.habitId);
                    context.go('/home');
                  },
                  child: const Text('Kembali ke Beranda'),
                ),
              ],
            ),
          ),
          data: (state) {
            final habit = state.habit;
            final Color accentColor = Color(habit.color);

            return Stack(
              alignment: Alignment.center,
              children: [
                // 1. Background Pulsing Glow Effect
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Positioned(
                      top: MediaQuery.of(context).size.height * 0.15,
                      child: Container(
                        width: 280 * _pulseAnimation.value,
                        height: 280 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              accentColor.withOpacity(0.24),
                              accentColor.withOpacity(0.08),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // 2. Main Content Layout
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Bagian Atas: Alarm Header & Icon
                        Column(
                          children: [
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: accentColor.withOpacity(0.2), width: 1.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.alarm_on_rounded, color: accentColor, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ALARM PENGINGAT',
                                    style: TextStyle(
                                      color: accentColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Bagian Tengah: Digital Clock & Habit Title
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tampilan Waktu
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  timeStr,
                                  style: const TextStyle(
                                    fontSize: 84,
                                    fontWeight: FontWeight.w200,
                                    color: Colors.white,
                                    letterSpacing: -2.0,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  secondsStr,
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white.withOpacity(0.4),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Glassmorphism Card Info Habit
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF161A22).withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.08),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        habit.name,
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: -0.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: accentColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            habit.category,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.6),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (habit.description != null && habit.description!.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          habit.description!,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.4),
                                            fontSize: 13,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Bagian Bawah: Tombol Aksi
                        Column(
                          children: [
                            // Tombol Selesaikan (Dismiss)
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton(
                                onPressed: () => _handleDismiss(ref, habit.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.statusDone,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 8,
                                  shadowColor: AppTheme.statusDone.withOpacity(0.4),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_rounded, size: 24),
                                    SizedBox(width: 10),
                                    Text(
                                      'Selesai & Matikan',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Tombol Tunda (Snooze)
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton(
                                onPressed: () => _handleSnooze(ref, habit),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.snooze_rounded, size: 22, color: AppTheme.statusSkipped),
                                    SizedBox(width: 8),
                                    Text(
                                      'Tunda 10 Menit',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
