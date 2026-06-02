import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/habit_list_controller.dart';
import '../widgets/habit_item_widget.dart';

/// Halaman utama (Home Screen) menampilkan daftar Habit aktif.
/// Menyediakan pull-to-refresh, ringkasan statistik sederhana, dan tombol tambah habit baru.
class HabitListPage extends ConsumerWidget {
  const HabitListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitListProvider);
    final authState = ref.watch(authControllerProvider);
    final user = authState.valueOrNull ?? AppUser.guest;

    return Scaffold(
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

              // Title Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Habit Aktif Anda',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Placeholder fitur filter ke depan
                        },
                        child: const Text('Filter'),
                      )
                    ],
                  ),
                ),
              ),

              // Daftar Habit Utama
              habitsAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => SliverFillRemaining(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text('Gagal memuat: $error', textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => ref.read(habitListProvider.notifier).refresh(),
                            child: const Text('Coba Lagi'),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                data: (habits) {
                  if (habits.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyHabitState(),
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
          context.push('/add-habit');
        },
        icon: const Icon(Icons.add),
        label: const Text('Habit Baru'),
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

    return habitsAsync.maybeWhen(
      data: (habits) {
        if (habits.isEmpty) return const SizedBox.shrink();
        
        final totalHabits = habits.length;
        
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
                'Progres Harian',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$totalHabits Kebiasaan Menunggumu!',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.stars, color: Colors.amber, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Tetap konsisten untuk menjaga streak tetap menyala.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            ],
          ),
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
