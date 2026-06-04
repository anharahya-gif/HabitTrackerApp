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
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const HabitItemWidget({
    super.key,
    required this.habit,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(habitStreakProvider(habit.id));
    final logTodayAsync = ref.watch(habitTodayLogProvider(habit.id));
    final trackingState = ref.watch(trackingProvider);

    final habitColor = Color(habit.color);
    final theme = Theme.of(context);

    return streakAsync.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      loading: () => const _HabitItemPlaceholder(),
      error: (err, _) => ListTile(title: Text('Error: $err')),
      data: (streak) {
        final currentStreak = streak?.currentStreak ?? 0;
        
        return logTodayAsync.when(
          skipLoadingOnRefresh: true,
          skipLoadingOnReload: true,
          loading: () => const _HabitItemPlaceholder(),
          error: (err, _) => ListTile(title: Text('Error: $err')),
          data: (logToday) {
            final isDone = logToday?.status == 'done';
            final isSkipped = logToday?.status == 'skipped';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap ?? () {
                    // Navigasi ke halaman detail habit
                    context.push('/habit/${habit.id}');
                  },
                  onLongPress: onLongPress,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Indicator Kategori Berwarna
                        Container(
                          width: 4,
                          height: 48,
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
                                const SizedBox(height: 6),
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
                                    const SizedBox(width: 8),
                                    Text(
                                      habit.type == 'daily' ? 'Harian' : 'Mingguan',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    if (habit.startTime != null && habit.endTime != null) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '•',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 11,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        _formatDuration(habit.startTime!, habit.endTime!),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                    if (habit.reminderTime != null) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '•',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        habit.reminderType == 'alarm'
                                            ? Icons.alarm_rounded
                                            : Icons.notifications_none_rounded,
                                        size: 11,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        habit.reminderTime!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Streak Indicator (🔥 Flame, hidden in selection mode)
                          if (currentStreak > 0 && !isSelectionMode)
                            Center(
                              child: Row(
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
                            ),
                          if (!isSelectionMode) const SizedBox(width: 16),

                          // Aksi Cepat: Tombol aksi ganda (Skip & Done) or Selection Checkmark
                          isSelectionMode
                              ? Center(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? Colors.transparent : theme.colorScheme.onSurface.withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                                        : null,
                                  ),
                                )
                              : Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Tombol Lewati (Skip)
                                      GestureDetector(
                                        onTap: trackingState is TrackingLoading
                                            ? null
                                            : () async {
                                                final newStatus = isSkipped ? 'missed' : 'skipped';
                                                await ref.read(trackingProvider.notifier).trackHabit(
                                                  habitId: habit.id,
                                                  date: DateFormatter.todayString,
                                                  status: newStatus,
                                                );
                                              },
                                        onLongPress: trackingState is TrackingLoading
                                            ? null
                                            : () {
                                                _showStatusOptions(context, ref);
                                              },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: isSkipped 
                                                ? AppTheme.statusSkipped 
                                                : Colors.transparent,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSkipped 
                                                  ? Colors.transparent 
                                                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.next_plan,
                                            color: isSkipped 
                                                ? Colors.white 
                                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Tombol Selesai (Done)
                                      GestureDetector(
                                        onTap: trackingState is TrackingLoading
                                            ? null
                                            : () async {
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
                                                _showStatusOptions(context, ref);
                                              },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: isDone 
                                                ? AppTheme.statusDone 
                                                : Colors.transparent,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isDone 
                                                  ? Colors.transparent 
                                                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.check,
                                            color: isDone 
                                                ? Colors.white 
                                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ],
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

  String _formatDuration(String start, String end) {
    try {
      final startParts = start.split(':');
      final endParts = end.split(':');
      if (startParts.length < 2 || endParts.length < 2) return '';
      final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      var endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      if (endMin < startMin) {
        endMin += 24 * 60;
      }
      final diff = endMin - startMin;
      final hours = diff ~/ 60;
      final minutes = diff % 60;
      if (hours > 0 && minutes > 0) {
        return '${hours}j${minutes}m';
      } else if (hours > 0) {
        return '${hours}j';
      } else {
        return '${minutes}m';
      }
    } catch (e) {
      return '';
    }
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
