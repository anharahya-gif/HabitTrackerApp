import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/journal_entry.dart';
import '../controllers/journal_controller.dart';
import 'mood_selector_widget.dart';

class JournalEditorSheet extends ConsumerStatefulWidget {
  final JournalEntry? existingEntry;

  const JournalEditorSheet({
    super.key,
    this.existingEntry,
  });

  @override
  ConsumerState<JournalEditorSheet> createState() => _JournalEditorSheetState();
}

class _JournalEditorSheetState extends ConsumerState<JournalEditorSheet> {
  final _textController = TextEditingController();
  String? _selectedMood;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      _textController.text = widget.existingEntry!.content ?? '';
      _selectedMood = widget.existingEntry!.mood;
    } else {
      _selectedMood = 'neutral'; // Default mood
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih suasana hati (mood) Anda terlebih dahulu')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final entry = JournalEntry(
      id: widget.existingEntry?.id ?? const Uuid().v4(),
      date: widget.existingEntry?.date ?? todayStr,
      mood: _selectedMood!,
      content: _textController.text.trim().isNotEmpty ? _textController.text.trim() : null,
      createdAt: widget.existingEntry?.createdAt ?? now,
      updatedAt: now,
    );

    final result = await ref.read(journalControllerProvider.notifier).saveJournal(entry);

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      result.fold(
        onSuccess: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Refleksi harian berhasil disimpan!')),
          );
          Navigator.pop(context);
        },
        onFailure: (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan refleksi harian: ${failure.message}')),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existingEntry != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
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
              isEdit ? 'Perbarui Catatan Harian' : 'Tulis Catatan Hari Ini',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bagaimana perasaan Anda hari ini? Ceritakan refleksi singkat Anda.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),

            // Mood Selector
            MoodSelectorWidget(
              selectedMood: _selectedMood,
              onMoodSelected: (mood) {
                setState(() {
                  _selectedMood = mood;
                });
              },
            ),
            const SizedBox(height: 28),

            // Content input
            TextFormField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: 'Refleksi Harian (Opsional)',
                hintText: 'Tulis hal-hal yang Anda syukuri atau pelajari hari ini...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 4,
              maxLength: 500,
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                return Text(
                  '$currentLength/$maxLength',
                  style: TextStyle(
                    fontSize: 11,
                    color: currentLength > maxLength! ? theme.colorScheme.error : Colors.grey,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        isEdit ? 'Simpan Perubahan' : 'Simpan Catatan',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
