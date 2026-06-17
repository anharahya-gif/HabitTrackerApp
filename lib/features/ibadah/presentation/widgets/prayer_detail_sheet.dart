import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/prayer_item.dart';
import '../controllers/doa_controller.dart';

class PrayerDetailSheet extends ConsumerStatefulWidget {
  final PrayerItem prayer;

  const PrayerDetailSheet({
    super.key,
    required this.prayer,
  });

  @override
  ConsumerState<PrayerDetailSheet> createState() => _PrayerDetailSheetState();
}

class _PrayerDetailSheetState extends ConsumerState<PrayerDetailSheet> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _isSharingImage = false;

  /// Salin doa ke Clipboard
  void _copyToClipboard() {
    final text = '${widget.prayer.title}\n\n${widget.prayer.arabic}\n\n${widget.prayer.latin}\n\n${widget.prayer.translation}\n(${widget.prayer.reference})';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Doa berhasil disalin ke papan klip!')),
    );
  }

  /// Bagikan doa sebagai teks biasa
  void _shareAsText() {
    final text = '🤲 Doa Pilihan Harian - Dailio:\n\n${widget.prayer.title}\n\n${widget.prayer.arabic}\n\n"${widget.prayer.translation}"\n\nSumber: ${widget.prayer.reference}';
    Share.share(text);
  }

  /// Bagikan doa sebagai gambar estetik (PNG)
  Future<void> _shareAsImage() async {
    setState(() {
      _isSharingImage = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('RenderRepaintBoundary tidak ditemukan');

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Gagal mengevakuasi byte data gambar');
      
      final pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/dailio_doa_${widget.prayer.id}.png').create();
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Doa Pilihan: ${widget.prayer.title} #DailioApp',
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
    final state = ref.watch(doaControllerProvider);
    final controller = ref.read(doaControllerProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isFav = state.favoriteDoaIds.contains(widget.prayer.id);

    const primaryEmerald = Color(0xff0b3b24);
    const accentGold = Color(0xffd4af37);
    final bgColor = isDark ? const Color(0xff090f0c) : const Color(0xfff7f9f8);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
                  'Detail Doa',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : primaryEmerald,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
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
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: accentGold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  widget.prayer.category.toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    color: accentGold,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
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
                          Text(
                            widget.prayer.title,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              widget.prayer.arabic,
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
                            widget.prayer.latin,
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.4,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '"${widget.prayer.translation}"',
                            style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Sumber: ${widget.prayer.reference}',
                                  style: GoogleFonts.outfit(
                                    color: accentGold,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                  const SizedBox(height: 24),

                  // 2. Tombol Aksi (Salin, Favorit, Bagikan Teks, Bagikan Gambar)
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
                        onTap: () => controller.toggleFavoriteDoa(widget.prayer.id),
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
        fontSize: 13,
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
