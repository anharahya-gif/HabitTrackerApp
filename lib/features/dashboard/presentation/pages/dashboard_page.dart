import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/providers.dart';
import '../../../../shared/widgets/collapsible_sidebar.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../habits/domain/entities/habit.dart';
import '../../../habits/presentation/controllers/habit_list_controller.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/presentation/controllers/task_list_controller.dart';
import '../../../tasks/presentation/pages/task_list_page.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../tracking/presentation/controllers/tracking_controller.dart';

/// Provider reaktif untuk memperbarui jam setiap 10 detik secara background di Dashboard
final dashboardTimeProvider = StreamProvider.autoDispose<DateTime>((ref) {
  final controller = StreamController<DateTime>();
  controller.add(DateTime.now());

  final timer = Timer.periodic(const Duration(seconds: 10), (_) {
    if (!controller.isClosed) {
      controller.add(DateTime.now());
    }
  });

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Halaman Dashboard Utama (Terpadu & Compact)
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  String _formatCurrentDate(DateTime now) {
    final weekdays = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];

    final dayName = weekdays[now.weekday - 1];
    final monthName = months[now.month - 1];
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$dayName, ${now.day} $monthName ${now.year} • $hour:$minute';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(filteredHabitsProvider);
    final tasksAsync = ref.watch(todayTasksProvider);
    final authState = ref.watch(authControllerProvider);
    final user = authState.valueOrNull ?? AppUser.guest;

    // Watch real-time clock
    final currentTimeAsync = ref.watch(dashboardTimeProvider);
    final currentDateTime = currentTimeAsync.valueOrNull ?? DateTime.now();

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      drawer: isMobile ? const CollapsibleSidebar(isDrawer: true) : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(habitListProvider.notifier).refresh();
            await ref.read(taskListProvider.notifier).refresh();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header Gradient Dashboard
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (isMobile) ...[
                                Builder(
                                  builder: (context) => Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.black.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white.withOpacity(0.08)
                                            : Colors.black.withOpacity(0.08),
                                        width: 1,
                                      ),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.menu_rounded, size: 24),
                                      onPressed: () => Scaffold.of(context).openDrawer(),
                                      constraints: const BoxConstraints(),
                                      style: IconButton.styleFrom(
                                        padding: const EdgeInsets.all(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                              ],
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.isGuest ? 'Halo, Pejuang Dailio!' : 'Halo, ${user.displayName}!',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Dashboard',
                                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                          letterSpacing: -0.5,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          size: 12,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatCurrentDate(currentDateTime),
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 11,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => context.push('/profile'),
                            child: authState.maybeWhen(
                              data: (user) {
                                return Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: user.isAuthenticated 
                                          ? AppTheme.statusDone 
                                          : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xff1a1d24),
                                    backgroundImage: user.photoUrl != null 
                                        ? NetworkImage(user.photoUrl!) 
                                        : null,
                                    child: user.photoUrl == null
                                        ? const Icon(Icons.person_outline, size: 20)
                                        : null,
                                  ),
                                );
                              },
                              orElse: () => Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: const CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.transparent,
                                  child: Icon(Icons.person_outline, size: 20),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 24),
                      const _DashboardStatsBannerCard(),
                    ],
                  ),
                ),
              ),

              // Bagian 1: Kebiasaan Hari Ini
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 12.0, bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kebiasaan Hari Ini',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/habits'),
                        child: const Row(
                          children: [
                            Text('Lihat Semua', style: TextStyle(fontSize: 12)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded, size: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              habitsAsync.when(
                skipLoadingOnRefresh: true,
                skipLoadingOnReload: true,
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),
                ),
                error: (error, _) => SliverToBoxAdapter(
                  child: Center(child: Padding(padding: const EdgeInsets.all(12), child: Text('Gagal memuat: $error'))),
                ),
                data: (habits) {
                  if (habits.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: _DashboardSmallEmpty(
                        title: 'Tidak Ada Kebiasaan',
                        description: 'Semua kebiasaan sudah dilacak atau belum dibuat hari ini.',
                        icon: Icons.track_changes_rounded,
                        color: Colors.indigo,
                      ),
                    );
                  }

                  // Tampilkan maksimal 3 kebiasaan saja agar compact di Dashboard
                  final displayHabits = habits.take(3).toList();

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final habit = displayHabits[index];
                          return _CompactHabitRow(habit: habit);
                        },
                        childCount: displayHabits.length,
                      ),
                    ),
                  );
                },
              ),

              // Bagian 2: Tugas Hari Ini
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tugas Hari Ini & Tertunda',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/tasks'),
                        child: const Row(
                          children: [
                            Text('Lihat Semua', style: TextStyle(fontSize: 12)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded, size: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              tasksAsync.when(
                skipLoadingOnRefresh: true,
                skipLoadingOnReload: true,
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),
                ),
                error: (error, _) => SliverToBoxAdapter(
                  child: Center(child: Padding(padding: const EdgeInsets.all(12), child: Text('Gagal memuat: $error'))),
                ),
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: _DashboardSmallEmpty(
                        title: 'Tidak Ada Tugas',
                        description: 'Semua tugas hari ini atau yang tertunda sudah selesai.',
                        icon: Icons.checklist_rounded,
                        color: AppTheme.statusDone,
                      ),
                    );
                  }

                  // Tampilkan maksimal 3 tugas saja agar compact di Dashboard
                  final displayTasks = tasks.take(3).toList();

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final task = displayTasks[index];
                          return _CompactTaskRow(task: task);
                        },
                        childCount: displayTasks.length,
                      ),
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 90),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDashboardAddOptions(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Baru'),
      ),
    );
  }
}

/// Double progress banner khusus dashboard
class _DashboardStatsBannerCard extends ConsumerWidget {
  const _DashboardStatsBannerCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitListProvider);
    final tasksAsync = ref.watch(todayTasksProvider);

    return habitsAsync.maybeWhen(
      data: (habits) {
        return tasksAsync.maybeWhen(
          data: (tasks) {
            if (habits.isEmpty && tasks.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat Datang di Dailio! 🌟',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Mulai kelola rutinitas dan agenda harian Anda dengan menekan tombol (+) Tambah Baru di bawah.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }

            final totalHabits = habits.length;
            final completedHabits = habits.where((habit) {
              final logAsync = ref.watch(habitTodayLogProvider(habit.id));
              return logAsync.valueOrNull?.status == 'done';
            }).length;

            final totalTasks = tasks.length;
            final completedTasks = tasks.where((t) => t.isCompleted).length;

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ringkasan Produktivitas Hari Ini',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (totalHabits > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Kebiasaan Hari Ini',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          '$completedHabits dari $totalHabits selesai',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: totalHabits > 0 ? (completedHabits / totalHabits) : 0,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 6,
                      ),
                    ),
                  ],
                  if (totalHabits > 0 && totalTasks > 0) const SizedBox(height: 16),
                  if (totalTasks > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tugas Harian',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          '$completedTasks dari $totalTasks selesai',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: totalTasks > 0 ? (completedTasks / totalTasks) : 0,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          orElse: () => const SizedBox.shrink(),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// Widget Baris Kebiasaan Compact khusus Dashboard
class _CompactHabitRow extends ConsumerWidget {
  final Habit habit;

  const _CompactHabitRow({required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logTodayAsync = ref.watch(habitTodayLogProvider(habit.id));
    final trackingState = ref.watch(trackingProvider);
    final theme = Theme.of(context);
    final habitColor = Color(habit.color);

    return logTodayAsync.maybeWhen(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      data: (logToday) {
        final isDone = logToday?.status == 'done';
        final isSkipped = logToday?.status == 'skipped';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.06),
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push('/habit/${habit.id}'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                child: Row(
                  children: [
                  // Dot warna tema habit
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: habitColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Judul habit (Strikethrough jika Done)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                            color: isDone 
                                ? theme.colorScheme.onSurface.withOpacity(0.5)
                                : theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (habit.reminderTime != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            habit.reminderTime!,
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: Colors.grey),
                          ),
                        ]
                      ],
                    ),
                  ),
                  // Dua tombol centang & skip cepat
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Skip button
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
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isSkipped ? AppTheme.statusSkipped : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSkipped
                                  ? Colors.transparent
                                  : theme.colorScheme.onSurface.withOpacity(0.12),
                              width: 1.2,
                            ),
                          ),
                          child: Icon(
                            Icons.next_plan,
                            color: isSkipped ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.3),
                            size: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Done button
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
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isDone ? AppTheme.statusDone : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDone
                                  ? Colors.transparent
                                  : theme.colorScheme.onSurface.withOpacity(0.12),
                              width: 1.2,
                            ),
                          ),
                          child: Icon(
                            Icons.check,
                            color: isDone ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.3),
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// Widget Baris Tugas Compact khusus Dashboard
class _CompactTaskRow extends ConsumerWidget {
  final Task task;

  const _CompactTaskRow({required this.task});

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppTheme.statusMissed;
      case 'medium':
        return AppTheme.statusSkipped;
      case 'low':
      default:
        return AppTheme.accentPrimary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final priorityColor = _getPriorityColor(task.priority);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.06),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => showTaskFormBottomSheet(context, ref, task: task),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            child: Row(
            children: [
              // Prioritas Bar Pendek di Sisi Kiri
              Container(
                width: 3,
                height: 24,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              const SizedBox(width: 12),
              // Checkbox interaktif
              GestureDetector(
                onTap: () {
                  ref.read(taskListProvider.notifier).toggleTaskCompletion(task.id);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: task.isCompleted ? AppTheme.statusDone : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: task.isCompleted
                          ? Colors.transparent
                          : theme.colorScheme.onSurface.withOpacity(0.12),
                      width: 1.2,
                    ),
                  ),
                  child: task.isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 13)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              // Judul tugas
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted
                        ? theme.colorScheme.onSurface.withOpacity(0.5)
                        : theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}

/// Widget Empty State Kecil khusus Dashboard
class _DashboardSmallEmpty extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _DashboardSmallEmpty({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.04),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 11,
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
}

/// Menampilkan dialog bottom sheet pilihan tambah habit/tugas di Dashboard
void _showDashboardAddOptions(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xff111318),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 20),
              Text(
                'Tambah Baru',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pilih apa yang ingin Anda tambahkan hari ini',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
              const Divider(height: 32, color: Colors.white10),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.1),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.track_changes_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: const Text(
                  'Tambah Kebiasaan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: const Text(
                  'Bangun rutinitas harian atau mingguan yang positif',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/add-habit');
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.1),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.statusDone.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.checklist_rounded,
                    color: AppTheme.statusDone,
                  ),
                ),
                title: const Text(
                  'Tambah Tugas',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: const Text(
                  'Catat target atau pekerjaan yang harus diselesaikan',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () {
                  Navigator.pop(context);
                  showTaskFormBottomSheet(context, ref);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    },
  );
}
