import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';

/// Grafik Kecepatan Tugas (Donut Chart) berbasis fl_chart.
/// Menampilkan proporsi tugas yang selesai berdasarkan kategorinya.
class TaskVelocityChart extends StatefulWidget {
  final Map<String, int> categoryCounts;
  final int totalCompleted;

  const TaskVelocityChart({
    super.key,
    required this.categoryCounts,
    required this.totalCompleted,
  });

  @override
  State<TaskVelocityChart> createState() => _TaskVelocityChartState();
}

class _TaskVelocityChartState extends State<TaskVelocityChart> {
  int _touchedIndex = -1;

  // Dapatkan daftar warna premium untuk kategori
  Color _getCategoryColor(String category, int index) {
    switch (category.toLowerCase()) {
      case 'kerja':
        return AppTheme.accentPrimary; // Biru
      case 'belajar':
        return const Color(0xffa855f7); // Violet/Purple
      case 'kesehatan':
        return AppTheme.statusDone; // Hijau
      case 'sosial':
        return const Color(0xfff97316); // Orange
      case 'keuangan':
        return const Color(0xffeab308); // Kuning
      case 'lainnya':
        return const Color(0xff64748b); // Slate Grey
      default:
        // Hasilkan warna dinamis berbasis index agar unik
        final colors = [
          AppTheme.accentPrimary,
          const Color(0xffa855f7),
          AppTheme.statusDone,
          const Color(0xfff97316),
          const Color(0xffeab308),
          const Color(0xffec4899), // Pink
          const Color(0xff06b6d4), // Cyan
          const Color(0xff64748b),
        ];
        return colors[index % colors.length];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xff1a1d24) : Colors.white;
    final textPrimary = isDark ? const Color(0xffe2e8f0) : Colors.black87;
    final textSecondary = isDark ? const Color(0xff94a3b8) : Colors.grey;

    final hasData = widget.totalCompleted > 0 && widget.categoryCounts.isNotEmpty;

    // Persiapkan data sections untuk fl_chart
    final List<PieChartSectionData> sections = [];
    final List<Widget> legendItems = [];
    int index = 0;

    if (hasData) {
      widget.categoryCounts.forEach((category, count) {
        final isTouched = index == _touchedIndex;
        final double radius = isTouched ? 22.0 : 16.0;
        final double percentage = (count / widget.totalCompleted) * 100;
        final color = _getCategoryColor(category, index);

        sections.add(
          PieChartSectionData(
            color: color,
            value: count.toDouble(),
            title: isTouched ? '${percentage.toStringAsFixed(0)}%' : '',
            radius: radius,
            titleStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );

        // Buat item legenda
        legendItems.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$category ($count)',
                    style: TextStyle(
                      fontSize: 12,
                      color: textPrimary,
                      fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );

        index++;
      });
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Kategori Tugas Selesai',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Distribusi tugas yang diselesaikan',
            style: TextStyle(
              fontSize: 11,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 28),

          // Tampilan Konten (Chart + Legend)
          if (!hasData)
            AspectRatio(
              aspectRatio: 1.7,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.donut_large_rounded,
                      color: textSecondary.withOpacity(0.4),
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Selesaikan tugas untuk melihat grafik.',
                      style: TextStyle(color: textSecondary, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Row(
              children: [
                // Donut Chart
                Expanded(
                  flex: 5,
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    _touchedIndex = -1;
                                    return;
                                  }
                                  _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 3,
                            centerSpaceRadius: 38,
                            sections: sections,
                          ),
                        ),
                        // Angka total tugas di tengah donat
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${widget.totalCompleted}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tugas',
                              style: TextStyle(
                                fontSize: 10,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Legenda
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: legendItems,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
