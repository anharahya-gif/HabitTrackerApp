import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum BreathingPhase {
  inhale, // Tarik
  holdIn,  // Tahan (setelah tarik)
  exhale, // Hembus
  holdOut, // Tahan (setelah hembus)
}

class VaultSosPage extends ConsumerStatefulWidget {
  const VaultSosPage({super.key});

  @override
  ConsumerState<VaultSosPage> createState() => _VaultSosPageState();
}

class _VaultSosPageState extends ConsumerState<VaultSosPage> with TickerProviderStateMixin {
  static const List<String> _affirmations = [
    'Ingatlah mengapa Anda memulai. Rasa sesal setelah menyerah jauh lebih menyakitkan daripada rasa lelah saat bertahan.',
    'Disiplin adalah memilih antara apa yang Anda inginkan saat ini dan apa yang paling Anda impikan di masa depan.',
    'Setiap kali Anda menolak dorongan itu, Anda sedang membangun kembali sirkuit otak Anda menjadi lebih kuat.',
    'Kebebasan sejati bukanlah menuruti semua hasrat kita, melainkan kemampuan mutlak untuk mengendalikan diri sendiri.',
    'Satu keputusan kecil saat ini menentukan arah hidup Anda di masa depan. Pilih pertarungan ini, menangkan hari ini.',
    'Hasrat itu seperti ombak. Ia akan datang, memuncak, lalu mereda. Anda hanya perlu berdiri kokoh saat ombak itu lewat.',
    'Anda tidak kehilangan apa pun ketika menolak PMO. Anda sedang mendapatkan kembali kendali atas hidup Anda sendiri.',
    'Kekuatan tidak berasal dari kemampuan fisik, tetapi dari kemauan yang tidak tergoyahkan.',
    'Setiap detik Anda bertahan dalam ketenangan adalah kemenangan besar bagi masa depan Anda.',
    'Tenangkan pikiran Anda. Tarik napas perlahan. Hari ini Anda berkuasa penuh atas tindakan Anda sendiri.'
  ];

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  BreathingPhase _currentPhase = BreathingPhase.inhale;
  int _secondsRemaining = 4;
  int _cycleCount = 0;
  Timer? _timer;
  String _currentAffirmation = '';

  String _getRandomAffirmation() {
    final random = DateTime.now().millisecond % _affirmations.length;
    return _affirmations[random];
  }

  void _refreshAffirmation() {
    setState(() {
      String next;
      do {
        next = _getRandomAffirmation();
      } while (next == _currentAffirmation && _affirmations.length > 1);
      _currentAffirmation = next;
    });
  }

  @override
  void initState() {
    super.initState();
    _currentAffirmation = _getRandomAffirmation();
    
    // Scale animation for breathing (4 seconds for inhale/exhale)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _scaleAnimation = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Subtle pulsing animation during hold phase
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Start with Inhale
    _animationController.forward();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 1) {
          _secondsRemaining--;
        } else {
          _secondsRemaining = 4;
          _advancePhase();
        }
      });
    });
  }

  void _advancePhase() {
    switch (_currentPhase) {
      case BreathingPhase.inhale:
        _currentPhase = BreathingPhase.holdIn;
        // Keep circle expanded
        break;
      case BreathingPhase.holdIn:
        _currentPhase = BreathingPhase.exhale;
        _animationController.reverse();
        break;
      case BreathingPhase.exhale:
        _currentPhase = BreathingPhase.holdOut;
        // Keep circle small
        break;
      case BreathingPhase.holdOut:
        _currentPhase = BreathingPhase.inhale;
        _animationController.forward();
        _cycleCount++;
        break;
    }
  }

  String _getPhaseTitle() {
    switch (_currentPhase) {
      case BreathingPhase.inhale:
        return 'TARIK NAPAS';
      case BreathingPhase.holdIn:
        return 'TAHAN NAPAS';
      case BreathingPhase.exhale:
        return 'HEMBUSKAN';
      case BreathingPhase.holdOut:
        return 'TAHAN NAPAS';
    }
  }

  String _getPhaseDescription() {
    switch (_currentPhase) {
      case BreathingPhase.inhale:
        return 'Tarik napas perlahan lewat hidung...';
      case BreathingPhase.holdIn:
        return 'Tahan napas Anda, rasakan kedamaian...';
      case BreathingPhase.exhale:
        return 'Keluarkan napas perlahan lewat mulut...';
      case BreathingPhase.holdOut:
        return 'Tahan paru-paru Anda dalam kondisi kosong...';
    }
  }

  Color _getPhaseColor() {
    switch (_currentPhase) {
      case BreathingPhase.inhale:
        return const Color(0xffb388ff); // Lavender purple
      case BreathingPhase.holdIn:
        return const Color(0xff64ffda); // Teal-green calming
      case BreathingPhase.exhale:
        return const Color(0xff82b1ff); // Calming blue
      case BreathingPhase.holdOut:
        return const Color(0xffff8a80); // Soft orange-red
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final bgColor = isDark ? const Color(0xff0b0711) : const Color(0xfff3eef9);
    final accentColor = _getPhaseColor();

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background soft ambient light matching the phase
          AnimatedPositioned(
            duration: const Duration(seconds: 2),
            top: MediaQuery.of(context).size.height / 2 - 170,
            left: MediaQuery.of(context).size.width / 2 - 170,
            child: AnimatedContainer(
              duration: const Duration(seconds: 2),
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withOpacity(0.08),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // Main layout
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Exit Icon
                Padding(
                  padding: const EdgeInsets.only(top: 12.0, left: 16.0, right: 16.0),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: Icon(Icons.close_rounded, size: 28, color: isDark ? Colors.white60 : Colors.black54),
                      onPressed: () => context.pop(),
                    ),
                  ),
                ),

                // Core Breathing Circle & Text
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Phase description
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: Column(
                          key: ValueKey<BreathingPhase>(_currentPhase),
                          children: [
                            Text(
                              _getPhaseTitle(),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.5,
                                color: accentColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getPhaseDescription(),
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white60 : Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),

                      // Animated Breathing Circle
                      AnimatedBuilder(
                        animation: Listenable.merge([_scaleAnimation, _pulseAnimation]),
                        builder: (context, child) {
                          // Combine scale animation and hold-in pulsing effect
                          double finalScale = _scaleAnimation.value;
                          if (_currentPhase == BreathingPhase.holdIn) {
                            finalScale *= _pulseAnimation.value;
                          }
                          
                          return Container(
                            width: 260 * finalScale,
                            height: 260 * finalScale,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  accentColor.withOpacity(0.4),
                                  accentColor.withOpacity(0.05),
                                ],
                              ),
                              border: Border.all(
                                color: accentColor.withOpacity(0.4),
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.25),
                                  blurRadius: 32 * finalScale,
                                  spreadRadius: 2 * finalScale,
                                ),
                              ],
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 140 * finalScale,
                              height: 140 * finalScale,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? const Color(0xff191325) : Colors.white,
                                border: Border.all(
                                  color: accentColor.withOpacity(0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                '$_secondsRemaining',
                                style: TextStyle(
                                  fontSize: 48 * finalScale,
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Affirmation / Contemplation Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: accentColor.withOpacity(0.15),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.format_quote_rounded,
                                color: accentColor.withOpacity(0.5),
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _currentAffirmation,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    height: 1.5,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(Icons.refresh_rounded, size: 20, color: accentColor),
                                tooltip: 'Ganti Motivasi',
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                onPressed: _refreshAffirmation,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Cycle count indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),
                        ),
                        child: Text(
                          'Siklus Selesai: $_cycleCount',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom CTA Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 40.0, left: 32.0, right: 32.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xff221735) : Colors.white,
                        foregroundColor: isDark ? const Color(0xffb388ff) : Colors.deepPurple,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: (isDark ? const Color(0xffb388ff) : Colors.deepPurple).withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.favorite_rounded),
                      label: const Text(
                        'Saya Sudah Tenang / Keluar',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        context.pop();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
