import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/theme/app_theme.dart';
import '../controllers/habit_detail_controller.dart';
import '../controllers/habit_list_controller.dart';

/// Halaman detail habit harian, menampilkan statistik streak lengkap,
/// diagram kalender 30 hari visual, serta opsi manajemen (arsip, hapus).
class HabitDetailPage extends ConsumerWidget {
  final String habitId;

  const HabitDetailPage({super.key, required this.habitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(habitDetailProvider(habitId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Habit'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Opsi Edit Habit
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              context.push('/edit-habit/$habitId');
            },
          ),
          // Opsi Hapus Habit
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.statusMissed),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Detail error: $error', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.read(habitDetailProvider(habitId).notifier).refresh(),
                  child: const Text('Coba Lagi'),
                )
              ],
            ),
          ),
        ),
        data: (state) {
          final habit = state.habit;
          final streak = state.streak;
          final logs = state.logs;
          
          final habitColor = Color(habit.color);
          
          // Kalkulasi statistik dasar
          final totalDone = logs.where((l) => l.status == 'done').length;
          final successRate = logs.isEmpty 
              ? 0.0 
              : (totalDone / logs.length) * 100.0;

          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Informasi Utama
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 16,
                          height: 64,
                          decoration: BoxDecoration(
                            color: habitColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                habit.name,
                                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                      fontSize: 24,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                habit.description ?? 'Tidak ada deskripsi.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  // Category Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      habit.category,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Frequency Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      habit.type == 'daily' ? 'Harian' : 'Mingguan',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (habit.reminderTime != null) ...[
                                    const SizedBox(width: 8),
                                    // Reminder Time Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.statusSkipped.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: AppTheme.statusSkipped.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.access_time_rounded,
                                            size: 14,
                                            color: AppTheme.statusSkipped,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            habit.reminderTime!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.statusSkipped,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Grid Statistik Streak & Pencapaian
                    Row(
                      children: [
                        Expanded(
                          child: _StatWidget(
                            title: 'Streak Sekarang',
                            value: '${streak?.currentStreak ?? 0} 🔥',
                            subtitle: streak?.lastCompletedDate != null 
                                ? 'Terakhir: ${streak!.lastCompletedDate}'
                                : 'Belum dimulai',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatWidget(
                            title: 'Streak Terbaik',
                            value: '${streak?.bestStreak ?? 0} 🏆',
                            subtitle: 'Rekor tertinggi Anda',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatWidget(
                            title: 'Total Selesai',
                            value: '$totalDone Kali',
                            subtitle: 'Dari total ${logs.length} catatan',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatWidget(
                            title: 'Tingkat Keberhasilan',
                            value: '${successRate.toStringAsFixed(0)}%',
                            subtitle: 'Konsistensi log keseluruhan',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Grid Riwayat Progress 30 Hari Terakhir
                    Text(
                      'Riwayat 30 Hari Terakhir',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _CalendarHistoryGrid(logs: logs, habitColor: habitColor),
                    const SizedBox(height: 32),

                    // Fitur Pengarsipan
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Arsipkan Kebiasaan Ini',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  'Menyembunyikan dari halaman utama',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                            Switch(
                              value: habit.isArchived,
                              onChanged: (val) async {
                                final res = await ref
                                    .read(habitDetailProvider(habitId).notifier)
                                    .toggleArchive(val);
                                if (context.mounted && res is Success<void>) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        val ? 'Habit berhasil diarsipkan.' : 'Habit diaktifkan kembali.',
                                      ),
                                    ),
                                  );
                                }
                              },
                            )
                          ],
                        ),
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

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Habit?'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus habit ini beserta seluruh histori lognya? Tindakan ini bersifat permanen.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                // Tutup dialog
                Navigator.pop(context);
                // Eksekusi hapus di controller list utama
                final result = await ref.read(habitListProvider.notifier).removeHabit(habitId);
                
                if (context.mounted) {
                  result.fold(
                    onSuccess: (_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Habit berhasil dihapus.')),
                      );
                      context.pop(); // Kembali ke home
                    },
                    onFailure: (fail) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal menghapus: ${fail.message}')),
                      );
                    },
                  );
                }
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

/// Widget Kustom Menampilkan Box Statistik
class _StatWidget extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _StatWidget({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Grid Kalender 30 Hari Terakhir
/// Grid Kalender Bulanan
class _CalendarHistoryGrid extends StatefulWidget {
  final List<dynamic> logs;
  final Color habitColor;

  const _CalendarHistoryGrid({
    super.key,
    required this.logs,
    required this.habitColor,
  });

  @override
  State<_CalendarHistoryGrid> createState() => _CalendarHistoryGridState();
}

class _CalendarHistoryGridState extends State<_CalendarHistoryGrid> {
  late DateTime _currentMonth;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '--:--';
    final localTime = dateTime.toLocal();
    final hour = localTime.hour.toString().padLeft(2, '0');
    final minute = localTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getMonthYearName(DateTime date) {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _getMonthName(DateTime date) {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[date.month - 1];
  }

  String _formatReadableDate(DateTime date) {
    final weekdays = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
    ];
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    final dayName = weekdays[date.weekday - 1];
    final monthName = months[date.month - 1];
    return '$dayName, ${date.day} $monthName';
  }

  @override
  Widget build(BuildContext context) {
    final year = _currentMonth.year;
    final month = _currentMonth.month;

    final firstDayOfMonth = DateTime(year, month, 1);
    final firstWeekday = firstDayOfMonth.weekday; // Senin = 1, Minggu = 7
    final totalDays = DateTime(year, month + 1, 0).day;

    final prefixEmptyCells = firstWeekday - 1;
    final totalCells = prefixEmptyCells + totalDays;

    final now = DateTime.now();
    final todayStr = DateFormatter.todayString;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bulan & Navigasi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getMonthYearName(_currentMonth),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 22),
                    onPressed: () {
                      setState(() {
                        _currentMonth = DateTime(year, month - 1, 1);
                        _isExpanded = false;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 22),
                    onPressed: () {
                      setState(() {
                        _currentMonth = DateTime(year, month + 1, 1);
                        _isExpanded = false;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Header Hari
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'].map((day) {
              return Expanded(
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Grid Kalender
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              if (index < prefixEmptyCells) {
                return const SizedBox.shrink();
              }

              final day = index - prefixEmptyCells + 1;
              final date = DateTime(year, month, day);
              final dateStr = DateFormatter.formatDate(date);

              // Cari log pada tanggal ini
              final matchingLogs = widget.logs.where((l) => l.date == dateStr);
              final dayLog = matchingLogs.isNotEmpty ? matchingLogs.first : null;

              Color cellColor = Theme.of(context).scaffoldBackgroundColor;
              Border? cellBorder = Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
                width: 1,
              );
              
              final isToday = dateStr == todayStr;

              Widget child = Text(
                '$day',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                  color: isToday
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              );

              if (dayLog != null) {
                if (dayLog.status == 'done') {
                  cellColor = widget.habitColor;
                  cellBorder = null;
                  child = Text(
                    '$day',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                } else if (dayLog.status == 'skipped') {
                  cellColor = AppTheme.statusSkipped.withOpacity(0.15);
                  cellBorder = Border.all(color: AppTheme.statusSkipped, width: 1.5);
                  child = Text(
                    '$day',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.statusSkipped,
                    ),
                  );
                } else if (dayLog.status == 'missed') {
                  cellColor = AppTheme.statusMissed.withOpacity(0.15);
                  cellBorder = Border.all(color: AppTheme.statusMissed, width: 1.5);
                  child = Text(
                    '$day',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.statusMissed,
                    ),
                  );
                }
              }

              // Sorot hari ini dengan border tebal jika belum di-log
              if (isToday && dayLog == null) {
                cellBorder = Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                );
              }

              Widget cellWidget = Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cellColor,
                  borderRadius: BorderRadius.circular(8),
                  border: cellBorder,
                ),
                child: child,
              );

              // Click handler untuk info SnackBar & Tooltip
              String tooltipMsg = '${_formatReadableDate(date)}: Belum diisi';
              if (dayLog != null) {
                if (dayLog.status == 'done') {
                  tooltipMsg = 'Selesai pukul ${_formatTime(dayLog.completedAt)}';
                } else if (dayLog.status == 'skipped') {
                  tooltipMsg = 'Dilewati (Skipped)';
                } else if (dayLog.status == 'missed') {
                  tooltipMsg = 'Terlewat (Missed)';
                }
              }

              return Tooltip(
                message: tooltipMsg,
                child: GestureDetector(
                  onTap: () {
                    if (date.isAfter(now)) return; // Jangan izinkan klik tanggal masa depan
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          dayLog != null
                              ? (dayLog.status == 'done'
                                  ? 'Selesai pada ${_formatReadableDate(date)} pukul ${_formatTime(dayLog.completedAt)}'
                                  : '${_formatReadableDate(date)}: ${dayLog.status == 'skipped' ? 'Dilewati' : 'Terlewat'}')
                              : '${_formatReadableDate(date)}: Tidak ada catatan',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: cellWidget,
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          // Legend Keterangan Warna
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const _LegendItem(color: Colors.grey, label: 'Kosong'),
              _LegendItem(color: widget.habitColor, label: 'Done', isDoneStyle: true),
              const _LegendItem(color: AppTheme.statusSkipped, label: 'Skip'),
              const _LegendItem(color: AppTheme.statusMissed, label: 'Missed'),
            ],
          ),

          // Detail Waktu Centang untuk bulan saat ini
          () {
            final completedLogs = widget.logs
                .where((l) {
                  if (l.status != 'done' || l.completedAt == null) return false;
                  final logDate = DateTime.tryParse(l.date);
                  if (logDate == null) return false;
                  return logDate.year == year && logDate.month == month;
                })
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));

            if (completedLogs.isEmpty) return const SizedBox.shrink();

            final totalCompleted = completedLogs.length;
            final displayCount = _isExpanded ? totalCompleted : (totalCompleted > 5 ? 5 : totalCompleted);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.history_toggle_off_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Waktu Centang Selesai (${_getMonthName(_currentMonth)})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayCount,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Theme.of(context).dividerColor.withOpacity(0.05),
                  ),
                  itemBuilder: (context, index) {
                    final log = completedLogs[index];
                    final dateObj = DateTime.tryParse(log.date) ?? DateTime.now();
                    final formattedDateStr = _formatReadableDate(dateObj);
                    final timeStr = _formatTime(log.completedAt);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: widget.habitColor.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: widget.habitColor,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              formattedDateStr,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Pukul $timeStr',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                if (totalCompleted > 5) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      icon: Icon(
                        _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      label: Text(
                        _isExpanded
                            ? 'Sembunyikan'
                            : 'Lihat Lebih Banyak (${totalCompleted - 5})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          }(),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDoneStyle;

  const _LegendItem({
    required this.color,
    required this.label,
    this.isDoneStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isDoneStyle ? color : color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
            border: isDoneStyle ? null : Border.all(color: color, width: 1),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
