import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../shared/providers/vault_provider.dart';
import '../../domain/entities/vision_item.dart';
import '../controllers/vision_board_controller.dart';

class MyWhyPage extends ConsumerStatefulWidget {
  const MyWhyPage({super.key});

  @override
  ConsumerState<MyWhyPage> createState() => _MyWhyPageState();
}

class _MyWhyPageState extends ConsumerState<MyWhyPage> {
  // Preset warna kartu yang estetik & premium
  static const List<Map<String, dynamic>> _cardColors = [
    {'name': 'Amethyst Purple', 'value': 0xff7e57c2},
    {'name': 'Lavender', 'value': 0xff9c27b0},
    {'name': 'Ocean Teal', 'value': 0xff00897b},
    {'name': 'Mint Green', 'value': 0xff2e7d32},
    {'name': 'Rose Gold', 'value': 0xffe91e63},
    {'name': 'Sunset Orange', 'value': 0xffe64a19},
    {'name': 'Calm Slate', 'value': 0xff546e7a},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isUnlocked = ref.read(vaultSecurityProvider).isUnlocked;
      if (!isUnlocked) {
        context.go('/vault');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final securityState = ref.watch(vaultSecurityProvider);
    final visionItemsAsync = ref.watch(visionBoardProvider);

    // Redirect jika dikunci
    if (!securityState.isUnlocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/vault');
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Amethyst palette
    final bgColor = isDark ? const Color(0xff0e0b16) : const Color(0xfff5f0fa);
    final accentPurple = const Color(0xffa586e0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/vault/dashboard');
        }
      },
      child: Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: accentPurple,
            secondary: accentPurple,
          ),
        ),
        child: Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black87),
              onPressed: () => context.go('/vault/dashboard'),
            ),
            title: Row(
              children: [
                Icon(Icons.psychology_rounded, color: accentPurple),
                const SizedBox(width: 10),
                Text(
                  'My Why - Papan Visi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: visionItemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Gagal memuat papan visi: $err')),
              data: (items) {
                if (items.isEmpty) {
                  return _buildEmptyState(theme, isDark, accentPurple);
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildVisionCard(item, isDark, theme);
                  },
                );
              },
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: accentPurple,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tulis Komitmen', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => _showAddEditDialog(context, null),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark, Color accentPurple) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: accentPurple.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.psychology_rounded, size: 72, color: accentPurple.withOpacity(0.8)),
            ),
            const SizedBox(height: 24),
            Text(
              'Papan Visi Masih Kosong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tulis surat komitmen untuk diri sendiri atau pengingat penting '
              'tentang mengapa Anda berjuang keluar dari kebiasaan buruk. '
              'Ini tersimpan secara aman di database lokal Anda.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white38 : Colors.black45,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('Mulai Menulis', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _showAddEditDialog(context, null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisionCard(VisionItem item, bool isDark, ThemeData theme) {
    final cardBg = Color(item.color);
    // Hitung apakah warna background terlalu terang/gelap untuk teks kontras
    final useWhiteText = ThemeData.estimateBrightnessForColor(cardBg) == Brightness.dark;
    final textColor = useWhiteText ? Colors.white : Colors.black87;
    final subTextColor = useWhiteText ? Colors.white70 : Colors.black54;

    return Card(
      color: cardBg,
      elevation: 3,
      shadowColor: cardBg.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () => _showViewDetailDialog(context, item),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pin icon or quotes mark decoration
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    color: useWhiteText ? Colors.white38 : Colors.black26,
                    size: 24,
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: useWhiteText ? Colors.white70 : Colors.black54,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showAddEditDialog(context, item);
                      } else if (value == 'delete') {
                        _showDeleteConfirm(context, item.id);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Ubah'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_rounded, color: Colors.redAccent, size: 18),
                            SizedBox(width: 8),
                            Text('Hapus', style: TextStyle(color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Title
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              // Body preview
              Expanded(
                child: Text(
                  item.content,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: subTextColor,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showViewDetailDialog(BuildContext context, VisionItem item) {
    final cardBg = Color(item.color);
    final useWhiteText = ThemeData.estimateBrightnessForColor(cardBg) == Brightness.dark;
    final textColor = useWhiteText ? Colors.white : Colors.black87;
    final subTextColor = useWhiteText ? Colors.white70 : Colors.black54;

    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      Icons.format_quote_rounded,
                      color: useWhiteText ? Colors.white38 : Colors.black26,
                      size: 32,
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: textColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      item.content,
                      style: TextStyle(
                        fontSize: 15,
                        color: subTextColor,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: textColor),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Edit'),
                onPressed: () {
                  Navigator.pop(context);
                  _showAddEditDialog(context, item);
                },
              ),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                icon: const Icon(Icons.delete_rounded, size: 18),
                label: const Text('Hapus'),
                onPressed: () {
                  Navigator.pop(context);
                  _showDeleteConfirm(context, item.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddEditDialog(BuildContext context, VisionItem? existingItem) {
    final isEdit = existingItem != null;
    final titleController = TextEditingController(text: existingItem?.title ?? '');
    final contentController = TextEditingController(text: existingItem?.content ?? '');
    
    // Default warna lavender jika baru, atau pakai warna yang ada
    int selectedColor = existingItem?.color ?? _cardColors[0]['value'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'Ubah Komitmen Anda' : 'Tulis Surat Komitmen Baru',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Judul Pengingat (misal: Alasan Saya Mulai)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contentController,
                      maxLines: 6,
                      minLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Isi Surat / Komitmen Detail',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Color Picker Row Title
                    const Text(
                      'Pilih Warna Kartu:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Horizontal color list
                    SizedBox(
                      height: 48,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _cardColors.length,
                        itemBuilder: (context, index) {
                          final c = _cardColors[index];
                          final isSelected = selectedColor == c['value'];
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedColor = c['value'];
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Color(c['value']),
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(
                                        color: Theme.of(context).colorScheme.primary,
                                        width: 3,
                                      )
                                    : Border.all(
                                        color: Colors.white24,
                                        width: 1,
                                      ),
                              ),
                              child: isSelected
                                  ? Icon(
                                      Icons.check,
                                      size: 16,
                                      color: ThemeData.estimateBrightnessForColor(Color(c['value'])) == Brightness.dark
                                          ? Colors.white
                                          : Colors.black87,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          child: const Text('Batal'),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(isEdit ? 'Simpan' : 'Tambahkan'),
                          onPressed: () {
                            final title = titleController.text.trim();
                            final content = contentController.text.trim();
                            if (title.isEmpty || content.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Judul dan isi tidak boleh kosong')),
                              );
                              return;
                            }

                            final item = VisionItem(
                              id: isEdit ? existingItem.id : const Uuid().v4(),
                              title: title,
                              content: content,
                              color: selectedColor,
                              createdAt: isEdit ? existingItem.createdAt : DateTime.now(),
                              updatedAt: DateTime.now(),
                            );

                            if (isEdit) {
                              ref.read(visionBoardProvider.notifier).updateVisionItem(item);
                            } else {
                              ref.read(visionBoardProvider.notifier).addVisionItem(item);
                            }

                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirm(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Hapus Komitmen?'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus surat komitmen/pengingat ini secara permanen dari Papan Visi Anda?',
          ),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Hapus'),
              onPressed: () {
                ref.read(visionBoardProvider.notifier).removeVisionItem(id);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
