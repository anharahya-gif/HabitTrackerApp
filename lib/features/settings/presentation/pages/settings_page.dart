import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/utils/csv_habit_helper.dart';
import '../../../../core/utils/csv_task_helper.dart';
import '../../../../core/utils/notification_service.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/theme/theme_settings_provider.dart';
import '../../../../shared/providers.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../habits/presentation/controllers/habit_list_controller.dart';
import '../../../tasks/presentation/controllers/task_list_controller.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../../core/errors/failure.dart';
import '../../../../shared/widgets/collapsible_sidebar.dart';

/// Halaman Pengaturan Dailio untuk konfigurasi tema, notifikasi, dan manajemen data.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final themeSettings = ref.watch(themeSettingsProvider);
    final habits = ref.watch(habitListProvider).valueOrNull ?? [];
    final tasks = ref.watch(taskListProvider).valueOrNull ?? [];

    final isMobile = MediaQuery.of(context).size.width < 600;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    const Divider(height: 28),
                    
                    // Theme Presets
                    const Text(
                      'Preset Palet Warna',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 80,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildPresetItem(context, ref, 'default', 'Default Slate', [const Color(0xFF111318), const Color(0xFF5AA9FF)]),
                          _buildPresetItem(context, ref, 'warm_coffee', 'Warm Coffee', [const Color(0xFF1F1A16), const Color(0xFFB5835A)]),
                          _buildPresetItem(context, ref, 'ocean_blue', 'Ocean Blue', [const Color(0xFF0B132B), const Color(0xFF00B4D8)]),
                          _buildPresetItem(context, ref, 'forest_green', 'Forest Green', [const Color(0xFF0D1F10), const Color(0xFF52B788)]),
                        ],
                      ),
                    ),
                    const Divider(height: 28),

                    // Custom Accent Colors
                    const Text(
                      'Warna Aksen Kustom',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 48,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          GestureDetector(
                            onTap: () => ref.read(themeSettingsProvider.notifier).setCustomAccentColor(null),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5), width: 1.5),
                              ),
                              child: Icon(Icons.block_flipped, size: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                            ),
                          ),
                          ...[
                            0xFF6366F1, // Indigo
                            0xFF10B981, // Emerald
                            0xFF3B82F6, // Blue
                            0xFFF59E0B, // Amber
                            0xFFEF4444, // Red
                            0xFFEC4899, // Pink
                            0xFF8B5CF6, // Purple
                            0xFFFF6B6B, // Soft Red
                            0xFF4D96FF, // Soft Blue
                            0xFF6BCB77, // Soft Green
                          ].map((colorHex) {
                            final color = Color(colorHex);
                            final isSelected = themeSettings.customAccentColor == colorHex;
                            return GestureDetector(
                              onTap: () => ref.read(themeSettingsProvider.notifier).setCustomAccentColor(color),
                              child: Container(
                                margin: const EdgeInsets.only(right: 12),
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                                  boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6, spreadRadius: 1)] : null,
                                ),
                                child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const Divider(height: 28),

                    // Font Selection
                    const Text(
                      'Gaya Huruf / Font',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: themeSettings.fontFamily,
                      items: ['Default', 'Inter', 'Poppins', 'Outfit', 'Lora'].map((font) {
                        return DropdownMenuItem(
                          value: font,
                          child: Text(
                            font,
                            style: TextStyle(
                              fontFamily: font == 'Default' ? null : font,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(themeSettingsProvider.notifier).setFontFamily(val);
                        }
                      },
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
  
              // 3. Seksi Pencadangan File Lokal (JSON)
              _buildSectionTitle(context, 'Pencadangan Data Lokal (JSON)'),
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
                        'Ekspor Cadangan Lengkap (JSON)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Ekspor seluruh data habits, logs, tugas, dan jurnal ke file JSON.',
                        style: TextStyle(fontSize: 11),
                      ),
                      onTap: () => _exportFullBackupJSON(context, ref),
                    ),
                    const Divider(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.statusDone.withOpacity(0.1),
                        child: const Icon(Icons.download_rounded, color: AppTheme.statusDone),
                      ),
                      title: const Text(
                        'Impor Cadangan Lengkap (JSON)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Pulihkan seluruh data Dailio Anda dari berkas JSON ekspor.',
                        style: TextStyle(fontSize: 11),
                      ),
                      onTap: () => _importFullBackupJSON(context, ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 4. Seksi Google Drive Cloud Backup
              _buildSectionTitle(context, 'Pencadangan Cloud (Google Drive)'),
              const SizedBox(height: 12),
              _buildSettingsCard(
                context,
                child: Consumer(
                  builder: (context, ref, _) {
                    final authState = ref.watch(authControllerProvider);
                    final autoBackupFreq = ref.watch(autoBackupFrequencyProvider);
                    final lastBackupTime = ref.watch(lastBackupTimeProvider);

                    final user = authState.valueOrNull ?? AppUser.guest;
                    final isLoggedIn = !user.isGuest && user.id != 'demo_user_google_123';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            child: const Icon(Icons.cloud_queue_rounded, color: Colors.blue),
                          ),
                          title: const Text(
                            'Status Sinkronisasi Cloud',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            isLoggedIn 
                                ? 'Terhubung dengan ${user.email}' 
                                : 'Google Drive memerlukan login Google aktif.',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: isLoggedIn
                              ? const Icon(Icons.check_circle_outline_rounded, color: AppTheme.statusDone)
                              : TextButton(
                                  onPressed: () => context.push('/profile'),
                                  child: const Text('Login'),
                                ),
                        ),
                        const Divider(height: 24),
                        
                        // Auto-Backup Frequency
                        const Text(
                          'Jadwal Auto-Backup',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: autoBackupFreq,
                          items: const [
                            DropdownMenuItem(value: 'off', child: Text('Mati (Off)', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'daily', child: Text('Setiap Hari (Daily)', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'weekly', child: Text('Setiap Minggu (Weekly)', style: TextStyle(fontSize: 13))),
                          ],
                          onChanged: isLoggedIn
                              ? (val) {
                                  if (val != null) {
                                    ref.read(autoBackupFrequencyProvider.notifier).setFrequency(val);
                                  }
                                }
                              : null,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Last backup time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Waktu Backup Terakhir:',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              _formatLastBackupTime(lastBackupTime),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Actions
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: isLoggedIn 
                                    ? () => _backupToGoogleDrive(context, ref)
                                    : null,
                                icon: const Icon(Icons.backup_rounded, size: 16),
                                label: const Text('Backup Sekarang', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: isLoggedIn 
                                    ? () => _restoreFromGoogleDrive(context, ref)
                                    : null,
                                icon: const Icon(Icons.settings_backup_restore_rounded, size: 16),
                                label: const Text('Pulihkan', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
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
                      'Versi 1.2.0 • Built with 🌿 in Flutter',
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

  Widget _buildPresetItem(BuildContext context, WidgetRef ref, String presetId, String title, List<Color> previewColors) {
    final activePreset = ref.watch(themeSettingsProvider).preset;
    final isSelected = activePreset == presetId;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => ref.read(themeSettingsProvider.notifier).setPreset(presetId),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 100,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: previewColors.map((c) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                ),
              )).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
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

  Future<void> _exportTasks(BuildContext context, List<Task> tasks) async {
    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda belum memiliki tugas untuk diekspor.'),
          backgroundColor: AppTheme.statusSkipped,
        ),
      );
      return;
    }

    try {
      final csvString = CsvTaskHelper.tasksToCsv(tasks);

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/dailio_tasks_backup.csv');
      await file.writeAsString(csvString);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Dailio Tasks Backup (.csv)',
        text: 'Berikut adalah file backup daftar tugas Dailio saya! 📋',
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

  Future<void> _importTasks(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      final file = File(result.files.single.path!);
      final csvContent = await file.readAsString();

      final importedTasks = CsvTaskHelper.csvToTasks(csvContent);

      if (importedTasks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File CSV kosong atau tidak sesuai dengan format ekspor tugas Dailio.'),
            backgroundColor: AppTheme.statusSkipped,
          ),
        );
        return;
      }

      int successCount = 0;
      for (final task in importedTasks) {
        final res = await ref.read(taskListProvider.notifier).addTask(task);
        if (res is Success<void>) {
          successCount++;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil memulihkan $successCount dari ${importedTasks.length} tugas! 🎉'),
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

  String _formatLastBackupTime(String timeStr) {
    if (timeStr == 'Belum pernah') return timeStr;
    try {
      final dt = DateTime.parse(timeStr);
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '${dt.day}/${dt.month}/${dt.year} $hour:$min';
    } catch (_) {
      return timeStr;
    }
  }

  Future<void> _exportFullBackupJSON(BuildContext context, WidgetRef ref) async {
    try {
      final backupData = await ref.read(backupServiceProvider).exportBackup();
      final jsonString = jsonEncode(backupData);

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/dailio_full_backup.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Dailio Full Backup (.json)',
        text: 'Berikut adalah file backup lengkap data Dailio saya! 🌿',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengekspor data backup: $e'),
            backgroundColor: AppTheme.statusMissed,
          ),
        );
      }
    }
  }

  Future<void> _importFullBackupJSON(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      final file = File(result.files.single.path!);
      final jsonContent = await file.readAsString();
      final Map<String, dynamic> backupMap = jsonDecode(jsonContent);

      if (!context.mounted) return;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Konfirmasi Pemulihan'),
          content: const Text(
            'Perhatian: Impor data cadangan ini akan MENGAPUS dan mengganti seluruh data kebiasaan, log, tugas, dan jurnal aktif saat ini di perangkat Anda. Tindakan ini tidak dapat dibatalkan.\n\nApakah Anda yakin ingin melanjutkan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.statusMissed),
              child: const Text('Ya, Impor'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Jalankan restorasi
      await ref.read(backupServiceProvider).importBackup(backupMap);

      // Refresh data
      await ref.read(habitListProvider.notifier).refresh();
      await ref.read(taskListProvider.notifier).refresh();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pemulihan database Dailio berhasil diselesaikan! 🎉'),
            backgroundColor: AppTheme.statusDone,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memulihkan data backup. Pastikan format file sesuai.\nError: $e'),
            backgroundColor: AppTheme.statusMissed,
          ),
        );
      }
    }
  }

  Future<void> _backupToGoogleDrive(BuildContext context, WidgetRef ref) async {
    // 1. Minta Drive Scope
    final hasScope = await ref.read(authRepositoryProvider).requestDriveScope();
    if (!hasScope) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin akses Google Drive ditolak oleh pengguna.'),
            backgroundColor: AppTheme.statusMissed,
          ),
        );
      }
      return;
    }

    // Tampilkan loading dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Mengunggah ke Google Drive...'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      final backupData = await ref.read(backupServiceProvider).exportBackup();
      final success = await ref.read(googleDriveServiceProvider).uploadBackup(backupData);

      if (context.mounted) {
        Navigator.pop(context); // Tutup loading dialog
      }

      if (success) {
        await ref.read(lastBackupTimeProvider.notifier).updateLastBackupTime();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Berhasil mencadangkan data ke Google Drive! ☁️'),
              backgroundColor: AppTheme.statusDone,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mengunggah data cadangan ke Google Drive.'),
              backgroundColor: AppTheme.statusMissed,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Tutup loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan saat mencadangkan: $e'),
            backgroundColor: AppTheme.statusMissed,
          ),
        );
      }
    }
  }

  Future<void> _restoreFromGoogleDrive(BuildContext context, WidgetRef ref) async {
    final hasScope = await ref.read(authRepositoryProvider).requestDriveScope();
    if (!hasScope) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin akses Google Drive ditolak oleh pengguna.'),
            backgroundColor: AppTheme.statusMissed,
          ),
        );
      }
      return;
    }

    // Tampilkan loading dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Mengunduh dari Google Drive...'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      final backupData = await ref.read(googleDriveServiceProvider).downloadBackup();

      if (context.mounted) {
        Navigator.pop(context); // Tutup loading dialog
      }

      if (backupData == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File cadangan tidak ditemukan di Google Drive Anda.'),
              backgroundColor: AppTheme.statusSkipped,
            ),
          );
        }
        return;
      }

      if (!context.mounted) return;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Konfirmasi Pemulihan Cloud'),
          content: const Text(
            'Perhatian: Pemulihan dari Google Drive akan MENGAPUS seluruh data aktif perangkat saat ini.\n\nApakah Anda yakin ingin melanjutkan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.statusMissed),
              child: const Text('Ya, Pulihkan'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Jalankan pemulihan
      await ref.read(backupServiceProvider).importBackup(backupData);

      // Refresh data
      await ref.read(habitListProvider.notifier).refresh();
      await ref.read(taskListProvider.notifier).refresh();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil memulihkan seluruh data dari Google Drive! 🎉'),
            backgroundColor: AppTheme.statusDone,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memulihkan cadangan Google Drive: $e'),
            backgroundColor: AppTheme.statusMissed,
          ),
        );
      }
    }
  }
}
