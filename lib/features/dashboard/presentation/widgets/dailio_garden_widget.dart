import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_theme.dart';
import '../controllers/gamification_controller.dart';

/// Widget visualisasi kebun mini (Dailio Garden) di Beranda.
/// Menampilkan tanaman dinamis menggunakan emoji, status hidrasi,
/// progress bar pertumbuhan, serta aksi tanam ulang atau menghidupkan kembali.
class DailioGardenWidget extends ConsumerWidget {
  const DailioGardenWidget({super.key});

  // Dapatkan ikon emoji sesuai tahap pertumbuhan tanaman
  String _getPlantEmoji(int stage) {
    switch (stage) {
      case -1:
        return '🥀'; // Mati
      case 0:
        return '🫘'; // Benih
      case 1:
        return '🌱'; // Kecambah
      case 2:
        return '🪴'; // Sapling / Bibit di Pot
      case 3:
        return '🌳'; // Tanaman Dewasa
      case 4:
        return '🌻'; // Mekar Sempurna (Bunga Matahari)
      default:
        return '🫘';
    }
  }

  // Dapatkan nama tahap pertumbuhan tanaman
  String _getStageName(int stage) {
    switch (stage) {
      case -1:
        return 'Mati Kering';
      case 0:
        return 'Benih';
      case 1:
        return 'Kecambah';
      case 2:
        return 'Bibit Muda';
      case 3:
        return 'Tanaman Rindang';
      case 4:
        return 'Mekar Sempurna';
      default:
        return 'Benih';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gamificationProvider);
    final notifier = ref.read(gamificationProvider.notifier);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xff1e293b) : Colors.white;
    final textPrimary = isDark ? const Color(0xffe2e8f0) : Colors.black87;
    final textSecondary = isDark ? const Color(0xff94a3b8) : Colors.grey.shade600;

    // Tentukan status hidrasi tanaman harian
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final isWateredToday = game.lastWateredDate == todayStr;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (game.plantStage == -1) {
      statusColor = AppTheme.statusMissed; // Merah
      statusText = 'Tanaman Mati Kering';
      statusIcon = Icons.cancel_outlined;
    } else if (game.wiltDays > 0) {
      statusColor = AppTheme.statusSkipped; // Kuning/Amber
      statusText = 'Layu (Haus ${game.wiltDays} Hari)';
      statusIcon = Icons.warning_amber_rounded;
    } else if (isWateredToday) {
      statusColor = AppTheme.statusDone; // Hijau
      statusText = 'Subur & Segar';
      statusIcon = Icons.opacity;
    } else {
      statusColor = AppTheme.accentPrimary; // Biru
      statusText = 'Butuh Air Harian';
      statusIcon = Icons.water_drop_outlined;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: game.plantStage == -1
              ? AppTheme.statusMissed.withOpacity(0.25)
              : (game.wiltDays > 0 
                  ? AppTheme.statusSkipped.withOpacity(0.25)
                  : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06))),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Visual Pot Tanaman (Glow Circle + Emoji)
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xff0f172a) : Colors.grey.shade100,
                  boxShadow: game.plantStage != -1
                      ? [
                          BoxShadow(
                            color: statusColor.withOpacity(0.15),
                            blurRadius: 16,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    _getPlantEmoji(game.plantStage),
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
              // Ikon kecil status di pojok lingkaran tanaman
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: cardColor, width: 2),
                ),
                child: Icon(
                  statusIcon,
                  color: Colors.white,
                  size: 10,
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),

          // Detail tanaman dan perkembangannya
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      game.plantType,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getStageName(game.plantStage),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                
                // Status teks hidrasi
                Text(
                  game.plantStage == -1
                      ? 'Tanamanmu layu karena tidak disiram 3 hari. Tanam ulang gratis atau selamatkan dengan ramuan!'
                      : (isWateredToday
                          ? 'Tanaman terhidrasi dengan baik! Pertumbuhannya akan berlanjut besok.'
                          : 'Selesaikan kebiasaanmu hari ini untuk menyiram tanaman virtual ini secara otomatis.'),
                  style: TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),

                // Pertumbuhan progress bar (Hanya muncul jika hidup & belum mekar sempurna)
                if (game.plantStage >= 0 && game.plantStage < 4) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: game.plantProgress,
                            backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                            minHeight: 5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${(game.plantProgress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ] else if (game.plantStage == 4) ...[
                  // Tanaman mekar sempurna!
                  Row(
                    children: [
                      const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Tumbuh Maksimal! 🌻✨',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade600,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _showResetConfirmation(context, notifier),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Tanam Baru',
                          style: TextStyle(fontSize: 11, color: AppTheme.accentPrimary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Tanaman mati, tawarkan opsi pulihkan/tanam ulang
                  Row(
                    children: [
                      // Tombol Tanam Ulang Gratis
                      ElevatedButton(
                        onPressed: () => notifier.resetPlant(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                          foregroundColor: textPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('Tanam Ulang', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      // Tombol Selamatkan (150 XP)
                      ElevatedButton.icon(
                        onPressed: () async {
                          final bool success = await notifier.revivePlant(150);
                          if (!success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('XP Akumulatif Anda tidak mencukupi untuk membeli ramuan pemulih! (Butuh 150 XP) 🧪'),
                                backgroundColor: AppTheme.statusMissed,
                              ),
                            );
                          } else if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tanaman berhasil dipulihkan dari kelayuan! 🧪✨'),
                                backgroundColor: AppTheme.statusDone,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.withOpacity(0.15),
                          foregroundColor: Colors.amber.shade700,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                        icon: const Icon(Icons.science_outlined, size: 12),
                        label: const Text('Pulihkan (150 XP)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, GamificationController notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff1a1d24),
        title: const Text('Tanam Baru?', style: TextStyle(color: Color(0xffe2e8f0))),
        content: const Text(
          'Bunga Matahari kamu sudah mekar sempurna. Apakah kamu ingin memanennya dan menanam benih baru dari awal?',
          style: TextStyle(color: Color(0xff94a3b8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Color(0xff64748b))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              notifier.resetPlant();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Panen & Reset'),
          ),
        ],
      ),
    );
  }
}
