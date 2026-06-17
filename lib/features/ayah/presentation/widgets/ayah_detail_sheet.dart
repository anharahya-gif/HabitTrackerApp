import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/daily_ayah.dart';
import '../controllers/ayah_controller.dart';
import 'tajwid_rule_detail_dialog.dart';

class AyahDetailSheet extends ConsumerStatefulWidget {
  final DailyAyah ayah;

  const AyahDetailSheet({
    super.key,
    required this.ayah,
  });

  @override
  ConsumerState<AyahDetailSheet> createState() => _AyahDetailSheetState();
}

class _AyahDetailSheetState extends ConsumerState<AyahDetailSheet> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _isSharingImage = false;

  /// Salin ayat beserta referensinya ke Clipboard
  void _copyToClipboard() {
    final text = '${widget.ayah.arabicText}\n\n${widget.ayah.translation}\n(QS. ${widget.ayah.surahName}:${widget.ayah.ayahNumber})';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ayat berhasil disalin ke papan klip!')),
    );
  }

  /// Bagikan ayat sebagai teks biasa
  void _shareAsText() {
    final text = '📖 Ayat Hari Ini - Dailio:\n\n${widget.ayah.arabicText}\n\n"${widget.ayah.translation}"\n\nQS. ${widget.ayah.surahName}:${widget.ayah.ayahNumber}';
    Share.share(text);
  }

  /// Bagikan ayat sebagai gambar grafis estetik (PNG)
  Future<void> _shareAsImage() async {
    setState(() {
      _isSharingImage = true;
    });

    try {
      // Tunggu render frame selesai
      await Future.delayed(const Duration(milliseconds: 300));
      
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('RenderRepaintBoundary tidak ditemukan');

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Gagal mengevakuasi byte data gambar');
      
      final pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/dailio_ayah_${widget.ayah.surahNumber}_${widget.ayah.ayahNumber}.png').create();
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Ayat Hari Ini: QS. ${widget.ayah.surahName}:${widget.ayah.ayahNumber} #DailioApp',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat gambar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharingImage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ayahControllerProvider);
    final controller = ref.read(ayahControllerProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isFav = controller.isFavorited(widget.ayah);

    const primaryEmerald = Color(0xff0b3b24);
    const accentGold = Color(0xffd4af37);
    final bgColor = isDark ? const Color(0xff090f0c) : const Color(0xfff7f9f8);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle Bar atas
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),

          // Header Detail Sheet
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detail Ayat',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : primaryEmerald,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    controller.stopAudio();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10),

          // Konten Sheet
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. RepaintBoundary untuk ekspor Gambar (Share as Image)
                  RepaintBoundary(
                    key: _repaintKey,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primaryEmerald, Color(0xff143f2a)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: accentGold.withValues(alpha: 0.3), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '📖 AYAT HARI INI',
                                style: GoogleFonts.outfit(
                                  color: accentGold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                'DAILIO',
                                style: GoogleFonts.outfit(
                                  color: Colors.white30,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              widget.ayah.arabicText,
                              style: GoogleFonts.amiri(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                height: 1.6,
                              ),
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            '"${widget.ayah.translation}"',
                            style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              height: 1.4,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'QS. ${widget.ayah.surahName}:${widget.ayah.ayahNumber}',
                                style: GoogleFonts.outfit(
                                  color: accentGold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Tumbuh Lewat Konsistensi',
                                style: GoogleFonts.outfit(
                                  color: Colors.white38,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Panel Pemutar Audio
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                    ),
                    child: Row(
                      children: [
                        // Play/Pause button
                        GestureDetector(
                          onTap: () => controller.toggleAudioPlayback(widget.ayah.audioUrl),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: primaryEmerald,
                              shape: BoxShape.circle,
                            ),
                            child: state.isAudioLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
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
                                    size: 18,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.isAudioPlaying ? 'Sedang Memutar Audio...' : 'Audio Murattal',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                'Syaikh Mishary Rashid Alafasy',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white38 : Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (state.isAudioPlaying)
                          IconButton(
                            icon: const Icon(Icons.stop_rounded, color: Colors.redAccent),
                            onPressed: () => controller.stopAudio(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Tombol Aksi (Salin, Favorit, Bagikan Teks, Bagikan Gambar)
                  _buildSectionTitle(context, 'Peralatan Aksi'),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildActionButton(
                        icon: Icons.copy_rounded,
                        label: 'Salin',
                        onTap: _copyToClipboard,
                      ),
                      _buildActionButton(
                        icon: isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                        iconColor: isFav ? Colors.redAccent : null,
                        label: 'Favorit',
                        onTap: () => controller.toggleFavorite(widget.ayah),
                      ),
                      _buildActionButton(
                        icon: Icons.text_fields_rounded,
                        label: 'Teks',
                        onTap: _shareAsText,
                      ),
                      _buildActionButton(
                        icon: Icons.image_outlined,
                        label: _isSharingImage ? 'Membuat...' : 'Gambar',
                        onTap: _isSharingImage ? () {} : _shareAsImage,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // 4. Tab Analisis Tajwid
                  _buildSectionTitle(context, 'Analisis Hukum Tajwid'),
                  const SizedBox(height: 4),
                  Text(
                    'Ketuk pada hukum tajwid untuk mempelajari definisi, alasan, dan cara membaca.',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  
                  if (widget.ayah.tajwidOccurrences.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'Aturan tajwid tidak terdefinisi untuk ayat ini.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.ayah.tajwidOccurrences.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final occ = widget.ayah.tajwidOccurrences[index];
                        final tajwidRepo = ref.read(tajwidRepositoryProvider);
                        final rule = tajwidRepo.getRule(occ.ruleKey);

                        return Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: accentGold.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            title: Text(
                              rule?.name ?? occ.ruleKey.toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              occ.reason,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  occ.phrase,
                                  style: GoogleFonts.amiri(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: primaryEmerald,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: accentGold),
                              ],
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => TajwidRuleDetailDialog(occurrence: occ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: isDark ? const Color(0xffd4af37) : const Color(0xff0b3b24),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Material(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Column(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: iconColor ?? (isDark ? const Color(0xffd4af37) : const Color(0xff0b3b24)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
