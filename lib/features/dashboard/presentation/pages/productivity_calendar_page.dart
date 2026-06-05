import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/collapsible_sidebar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../habits/domain/entities/habit.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tracking/domain/entities/habit_log.dart';
import '../controllers/productivity_calendar_controller.dart';

const List<String> _monthNames = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
];

const List<String> _dayNames = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];

/// Halaman Kalender Produktivitas Bulanan dengan heatmap kontribusi
/// dan integrasi sinkronisasi Google Calendar.
class ProductivityCalendarPage extends ConsumerWidget {
  const ProductivityCalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarState = ref.watch(productivityCalendarControllerProvider);
    final productivityAsync = ref.watch(monthlyProductivityProvider);
    
    final isMobile = MediaQuery.of(context).size.width < 800;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
        drawer: isMobile ? const CollapsibleSidebar(isDrawer: true) : null,
        appBar: AppBar(
          title: const Text('Kalender Produktivitas'),
          leading: isMobile
              ? Builder(
                  builder: (context) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
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
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.sync_rounded, size: 20),
                  color: AppTheme.accentPrimary,
                  onPressed: () => _showSyncSettingsBottomSheet(context, ref),
                  tooltip: 'Sinkronisasi Google Calendar',
                ),
              ),
            ),
          ],
        ),
        body: Row(
          children: [
            if (!isMobile) const CollapsibleSidebar(isDrawer: false),
            Expanded(
              child: productivityAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentPrimary),
                  ),
                ),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text('Gagal memuat data produktivitas: $err', textAlign: TextAlign.center),
                  ),
                ),
                data: (productivityData) => SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Month Picker Header
                      _buildMonthPicker(context, ref, calendarState.selectedMonth),
                      const SizedBox(height: 20),

                      // 2. Summary Statistics Card
                      _buildStatsSummary(context, calendarState.selectedMonth, productivityData),
                      const SizedBox(height: 24),

                      // 3. GitHub style Calendar Heatmap
                      _buildCalendarHeatmap(context, ref, calendarState.selectedMonth, productivityData),
                      const SizedBox(height: 24),

                      // 4. Color Legend & Info
                      _buildLegend(context),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Membangun navigasi pemilih bulan aktif
  Widget _buildMonthPicker(BuildContext context, WidgetRef ref, DateTime selectedMonth) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${_monthNames[selectedMonth.month - 1]} ${selectedMonth.year}',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () {
                final prevMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
                ref.read(productivityCalendarControllerProvider.notifier).setMonth(prevMonth);
              },
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: () {
                final nextMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
                ref.read(productivityCalendarControllerProvider.notifier).setMonth(nextMonth);
              },
            ),
          ],
        ),
      ],
    );
  }

  /// Membangun kartu ringkasan statistik produktivitas bulan tersebut
  Widget _buildStatsSummary(BuildContext context, DateTime selectedMonth, ProductivityData data) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkSurface : theme.colorScheme.surface;
    final borderCol = isDark ? AppTheme.darkBorder : theme.colorScheme.outline.withOpacity(0.12);

    int totalHabitsCompleted = 0;
    int totalTasksCompleted = 0;
    
    // Hitung total penyelesaian di bulan aktif
    data.dailyDetails.forEach((dateStr, items) {
      final parsedDate = DateFormatter.parseDate(dateStr);
      if (parsedDate.year == selectedMonth.year && parsedDate.month == selectedMonth.month) {
        for (final item in items) {
          if (item is Task && item.isCompleted) {
            totalTasksCompleted++;
          } else if (item is Map && item.containsKey('log')) {
            final log = item['log'] as HabitLog;
            if (log.status == 'done') {
              totalHabitsCompleted++;
            }
          }
        }
      }
    });

    final totalCompleted = totalHabitsCompleted + totalTasksCompleted;

    // Cari hari paling produktif
    String peakDayStr = '-';
    int maxCompletions = 0;
    data.completions.forEach((dateStr, count) {
      final parsedDate = DateFormatter.parseDate(dateStr);
      if (parsedDate.year == selectedMonth.year && parsedDate.month == selectedMonth.month) {
        if (count > maxCompletions) {
          maxCompletions = count;
          peakDayStr = '${parsedDate.day} ${_monthNames[parsedDate.month - 1].substring(0, 3)}';
        }
      }
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Row(
        children: [
          _buildStatItem(context, 'Total Selesai', '$totalCompleted', Icons.task_alt_rounded, AppTheme.accentPrimary),
          Container(height: 40, width: 1, color: borderCol),
          _buildStatItem(context, 'Habit Centang', '$totalHabitsCompleted', Icons.spa_rounded, AppTheme.statusDone),
          Container(height: 40, width: 1, color: borderCol),
          _buildStatItem(context, 'Tugas Selesai', '$totalTasksCompleted', Icons.checklist_rounded, AppTheme.statusSkipped),
          Container(height: 40, width: 1, color: borderCol),
          _buildStatItem(context, 'Hari Tersibuk', peakDayStr, Icons.local_fire_department_rounded, AppTheme.statusMissed),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Membangun grid kalender kontribusi bulanan
  Widget _buildCalendarHeatmap(BuildContext context, WidgetRef ref, DateTime selectedMonth, ProductivityData data) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkSurface : theme.colorScheme.surface;
    final borderCol = isDark ? AppTheme.darkBorder : theme.colorScheme.outline.withOpacity(0.12);

    // Cari hari pertama bulan aktif dan tentukan padding awal (Senin=1, Minggu=7)
    final firstDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final weekdayOfFirstDay = firstDayOfMonth.weekday; // 1 = Senin, 7 = Minggu
    final paddingDays = weekdayOfFirstDay - 1; // Jumlah sel kosong dari Senin

    // Cari total hari pada bulan aktif
    final lastDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
    final totalDays = lastDayOfMonth.day;

    final totalGridCells = paddingDays + totalDays;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        children: [
          // 1. Day headers (Sen, Sel, Rab, dll)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: 7,
            itemBuilder: (context, index) {
              return Center(
                child: Text(
                  _dayNames[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkTextSecondary.withOpacity(0.7) : AppTheme.lightTextSecondary.withOpacity(0.7),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // 2. Day cells
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: totalGridCells,
            itemBuilder: (context, index) {
              if (index < paddingDays) {
                // Sel kosong / padding bulan sebelumnya
                return const SizedBox.shrink();
              }

              final dayNum = index - paddingDays + 1;
              final currentDate = DateTime(selectedMonth.year, selectedMonth.month, dayNum);
              final dateStr = DateFormatter.formatDate(currentDate);

              // 1. Hitung tingkat keproduktifan hari itu
              final completions = data.completions[dateStr] ?? 0;

              Color cellColor;
              if (completions == 0) {
                cellColor = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04);
              } else if (completions <= 2) {
                cellColor = AppTheme.statusDone.withOpacity(0.25);
              } else if (completions <= 4) {
                cellColor = AppTheme.statusDone.withOpacity(0.55);
              } else {
                cellColor = AppTheme.statusDone;
              }

              // 2. Cek deadline tugas
              final deadlinePriority = data.highestPriorityDeadline[dateStr];
              Color? deadlineColor;
              if (deadlinePriority != null) {
                if (deadlinePriority == 'high') {
                  deadlineColor = AppTheme.statusMissed;
                } else if (deadlinePriority == 'medium') {
                  deadlineColor = AppTheme.statusSkipped;
                } else {
                  deadlineColor = AppTheme.accentPrimary;
                }
              }

              final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;

              return Material(
                color: cellColor,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _showDailyDetailsBottomSheet(context, currentDate, data.dailyDetails[dateStr] ?? []),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Angka tanggal
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: completions >= 5 ? Colors.black : textPrimary,
                        ),
                      ),
                      // Indikator tenggat tugas (deadline) di bagian bawah
                      if (deadlineColor != null)
                        Positioned(
                          bottom: 5,
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: deadlineColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Membangun petunjuk warna heatmap & deadline
  Widget _buildLegend(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkSurface : theme.colorScheme.surface;
    final borderCol = isDark ? AppTheme.darkBorder : theme.colorScheme.outline.withOpacity(0.12);
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Petunjuk Kalender',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // Heatmap legend
          Row(
            children: [
              Text('Produktif: ', style: TextStyle(fontSize: 10, color: textSecondary)),
              const SizedBox(width: 8),
              _buildLegendBox(context, Colors.white.withOpacity(0.04), '0'),
              const SizedBox(width: 4),
              _buildLegendBox(context, AppTheme.statusDone.withOpacity(0.25), '1-2'),
              const SizedBox(width: 4),
              _buildLegendBox(context, AppTheme.statusDone.withOpacity(0.55), '3-4'),
              const SizedBox(width: 4),
              _buildLegendBox(context, AppTheme.statusDone, '5+ selesai'),
            ],
          ),
          const SizedBox(height: 12),
          // Deadline legend
          Row(
            children: [
              Text('Prioritas Tenggat: ', style: TextStyle(fontSize: 10, color: textSecondary)),
              const SizedBox(width: 8),
              _buildLegendDot(AppTheme.statusMissed, 'Tinggi'),
              const SizedBox(width: 12),
              _buildLegendDot(AppTheme.statusSkipped, 'Sedang'),
              const SizedBox(width: 12),
              _buildLegendDot(AppTheme.accentPrimary, 'Rendah'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendBox(BuildContext context, Color color, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: Colors.grey),
        ),
      ],
    );
  }

  /// Menampilkan rincian harian saat mengetuk sel tanggal
  void _showDailyDetailsBottomSheet(BuildContext context, DateTime date, List<dynamic> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomSheetBg = isDark ? AppTheme.darkSurface : Colors.white;
    final titleColor = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;

    showModalBottomSheet(
      context: context,
      backgroundColor: bottomSheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handlebar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Header
              Text(
                'Rincian Aktivitas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor),
              ),
              Text(
                '${date.day} ${_monthNames[date.month - 1]} ${date.year}',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const Divider(height: 24),
              
              if (items.isEmpty)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('Tidak ada riwayat aktivitas pada tanggal ini.', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      if (item is Task) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: item.isCompleted ? AppTheme.statusDone.withOpacity(0.12) : AppTheme.accentPrimary.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: item.isCompleted ? AppTheme.statusDone : AppTheme.accentPrimary,
                              size: 16,
                            ),
                          ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                              color: item.isCompleted ? Colors.grey : titleColor,
                            ),
                          ),
                          subtitle: Text('Tugas • Prioritas: ${item.priority.toUpperCase()}', style: const TextStyle(fontSize: 11)),
                        );
                      } else if (item is Map && item.containsKey('habit')) {
                        final habit = item['habit'] as Habit;
                        final log = item['log'] as HabitLog;
                        
                        IconData iconData;
                        Color statusColor;
                        String statusLabel;

                        if (log.status == 'done') {
                          iconData = Icons.spa_rounded;
                          statusColor = AppTheme.statusDone;
                          statusLabel = 'Selesai';
                        } else if (log.status == 'skipped') {
                          iconData = Icons.next_plan_rounded;
                          statusColor = AppTheme.statusSkipped;
                          statusLabel = 'Dilewati';
                        } else {
                          iconData = Icons.circle_outlined;
                          statusColor = Colors.grey;
                          statusLabel = 'Belum Centang';
                        }

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              iconData,
                              color: statusColor,
                              size: 16,
                            ),
                          ),
                          title: Text(
                            habit.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                          subtitle: Text('Kebiasaan • Status: $statusLabel', style: const TextStyle(fontSize: 11)),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Menampilkan Bottom Sheet Pengaturan & Sinkronisasi Google Calendar
  void _showSyncSettingsBottomSheet(BuildContext context, WidgetRef ref) {
    final authUser = ref.read(authControllerProvider).valueOrNull;
    final isGuest = authUser == null || authUser.isGuest;
    final calendarState = ref.watch(productivityCalendarControllerProvider);
    final calendarNotifier = ref.read(productivityCalendarControllerProvider.notifier);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomSheetBg = isDark ? AppTheme.darkSurface : Colors.white;
    final titleColor = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bottomSheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        // Karena bottom sheet berada di konteks terpisah, gunakan Consumer
        // agar state perubahan toggle langsung ter-render real-time.
        return Consumer(
          builder: (context, ref, child) {
            final state = ref.watch(productivityCalendarControllerProvider);
            return SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.sync_rounded, color: AppTheme.accentPrimary),
                      const SizedBox(width: 8),
                      Text(
                        'Google Calendar Sync',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isGuest
                        ? 'Sinkronisasikan habit dan task harian Anda langsung ke Google Calendar secara real-time. (Mode Tamu tidak didukung)'
                        : (authUser?.id == 'demo_user_google_123'
                            ? 'Sinkronisasikan habit dan task harian Anda langsung ke Google Calendar secara real-time. (Mode Demo tidak didukung)'
                            : 'Kelola preferensi sinkronisasi data Anda dengan Google Calendar.'),
                    style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                  ),
                  const Divider(height: 32),
                  
                  if (isGuest) ...[
                    // Opsi login jika masih tamu
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'Silakan masuk ke Akun Google di tab Profil.',
                        style: TextStyle(color: AppTheme.statusMissed, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          context.go('/profile');
                        },
                        icon: const Icon(Icons.person),
                        label: const Text('Buka Profil & Login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ] else if (authUser?.id == 'demo_user_google_123') ...[
                    // Opsi login jika menggunakan akun demo
                    const SizedBox(height: 10),
                    Center(
                      child: Column(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppTheme.statusSkipped, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            'Mode Demo Aktif',
                            style: TextStyle(color: titleColor, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Sinkronisasi Google Calendar memerlukan autentikasi riil.\nSilakan hubungkan Akun Google Anda di menu Profil untuk mengaktifkan sinkronisasi.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          context.go('/profile');
                        },
                        icon: const Icon(Icons.person),
                        label: const Text('Buka Profil & Hubungkan Akun'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Toggle integrasi global
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Aktifkan Google Calendar Sync', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Menghubungkan aplikasi dengan Google Calendar Anda.', style: TextStyle(fontSize: 11)),
                      value: state.googleCalendarSyncEnabled,
                      activeColor: AppTheme.accentPrimary,
                      onChanged: (val) async {
                        if (val) {
                          final success = await ref.read(authRepositoryProvider).requestCalendarScope();
                          if (!success) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Izin akses Google Calendar ditolak atau gagal.'),
                                  backgroundColor: AppTheme.statusMissed,
                                ),
                              );
                            }
                            return;
                          }
                          calendarNotifier.toggleGoogleCalendarSync(val);
                        } else {
                          // Tampilkan konfirmasi sebelum menonaktifkan & menghapus event
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppTheme.darkCard,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: AppTheme.statusMissed),
                                  SizedBox(width: 8),
                                  Text('Nonaktifkan Sync?', style: TextStyle(fontSize: 16)),
                                ],
                              ),
                              content: const Text(
                                'Semua event Dailio akan dihapus dari Google Calendar Anda. Tindakan ini tidak bisa dibatalkan.',
                                style: TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Batal'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.statusMissed,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Hapus & Nonaktifkan'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            calendarNotifier.toggleGoogleCalendarSync(false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Menghapus event Dailio dari Google Calendar...'),
                                  backgroundColor: AppTheme.accentPrimary,
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    
                    if (state.googleCalendarSyncEnabled) ...[
                      // Toggle detail auto sync
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Sinkronisasikan Kebiasaan', style: TextStyle(fontSize: 14)),
                        subtitle: const Text('Sync agenda habit sebagai event berulang (recurring).', style: TextStyle(fontSize: 11)),
                        value: state.autoSyncHabits,
                        activeColor: AppTheme.statusDone,
                        onChanged: (val) {
                          calendarNotifier.toggleAutoSyncHabits(val);
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Sinkronisasikan Tugas', style: TextStyle(fontSize: 14)),
                        subtitle: const Text('Sync deadline tugas ke Google Calendar.', style: TextStyle(fontSize: 11)),
                        value: state.autoSyncTasks,
                        activeColor: AppTheme.statusDone,
                        onChanged: (val) {
                          calendarNotifier.toggleAutoSyncTasks(val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Error message jika ada
                      if (state.syncError != null) ...[
                        Text(
                          state.syncError!,
                          style: const TextStyle(color: AppTheme.statusMissed, fontSize: 11),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Tombol pemicu manual sync
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: state.isSyncing
                              ? null
                              : () async {
                                  final success = await calendarNotifier.triggerManualSync();
                                  if (success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Sinkronisasi Google Calendar berhasil! 🌱'),
                                        backgroundColor: AppTheme.statusDone,
                                      ),
                                    );
                                  }
                                },
                          icon: state.isSyncing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                )
                              : const Icon(Icons.cloud_upload_rounded),
                          label: Text(state.isSyncing ? 'Menyinkronkan...' : 'Mulai Sinkronisasi Manual'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.statusDone.withOpacity(0.15),
                            foregroundColor: AppTheme.statusDone,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
}
