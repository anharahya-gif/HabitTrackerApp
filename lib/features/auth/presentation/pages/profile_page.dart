import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/csv_habit_helper.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../habits/domain/entities/habit.dart';
import '../../../habits/presentation/controllers/habit_list_controller.dart';
import '../../domain/entities/app_user.dart';
import '../controllers/auth_controller.dart';
import '../../../../shared/providers.dart';
import '../../../../core/utils/dummy_seeder.dart';

/// Halaman Profil Pengguna Dailio berdesain premium.
/// Mendukung login Google reaktif, keluar akun, info sinkronisasi SQLite lokal,
/// serta penyediaan fitur Demo Bypass saat verifikasi asli di emulator terkendala.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xff111318), // Background Calm Productivity Dark
      appBar: AppBar(
        title: const Text('Profil Dailio'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: authState.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentPrimary)),
              SizedBox(height: 16),
              Text('Memproses autentikasi...', style: TextStyle(color: Color(0xff94a3b8))),
            ],
          ),
        ),
        error: (error, _) => _buildErrorScreen(context, ref, error.toString()),
        data: (user) {
          final habits = ref.watch(habitListProvider).valueOrNull ?? [];
          return _buildProfileContent(context, ref, user, habits);
        },
      ),
    );
  }

  /// Membangun antarmuka konten profil utama
  Widget _buildProfileContent(BuildContext context, WidgetRef ref, AppUser user, List<Habit> habits) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),

          // 1. Tampilan Avatar & Info Akun Utama
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                // Container Avatar Lingkaran Ganda
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: user.isAuthenticated 
                          ? AppTheme.statusDone.withOpacity(0.3) 
                          : AppTheme.accentPrimary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: const Color(0xff1a1d24),
                    backgroundImage: user.photoUrl != null 
                        ? NetworkImage(user.photoUrl!) 
                        : null,
                    child: user.photoUrl == null
                        ? Icon(
                            user.isGuest ? Icons.person_outline : Icons.spa_outlined,
                            size: 48,
                            color: user.isGuest ? AppTheme.accentPrimary : AppTheme.statusDone,
                          )
                        : null,
                  ),
                ),
                // Badge Indikator Status Akun di atas Avatar
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: user.isAuthenticated ? AppTheme.statusDone : AppTheme.accentPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xff111318), width: 2),
                  ),
                  child: Icon(
                    user.isAuthenticated ? Icons.verified : Icons.lock_outline,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Nama Pengguna
          Text(
            user.displayName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xffe2e8f0),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),

          // Email Pengguna
          Text(
            user.email,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xff94a3b8),
            ),
          ),
          const SizedBox(height: 32),

          // 2. Banner Status Integrasi & Database
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xff1a1d24),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: user.isAuthenticated 
                    ? AppTheme.statusDone.withOpacity(0.12)
                    : AppTheme.accentPrimary.withOpacity(0.12),
              ),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: user.isAuthenticated 
                        ? AppTheme.statusDone.withOpacity(0.1)
                        : AppTheme.accentPrimary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    user.isAuthenticated ? Icons.cloud_done_outlined : Icons.storage_outlined,
                    color: user.isAuthenticated ? AppTheme.statusDone : AppTheme.accentPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Keterangan Teks
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.isAuthenticated ? 'Cloud Sinkronisasi Aktif' : 'Mode Tamu (Guest Mode)',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xffe2e8f0),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.isAuthenticated 
                            ? 'Seluruh data habit Anda tersimpan di cloud & siap diakses dari HP mana pun.'
                            : 'Aplikasi berjalan offline. Data habit Anda tersimpan dengan aman di SQLite lokal Anda.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xff94a3b8),
                          height: 1.4,
                        ),
                      ),
                      if (user.isAuthenticated) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 36,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Sedang menyelaraskan data dengan cloud...'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                              try {
                                await ref.read(syncServiceProvider).syncData(user.id);
                                
                                // Refresh data lokal di UI setelah sukses ditarik/unggah
                                ref.read(habitListProvider.notifier).refresh();
                                
                                // Invalidate semua streak & log provider agar UI terupdate
                                final habits = ref.read(habitListProvider).valueOrNull ?? [];
                                for (final h in habits) {
                                  ref.invalidate(habitStreakProvider(h.id));
                                  ref.invalidate(habitTodayLogProvider(h.id));
                                }


                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Sinkronisasi sukses! Data aman di cloud. 🌱'),
                                    backgroundColor: AppTheme.statusDone,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal sinkronisasi: $e'),
                                    backgroundColor: AppTheme.statusMissed,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.statusDone.withOpacity(0.15),
                              foregroundColor: AppTheme.statusDone,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            icon: const Icon(Icons.sync, size: 16),
                            label: const Text(
                              'Sinkronkan Sekarang',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2.5. Cadangan Data Lokal (.xml) Ekspor & Impor
          _buildBackupSection(context, ref, habits),

          if (kDebugMode) ...[
            const SizedBox(height: 24),
            // Tombol Seeder Dummy Sementara
            _buildDummySeederButton(context, ref),
          ],

          const SizedBox(height: 32),

          // 3. Tombol Aksi Autentikasi Utama
          if (user.isGuest) ...[
            // Tombol Login Google Asli
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(authControllerProvider.notifier).signInWithGoogle(useDemoBypass: false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xff0f172a),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                icon: const GoogleLogoIcon(size: 20),
                label: const Text(
                  'Hubungkan Akun Google',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Tombol Simulasi Akun Demo (Bypass)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(authControllerProvider.notifier).signInWithGoogle(useDemoBypass: true);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.statusDone,
                  side: const BorderSide(color: AppTheme.statusDone, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.bolt, size: 20),
                label: const Text(
                  'Simulasi dengan Akun Demo Dailio',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ] else ...[
            // Tombol Sign Out / Keluar Akun
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: () {
                  _showConfirmSignOutDialog(context, ref);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.statusMissed,
                  side: BorderSide(color: AppTheme.statusMissed.withOpacity(0.5), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.logout_outlined, size: 20),
                label: const Text(
                  'Keluar dari Akun',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 48),
          
          // Footer
          const Column(
            children: [
              Text(
                'Dailio — Grow Through Consistency. 🌿',
                style: TextStyle(color: Color(0xff475569), fontSize: 11, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 4),
              Text(
                'Versi 1.0.0 (Guest Mode Pluggable)',
                style: TextStyle(color: Color(0xff334155), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Tombol Seeder Dummy Sementara untuk kemudahan verifikasi calendar & time log
  Widget _buildDummySeederButton(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff1e293b),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amber.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.science_outlined, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                'Menu Developer (Testing)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Hasilkan 1 habit olahraga pagi beserta riwayat 40 hari penuh centang secara otomatis untuk menguji kalender.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: () async {
                final localHabitDS = ref.read(habitLocalDataSourceProvider);
                final localLogDS = ref.read(trackingLocalDataSourceProvider);
                final calculateStreak = ref.read(calculateStreakProvider);

                try {
                  await DummySeeder.seedDummyHabit(
                    habitLocalDS: localHabitDS,
                    trackingLocalDS: localLogDS,
                    calculateStreak: calculateStreak,
                  );
                  
                  // Segarkan data UI utama
                  await ref.read(habitListProvider.notifier).refresh();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Habit dummy "Olahraga Pagi 🏃" berhasil di-generate! 🌱'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal men-generate: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.withOpacity(0.15),
                foregroundColor: Colors.amber,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.bolt, size: 16),
              label: const Text(
                'Generate Habit Dummy & Riwayat',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Menampilkan layar error dengan opsi alternatif Demo Bypass
  Widget _buildErrorScreen(BuildContext context, WidgetRef ref, String errorMessage) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          // Ikon Peringatan
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.statusMissed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.statusMissed,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          
          const Text(
            'Konfigurasi Diperlukan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xffe2e8f0),
            ),
          ),
          const SizedBox(height: 8),
          
          // Detail Error
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xff1a1d24),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              errorMessage,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xff94a3b8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),

          // Pilihan 1: Gunakan Simulasi Demo (Sangat Direkomendasikan untuk uji coba)
          const Text(
            'Rekomendasi Uji Coba UI:',
            style: TextStyle(color: Color(0xff64748b), fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                ref.read(authControllerProvider.notifier).signInWithGoogle(useDemoBypass: true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statusDone,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.bolt),
              label: const Text(
                'Simulasi dengan Akun Demo Dailio',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Pilihan 2: Kembali ke Guest Mode / Halaman utama
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () {
                // Clear error dengan cara memicu logout (mengembalikan status ke Guest)
                ref.read(authControllerProvider.notifier).signOut();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xff94a3b8),
                side: const BorderSide(color: Color(0xff2e3342)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Tetap di Guest Mode (Offline)'),
            ),
          ),
        ],
      ),
    );
  }

  /// Menampilkan dialog konfirmasi sign out
  void _showConfirmSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xff1a1d24),
          title: const Text('Keluar dari Akun?', style: TextStyle(color: Color(0xffe2e8f0))),
          content: const Text(
            'Apakah Anda yakin ingin keluar? Dailio akan otomatis kembali ke Guest Mode lokal.',
            style: TextStyle(color: Color(0xff94a3b8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal', style: TextStyle(color: Color(0xff64748b))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(authControllerProvider.notifier).signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statusMissed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }

  /// Membangun kartu cadangan lokal untuk melakukan ekspor & impor CSV
  Widget _buildBackupSection(BuildContext context, WidgetRef ref, List<Habit> habits) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xff1a1d24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xff2e3342),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.table_chart_outlined, color: AppTheme.statusSkipped, size: 20),
              SizedBox(width: 8),
              Text(
                'Cadangan Data Lokal',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xffe2e8f0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Ekspor atau impor data kebiasaan Dailio Anda secara mandiri menggunakan file format .csv (Excel).',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xff94a3b8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Tombol Ekspor
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () => _exportHabits(context, habits),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentPrimary,
                      side: const BorderSide(color: Color(0xff2e3342)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.upload_outlined, size: 16),
                    label: const Text(
                      'Ekspor (.csv)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Tombol Impor
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => _importHabits(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.download_outlined, size: 16),
                    label: const Text(
                      'Impor (.csv)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Proses mengekspor habit lokal ke file CSV dan membagikannya via Share Sheet
  Future<void> _exportHabits(BuildContext context, List<Habit> habits) async {
    if (habits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda belum memiliki kebiasaan aktif untuk diekspor.'),
          backgroundColor: AppTheme.statusSkipped,
        ),
      );
      return;
    }

    try {
      // 1. Generate konten CSV
      final csvString = CsvHabitHelper.habitsToCsv(habits);

      // 2. Simpan di direktori temporer HP
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/dailio_habits_backup.csv');
      await file.writeAsString(csvString);

      // 3. Share file CSV menggunakan Share Sheet native OS
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

  /// Proses mengimpor file CSV dari storage lokal dan memasukkannya ke database SQLite
  Future<void> _importHabits(BuildContext context, WidgetRef ref) async {
    try {
      // 1. Buka File Picker bawaan OS untuk menyaring berkas .csv
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.single.path == null) {
        // Proses dibatalkan oleh user
        return;
      }

      // 2. Baca isi file CSV
      final file = File(result.files.single.path!);
      final csvContent = await file.readAsString();

      // 3. Parsing CSV ke List<Habit>
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

      // 4. Masukkan ke dalam SQLite menggunakan controller HabitList secara paralel/sekuensial
      int successCount = 0;
      for (final habit in importedHabits) {
        final res = await ref.read(habitListProvider.notifier).addHabit(habit);
        if (res is Success<void>) {
          successCount++;
        }
      }

      // 5. Beri feedback visual SnackBar
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

/// Widget Kustom Logo Google Presisi Tinggi demi Keunggulan Visual
class GoogleLogoIcon extends StatelessWidget {
  final double size;

  const GoogleLogoIcon({super.key, this.size = 20.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: const _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double r = w / 2;
    final double cx = r;
    final double cy = r;

    final double outerRadius = r;
    final double innerRadius = outerRadius * 0.58;
    final double thickness = outerRadius - innerRadius;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    Path getRingSector(double startAngle, double sweepAngle) {
      final path = Path();
      // Outer arc
      path.addArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: outerRadius),
        startAngle,
        sweepAngle,
      );
      final double endAngle = startAngle + sweepAngle;
      // Line to inner arc
      path.lineTo(
        cx + innerRadius * math.cos(endAngle),
        cy + innerRadius * math.sin(endAngle),
      );
      // Inner arc (reversed)
      path.arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: innerRadius),
        endAngle,
        -sweepAngle,
        false,
      );
      path.close();
      return path;
    }

    // Google Logo Colors
    const Color blue = Color(0xFF4285F4);
    const Color red = Color(0xFFEA4335);
    const Color yellow = Color(0xFFFBBC05);
    const Color green = Color(0xFF34A853);

    // 1. Red (Top Segment)
    paint.color = red;
    canvas.drawPath(
      getRingSector(
        -140 * math.pi / 180,
        105 * math.pi / 180,
      ),
      paint,
    );

    // 2. Yellow (Left Segment)
    paint.color = yellow;
    canvas.drawPath(
      getRingSector(
        135 * math.pi / 180,
        85 * math.pi / 180,
      ),
      paint,
    );

    // 3. Green (Bottom Segment)
    paint.color = green;
    canvas.drawPath(
      getRingSector(
        45 * math.pi / 180,
        90 * math.pi / 180,
      ),
      paint,
    );

    // 4. Blue (Right Segment & Bar)
    paint.color = blue;
    final Path bluePath = Path();
    
    // Blue upper arc: -35 to 0 degrees
    bluePath.addPath(
      getRingSector(
        -35 * math.pi / 180,
        35 * math.pi / 180,
      ),
      Offset.zero,
    );

    // Blue lower arc: 0 to 45 degrees
    bluePath.addPath(
      getRingSector(
        0 * math.pi / 180,
        45 * math.pi / 180,
      ),
      Offset.zero,
    );

    // Horizontal bar: y = cy to cy + thickness, x = cx to cx + outerRadius
    bluePath.addRect(
      Rect.fromLTRB(cx, cy - 0.2, cx + outerRadius, cy + thickness),
    );

    canvas.drawPath(bluePath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
