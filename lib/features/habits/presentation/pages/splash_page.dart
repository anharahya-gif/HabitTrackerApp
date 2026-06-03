import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/notification_service.dart';
import '../../../../shared/theme/app_theme.dart';

/// Halaman Splash Screen yang ditampilkan pertama kali saat aplikasi dibuka.
/// Menampilkan Logo Dailio, Nama, Tagline, dan animasi halus.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Jika ada alarm tertunda dari launch payload, langsung arahkan ke Alarm Screen
    if (NotificationService.pendingAlarmHabitId != null) {
      final habitId = NotificationService.pendingAlarmHabitId!;
      NotificationService.pendingAlarmHabitId = null; // reset
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/alarm/$habitId');
        }
      });
      return;
    }

    // Inisialisasi animasi masuk (fade & scale)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    // Jalankan animasi
    _animationController.forward();

    // Navigasi ke halaman utama setelah delay 2.5 detik
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        context.go('/home');
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff111318), // Warna background Calm Productivity Dark
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background soft gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    const Color(0xff222632).withOpacity(0.4),
                    const Color(0xff111318),
                  ],
                ),
              ),
            ),
          ),
          
          // Konten Tengah
          Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo Dailio dengan Frame Halus
                        Container(
                          width: 120,
                          height: 120,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xff1a1d24),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: AppTheme.accentPrimary.withOpacity(0.12),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentPrimary.withOpacity(0.06),
                                blurRadius: 24,
                                spreadRadius: 4,
                              )
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/images/Logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback jika logo belum terbaca/belum ada
                                return const Icon(
                                  Icons.spa,
                                  size: 64,
                                  color: AppTheme.statusDone,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Nama Aplikasi
                        const Text(
                          'Dailio',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.8,
                            color: Color(0xffe2e8f0),
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Tagline Utama
                        const Text(
                          'Small Steps, Every Day.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xff94a3b8),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Teks Bawah / Filosofi Pendukung
          Positioned(
            bottom: 48,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: const Column(
                    children: [
                      Text(
                        'Grow Through Consistency.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.statusDone,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.statusDone),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
