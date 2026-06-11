import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/urge_log.dart';
import '../controllers/urge_log_controller.dart';

/// Bottom Sheet untuk mencatat urge/hasrat pemicu secara cepat.
class UrgeFormSheet extends ConsumerStatefulWidget {
  const UrgeFormSheet({super.key});

  @override
  ConsumerState<UrgeFormSheet> createState() => _UrgeFormSheetState();
}

class _UrgeFormSheetState extends ConsumerState<UrgeFormSheet> {
  int _selectedSeverity = 3; // Default 3 (sedang)
  String _selectedEmotion = 'Bosan'; // Default Bosan
  final _notesController = TextEditingController();

  final List<Map<String, String>> _emotions = [
    {'label': 'Stres', 'emoji': '😫'},
    {'label': 'Bosan', 'emoji': '🥱'},
    {'label': 'Sepi', 'emoji': '😔'},
    {'label': 'Lelah', 'emoji': '😴'},
    {'label': 'Sosmed', 'emoji': '📱'},
    {'label': 'Lainnya', 'emoji': '❓'},
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentPurple = const Color(0xffa586e0);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff120e1c) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Row(
              children: [
                Icon(Icons.bolt_rounded, color: Colors.amberAccent, size: 28),
                const SizedBox(width: 8),
                Text(
                  'Catat Urge / Hasrat',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Catat dorongan hasrat untuk mendeteksi pola pemicu di kemudian hari.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 24),

            // 1. Severity Level selector
            const Text(
              'Tingkat Keparahan Hasrat:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                final severityValue = index + 1;
                final isSelected = _selectedSeverity >= severityValue;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSeverity = severityValue;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Colors.orange.withOpacity(0.15) 
                          : (isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.orange : (isDark ? Colors.white10 : Colors.black12),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          color: isSelected ? Colors.orange : Colors.grey.withOpacity(0.4),
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$severityValue',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.orange : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // 2. Trigger Emotion Selector
            const Text(
              'Emosi Pemicu Terbesar:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _emotions.map((e) {
                final isSelected = _selectedEmotion == e['label'];
                return ChoiceChip(
                  label: Text('${e['emoji']} ${e['label']}'),
                  selected: isSelected,
                  selectedColor: accentPurple.withOpacity(0.25),
                  backgroundColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                  labelStyle: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected 
                        ? (isDark ? Colors.white : Colors.deepPurple)
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? accentPurple : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedEmotion = e['label']!;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // 3. Short context notes
            const Text(
              'Konteks / Catatan Pendek (Opsional):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Misal: Sedang begadang sendirian di kamar, lelah sehabis kerja.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 28),

            // Actions
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Batal'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Simpan Catatan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      final now = DateTime.now();
                      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                      final log = UrgeLog(
                        id: const Uuid().v4(),
                        date: dateStr,
                        time: timeStr,
                        severity: _selectedSeverity,
                        triggerEmotion: _selectedEmotion,
                        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                        createdAt: now,
                      );

                      ref.read(urgeLogProvider.notifier).addUrgeLog(log);
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.orange.shade800,
                          content: const Row(
                            children: [
                              Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                              SizedBox(width: 10),
                              Text('Catatan pemicu berhasil disimpan secara aman.'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
