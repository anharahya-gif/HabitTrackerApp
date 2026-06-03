import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/providers.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/habit_list_controller.dart';
import '../widgets/habit_item_widget.dart';
import '../../../../shared/widgets/collapsible_sidebar.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/presentation/controllers/task_list_controller.dart';
import '../../../tasks/presentation/pages/task_list_page.dart';


/// Provider reaktif untuk memperbarui jam setiap 10 detik secara background
final currentTimeProvider = StreamProvider.autoDispose<DateTime>((ref) {
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

/// Halaman utama (Home Screen) menampilkan daftar Habit aktif.
/// Menyediakan pull-to-refresh, ringkasan statistik sederhana, dan tombol tambah habit baru.
class HabitListPage extends ConsumerWidget {
  const HabitListPage({super.key});

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
    
    // Watch provider jam real-time
    final currentTimeAsync = ref.watch(currentTimeProvider);
    final currentDateTime = currentTimeAsync.valueOrNull ?? DateTime.now();

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      drawer: isMobile ? const CollapsibleSidebar(isDrawer: true) : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(habitListProvider.notifier).refresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Premium Gradient App Header
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
                                  builder: (context) => IconButton(
                                    icon: const Icon(Icons.menu_rounded, size: 28),
                                    onPressed: () => Scaffold.of(context).openDrawer(),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ),
                                const SizedBox(width: 16),
                              ],
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.isGuest ? 'Halo, Pejuang Habit!' : 'Halo, ${user.displayName}!',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Dailio',
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
                          // Premium Profile Icon / Settings reaktif ke Google OAuth
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
                      
                      // Ringkasan Statistik Singkat Visual Card
                      const _StatsBannerCard(),
                    ],
                  ),
                ),
              ),

              // 1. Kebiasaan Hari Ini Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0, bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kebiasaan Hari Ini',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Consumer(
                        builder: (context, ref, _) {
                          final activeFilter = ref.watch(habitCategoryFilterProvider);
                          final activeSort = ref.watch(habitSortOptionProvider);
                          final hasActiveChanges = activeFilter != 'Semua' || activeSort != HabitSortOption.closestTime;

                          return TextButton.icon(
                            onPressed: () => _showFilterSortBottomSheet(context, ref),
                            icon: const Icon(Icons.tune_rounded, size: 16),
                            label: Row(
                              children: [
                                const Text('Filter & Urutkan'),
                                if (hasActiveChanges) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.amber,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          );
                        },
                      )
                    ],
                  ),
                ),
              ),

              // 2. Daftar Kebiasaan Hari Ini
              habitsAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(child: Text('Gagal memuat kebiasaan: $error')),
                  ),
                ),
                data: (habits) {
                  if (habits.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: _SmallEmptyHabitState(),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final habit = habits[index];
                          return HabitItemWidget(habit: habit);
                        },
                        childCount: habits.length,
                      ),
                    ),
                  );
                },
              ),

              // 3. Tugas Hari Ini Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 24.0, bottom: 12.0),
                  child: Text(
                    'Tugas Hari Ini & Tertunda',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),

              // 4. Daftar Tugas Hari Ini
              tasksAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(child: Text('Gagal memuat tugas: $error')),
                  ),
                ),
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: _SmallEmptyTaskState(),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final task = tasks[index];
                          return TaskItemWidget(task: task);
                        },
                        childCount: tasks.length,
                      ),
                    ),
                  );
                },
              ),
              
              // Spacing Bawah untuk FAB agar tidak menghalangi item paling bawah
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddOptionsBottomSheet(context, ref);
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah Baru'),
      ),
    );
  }
}

/// Banner Widget Statistik Ringkas Berdesain Glassmorphism
class _StatsBannerCard extends ConsumerWidget {
  const _StatsBannerCard();

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
                      'Mulai Hari Produktifmu! 🌟',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Ketuk tombol di bawah untuk membuat habit pertama Anda, atau klik menu sidebar untuk beralih ke Tugas Harian.',
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
                    'Progres Harian Anda',
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
                          'Tugas Hari Ini',
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

/// UI State Kosong Premium (Ketika belum ada habit)
class _EmptyHabitState extends StatelessWidget {
  const _EmptyHabitState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.track_changes,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Mulai Langkah Pertamamu!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Anda belum memiliki kebiasaan aktif yang dilacak. Ketuk tombol di bawah untuk membuat habit pertamamu!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Bottom Sheet untuk memfilter dan mengurutkan habit secara premium
void _showFilterSortBottomSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xff111318),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Consumer(
        builder: (context, ref, _) {
          final activeFilter = ref.watch(habitCategoryFilterProvider);
          final activeSort = ref.watch(habitSortOptionProvider);

          final categories = [
            'Semua',
            'Kesehatan',
            'Produktivitas',
            'Kebugaran',
            'Mental/Pikiran',
            'Sosial/Hubungan',
            'Lainnya',
          ];

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
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

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter & Urutkan',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(habitCategoryFilterProvider.notifier).state = 'Semua';
                          ref.read(habitSortOptionProvider.notifier).state = HabitSortOption.closestTime;
                        },
                        child: const Text('Reset', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Colors.white10),

                  // Sorting Section
                  const Text(
                    'Urutkan Berdasarkan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SortChip(
                        label: 'Waktu Terdekat',
                        icon: Icons.access_time_rounded,
                        isSelected: activeSort == HabitSortOption.closestTime,
                        onSelected: () => ref.read(habitSortOptionProvider.notifier).state = HabitSortOption.closestTime,
                      ),
                      _SortChip(
                        label: 'Nama (A-Z)',
                        icon: Icons.sort_by_alpha_rounded,
                        isSelected: activeSort == HabitSortOption.alphabetical,
                        onSelected: () => ref.read(habitSortOptionProvider.notifier).state = HabitSortOption.alphabetical,
                      ),
                      _SortChip(
                        label: 'Terbaru',
                        icon: Icons.calendar_month_rounded,
                        isSelected: activeSort == HabitSortOption.newest,
                        onSelected: () => ref.read(habitSortOptionProvider.notifier).state = HabitSortOption.newest,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Filter Section
                  const Text(
                    'Filter Kategori',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = activeFilter == cat;
                        return ChoiceChip(
                          label: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Theme.of(context).colorScheme.primary,
                          backgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected 
                                  ? Colors.transparent 
                                  : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              ref.read(habitCategoryFilterProvider.notifier).state = cat;
                            }
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _SortChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onSelected;

  const _SortChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 14,
        color: isSelected ? Colors.white : theme.colorScheme.primary,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: theme.colorScheme.primary,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? Colors.transparent : theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      onSelected: (_) => onSelected(),
    );
  }
}

/// Small empty state for habits inline in the scrollable home dashboard list.
class _SmallEmptyHabitState extends StatelessWidget {
  const _SmallEmptyHabitState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.track_changes_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tidak Ada Kebiasaan',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Semua kebiasaan sudah dilacak atau belum ditambahkan hari ini.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
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

/// Small empty state for tasks inline in the scrollable home dashboard list.
class _SmallEmptyTaskState extends StatelessWidget {
  const _SmallEmptyTaskState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.statusDone.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.checklist_rounded,
                color: AppTheme.statusDone,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tidak Ada Tugas',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Semua tugas hari ini atau yang tertunda sudah selesai.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
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

/// Bottom Sheet to choose between adding a new Habit or a new Task.
void _showAddOptionsBottomSheet(BuildContext context, WidgetRef ref) {
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
              
              // Option 1: Habit
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
              
              // Option 2: Task
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

