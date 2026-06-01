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
class _CalendarHistoryGrid extends StatelessWidget {
  final List<dynamic> logs;
  final Color habitColor;

  const _CalendarHistoryGrid({
    required this.logs,
    required this.habitColor,
  });

  @override
  Widget build(BuildContext context) {
    // Generate list 30 hari ke belakang (termasuk hari ini)
    final now = DateTime.now();
    final List<DateTime> last30Days = List.generate(30, (index) {
      return now.subtract(Duration(days: 29 - index));
    });

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
        children: [
          // Grid 30 Hari
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 30,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, // 7 Kolom (Hari per minggu)
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final date = last30Days[index];
              final dateStr = DateFormatter.formatDate(date);
              
              // Cari log pada tanggal ini
              final matchingLogs = logs.where((l) => l.date == dateStr);
              final dayLog = matchingLogs.isNotEmpty ? matchingLogs.first : null;

              Color cellColor = Theme.of(context).scaffoldBackgroundColor;
              Border? cellBorder = Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
                width: 1,
              );
              Widget child = Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              );

              if (dayLog != null) {
                if (dayLog.status == 'done') {
                  cellColor = habitColor;
                  cellBorder = null;
                  child = const Icon(Icons.check, color: Colors.white, size: 14);
                } else if (dayLog.status == 'skipped') {
                  cellColor = AppTheme.statusSkipped.withOpacity(0.2);
                  cellBorder = Border.all(color: AppTheme.statusSkipped, width: 1.5);
                  child = const Icon(Icons.next_plan, color: AppTheme.statusSkipped, size: 14);
                } else if (dayLog.status == 'missed') {
                  cellColor = AppTheme.statusMissed.withOpacity(0.2);
                  cellBorder = Border.all(color: AppTheme.statusMissed, width: 1.5);
                  child = const Icon(Icons.close, color: AppTheme.statusMissed, size: 14);
                }
              }

              // Sorot hari ini dengan border tebal jika belum di-log
              final isToday = dateStr == DateFormatter.todayString;
              if (isToday && dayLog == null) {
                cellBorder = Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                );
              }

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: cellColor,
                        borderRadius: BorderRadius.circular(8),
                        border: cellBorder,
                      ),
                      child: child,
                    ),
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 16),
          // Legend Keterangan Warna
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _LegendItem(color: Colors.grey, label: 'Kosong'),
              _LegendItem(color: Colors.green, label: 'Done', isDoneStyle: true),
              _LegendItem(color: AppTheme.statusSkipped, label: 'Skip'),
              _LegendItem(color: AppTheme.statusMissed, label: 'Missed'),
            ],
          )
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
