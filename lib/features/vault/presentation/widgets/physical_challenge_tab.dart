import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _Challenge {
  final String emoji;
  final String title;
  final String description;
  final int durationSeconds;

  const _Challenge({
    required this.emoji,
    required this.title,
    required this.description,
    this.durationSeconds = 120,
  });
}

enum ChallengeState { idle, active, completed }

class PhysicalChallengeTab extends StatefulWidget {
  final bool isDark;

  const PhysicalChallengeTab({super.key, required this.isDark});

  @override
  State<PhysicalChallengeTab> createState() => _PhysicalChallengeTabState();
}

class _PhysicalChallengeTabState extends State<PhysicalChallengeTab>
    with SingleTickerProviderStateMixin {
  static const List<_Challenge> _challenges = [
    _Challenge(
      emoji: '💪',
      title: '20 Push-up',
      description: 'Turun ke lantai dan lakukan 20 push-up sekarang! Fokus pada setiap gerakan.',
    ),
    _Challenge(
      emoji: '🧊',
      title: 'Mandi Air Dingin',
      description: 'Pergi ke kamar mandi dan siram tubuh Anda dengan air dingin. Shock therapy terbaik!',
    ),
    _Challenge(
      emoji: '🏃',
      title: 'Lari di Tempat 1 Menit',
      description: 'Berdiri dan lari di tempat secepat mungkin! Angkat lutut tinggi-tinggi.',
      durationSeconds: 60,
    ),
    _Challenge(
      emoji: '🧘',
      title: 'Plank 1 Menit',
      description: 'Ambil posisi plank dan tahan selama 1 menit. Rasakan kekuatan inti Anda!',
      durationSeconds: 60,
    ),
    _Challenge(
      emoji: '⭐',
      title: '30 Jumping Jack',
      description: 'Lakukan 30 jumping jack dengan semangat! Gerakkan seluruh tubuh Anda.',
    ),
    _Challenge(
      emoji: '🔥',
      title: '20 Sit-up',
      description: 'Berbaring dan lakukan 20 sit-up. Fokus pada kontraksi otot perut.',
    ),
    _Challenge(
      emoji: '🚶',
      title: 'Jalan Kaki 5 Menit',
      description: 'Keluar dan berjalan kaki selama 5 menit. Hirup udara segar dan bersihkan pikiran.',
      durationSeconds: 300,
    ),
    _Challenge(
      emoji: '🦵',
      title: '20 Squat',
      description: 'Lakukan 20 squat dengan postur yang benar. Turun hingga paha sejajar lantai.',
    ),
    _Challenge(
      emoji: '🙆',
      title: 'Stretching 2 Menit',
      description: 'Regangkan seluruh tubuh Anda selama 2 menit. Sentuh jari kaki, putar bahu.',
    ),
    _Challenge(
      emoji: '💦',
      title: 'Cuci Muka dengan Air Dingin',
      description: 'Sprint ke kamar mandi dan basuh muka Anda dengan air dingin sebanyak 10 kali!',
      durationSeconds: 60,
    ),
    _Challenge(
      emoji: '🫁',
      title: 'Tahan Napas 30 Detik',
      description: 'Tarik napas dalam-dalam dan tahan selama 30 detik. Ulangi 3 kali.',
      durationSeconds: 90,
    ),
    _Challenge(
      emoji: '✊',
      title: '15 Burpee',
      description: 'Tantangan ultimate! Lakukan 15 burpee tanpa henti. Anda lebih kuat dari hasrat itu!',
    ),
  ];

  ChallengeState _state = ChallengeState.idle;
  _Challenge? _currentChallenge;
  int _secondsRemaining = 0;
  Timer? _timer;
  late AnimationController _celebrationController;
  late Animation<double> _celebrationAnimation;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _celebrationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _celebrationController.dispose();
    super.dispose();
  }

  void _rollChallenge() {
    HapticFeedback.mediumImpact();
    final challenge = _challenges[_random.nextInt(_challenges.length)];
    setState(() {
      _currentChallenge = challenge;
      _state = ChallengeState.active;
      _secondsRemaining = challenge.durationSeconds;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _completeChallenge();
        }
      });
    });
  }

  void _completeChallenge() {
    _timer?.cancel();
    HapticFeedback.heavyImpact();
    setState(() {
      _state = ChallengeState.completed;
    });
    _celebrationController.forward(from: 0);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _state = ChallengeState.idle;
      _currentChallenge = null;
      _secondsRemaining = 0;
    });
  }

  String _formatTime(int totalSeconds) {
    final min = totalSeconds ~/ 60;
    final sec = totalSeconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    const accentOrange = Color(0xffffab40);
    const accentPurple = Color(0xffb388ff);

    switch (_state) {
      case ChallengeState.idle:
        return _buildIdleView(isDark, accentOrange, accentPurple);
      case ChallengeState.active:
        return _buildActiveView(isDark, accentOrange);
      case ChallengeState.completed:
        return _buildCompletedView(isDark, accentPurple);
    }
  }

  // ─── Idle: Roll Challenge ──────────────────────────────────────────────────

  Widget _buildIdleView(bool isDark, Color accentOrange, Color accentPurple) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accentOrange.withValues(alpha: 0.2),
                    accentPurple.withValues(alpha: 0.15),
                  ],
                ),
                border: Border.all(
                  color: accentOrange.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Text('🎲', style: TextStyle(fontSize: 44)),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Tantangan Fisik',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Pindahkan energi hasrat ke aktivitas fisik. Tekan tombol di bawah untuk mendapat tantangan acak!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),
            // Roll button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _rollChallenge,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentOrange,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🎲', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 12),
                    Text(
                      'ACAK TANTANGAN',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Active: Timer Running ─────────────────────────────────────────────────

  Widget _buildActiveView(bool isDark, Color accentOrange) {
    final challenge = _currentChallenge!;
    final totalDuration = challenge.durationSeconds;
    final progress = totalDuration > 0
        ? (totalDuration - _secondsRemaining) / totalDuration
        : 1.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Challenge emoji
          Text(challenge.emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          // Title
          Text(
            challenge.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          // Description
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accentOrange.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              challenge.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Circular Timer
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 8,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                // Progress circle
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    color: accentOrange,
                  ),
                ),
                // Timer text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(_secondsRemaining),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'tersisa',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _reset,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                  ),
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _completeChallenge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentOrange,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '✅ SELESAI!',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Completed: Celebration ────────────────────────────────────────────────

  Widget _buildCompletedView(bool isDark, Color accentPurple) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: AnimatedBuilder(
          animation: _celebrationAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.5 + (_celebrationAnimation.value * 0.5),
              child: Opacity(
                opacity: _celebrationAnimation.value.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 20),
              Text(
                'LUAR BIASA!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Anda berhasil menyelesaikan tantangan!\nHasrat itu sudah lewat. Anda yang berkuasa.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.black54,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 36),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _reset,
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        size: 18,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      label: Text(
                        'Kembali',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _rollChallenge,
                      icon: const Text('🎲', style: TextStyle(fontSize: 18)),
                      label: const Text(
                        'Acak Lagi',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
