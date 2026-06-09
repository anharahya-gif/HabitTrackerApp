import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/collapsible_sidebar.dart';
import '../../domain/entities/journal_entry.dart';
import '../controllers/journal_controller.dart';
import '../widgets/journal_editor_sheet.dart';

class JournalPage extends ConsumerStatefulWidget {
  const JournalPage({super.key});

  @override
  ConsumerState<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends ConsumerState<JournalPage> {
  void _showJournalEditor({JournalEntry? entry}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff161920),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return JournalEditorSheet(existingEntry: entry);
      },
    );
  }

  void _showDeleteConfirmation(JournalEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan'),
        content: const Text('Apakah Anda yakin ingin menghapus catatan harian ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await ref.read(journalControllerProvider.notifier).deleteJournal(entry.id);
              if (mounted) {
                result.fold(
                  onSuccess: (_) => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Catatan berhasil dihapus')),
                  ),
                  onFailure: (failure) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus catatan: ${failure.message}')),
                  ),
                );
              }
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

  String _formatDisplayDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length != 3) return dateStr;
      final year = parts[0];
      final monthInt = int.parse(parts[1]);
      final day = parts[2];

      final months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      return '$day ${months[monthInt - 1]} $year';
    } catch (_) {
      return dateStr;
    }
  }

  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'great':
        return const Color(0xff4ade80);
      case 'good':
        return const Color(0xff60a5fa);
      case 'neutral':
        return const Color(0xfffbbf24);
      case 'bad':
        return const Color(0xfffb7185);
      case 'terrible':
        return const Color(0xfff43f5e);
      default:
        return const Color(0xfffbbf24);
    }
  }

  @override
  Widget build(BuildContext context) {
    final journalEntriesAsync = ref.watch(journalControllerProvider);
    final todayEntry = ref.watch(todayJournalProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      drawer: isMobile ? const CollapsibleSidebar(isDrawer: true) : null,
      body: SafeArea(
        child: Row(
          children: [
            if (!isMobile) const CollapsibleSidebar(isDrawer: false),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
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
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.menu_rounded, size: 24),
                                      onPressed: () => Scaffold.of(context).openDrawer(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                              ],
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Refleksi & Suasana Hati',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Jurnal Harian',
                                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                          letterSpacing: -0.5,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Today Entry Quick Action
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.edit_note_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    todayEntry != null ? 'Refleksi Hari Ini Selesai' : 'Bagaimana Hari Anda?',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    todayEntry != null
                                        ? 'Anda merasa ${todayEntry.moodLabel} ${todayEntry.moodEmoji}'
                                        : 'Luangkan 1 menit untuk mencatat suasana hati Anda.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _showJournalEditor(entry: todayEntry),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(todayEntry != null ? 'Sunting' : 'Tulis'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(left: 20.0, top: 16.0, bottom: 12.0),
                      child: Text(
                        'Riwayat Perjalanan Anda',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
                      ),
                    ),
                  ),

                  // Journal Timeline List
                  journalEntriesAsync.when(
                    loading: () => const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => SliverFillRemaining(
                      child: Center(child: Text('Gagal memuat jurnal: $error')),
                    ),
                    data: (entries) {
                      if (entries.isEmpty) {
                        return const SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyJournalState(),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final entry = entries[index];
                              final isLast = index == entries.length - 1;
                              final moodColor = _getMoodColor(entry.mood);

                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Timeline Indicator Left
                                    Column(
                                      children: [
                                        Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: moodColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: moodColor.withOpacity(0.4),
                                                blurRadius: 6,
                                              )
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: isLast
                                              ? const SizedBox.shrink()
                                              : Container(
                                                  width: 2,
                                                  color: Colors.grey.withOpacity(0.2),
                                                ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),

                                    // Timeline content Card
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 20.0),
                                        child: Card(
                                          margin: EdgeInsets.zero,
                                          clipBehavior: Clip.antiAlias,
                                          child: InkWell(
                                            onTap: () => _showJournalEditor(entry: entry),
                                            onLongPress: () => _showDeleteConfirmation(entry),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        _formatDisplayDate(entry.date),
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: moodColor.withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(12),
                                                          border: Border.all(color: moodColor.withOpacity(0.2)),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Text(entry.moodEmoji),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              entry.moodLabel,
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                color: moodColor,
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (entry.content != null && entry.content!.isNotEmpty) ...[
                                                    const SizedBox(height: 12),
                                                    Text(
                                                      entry.content!,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            childCount: entries.length,
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
          ],
        ),
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton.extended(
              onPressed: () => _showJournalEditor(),
              icon: const Icon(Icons.add_comment_rounded),
              label: const Text('Catat Mood'),
            )
          : null,
    );
  }
}

class _EmptyJournalState extends StatelessWidget {
  const _EmptyJournalState();

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
              Icons.auto_stories_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Mulai Lembaran Baru!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Catatan jurnal harian Anda kosong. Ketuk tombol untuk mulai merekam perjalanan emosi dan refleksi Anda.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
