import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/utils/csv_habit_helper.dart';
import '../../../../core/utils/notification_service.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../habits/presentation/controllers/habit_list_controller.dart';
import '../../../../core/errors/failure.dart';
import '../../../../shared/widgets/collapsible_sidebar.dart';

/// Halaman Pengaturan Dailio untuk konfigurasi tema, notifikasi, dan manajemen data.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final habits = ref.watch(habitListProvider).valueOrNull ?? [];

    final isMobile = MediaQuery.of(context).size.width < 600;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xff111318)
            : Theme.of(context).scaffoldBackgroundColor,
        drawer: isMobile ? const CollapsibleSidebar(isDrawer: true) : null,
        appBar: AppBar(
          title: const Text('Pengaturan'),
          leading: isMobile
              ? Builder(
                  builder: (context) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
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
                        icon: const Icon(Icons.menu_rounded, size: 20),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        style: IconButton.styleFrom(
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Seksi Tampilan (Theme)
              _buildSectionTitle(context, 'Tampilan & Tema'),
              const SizedBox(height: 12),
              _buildSettingsCard(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilih Tema Aplikasi',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Atur warna dasar aplikasi agar sesuai dengan kenyamanan mata Anda.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        segments: const <ButtonSegment<ThemeMode>>[
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.system,
                            label: Text('Sistem'),
                            icon: Icon(Icons.settings_suggest_outlined),
                          ),
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.light,
                            label: Text('Terang'),
                            icon: Icon(Icons.light_mode_outlined),
                          ),
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.dark,
                            label: Text('Gelap'),
                            icon: Icon(Icons.dark_mode_outlined),
                          ),
                        ],
                        selected: <ThemeMode>{themeMode},
                        onSelectionChanged: (Set<ThemeMode> newSelection) {
                          ref.read(themeModeProvider.notifier).state = newSelection.first;
                        },
                        style: SegmentedButton.styleFrom(
                          selectedBackgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          selectedForegroundColor: Theme.of(context).colorScheme.primary,
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
  
              // 2. Seksi Notifikasi
              _buildSectionTitle(context, 'Notifikasi & Alarm'),
              const SizedBox(height: 12),
              _buildSettingsCard(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Uji Pengingat',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Kirim notifikasi tes instan untuk memastikan notifikasi lokal aktif di perangkat.',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: ElevatedButton.icon(
                        onPressed: () async {
                          await NotificationService.showTestNotification();
                        },
                        icon: const Icon(Icons.notification_important_outlined, size: 16),
                        label: const Text('Tes'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 24),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Minta Izin Ulang',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Minta persetujuan perizinan notifikasi & alarm tepat di sistem OS.',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: OutlinedButton(
                        onPressed: () async {
                          await NotificationService.requestPermissions();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Permintaan izin dikirim ke sistem OS.'),
                                backgroundColor: AppTheme.statusDone,
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Izin'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
  
              // 3. Seksi Data
              _buildSectionTitle(context, 'Pencadangan Data'),
              const SizedBox(height: 12),
              _buildSettingsCard(
                context,
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.statusSkipped.withOpacity(0.1),
                        child: const Icon(Icons.upload_file_rounded, color: AppTheme.statusSkipped),
                      ),
                      title: const Text(
                        'Ekspor Data ke CSV',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Cadangkan data habit Anda ke berkas .csv secara lokal.',
                        style: TextStyle(fontSize: 11),
                      ),
                      onTap: () => _exportHabits(context, habits),
                    ),
                    const Divider(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.statusDone.withOpacity(0.1),
                        child: const Icon(Icons.download_rounded, color: AppTheme.statusDone),
                      ),
                      title: const Text(
                        'Impor Data dari CSV',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Pulihkan data habit Anda dari berkas ekspor cadangan Dailio.',
                        style: TextStyle(fontSize: 11),
                      ),
                      onTap: () => _importHabits(context, ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
  
              // 4. Footer Info
              Center(
                child: Column(
                  children: [
                    Text(
                      'Dailio Habit Tracker',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Versi 1.1.0 • Built with 🌿 in Flutter',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, {required Widget child}) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }

  Future<void> _exportHabits(BuildContext context, List<dynamic> habits) async {
    try {
      // 1. Generate CSV content
      final List<dynamic> rawList = habits;
      final csvString = CsvHabitHelper.habitsToCsv(rawList.cast());

      // 2. Save in temporary directory
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/dailio_habits_backup.csv');
      await file.writeAsString(csvString);

      // 3. Share CSV file using native Share Sheet
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Dailio Habits Backup (.csv)',
        text: 'Berikut adalah file backup daftar kebiasaan Dailio saya! 🌱',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengekspor data: $e'),
          backgroundColor: AppTheme.statusMissed,
        ),
      );
    }
  }

  Future<void> _importHabits(BuildContext context, WidgetRef ref) async {
    try {
      // 1. Open native file picker to select .csv file
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      // 2. Read CSV file
      final file = File(result.files.single.path!);
      final csvContent = await file.readAsString();

      // 3. Parse CSV to List<Habit>
      final importedHabits = CsvHabitHelper.csvToHabits(csvContent);

      if (importedHabits.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File CSV kosong atau tidak sesuai dengan format ekspor Dailio.'),
            backgroundColor: AppTheme.statusSkipped,
          ),
        );
        return;
      }

      // 4. Import into SQLite
      int successCount = 0;
      for (final habit in importedHabits) {
        final res = await ref.read(habitListProvider.notifier).addHabit(habit);
        if (res is Success<void>) {
          successCount++;
        }
      }

      // 5. Visual SnackBar Feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil memulihkan $successCount dari ${importedHabits.length} kebiasaan! 🎉'),
          backgroundColor: AppTheme.statusDone,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengimpor data. Pastikan format CSV sesuai.\nError: $e'),
          backgroundColor: AppTheme.statusMissed,
        ),
      );
    }
  }
}
