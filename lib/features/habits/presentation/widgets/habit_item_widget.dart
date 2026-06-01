import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/providers.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../tracking/presentation/controllers/tracking_controller.dart';
import '../../domain/entities/habit.dart';

/// Widget item habit untuk daftar halaman beranda.
/// Menampilkan metadata, streak saat ini, dan menyediakan aksi penandaan cepat harian.
class HabitItemWidget extends ConsumerWidget {
  final Habit habit;

  const HabitItemWidget({super.key, required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(habitStreakProvider(habit.id));
    final logTodayAsync = ref.watch(habitTodayLogProvider(habit.id));
    final trackingState = ref.watch(trackingProvider);

    final habitColor = Color(habit.color);

    return streakAsync.when(
      loading: () => const _HabitItemPlaceholder(),
      error: (err, _) => ListTile(title: Text('Error: $err')),
      data: (streak) {
        final currentStreak = streak?.currentStreak ?? 0;
        
        return logTodayAsync.when(
          loading: () => const _HabitItemPlaceholder(),
          error: (err, _) => ListTile(title: Text('Error: $err')),
          data: (logToday) {
            final isDone = logToday?.status == 'done';
            final isSkipped = logToday?.status == 'skipped';
            
            Color statusColor = Colors.transparent;
            IconData statusIcon = Icons.circle_outlined;
            Color iconColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.3);

            if (isDone) {
              statusColor = AppTheme.statusDone.withOpacity(0.15);
              statusIcon = Icons.check_circle;
              iconColor = AppTheme.statusDone;
            } else if (isSkipped) {
              statusColor = AppTheme.statusSkipped.withOpacity(0.15);
              statusIcon = Icons.next_plan;
              iconColor = AppTheme.statusSkipped;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    // Navigasi ke halaman detail habit
                    context.push('/habit/${habit.id}');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Indicator Kategori Berwarna
                        Container(
                          width: 4,
                          height: 50,
                          decoration: BoxDecoration(
                            color: habitColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Metadata Habit
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                habit.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                  color: isDone 
                                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      habit.category,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    habit.type == 'daily' ? 'Harian' : 'Mingguan',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Streak Indicator (🔥 Flame)
                        if (currentStreak > 0)
                          Row(
                            children: [
                              const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                              const SizedBox(width: 2),
                              Text(
                                '$currentStreak',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(width: 16),

                        // Aksi Cepat: Toggle tracking harian
                        GestureDetector(
                          onTap: trackingState is TrackingLoading
                              ? null
                              : () async {
                                  // Toggle Done <-> Idle
                                  final newStatus = isDone ? 'missed' : 'done';
                                  await ref.read(trackingProvider.notifier).trackHabit(
                                    habitId: habit.id,
                                    date: DateFormatter.todayString,
                                    status: newStatus,
                                  );
                                },
                          onLongPress: trackingState is TrackingLoading
                              ? null
                              : () {
                                  // Menampilkan BottomSheet opsi status lengkap (Done, Skip, Miss)
                                  _showStatusOptions(context, ref);
                                },
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDone || isSkipped ? Colors.transparent : iconColor,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              statusIcon,
                              color: iconColor,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showStatusOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
                  child: Text(
                    'Pilih Status Hari Ini - "${habit.name}"',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.check_circle, color: AppTheme.statusDone),
                  title: const Text('Tandai Selesai (Done)'),
                  subtitle: const Text('Menambah jumlah streak harian Anda.'),
                  onTap: () {
                    ref.read(trackingProvider.notifier).trackHabit(
                          habitId: habit.id,
                          date: DateFormatter.todayString,
                          status: 'done',
                        );
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.next_plan, color: AppTheme.statusSkipped),
                  title: const Text('Lewati (Skipped)'),
                  subtitle: const Text('Hari libur/skip. Streak tidak terputus maupun bertambah.'),
                  onTap: () {
                    ref.read(trackingProvider.notifier).trackHabit(
                          habitId: habit.id,
                          date: DateFormatter.todayString,
                          status: 'skipped',
                        );
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cancel, color: AppTheme.statusMissed),
                  title: const Text('Gagal (Missed)'),
                  subtitle: const Text('Memutus streak harian Anda kembali ke 0.'),
                  onTap: () {
                    ref.read(trackingProvider.notifier).trackHabit(
                          habitId: habit.id,
                          date: DateFormatter.todayString,
                          status: 'missed',
                        );
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Placeholder Loading skeleton
class _HabitItemPlaceholder extends StatelessWidget {
  const _HabitItemPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        height: 82,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color?.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        ),
      ),
    );
  }
}
