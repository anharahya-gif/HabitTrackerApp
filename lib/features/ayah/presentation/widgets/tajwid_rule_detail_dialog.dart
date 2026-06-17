import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/tajwid_rule.dart';
import '../controllers/ayah_controller.dart';

class TajwidRuleDetailDialog extends ConsumerWidget {
  final AyahTajwidOccurrence occurrence;

  const TajwidRuleDetailDialog({
    super.key,
    required this.occurrence,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tajwidRepo = ref.read(tajwidRepositoryProvider);
    final rule = tajwidRepo.getRule(occurrence.ruleKey);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const primaryEmerald = Color(0xff0b3b24);
    const accentGold = Color(0xffd4af37);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xff0e1411) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Rule Icon & Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryEmerald.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: accentGold.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: const Icon(
                      Icons.menu_book_outlined,
                      color: accentGold,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hukum Tajwid',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white38 : Colors.black38,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          rule?.name ?? occurrence.ruleKey.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : primaryEmerald,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),

              // 1. Lafadz
              _buildSectionTitle(context, 'Potongan Lafadz'),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: primaryEmerald.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryEmerald.withValues(alpha: 0.15)),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    occurrence.phrase,
                    style: GoogleFonts.amiri(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isDark ? accentGold : primaryEmerald,
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. Definisi
              if (rule != null) ...[
                _buildSectionTitle(context, 'Definisi Hukum'),
                const SizedBox(height: 6),
                Text(
                  rule.definition,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 3. Alasan Terjadi di Ayat Ini
              _buildSectionTitle(context, 'Alasan Terbentuk (Reason)'),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  occurrence.reason,
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 4. Cara Membaca
              if (rule != null) ...[
                _buildSectionTitle(context, 'Cara Membaca'),
                const SizedBox(height: 6),
                Text(
                  rule.instruction,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Contoh Tambahan
                _buildSectionTitle(context, 'Contoh Tambahan Lainnya'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: rule.generalExamples.map((ex) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: accentGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: accentGold.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        ex,
                        style: GoogleFonts.amiri(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? accentGold : const Color(0xff996515),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isDark ? const Color(0xffd4af37) : const Color(0xff0b3b24),
        letterSpacing: 0.5,
      ),
    );
  }
}
