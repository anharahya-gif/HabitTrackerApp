import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/collapsible_sidebar.dart';
import '../../data/constants/curated_prayers.dart';
import '../../domain/entities/prayer_item.dart';
import '../controllers/doa_controller.dart';
import '../widgets/prayer_detail_sheet.dart';

class PrayerCollectionPage extends ConsumerWidget {
  const PrayerCollectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(doaControllerProvider);
    final controller = ref.read(doaControllerProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    const primaryEmerald = Color(0xff0b3b24);
    const accentGold = Color(0xffd4af37);
    final bgColor = isDark ? const Color(0xff070c09) : const Color(0xfff3f6f4);
    final glassColor = isDark
        ? const Color(0xff121814).withValues(alpha: 0.8)
        : Colors.white.withValues(alpha: 0.9);

    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white60 : Colors.black54;

    // Filter doa secara dinamis di level UI berdasarkan query dan kategori
    final List<PrayerItem> filteredPrayers = curatedPrayers.where((prayer) {
      // 1. Filter Kategori / Favorit
      if (state.selectedCategory == 'Favorit') {
        if (!state.favoriteDoaIds.contains(prayer.id)) return false;
      } else if (state.selectedCategory != 'Semua') {
        if (prayer.category != state.selectedCategory) return false;
      }

      // 2. Filter Search Query
      if (state.searchQuery.isNotEmpty) {
        final query = state.searchQuery.toLowerCase();
        final matchTitle = prayer.title.toLowerCase().contains(query);
        final matchTranslation = prayer.translation.toLowerCase().contains(query);
        final matchLatin = prayer.latin.toLowerCase().contains(query);
        if (!matchTitle && !matchTranslation && !matchLatin) return false;
      }

      return true;
    }).toList();

    final categories = [
      'Semua',
      'Favorit',
      'Harian',
      'Kemudahan',
      'Perlindungan',
      'Shalat & Ibadah',
      'Qur\'an & Hadits'
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        context.go('/ibadah');
      },
      child: Scaffold(
        backgroundColor: bgColor,
        drawer: isMobile ? const CollapsibleSidebar(isDrawer: true) : null,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Kumpulan Doa Harian',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.go('/ibadah'),
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              // Ambient lights latar belakang
              _buildAmbientLights(isDark),

              Row(
                children: [
                  if (!isMobile) const CollapsibleSidebar(isDrawer: false),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          // 1. Search Bar
                          _buildSearchBar(controller, isDark, glassColor, textPrimary),
                          const SizedBox(height: 16),

                          // 2. Horizontal Category Chips
                          _buildCategoryChips(state, controller, categories, isDark, accentGold, primaryEmerald),
                          const SizedBox(height: 16),

                          // 3. List of Prayers
                          Expanded(
                            child: state.isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(accentGold),
                                    ),
                                  )
                                : filteredPrayers.isEmpty
                                    ? _buildEmptyState(state.selectedCategory, textPrimary, textSecondary)
                                    : ListView.separated(
                                        physics: const BouncingScrollPhysics(),
                                        padding: const EdgeInsets.only(bottom: 24),
                                        itemCount: filteredPrayers.length,
                                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                                        itemBuilder: (context, index) {
                                          final prayer = filteredPrayers[index];
                                          final isFav = state.favoriteDoaIds.contains(prayer.id);

                                          return _buildPrayerCard(
                                            context,
                                            prayer,
                                            isFav,
                                            controller,
                                            glassColor,
                                            textPrimary,
                                            textSecondary,
                                            accentGold,
                                            primaryEmerald,
                                          );
                                        },
                                      ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── AMBIENT BACKGROUND GLOWS ──────────────────────────────────────────────

  Widget _buildAmbientLights(bool isDark) {
    if (!isDark) return const SizedBox.shrink();
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x150b3b24),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SEARCH BAR ────────────────────────────────────────────────────────────

  Widget _buildSearchBar(
    DoaController controller,
    bool isDark,
    Color glassColor,
    Color textPrimary,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: glassColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: TextField(
        onChanged: controller.setSearchQuery,
        style: TextStyle(color: textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Cari doa berdasarkan judul atau arti...',
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // ─── CATEGORY CHIPS ────────────────────────────────────────────────────────

  Widget _buildCategoryChips(
    DoaState state,
    DoaController controller,
    List<String> categories,
    bool isDark,
    Color accentGold,
    Color primaryEmerald,
  ) {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = state.selectedCategory == cat;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                cat == 'Favorit' ? '⭐ Favorit' : cat,
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
              selected: isSelected,
              onSelected: (_) => controller.setSelectedCategory(cat),
              selectedColor: primaryEmerald,
              backgroundColor: isDark ? Colors.white12 : Colors.white,
              checkmarkColor: Colors.white,
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? accentGold.withValues(alpha: 0.5)
                      : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                  width: 1.2,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
          );
        },
      ),
    );
  }

  // ─── PRAYER CARD WIDGET ────────────────────────────────────────────────────

  Widget _buildPrayerCard(
    BuildContext context,
    PrayerItem prayer,
    bool isFav,
    DoaController controller,
    Color glassColor,
    Color textPrimary,
    Color textSecondary,
    Color accentGold,
    Color primaryEmerald,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: glassColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFav ? accentGold.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.05),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              builder: (context) => PrayerDetailSheet(prayer: prayer),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Kategori Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: primaryEmerald.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        prayer.category.toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: primaryEmerald,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    // Bookmark heart button
                    GestureDetector(
                      onTap: () => controller.toggleFavoriteDoa(prayer.id),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isFav ? Colors.red.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.03),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? Colors.redAccent : Colors.grey,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Judul Doa
                Text(
                  prayer.title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                // Arabic teaser
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    prayer.arabic,
                    style: GoogleFonts.amiri(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryEmerald,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                ),
                const SizedBox(height: 6),
                // Terjemahan teaser
                Text(
                  prayer.translation,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── EMPTY STATE WIDGET ────────────────────────────────────────────────────

  Widget _buildEmptyState(String category, Color textPrimary, Color textSecondary) {
    final isFav = category == 'Favorit';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: (isFav ? Colors.red : Colors.grey).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFav ? Icons.favorite_border_rounded : Icons.search_off_rounded,
                color: isFav ? Colors.redAccent : Colors.grey,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isFav ? 'Belum Ada Doa Favorit' : 'Doa Tidak Ditemukan',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isFav
                  ? 'Tandai doa dengan mengetuk ikon hati pada kartu doa agar terkumpul di sini.'
                  : 'Coba periksa kembali kata kunci pencarian Anda atau ganti filter kategori.',
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
