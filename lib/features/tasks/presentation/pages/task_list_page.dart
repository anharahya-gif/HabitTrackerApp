import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/collapsible_sidebar.dart';
import '../../domain/entities/task.dart';
import '../controllers/task_list_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/domain/entities/app_user.dart';

class TaskListPage extends ConsumerWidget {
  const TaskListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(filteredTasksProvider);
    final allTasksRaw = ref.watch(taskListProvider);
    final authState = ref.watch(authControllerProvider);
    final user = authState.valueOrNull ?? AppUser.guest;

    final isMobile = MediaQuery.of(context).size.width < 600;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
      drawer: isMobile ? const CollapsibleSidebar(isDrawer: true) : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(taskListProvider.notifier).refresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Premium Header
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
                                    user.isGuest ? 'Halo, Pejuang Produktif!' : 'Halo, ${user.displayName}!',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tugas Harian',
                                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                          letterSpacing: -0.5,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Profile
                          GestureDetector(
                            onTap: () => Navigator.of(context).pushNamed('/profile'), // Handled or fallback
                            child: Container(
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
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Stats Banner
                      _TaskStatsBanner(allTasks: allTasksRaw.valueOrNull ?? []),
                    ],
                  ),
                ),
              ),

              // Filter Tabs & Config Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Status Segmented Filter
                      const _StatusFilterSegmented(),
                      
                      // Filter & Sort Bottom Sheet Trigger
                      IconButton(
                        icon: const Icon(Icons.tune_rounded),
                        onPressed: () => _showFilterSortBottomSheet(context, ref),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.2),
                        ),
                      )
                    ],
                  ),
                ),
              ),

              // Task List
              tasksAsync.when(
                skipLoadingOnRefresh: true,
                skipLoadingOnReload: true,
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => SliverFillRemaining(
                  child: Center(
                    child: Text('Gagal memuat tugas: $error'),
                  ),
                ),
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyTasksState(),
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

              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTaskFormBottomSheet(context, ref),
        icon: const Icon(Icons.playlist_add_rounded),
        label: const Text('Tugas Baru'),
      ),
    ));
  }
}

/// Statistics card representing completed tasks vs total tasks.
class _TaskStatsBanner extends StatelessWidget {
  final List<Task> allTasks;

  const _TaskStatsBanner({required this.allTasks});

  @override
  Widget build(BuildContext context) {
    if (allTasks.isEmpty) return const SizedBox.shrink();

    final total = allTasks.length;
    final completed = allTasks.where((t) => t.isCompleted).length;
    final percent = total > 0 ? (completed / total) : 0.0;

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
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progres Tugas',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$completed dari $total tugas selesai',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Segmented Filter Buttons for Status: Semua, Belum Selesai, Selesai.
class _StatusFilterSegmented extends ConsumerWidget {
  const _StatusFilterSegmented();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeStatus = ref.watch(taskStatusFilterProvider);
    final theme = Theme.of(context);

    final options = ['Semua', 'Belum Selesai', 'Selesai'];

    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isSelected = activeStatus == opt;
          return GestureDetector(
            onTap: () => ref.read(taskStatusFilterProvider.notifier).state = opt,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Text(
                opt,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Empty state when no tasks match the filter.
class _EmptyTasksState extends StatelessWidget {
  const _EmptyTasksState();

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
              Icons.checklist_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Semua Bersih!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tidak ada tugas yang perlu dikerjakan. Ketuk tombol di bawah untuk menambahkan tugas baru.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Single Task item rendering.
class TaskItemWidget extends ConsumerWidget {
  final Task task;

  const TaskItemWidget({required this.task});

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppTheme.statusMissed; // Crimson/Red
      case 'medium':
        return AppTheme.statusSkipped; // Yellow/Amber
      case 'low':
      default:
        return AppTheme.accentPrimary; // Blue
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return 'Tinggi';
      case 'medium':
        return 'Sedang';
      case 'low':
      default:
        return 'Rendah';
    }
  }

  String _formatDueDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final priorityColor = _getPriorityColor(task.priority);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showTaskFormBottomSheet(context, ref, task: task),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Priority Bar Indicator
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),

                // Interactive Animated Checklist Circle
                GestureDetector(
                  onTap: () {
                    ref.read(taskListProvider.notifier).toggleTaskCompletion(task.id);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: task.isCompleted ? AppTheme.statusDone : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.isCompleted
                            ? Colors.transparent
                            : theme.colorScheme.onSurface.withOpacity(0.15),
                        width: 1.5,
                      ),
                    ),
                    child: task.isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),

                // Task Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          color: task.isCompleted
                              ? theme.colorScheme.onSurface.withOpacity(0.5)
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      if (task.description != null && task.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),

                      // Meta Badges
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          // Category
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              task.category,
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),

                          // Priority
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: priorityColor.withOpacity(0.15)),
                            ),
                            child: Text(
                              _getPriorityLabel(task.priority),
                              style: TextStyle(
                                fontSize: 10,
                                color: priorityColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          // Due Date
                          if (task.dueDate != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 11,
                                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDueDate(task.dueDate!),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Delete Button
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  onPressed: () {
                    _showDeleteConfirmation(context, ref, task);
                  },
                  color: theme.colorScheme.error.withOpacity(0.8),
                  style: IconButton.styleFrom(
                    hoverColor: theme.colorScheme.error.withOpacity(0.08),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Tugas'),
        content: Text('Apakah Anda yakin ingin menghapus tugas "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              ref.read(taskListProvider.notifier).removeTask(task.id);
              Navigator.pop(context);
            },
            child: Text(
              'Hapus',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter and Sort Bottom Sheet modal.
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
          final activeCategory = ref.watch(taskCategoryFilterProvider);
          final activeSort = ref.watch(taskSortOptionProvider);

          final categories = [
            'Semua',
            'Kerja',
            'Belajar',
            'Kesehatan',
            'Belanja',
            'Lainnya',
          ];

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
                          ref.read(taskCategoryFilterProvider.notifier).state = 'Semua';
                          ref.read(taskSortOptionProvider.notifier).state = TaskSortOption.newest;
                        },
                        child: const Text('Reset', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Colors.white10),

                  // Sorting
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
                        label: 'Terbaru',
                        icon: Icons.calendar_month_rounded,
                        isSelected: activeSort == TaskSortOption.newest,
                        onSelected: () => ref.read(taskSortOptionProvider.notifier).state = TaskSortOption.newest,
                      ),
                      _SortChip(
                        label: 'Skala Prioritas',
                        icon: Icons.priority_high_rounded,
                        isSelected: activeSort == TaskSortOption.priority,
                        onSelected: () => ref.read(taskSortOptionProvider.notifier).state = TaskSortOption.priority,
                      ),
                      _SortChip(
                        label: 'Tenggat Waktu',
                        icon: Icons.access_time_rounded,
                        isSelected: activeSort == TaskSortOption.dueDate,
                        onSelected: () => ref.read(taskSortOptionProvider.notifier).state = TaskSortOption.dueDate,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Category Filter
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
                        final isSelected = activeCategory == cat;
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
                              ref.read(taskCategoryFilterProvider.notifier).state = cat;
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

/// Shows the Add/Edit Task Bottom Sheet.
void showTaskFormBottomSheet(BuildContext context, WidgetRef ref, {Task? task}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xff161920),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return TaskFormBottomSheet(task: task);
    },
  );
}

class TaskFormBottomSheet extends ConsumerStatefulWidget {
  final Task? task;

  const TaskFormBottomSheet({this.task});

  @override
  ConsumerState<TaskFormBottomSheet> createState() => TaskFormBottomSheetState();
}

class TaskFormBottomSheetState extends ConsumerState<TaskFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _priority;
  late String _category;
  DateTime? _dueDate;

  final List<String> _categories = ['Kerja', 'Belajar', 'Kesehatan', 'Belanja', 'Lainnya'];
  final List<String> _priorities = ['low', 'medium', 'high'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _priority = widget.task?.priority ?? 'medium';
    _category = widget.task?.category ?? 'Lainnya';
    _dueDate = widget.task?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatDueDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (pickedDate != null) {
      setState(() {
        _dueDate = pickedDate;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final id = widget.task?.id ?? const Uuid().v4();
    final now = DateTime.now();

    final task = Task(
      id: id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      dueDate: _dueDate,
      priority: _priority,
      category: _category,
      isCompleted: widget.task?.isCompleted ?? false,
      completedAt: widget.task?.completedAt,
      createdAt: widget.task?.createdAt ?? now,
      updatedAt: now,
      isSynced: false,
    );

    if (widget.task == null) {
      ref.read(taskListProvider.notifier).addTask(task);
    } else {
      ref.read(taskListProvider.notifier).updateTask(task);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.task != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
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

              Text(
                isEdit ? 'Sunting Tugas' : 'Tugas Baru',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Title input
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Tugas',
                  hintText: 'Masukkan judul tugas...',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Judul tugas tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description input
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi (Opsional)',
                  hintText: 'Masukkan deskripsi...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // Category Choice Chips
              const Text(
                'Kategori',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _category == cat;
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
                      selectedColor: theme.colorScheme.primary,
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected
                              ? Colors.transparent
                              : theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _category = cat;
                          });
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Priority Choice Chips
              const Text(
                'Prioritas',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Row(
                children: _priorities.map((p) {
                  final isSelected = _priority == p;
                  final label = p == 'high'
                      ? 'Tinggi'
                      : p == 'medium'
                          ? 'Sedang'
                          : 'Rendah';
                  Color chipColor = AppTheme.accentPrimary;
                  if (p == 'high') chipColor = AppTheme.statusMissed;
                  if (p == 'medium') chipColor = AppTheme.statusSkipped;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: chipColor,
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected ? Colors.transparent : theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _priority = p;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Due Date Picker trigger
              InkWell(
                onTap: _pickDueDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tenggat Waktu',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _dueDate != null ? _formatDueDate(_dueDate!) : 'Pilih Tenggat Waktu (Opsional)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: _dueDate != null ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (_dueDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            setState(() {
                              _dueDate = null;
                            });
                          },
                        )
                      else
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isEdit ? 'Simpan Perubahan' : 'Tambah Tugas',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
