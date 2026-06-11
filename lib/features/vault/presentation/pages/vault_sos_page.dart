import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/urge_form_sheet.dart';
import '../widgets/physical_challenge_tab.dart';
import '../widgets/bubble_popper_tab.dart';
import '../../domain/entities/urge_log.dart';
import '../controllers/urge_log_controller.dart';
import '../../../../shared/providers/vault_provider.dart';

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
  int _pieTouchedIndex = -1;

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
        break;
      case BreathingPhase.holdIn:
        _currentPhase = BreathingPhase.exhale;
        _animationController.reverse();
        break;
      case BreathingPhase.exhale:
        _currentPhase = BreathingPhase.holdOut;
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

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'stres':
        return const Color(0xffef5350); // Red
      case 'bosan':
        return const Color(0xffab47bc); // Purple
      case 'sepi':
        return const Color(0xff42a5f5); // Blue
      case 'lelah':
        return const Color(0xffffa726); // Orange
      case 'sosmed':
        return const Color(0xff26a69a); // Teal
      default:
        return const Color(0xff78909c); // Slate grey
    }
  }

  String _getEmotionEmoji(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'stres':
        return '😫';
      case 'bosan':
        return '🥱';
      case 'sepi':
        return '😔';
      case 'lelah':
        return '😴';
      case 'sosmed':
        return '📱';
      default:
        return '❓';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final bgColor = isDark ? const Color(0xff0b0711) : const Color(0xfff3eef9);
    final cardColor = isDark ? const Color(0xff181424) : Colors.white;
    final accentColor = _getPhaseColor();
    final accentPurple = const Color(0xffb388ff);
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white60 : Colors.black54;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
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
                  color: accentColor.withOpacity(0.06),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 95, sigmaY: 95),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),

            // Main layout
            SafeArea(
              child: Column(
                children: [
                  // 1. Top Action Bar
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 20.0, right: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shield_outlined, color: accentPurple),
                            const SizedBox(width: 8),
                            Text(
                              'SOS Rescue Hub',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, size: 28, color: isDark ? Colors.white60 : Colors.black54),
                          onPressed: () => context.pop(),
                        ),
                      ],
                    ),
                  ),

                  // 2. Custom Sliding Segmented TabBar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    child: TabBar(
                      isScrollable: false,
                      tabs: const [
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.spa_rounded, size: 16),
                              SizedBox(width: 5),
                              Text('Napas'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.fitness_center_rounded, size: 16),
                              SizedBox(width: 5),
                              Text('Tantangan'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bubble_chart_rounded, size: 16),
                              SizedBox(width: 5),
                              Text('Bubble'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.analytics_rounded, size: 16),
                              SizedBox(width: 5),
                              Text('Analisis'),
                            ],
                          ),
                        ),
                      ],
                      indicator: BoxDecoration(
                        color: isDark ? const Color(0xff2c1b4d) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xffb388ff).withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: const Color(0xffb388ff),
                      unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ),

                  // 3. Tab Views
                  Expanded(
                    child: TabBarView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // Tab 1: Breathing Exercise
                        _buildBreathingTab(isDark, accentColor, bgColor),
                        // Tab 2: Physical Challenge
                        PhysicalChallengeTab(isDark: isDark),
                        // Tab 3: Bubble Popper
                        BubblePopperTab(isDark: isDark),
                        // Tab 4: Trigger Analytics
                        _buildAnalyticsTab(isDark, cardColor, accentPurple, textPrimary, textSecondary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreathingTab(bool isDark, Color accentColor, Color bgColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
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

        // Bottom CTA Buttons
        Padding(
          padding: const EdgeInsets.only(bottom: 24.0, left: 20.0, right: 20.0),
          child: Row(
            children: [
              // Catat Pemicu Button
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2c1b4d),
                      foregroundColor: const Color(0xffb388ff),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: const Color(0xffb388ff).withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.bolt_rounded, color: Colors.amberAccent),
                    label: const Text(
                      'Catat Urge',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const UrgeFormSheet(),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Keluar Button
              Expanded(
                child: SizedBox(
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
                      'Sudah Tenang',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
    );
  }

  Widget _buildAnalyticsTab(
    bool isDark,
    Color cardColor,
    Color accentPurple,
    Color textPrimary,
    Color textSecondary,
  ) {
    final urgeLogsAsync = ref.watch(urgeLogProvider);
    final theme = Theme.of(context);

    return urgeLogsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Gagal memuat analisis: $err')),
      data: (logs) {
        if (logs.isEmpty) {
          return _buildEmptyState(theme, isDark, accentPurple);
        }

        // 1. Hitung Rata-rata tingkat urge
        double avgSeverity = 0;
        if (logs.isNotEmpty) {
          final sum = logs.map((l) => l.severity).reduce((a, b) => a + b);
          avgSeverity = sum / logs.length;
        }

        // 2. Hitung Distribusi Emosi Pemicu
        final Map<String, int> emotionCounts = {};
        for (final log in logs) {
          final key = log.triggerEmotion;
          emotionCounts[key] = (emotionCounts[key] ?? 0) + 1;
        }

        // 3. Hitung Waktu Rawan per Jam (24 jam)
        final List<int> hourlyCounts = List.filled(24, 0);
        for (final log in logs) {
          try {
            final hour = int.parse(log.time.split(':')[0]);
            if (hour >= 0 && hour < 24) {
              hourlyCounts[hour]++;
            }
          } catch (_) {}
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          physics: const BouncingScrollPhysics(),
          children: [
            // A. METRIC CARD: AVERAGE SEVERITY
            _buildSeverityMetricCard(avgSeverity, logs.length, cardColor, textPrimary, textSecondary, accentPurple),
            const SizedBox(height: 20),

            // B. CHART: TRIGGER EMOTIONS (DONUT CHART)
            _buildTriggerDistributionChart(emotionCounts, logs.length, cardColor, textPrimary, textSecondary, isDark),
            const SizedBox(height: 20),

            // C. CHART: DANGER ZONE BY HOUR (LINE CHART)
            _buildDangerZoneLineChart(hourlyCounts, cardColor, textPrimary, textSecondary, accentPurple, isDark),
            const SizedBox(height: 24),

            // D. HISTORY LIST
            Row(
              children: [
                Icon(Icons.history_rounded, color: accentPurple, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Riwayat Catatan Hasrat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...logs.map((log) => _buildHistoryItem(log, cardColor, textPrimary, textSecondary, isDark)),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark, Color accentPurple) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: accentPurple.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.analytics_outlined, size: 72, color: accentPurple.withOpacity(0.8)),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum Ada Data Analisis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Anda belum mencatat dorongan hasrat (urge) sama sekali. '
              'Gunakan tombol "Catat Urge" di bagian bawah tab Latihan Napas untuk merekam pemicu pertama Anda.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white38 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityMetricCard(
    double avg,
    int total,
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
    Color accentPurple,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentPurple.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tingkat Keparahan Rata-rata',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSecondary),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      avg.toStringAsFixed(1),
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: textPrimary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/ 5.0',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Berdasarkan total $total laporan pemicu.',
                  style: TextStyle(fontSize: 11, color: textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.orange,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriggerDistributionChart(
    Map<String, int> counts,
    int total,
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    final List<PieChartSectionData> sections = [];
    final List<Widget> legendItems = [];
    int index = 0;

    counts.forEach((emotion, count) {
      final isTouched = index == _pieTouchedIndex;
      final double radius = isTouched ? 22.0 : 16.0;
      final double percentage = (count / total) * 100;
      final color = _getEmotionColor(emotion);
      final emoji = _getEmotionEmoji(emotion);

      sections.add(
        PieChartSectionData(
          color: color,
          value: count.toDouble(),
          title: isTouched ? '${percentage.toStringAsFixed(0)}%' : '',
          radius: radius,
          titleStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );

      legendItems.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$emoji $emotion ($count)',
                style: TextStyle(
                  fontSize: 12,
                  color: textPrimary,
                  fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );

      index++;
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: textSecondary.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pemicu Terbesar Saya',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          Text(
            'Persentase emosi utama yang memicu urge',
            style: TextStyle(fontSize: 11, color: textSecondary),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  _pieTouchedIndex = -1;
                                  return;
                                }
                                _pieTouchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 3,
                          centerSpaceRadius: 36,
                          sections: sections,
                        ),
                      ),
                      Icon(
                        Icons.psychology_rounded,
                        color: textSecondary.withOpacity(0.4),
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: legendItems,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZoneLineChart(
    List<int> hourlyCounts,
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
    Color accentPurple,
    bool isDark,
  ) {
    final List<FlSpot> spots = [];
    int maxCount = 1;
    for (int h = 0; h < 24; h++) {
      final val = hourlyCounts[h];
      spots.add(FlSpot(h.toDouble(), val.toDouble()));
      if (val > maxCount) {
        maxCount = val;
      }
    }

    final double yInterval = (maxCount / 4).ceilToDouble().clamp(1.0, 5.0);
    final double maxYVal = ((maxCount / yInterval).ceil() * yInterval).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: textSecondary.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Waktu Rawan (24 Jam)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          Text(
            'Jam terjadinya hasrat dalam periode waktu 24 jam',
            style: TextStyle(fontSize: 11, color: textSecondary),
          ),
          const SizedBox(height: 28),
          AspectRatio(
            aspectRatio: 1.8,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => isDark
                        ? const Color(0xff221b2d).withOpacity(0.9)
                        : Colors.white.withOpacity(0.9),
                    tooltipBorder: BorderSide(
                      color: accentPurple.withOpacity(0.3),
                      width: 1,
                    ),
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((barSpot) {
                        final hour = barSpot.x.toInt();
                        final count = barSpot.y.toInt();
                        final hourLabel = hour < 10 ? '0$hour:00' : '$hour:00';
                        return LineTooltipItem(
                          'Pukul $hourLabel\n',
                          TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 11),
                          children: [
                            TextSpan(
                              text: '$count Kejadian',
                              style: TextStyle(
                                color: accentPurple,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: yInterval,
                  verticalInterval: 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: yInterval,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: TextStyle(
                            color: textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      interval: 6,
                      getTitlesWidget: (value, meta) {
                        final valInt = value.toInt();
                        if (valInt < 0 || valInt > 23) return const SizedBox.shrink();
                        final label = valInt < 10 ? '0$valInt:00' : '$valInt:00';
                        return Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 23,
                minY: 0,
                maxY: maxYVal,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xffa586e0), Color(0xffffa726)],
                    ),
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xffa586e0).withOpacity(0.2),
                          const Color(0xffa586e0).withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    UrgeLog log,
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    final emoji = _getEmotionEmoji(log.triggerEmotion);
    final borderCol = _getEmotionColor(log.triggerEmotion).withOpacity(0.15);

    String formattedDate = log.date;
    try {
      final dt = DateTime.parse(log.date);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      formattedDate = '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {}

    return Card(
      color: cardColor,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderCol, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '$emoji ${log.triggerEmotion}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_fire_department_rounded, size: 12, color: Colors.orange),
                          Text(
                            ' ${log.severity}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '$formattedDate • ${log.time}',
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onPressed: () => _showDeleteConfirm(context, log.id),
                    ),
                  ],
                ),
              ],
            ),
            if (log.notes != null) ...[
              const SizedBox(height: 8),
              Text(
                log.notes!,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.white70 : Colors.black87,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Hapus Catatan Pemicu?'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus catatan pemicu/hasrat ini secara permanen dari riwayat?',
          ),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Hapus'),
              onPressed: () {
                ref.read(urgeLogProvider.notifier).removeUrgeLog(id);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
