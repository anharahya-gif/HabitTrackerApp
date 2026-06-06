import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';

/// Dialog selebrasi Level Up premium untuk memberi penghargaan atas konsistensi pengguna.
class LevelUpDialog extends StatelessWidget {
  final int oldLevel;
  final int newLevel;
  final VoidCallback onConfirm;

  const LevelUpDialog({
    super.key,
    required this.oldLevel,
    required this.newLevel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xff1e293b) : Colors.white;
    final textPrimary = isDark ? const Color(0xffe2e8f0) : Colors.black87;
    final textSecondary = isDark ? const Color(0xff94a3b8) : Colors.grey.shade600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Kotak Dialog Utama
          Container(
            margin: const EdgeInsets.only(top: 48), // Ruang untuk badge mengapung
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.amber.withOpacity(0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.12),
                  blurRadius: 32,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Judul Selebrasi
                const Text(
                  'NAIK LEVEL! 🎉',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.amber,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Pesan Selamat
                Text(
                  'Konsistensi membuahkan hasil. Kamu telah tumbuh lebih disiplin hari ini!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Perbandingan Level (Level Lama -> Level Baru)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLevelBadge(oldLevel, isPast: true),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.amber.shade600,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    _buildLevelBadge(newLevel, isPast: false),
                  ],
                ),
                const SizedBox(height: 32),

                // Tombol Aksi Konfirmasi
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Teruskan Berjuang!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lencana Mahkota Mengapung di Atas (Visual Utama)
          Positioned(
            top: 0,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xffffe259), Color(0xffffa751)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.workspace_premium,
                  color: Colors.white,
                  size: 52,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper untuk membuat box Level
  Widget _buildLevelBadge(int level, {required bool isPast}) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: isPast
            ? Colors.grey.withOpacity(0.12)
            : Colors.amber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPast
              ? Colors.grey.withOpacity(0.3)
              : Colors.amber.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Lvl',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isPast ? Colors.grey : Colors.amber.shade700,
            ),
          ),
          Text(
            '$level',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isPast ? Colors.grey : Colors.amber.shade700,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
