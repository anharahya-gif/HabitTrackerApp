import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../domain/entities/app_user.dart';
import '../controllers/auth_controller.dart';

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
        data: (user) => _buildProfileContent(context, ref, user),
      ),
    );
  }

  /// Membangun antarmuka konten profil utama
  Widget _buildProfileContent(BuildContext context, WidgetRef ref, AppUser user) {
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
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

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
                icon: Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    'G',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w900,
                      color: Colors.redAccent,
                      fontSize: 16,
                    ),
                  ),
                ),
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
}
