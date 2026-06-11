import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_theme.dart';
import '../controllers/focus_timer_controller.dart';

class FocusTimerPage extends ConsumerWidget {
  const FocusTimerPage({super.key});

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(focusTimerProvider);
    final timerNotifier = ref.read(focusTimerProvider.notifier);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    final progress = timerState.totalSeconds > 0
        ? timerState.remainingSeconds / timerState.totalSeconds
        : 1.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        if (timerState.isRunning) {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Keluar dari Mode Fokus?'),
              content: const Text('Timer fokus Anda masih berjalan. Keluar akan membatalkan sesi fokus ini.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () {
                    timerNotifier.stopTimer();
                    Navigator.pop(context, true);
                  },
                  child: Text(
                    'Keluar',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ],
            ),
          );
          if (shouldExit == true && context.mounted) {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          }
        } else {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        }
      },
      child: Theme(
        data: theme.copyWith(
          scaffoldBackgroundColor: const Color(0xff0b0d12), // Extra deep immersive dark
        ),
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70),
              onPressed: () => Navigator.maybePop(context),
            ),
          title: const Text(
            'Mode Fokus',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. Linked Habit Indicator
                Column(
                  children: [
                    if (timerState.habitName != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.spa_rounded, color: theme.colorScheme.primary, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              timerState.habitName!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Menjaga konsistensi kebiasaan Anda',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ] else ...[
                      const Text(
                        'Waktu untuk fokus penuh',
                        style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Jauhkan HP Anda dan mulailah produktif',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ]
                  ],
                ),

                // 2. Circular Timer Indicator
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer circular glow
                      Container(
                        width: screenWidth * 0.7 + 24,
                        height: screenWidth * 0.7 + 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.04),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      // Custom painter for countdown ring
                      SizedBox(
                        width: screenWidth * 0.7,
                        height: screenWidth * 0.7,
                        child: CustomPaint(
                          painter: _TimerPainter(
                            progress: progress,
                            primaryColor: theme.colorScheme.primary,
                            backgroundColor: Colors.white.withOpacity(0.04),
                          ),
                        ),
                      ),
                      // Text in the middle
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(timerState.remainingSeconds),
                            style: const TextStyle(
                              fontSize: 54,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timerState.isPaused
                                ? 'JEDA'
                                : (timerState.isRunning ? 'FOKUS' : 'SIAP'),
                            style: TextStyle(
                              fontSize: 12,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w900,
                              color: timerState.isPaused
                                  ? Colors.amber
                                  : (timerState.isRunning ? theme.colorScheme.primary : Colors.white38),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. Bottom controls
                Column(
                  children: [
                    // Duration selector chips (Only visible when NOT running)
                    if (!timerState.isRunning) ...[
                      const Text(
                        'Pilih Durasi Fokus',
                        style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [15, 25, 45, 60].map((min) {
                          final isCurrent = timerState.totalSeconds == min * 60;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ChoiceChip(
                              label: Text('$min Min'),
                              selected: isCurrent,
                              selectedColor: theme.colorScheme.primary,
                              backgroundColor: Colors.transparent,
                              labelStyle: TextStyle(
                                color: isCurrent ? Colors.white : Colors.white70,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: isCurrent ? Colors.transparent : Colors.white.withOpacity(0.1),
                                ),
                              ),
                              onSelected: (_) {
                                timerNotifier.setDuration(min);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Main Control Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!timerState.isRunning) ...[
                          // Start Timer
                          ElevatedButton.icon(
                            onPressed: () => timerNotifier.startTimer(),
                            icon: const Icon(Icons.play_arrow_rounded, size: 24),
                            label: const Text('Mulai Sesi'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ] else ...[
                          // Reset / Stop
                          IconButton(
                            icon: const Icon(Icons.stop_rounded, color: Colors.white70),
                            iconSize: 28,
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Hentikan Sesi Fokus?'),
                                  content: const Text('Apakah Anda yakin ingin menghentikan sesi fokus ini? Kemajuan Anda tidak akan disimpan.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Batal'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        timerNotifier.stopTimer();
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        'Hentikan',
                                        style: TextStyle(color: theme.colorScheme.error),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.06),
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                          const SizedBox(width: 32),

                          // Play / Pause Toggle
                          ElevatedButton(
                            onPressed: timerState.isPaused
                                ? () => timerNotifier.resumeTimer()
                                : () => timerNotifier.pauseTimer(),
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(24),
                              backgroundColor: timerState.isPaused ? Colors.amber : theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: Icon(
                              timerState.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                              size: 32,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class _TimerPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color backgroundColor;

  _TimerPainter({
    required this.progress,
    required this.primaryColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    const strokeWidth = 12.0;

    // Draw background track arc
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // Draw active progress countdown arc
    final activePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -pi / 2, // Start at 12 o'clock
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
