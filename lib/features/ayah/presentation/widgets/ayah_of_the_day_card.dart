import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/ayah_controller.dart';
import 'ayah_detail_sheet.dart';

class AyahOfTheDayCard extends ConsumerWidget {
  const AyahOfTheDayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ayahControllerProvider);
    final controller = ref.read(ayahControllerProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (state.isLoading) {
      return Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xff0c1611) : const Color(0xfff0f5f2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xff0b3b24).withValues(alpha: 0.15)),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xffd4af37)),
          ),
        ),
      );
    }

    final ayah = state.todayAyah;
    if (ayah == null) {
      return const SizedBox.shrink();
    }

    const primaryEmerald = Color(0xff0b3b24);
    const primaryEmeraldLight = Color(0xff1b4f35);
    const accentGold = Color(0xffd4af37);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryEmerald, primaryEmeraldLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentGold.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryEmerald.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              builder: (context) => AyahDetailSheet(ayah: ayah),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Title + Play Audio
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.menu_book_rounded,
                          color: accentGold,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ayat Hari Ini',
                          style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    // Play/Pause Audio Button
                    GestureDetector(
                      onTap: () => controller.toggleAudioPlayback(ayah.audioUrl),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accentGold.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: state.isAudioLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(accentGold),
                                ),
                              )
                            : Icon(
                                state.isAudioPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: accentGold,
                                size: 16,
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Teks Arab Uthmani
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    ayah.arabicText,
                    style: GoogleFonts.amiri(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                ),
                const SizedBox(height: 14),

                // Terjemahan Indonesia
                Text(
                  ayah.translation,
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Divider
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                const SizedBox(height: 8),

                // Reference: Surah:Ayah
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'QS. ${ayah.surahName}:${ayah.ayahNumber}',
                      style: GoogleFonts.outfit(
                        color: accentGold,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Ketuk untuk detail & tajwid ➔',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
