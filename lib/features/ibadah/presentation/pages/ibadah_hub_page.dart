import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/collapsible_sidebar.dart';
import '../../domain/entities/ibadah_log.dart';
import '../../domain/entities/prayer_time.dart';
import '../controllers/ibadah_controller.dart';

class IbadahHubPage extends ConsumerStatefulWidget {
  const IbadahHubPage({super.key});

  @override
  ConsumerState<IbadahHubPage> createState() => _IbadahHubPageState();
}

class _IbadahHubPageState extends ConsumerState<IbadahHubPage> {
  Timer? _countdownTimer;
  late DateTime _currentTime;
  String _selectedDhikrPreset = 'Subhanallah';
  int _localTasbihCount = 0;

  final List<String> _dhikrPresets = [
    'Subhanallah',
    'Alhamdulillah',
    'Allahu Akbar',
    'La ilaha illallah',
    'Astaghfirullah',
  ];

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    // Jalankan timer untuk memperbarui countdown setiap 15 detik
    _countdownTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// Mengecek apakah shalat fardhu terkunci berdasarkan waktu sekarang
  bool _isPrayerLocked(String prayerTimeStr, String selectedDateStr) {
    final todayStr = DateFormatter.todayString;
    if (selectedDateStr.compareTo(todayStr) > 0) {
      return true; // Tanggal masa depan -> terkunci semua
    }
    if (selectedDateStr.compareTo(todayStr) < 0) {
      return false; // Tanggal masa lalu -> terbuka agar bisa melengkapi riwayat/qadha
    }

    // Tanggal hari ini -> bandingkan jam-menit
    final timeParts = prayerTimeStr.split(':');
    if (timeParts.length < 2) return false;
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    final prayerDateTime = DateTime(
      _currentTime.year,
      _currentTime.month,
      _currentTime.day,
      hour,
      minute,
    );

    return _currentTime.isBefore(prayerDateTime);
  }

  /// Mendapatkan info shalat aktif, shalat selanjutnya, dan hitung mundur
  Map<String, String> _getNextPrayerInfo(PrayerTime? pt) {
    if (pt == null) {
      return {
        'current': '-',
        'next': 'Menghubungkan...',
        'countdown': '--:--',
      };
    }

    DateTime parseTime(String hhMm, {bool tomorrow = false}) {
      final parts = hhMm.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      var dt = DateTime(
        _currentTime.year,
        _currentTime.month,
        _currentTime.day,
        hour,
        minute,
      );
      if (tomorrow) {
        dt = dt.add(const Duration(days: 1));
      }
      return dt;
    }

    final subuhTime = parseTime(pt.fajr);
    final dzuhurTime = parseTime(pt.dhuhr);
    final asharTime = parseTime(pt.asr);
    final maghribTime = parseTime(pt.maghrib);
    final isyaTime = parseTime(pt.isha);

    String currentPrayer = '-';
    String nextPrayer = 'Subuh';
    DateTime nextTime = parseTime(pt.fajr, tomorrow: true);

    if (_currentTime.isBefore(subuhTime)) {
      currentPrayer = 'Isya (Kemarin)';
      nextPrayer = 'Subuh';
      nextTime = subuhTime;
    } else if (_currentTime.isBefore(dzuhurTime)) {
      currentPrayer = 'Subuh';
      nextPrayer = 'Dzuhur';
      nextTime = dzuhurTime;
    } else if (_currentTime.isBefore(asharTime)) {
      currentPrayer = 'Dzuhur';
      nextPrayer = 'Ashar';
      nextTime = asharTime;
    } else if (_currentTime.isBefore(maghribTime)) {
      currentPrayer = 'Ashar';
      nextPrayer = 'Maghrib';
      nextTime = maghribTime;
    } else if (_currentTime.isBefore(isyaTime)) {
      currentPrayer = 'Maghrib';
      nextPrayer = 'Isya';
      nextTime = isyaTime;
    } else {
      currentPrayer = 'Isya';
      nextPrayer = 'Subuh';
      nextTime = parseTime(pt.fajr, tomorrow: true);
    }

    final diff = nextTime.difference(_currentTime);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;

    String countdownStr = '';
    if (hours > 0) {
      countdownStr += '${hours}j ';
    }
    countdownStr += '${minutes}m';

    return {
      'current': currentPrayer,
      'next': nextPrayer,
      'countdown': countdownStr,
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ibadahControllerProvider);
    final controller = ref.read(ibadahControllerProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Sinkronisasi data tasbih digital lokal
    if (state.ibadahLog != null && _localTasbihCount == 0) {
      _localTasbihCount = state.ibadahLog!.dhikrCount;
    }

    // Variabel warna tema hijau-emas Islami
    const primaryEmerald = Color(0xff0b3b24);
    const accentGold = Color(0xffd4af37);
    const glassColorDark = Color(0xff121814); // Very dark green-tinted black

    final bgColor = isDark ? const Color(0xff070c09) : const Color(0xfff3f6f4);
    final glassColor = isDark
        ? glassColorDark.withValues(alpha: 0.8)
        : Colors.white.withValues(alpha: 0.9);

    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white60 : Colors.black54;

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
      child: Scaffold(
        backgroundColor: bgColor,
        drawer: isMobile ? const CollapsibleSidebar(isDrawer: true) : null,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Ibadah Hub',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          leading: isMobile
              ? Builder(
                  builder: (context) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.black12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.menu_rounded, size: 20),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                  ),
                )
              : null,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: accentGold),
              onPressed: () => _showLocationDialog(context, state.city, controller),
              tooltip: 'Pilih Lokasi',
            ),
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              // Ambient lights latar belakang (Pendaran hijau & emas)
              _buildAmbientLights(isDark),

              // Konten Utama
              Row(
                children: [
                  if (!isMobile) const CollapsibleSidebar(isDrawer: false),
                  Expanded(
                    child: state.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(accentGold),
                            ),
                          )
                        : SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 1. Strip Kalender Horizontal
                                _buildCalendarStrip(state, controller, isDark),
                                const SizedBox(height: 24),

                                // 2. Panel Info Adzan & Countdown
                                _buildCountdownPanel(state, isDark, textPrimary, textSecondary),
                                const SizedBox(height: 24),

                                // 3. Grid Shalat Fardhu
                                _buildSectionTitle('Shalat Fardhu 5 Waktu', textPrimary),
                                const SizedBox(height: 12),
                                _buildPrayerGrid(state, controller, glassColor, textPrimary, textSecondary),
                                const SizedBox(height: 28),

                                // 4. Quran Tracker & Tasbih (Row jika desktop, Column jika mobile)
                                isMobile
                                    ? Column(
                                        children: [
                                          _buildQuranTracker(state, controller, glassColor, textPrimary, textSecondary),
                                          const SizedBox(height: 24),
                                          _buildDhikrTasbih(state, controller, glassColor, textPrimary, textSecondary),
                                        ],
                                      )
                                    : Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: _buildQuranTracker(state, controller, glassColor, textPrimary, textSecondary),
                                          ),
                                          const SizedBox(width: 20),
                                          Expanded(
                                            child: _buildDhikrTasbih(state, controller, glassColor, textPrimary, textSecondary),
                                          ),
                                        ],
                                      ),
                                const SizedBox(height: 28),

                                // 5. Sunnah Checklist
                                _buildSectionTitle('Amalan Sunnah Harian', textPrimary),
                                const SizedBox(height: 12),
                                _buildSunnahChecklist(state, controller, glassColor, textPrimary, textSecondary),
                                const SizedBox(height: 28),

                                // 6. Analisis Ibadah & Heatmap
                                _buildSectionTitle('Statistik & Peta Panas Shalat', textPrimary),
                                const SizedBox(height: 12),
                                _buildAnalyticsSection(state, glassColor, textPrimary, textSecondary),
                                const SizedBox(height: 28),

                                // 7. Achievements / Pencapaian
                                _buildSectionTitle('Pencapaian & Lencana Ibadah 🏆', textPrimary),
                                const SizedBox(height: 12),
                                _buildAchievementsPanel(state, glassColor, textPrimary, textSecondary),
                                const SizedBox(height: 32),
                              ],
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

  // ─── AMBIENT BACKGROUND LIGHTS ─────────────────────────────────────────────

  Widget _buildAmbientLights(bool isDark) {
    if (!isDark) return const SizedBox.shrink();
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1a0b3b24), // Emerald green faint glow
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x0fbb9e3d), // Gold faint glow
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SECTION HEADER TITLE ──────────────────────────────────────────────────

  Widget _buildSectionTitle(String title, Color textColor) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textColor,
        letterSpacing: 0.3,
      ),
    );
  }

  // ─── STRIP KALENDER HORIZONTAL ──────────────────────────────────────────────

  Widget _buildCalendarStrip(IbadahState state, IbadahController controller, bool isDark) {
    final today = DateTime.now();
    final cardBgSelected = const Color(0xff0b3b24);

    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 7,
        itemBuilder: (context, index) {
          // Menampilkan 6 hari ke belakang dan hari ini
          final date = today.subtract(Duration(days: 6 - index));
          final dateStr = DateFormatter.formatDate(date);
          final isSelected = state.selectedDate == dateStr;

          final weekdayName = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'][date.weekday % 7];
          final dayNum = date.day.toString();

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => controller.setSelectedDate(dateStr),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? cardBgSelected
                      : (isDark ? Colors.white12 : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xffd4af37).withValues(alpha: 0.5)
                        : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      weekdayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white60
                            : (isDark ? Colors.white38 : Colors.black38),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dayNum,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── COUNTDOWN ADZAN PANEL ─────────────────────────────────────────────────

  Widget _buildCountdownPanel(IbadahState state, bool isDark, Color textPrimary, Color textSecondary) {
    final pt = state.prayerTime;
    final info = _getNextPrayerInfo(pt);

    const primaryEmerald = Color(0xff0b3b24);
    const accentGold = Color(0xffd4af37);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? primaryEmerald.withValues(alpha: 0.25) : Colors.green.shade50.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentGold.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? primaryEmerald.withValues(alpha: 0.6) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: accentGold.withValues(alpha: 0.5), width: 1.5),
                ),
                child: const Icon(
                  Icons.mosque_rounded,
                  color: accentGold,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shalat Berikutnya',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    info['next'] ?? 'Subuh',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Hitung Mundur',
                style: TextStyle(
                  fontSize: 11,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: accentGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentGold.withValues(alpha: 0.3), width: 1),
                ),
                child: Text(
                  info['countdown'] ?? '00:00',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? accentGold : const Color(0xff996515),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── PRAYER TRACKER GRID ───────────────────────────────────────────────────

  Widget _buildPrayerGrid(
    IbadahState state,
    IbadahController controller,
    Color glassColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final pt = state.prayerTime;
    final log = state.ibadahLog;

    // Definisikan daftar shalat fardhu beserta waktu dan ikonnya
    final List<Map<String, dynamic>> prayers = [
      {
        'key': 'subuh',
        'label': 'Subuh',
        'time': pt?.fajr ?? '04:35',
        'status': log?.subuh ?? 'belum',
      },
      {
        'key': 'dzuhur',
        'label': 'Dzuhur',
        'time': pt?.dhuhr ?? '11:55',
        'status': log?.dzuhur ?? 'belum',
      },
      {
        'key': 'ashar',
        'label': 'Ashar',
        'time': pt?.asr ?? '15:15',
        'status': log?.ashar ?? 'belum',
      },
      {
        'key': 'maghrib',
        'label': 'Maghrib',
        'time': pt?.maghrib ?? '17:55',
        'status': log?.maghrib ?? 'belum',
      },
      {
        'key': 'isya',
        'label': 'Isya',
        'time': pt?.isha ?? '19:10',
        'status': log?.isya ?? 'belum',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.55,
      ),
      itemCount: 5,
      itemBuilder: (context, index) {
        final prayer = prayers[index];
        final isLocked = _isPrayerLocked(prayer['time'] as String, state.selectedDate);

        // Styling status shalat
        Color statusColor = Colors.grey.withValues(alpha: 0.3);
        IconData statusIcon = Icons.circle_outlined;
        String statusLabel = 'Belum';

        switch (prayer['status']) {
          case 'munfarid':
            statusColor = Colors.blueAccent;
            statusIcon = Icons.person_rounded;
            statusLabel = 'Munfarid';
            break;
          case 'berjamaah':
            statusColor = Colors.green;
            statusIcon = Icons.people_rounded;
            statusLabel = 'Berjamaah';
            break;
          case 'qadha':
            statusColor = Colors.orange;
            statusIcon = Icons.sync_rounded;
            statusLabel = 'Qadha';
            break;
          case 'terlewat':
            statusColor = Colors.redAccent;
            statusIcon = Icons.close_rounded;
            statusLabel = 'Terlewat';
            break;
        }

        return Container(
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isLocked
                  ? Colors.transparent
                  : (prayer['status'] != 'belum'
                      ? statusColor.withValues(alpha: 0.5)
                      : Colors.transparent),
              width: 1.5,
            ),
            boxShadow: prayer['status'] != 'belum' && !isLocked
                ? [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.1),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLocked
                  ? null
                  : () => _showPrayerActionSheet(
                        context,
                        prayer['label'] as String,
                        prayer['status'] as String,
                        controller,
                      ),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Label & Time
                    Column(
                      children: [
                        Text(
                          prayer['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isLocked ? textSecondary.withValues(alpha: 0.4) : textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          prayer['time'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: isLocked ? textSecondary.withValues(alpha: 0.3) : textSecondary,
                          ),
                        ),
                      ],
                    ),

                    // Central Status Icon / Lock
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isLocked
                            ? Colors.black12
                            : statusColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isLocked ? Icons.lock_outline_rounded : statusIcon,
                        size: 18,
                        color: isLocked
                            ? textSecondary.withValues(alpha: 0.3)
                            : (prayer['status'] == 'belum'
                                ? textSecondary.withValues(alpha: 0.5)
                                : statusColor),
                      ),
                    ),

                    // Text status
                    Text(
                      isLocked ? 'Locked' : statusLabel,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: isLocked
                            ? textSecondary.withValues(alpha: 0.3)
                            : (prayer['status'] == 'belum' ? textSecondary : statusColor),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── DIALOG PEMILIHAN STATUS SHALAT ────────────────────────────────────────

  void _showPrayerActionSheet(
    BuildContext context,
    String prayerName,
    String currentStatus,
    IbadahController controller,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final List<Map<String, dynamic>> options = [
          {'status': 'berjamaah', 'label': 'Berjamaah 👥', 'desc': 'Melakukan shalat bersama (+10 XP & Siram 🌿)'},
          {'status': 'munfarid', 'label': 'Munfarid 👤', 'desc': 'Melakukan shalat sendiri (+5 XP & Siram 🌿)'},
          {'status': 'qadha', 'label': 'Qadha 🔄', 'desc': 'Mengganti shalat yang terlewat di waktu lain (0 XP)'},
          {'status': 'terlewat', 'label': 'Terlewat ❌', 'desc': 'Tidak melakukan shalat di waktu tersebut (0 XP)'},
          {'status': 'belum', 'label': 'Reset status ⚪', 'desc': 'Batalkan pencatatan shalat'},
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catat Shalat $prayerName',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: options.map((opt) {
                    final isSelected = opt['status'] == currentStatus;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      leading: Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                        color: isSelected ? const Color(0xff0b3b24) : Colors.grey,
                      ),
                      title: Text(
                        opt['label'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: Text(
                        opt['desc'] as String,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: () {
                        controller.updatePrayerStatus(prayerName, opt['status'] as String);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── QURAN TRACKER CARD ────────────────────────────────────────────────────

  Widget _buildQuranTracker(
    IbadahState state,
    IbadahController controller,
    Color glassColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final log = state.ibadahLog;
    final pages = log?.quranPages ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: glassColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (pages > 0 ? const Color(0xff0b3b24) : Colors.transparent).withValues(alpha: 0.15),
          width: 1.5,
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
                      color: Colors.green.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.book_rounded,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Tilawah Al-Quran',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '+2 XP / Halaman',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: Column(
              children: [
                Text(
                  '$pages',
                  style: GoogleFonts.outfit(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                  ),
                ),
                Text(
                  'Halaman dibaca hari ini',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAdjustButton(
                icon: Icons.remove,
                onTap: () {
                  if (pages > 0) {
                    controller.updateQuranPages(pages - 1);
                  }
                },
              ),
              _buildAdjustButton(
                icon: Icons.add,
                label: '+1',
                onTap: () => controller.updateQuranPages(pages + 1),
              ),
              _buildAdjustButton(
                icon: Icons.add,
                label: '+5',
                onTap: () => controller.updateQuranPages(pages + 5),
              ),
              _buildAdjustButton(
                icon: Icons.edit_outlined,
                onTap: () => _showQuranManualDialog(context, pages, controller),
                tooltip: 'Ketik Manual',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustButton({
    required IconData icon,
    String? label,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: Colors.green),
                if (label != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showQuranManualDialog(
    BuildContext context,
    int currentPages,
    IbadahController controller,
  ) {
    final textController = TextEditingController(text: currentPages.toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Ketik Jumlah Halaman'),
          content: TextField(
            controller: textController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              hintText: 'Masukkan jumlah halaman',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final input = int.tryParse(textController.text) ?? 0;
                controller.updateQuranPages(input);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0b3b24),
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  // ─── TASBIH DIGITAL ────────────────────────────────────────────────────────

  Widget _buildDhikrTasbih(
    IbadahState state,
    IbadahController controller,
    Color glassColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: glassColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (_localTasbihCount > 0 ? const Color(0xffd4af37) : Colors.transparent).withValues(alpha: 0.15),
          width: 1.5,
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
                      color: Colors.amber.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.trip_origin_rounded,
                      color: Colors.amber,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Tasbih Digital',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '+1 XP / 10 Dzikir',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Dropdown lafadz dzikir
              DropdownButton<String>(
                value: _selectedDhikrPreset,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.amber),
                underline: const SizedBox.shrink(),
                elevation: 3,
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                borderRadius: BorderRadius.circular(12),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _selectedDhikrPreset = value;
                    });
                  }
                },
                items: _dhikrPresets.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),

              // Tombol Reset
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _localTasbihCount = 0;
                  });
                  controller.updateDhikrCount(0);
                },
                icon: const Icon(Icons.refresh, size: 14, color: Colors.grey),
                label: const Text('Reset', style: TextStyle(color: Colors.grey, fontSize: 11)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tombol Klik Besar Tasbih
          Center(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _localTasbihCount++;
                });
                controller.updateDhikrCount(_localTasbihCount);
              },
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber.withValues(alpha: 0.1),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.35),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.05),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_localTasbihCount',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                        ),
                      ),
                      const Text(
                        'KLIK',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.amber,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── CHECKLIST AMALAN SUNNAH ───────────────────────────────────────────────

  Widget _buildSunnahChecklist(
    IbadahState state,
    IbadahController controller,
    Color glassColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final log = state.ibadahLog;

    final List<Map<String, dynamic>> items = [
      {
        'key': 'duha',
        'title': 'Shalat Duha ☀️',
        'reward': '+10 XP',
        'isCompleted': log?.duha == 1,
        'color': Colors.amber,
      },
      {
        'key': 'tahajjud',
        'title': 'Shalat Tahajjud 🌙',
        'reward': '+15 XP',
        'isCompleted': log?.tahajjud == 1,
        'color': Colors.indigoAccent,
      },
      {
        'key': 'sedekah',
        'title': 'Sedekah Harian 🤲',
        'reward': '+10 XP',
        'isCompleted': log?.sedekah == 1,
        'color': Colors.teal,
      },
    ];

    return Column(
      children: items.map((item) {
        final isDone = item['isCompleted'] as bool;
        final color = item['color'] as Color;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            decoration: BoxDecoration(
              color: glassColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDone ? color.withValues(alpha: 0.3) : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDone ? Icons.check_circle : Icons.circle_outlined,
                  color: color,
                  size: 20,
                ),
              ),
              title: Text(
                item['title'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDone ? color : textPrimary,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
              trailing: Text(
                item['reward'] as String,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDone ? color.withValues(alpha: 0.6) : Colors.grey,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              onTap: () => controller.toggleSunnah(item['key'] as String),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── ANALISIS & HEATMAP SECTION ────────────────────────────────────────────

  Widget _buildAnalyticsSection(IbadahState state, Color glassColor, Color textPrimary, Color textSecondary) {
    final logs = state.allLogs;

    // Kalkulasi Completion Rate
    final int totalDaysLogged = logs.length;
    int doneToday = 0;
    int doneThisWeek = 0;
    int expectedThisWeek = 0;

    final todayStr = DateFormatter.todayString;
    final todayLog = logs.where((l) => l.date == todayStr).firstOrNull;
    if (todayLog != null) {
      if (todayLog.subuh == 'berjamaah' || todayLog.subuh == 'munfarid') doneToday++;
      if (todayLog.dzuhur == 'berjamaah' || todayLog.dzuhur == 'munfarid') doneToday++;
      if (todayLog.ashar == 'berjamaah' || todayLog.ashar == 'munfarid') doneToday++;
      if (todayLog.maghrib == 'berjamaah' || todayLog.maghrib == 'munfarid') doneToday++;
      if (todayLog.isya == 'berjamaah' || todayLog.isya == 'munfarid') doneToday++;
    }

    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormatter.formatDate(date);
      final log = logs.where((l) => l.date == dateStr).firstOrNull;
      if (log != null) {
        expectedThisWeek += 5;
        if (log.subuh == 'berjamaah' || log.subuh == 'munfarid') doneThisWeek++;
        if (log.dzuhur == 'berjamaah' || log.dzuhur == 'munfarid') doneThisWeek++;
        if (log.ashar == 'berjamaah' || log.ashar == 'munfarid') doneThisWeek++;
        if (log.maghrib == 'berjamaah' || log.maghrib == 'munfarid') doneThisWeek++;
        if (log.isya == 'berjamaah' || log.isya == 'munfarid') doneThisWeek++;
      }
    }

    final int pct = expectedThisWeek > 0 ? ((doneThisWeek / expectedThisWeek) * 100).round() : 0;
    final int totalQuranPages = logs.fold(0, (sum, item) => sum + item.quranPages);

    // Kumpulan 7 hari terakhir untuk Heatmap
    final List<Map<String, dynamic>> heatmapData = [];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormatter.formatDate(date);
      final dayLog = logs.where((l) => l.date == dateStr).firstOrNull;
      final dayLabel = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'][date.weekday % 7];

      heatmapData.add({
        'day': dayLabel,
        'subuh': dayLog?.subuh ?? 'belum',
        'dzuhur': dayLog?.dzuhur ?? 'belum',
        'ashar': dayLog?.ashar ?? 'belum',
        'maghrib': dayLog?.maghrib ?? 'belum',
        'isya': dayLog?.isya ?? 'belum',
      });
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: glassColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row Metrik Angka
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAnalyticsCard(
                title: 'Hari Ini',
                value: '$doneToday/5',
                desc: 'Shalat fardhu selesai',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _buildAnalyticsCard(
                title: 'Minggu Ini',
                value: '$pct%',
                desc: '$doneThisWeek/$expectedThisWeek shalat fardhu',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _buildAnalyticsCard(
                title: 'Total Quran',
                value: '$totalQuranPages Hlm',
                desc: 'Dari $totalDaysLogged hari pencatatan',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),

          // Peta Panas (Heatmap) 7 Hari Terakhir
          Text(
            'Prayer Heatmap (7 Hari Terakhir)',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Tampilan Grid Heatmap
          Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            children: [
              // Header Row (Nama Hari)
              TableRow(
                children: [
                  const SizedBox(width: 48), // Padding kolom shalat
                  ...heatmapData.map((d) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Text(
                          d['day'] as String,
                          style: TextStyle(fontSize: 10, color: textSecondary, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      )),
                ],
              ),

              // Rows untuk masing-masing shalat fardhu
              ...['Subuh', 'Dzuhur', 'Ashar', 'Maghrib', 'Isya'].map((prayer) {
                return TableRow(
                  children: [
                    // Kolom Nama Shalat
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        prayer,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textPrimary),
                        textAlign: TextAlign.left,
                      ),
                    ),

                    // Kolom Dot Warna Heatmap
                    ...heatmapData.map((d) {
                      final status = d[prayer.toLowerCase()] as String;
                      Color dotColor = Colors.grey.withValues(alpha: 0.15); // 'belum'

                      if (status == 'berjamaah') dotColor = Colors.green;
                      if (status == 'munfarid') dotColor = Colors.blueAccent;
                      if (status == 'qadha') dotColor = Colors.amber;
                      if (status == 'terlewat') dotColor = Colors.redAccent;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: dotColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),

          const SizedBox(height: 16),
          // Legend Heatmap
          Wrap(
            spacing: 12,
            children: [
              _buildLegendDot(Colors.green, 'Berjamaah'),
              _buildLegendDot(Colors.blueAccent, 'Munfarid'),
              _buildLegendDot(Colors.amber, 'Qadha'),
              _buildLegendDot(Colors.redAccent, 'Terlewat'),
              _buildLegendDot(Colors.grey.withValues(alpha: 0.3), 'Belum'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard({
    required String title,
    required String value,
    required String desc,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            style: TextStyle(fontSize: 9, color: textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  // ─── ACHIEVEMENTS / LENCANA PANEL ─────────────────────────────────────────

  Widget _buildAchievementsPanel(IbadahState state, Color glassColor, Color textPrimary, Color textSecondary) {
    final logs = state.allLogs;

    // Hitung Lencana
    // 1. Shalat Pertama
    bool firstPrayer = false;
    // 2. Tahajjud Warrior (Tahajjud >= 7 hari)
    int tahajjudDays = 0;
    // 3. Charity Giver (Sedekah >= 7 hari)
    int sedekahDays = 0;
    // 4. Quran Beginner (Quran pages > 0)
    bool quranBeginner = false;
    // 5. Quran Consistent (Quran pages > 0 pada >= 7 hari berbeda)
    int quranDays = 0;
    // 6. Konsisten Shalat 7 Hari
    int consecutivePerfectDays = 0;

    // Olah seluruh log untuk lencana
    final Map<String, IbadahLog> logsByDate = {};
    for (final l in logs) {
      logsByDate[l.date] = l;
      if (l.subuh != 'belum' || l.dzuhur != 'belum' || l.ashar != 'belum' || l.maghrib != 'belum' || l.isya != 'belum') {
        firstPrayer = true;
      }
      if (l.tahajjud == 1) {
        tahajjudDays++;
      }
      if (l.sedekah == 1) {
        sedekahDays++;
      }
      if (l.quranPages > 0) {
        quranBeginner = true;
        quranDays++;
      }
    }

    // Kalkulasi streak shalat perfect 7 hari berturut-turut
    final today = DateTime.now();
    int currentStreak = 0;
    int maxStreak = 0;
    for (int i = 0; i < 90; i++) {
      final date = today.subtract(Duration(days: i));
      final dateStr = DateFormatter.formatDate(date);
      final log = logsByDate[dateStr];
      bool isPerfect = false;
      if (log != null) {
        final subCompleted = log.subuh == 'berjamaah' || log.subuh == 'munfarid';
        final dzuCompleted = log.dzuhur == 'berjamaah' || log.dzuhur == 'munfarid';
        final ashCompleted = log.ashar == 'berjamaah' || log.ashar == 'munfarid';
        final magCompleted = log.maghrib == 'berjamaah' || log.maghrib == 'munfarid';
        final isyCompleted = log.isya == 'berjamaah' || log.isya == 'isya'; // Typo safety isya
        final isyReal = log.isya == 'berjamaah' || log.isya == 'munfarid';

        if (subCompleted && dzuCompleted && ashCompleted && magCompleted && isyReal) {
          isPerfect = true;
        }
      }

      if (isPerfect) {
        currentStreak++;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }
      } else {
        currentStreak = 0;
      }
    }

    consecutivePerfectDays = maxStreak;

    final List<Map<String, dynamic>> badges = [
      {
        'id': 'first_prayer',
        'title': 'Shalat Pertama',
        'desc': 'Melakukan shalat fardhu pertama kali',
        'icon': Icons.mosque_rounded,
        'unlocked': firstPrayer,
        'color': Colors.teal,
      },
      {
        'id': 'quran_beginner',
        'title': 'Pemula Quran',
        'desc': 'Mulai membaca halaman Al-Quran pertama',
        'icon': Icons.menu_book_rounded,
        'unlocked': quranBeginner,
        'color': Colors.green,
      },
      {
        'id': 'tahajjud_warrior',
        'title': 'Tahajjud Warrior',
        'desc': 'Mendirikan Tahajjud selama 7 malam',
        'icon': Icons.dark_mode_rounded,
        'unlocked': tahajjudDays >= 7,
        'color': Colors.indigo,
      },
      {
        'id': 'charity_giver',
        'title': 'Tangan Di Atas',
        'desc': 'Mengisi Sedekah selama 7 hari',
        'icon': Icons.volunteer_activism_rounded,
        'unlocked': sedekahDays >= 7,
        'color': Colors.redAccent,
      },
      {
        'id': 'quran_consistent',
        'title': 'Pecinta Quran',
        'desc': 'Tilawah Al-Quran selama 7 hari berbeda',
        'icon': Icons.auto_stories_rounded,
        'unlocked': quranDays >= 7,
        'color': Colors.teal,
      },
      {
        'id': 'shalat_7d',
        'title': 'Disiplin Shalat (7 Hari)',
        'desc': 'Selesaikan 5 shalat fardhu 7 hari beruntun',
        'icon': Icons.emoji_events_rounded,
        'unlocked': consecutivePerfectDays >= 7,
        'color': Colors.amber,
      },
      {
        'id': 'shalat_30d',
        'title': 'Prajurit Shalat (30 Hari)',
        'desc': 'Selesaikan 5 shalat fardhu 30 hari beruntun',
        'icon': Icons.military_tech_rounded,
        'unlocked': consecutivePerfectDays >= 30,
        'color': Colors.deepOrange,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: glassColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: badges.length,
        separatorBuilder: (context, index) => const Divider(color: Colors.white10),
        itemBuilder: (context, index) {
          final badge = badges[index];
          final unlocked = badge['unlocked'] as bool;
          final color = badge['color'] as Color;

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: unlocked ? color.withValues(alpha: 0.12) : Colors.black12,
                shape: BoxShape.circle,
                border: Border.all(
                  color: unlocked ? color.withValues(alpha: 0.3) : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Icon(
                unlocked ? badge['icon'] as IconData : Icons.lock_outline,
                color: unlocked ? color : Colors.grey,
                size: 20,
              ),
            ),
            title: Text(
              badge['title'] as String,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: unlocked ? textPrimary : Colors.grey,
              ),
            ),
            subtitle: Text(
              badge['desc'] as String,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: unlocked ? color.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unlocked ? 'UNLOCKED' : 'LOCKED',
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: unlocked ? color : Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── DIALOG PENGATURAN LOKASI KOTA ─────────────────────────────────────────

  void _showLocationDialog(
    BuildContext context,
    String currentCity,
    IbadahController controller,
  ) {
    final textController = TextEditingController(text: currentCity);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('📍 Ubah Kota Lokasi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ubah nama kota untuk menyelaraskan jadwal adzan (Kemenag RI).',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'Nama Kota',
                  hintText: 'Misal: Surabaya, Bandung, Medan',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final newCity = textController.text;
                if (newCity.trim().isNotEmpty) {
                  controller.changeCity(newCity);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0b3b24),
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }
}
