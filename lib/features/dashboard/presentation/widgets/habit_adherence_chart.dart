import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';
import '../controllers/analytics_controller.dart';

/// Grafik Kepatuhan Habit Harian (Line Chart) berbasis fl_chart.
/// Mendukung filter dinamis 7 Hari vs 30 Hari terakhir dengan sentuhan interaktif.
class HabitAdherenceChart extends StatefulWidget {
  final List<AdherenceDataPoint> data;

  const HabitAdherenceChart({
    super.key,
    required this.data,
  });

  @override
  State<HabitAdherenceChart> createState() => _HabitAdherenceChartState();
}

class _HabitAdherenceChartState extends State<HabitAdherenceChart> {
  int _selectedDaysFilter = 7; // Default 7 hari terakhir

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xff1a1d24) : Colors.white;
    final textPrimary = isDark ? const Color(0xffe2e8f0) : Colors.black87;
    final textSecondary = isDark ? const Color(0xff94a3b8) : Colors.grey;

    // Filter data sesuai opsi
    final filteredData = widget.data.length > _selectedDaysFilter
        ? widget.data.sublist(widget.data.length - _selectedDaysFilter)
        : widget.data;

    // Siapkan list titik koordinat grafik (X, Y)
    final List<FlSpot> spots = [];
    for (int i = 0; i < filteredData.length; i++) {
      spots.add(FlSpot(i.toDouble(), filteredData[i].rate * 100));
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
          // Header: Judul & Filter Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kepatuhan Kebiasaan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Persentase penyelesaian habit harian',
                    style: TextStyle(
                      fontSize: 11,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
              
              // Segmented Control (7 Hari vs 30 Hari)
              Container(
                height: 32,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xff111318) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildFilterTab(7, '7 H'),
                    _buildFilterTab(30, '30 H'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tampilan Grafik
          AspectRatio(
            aspectRatio: 1.7,
            child: spots.isEmpty
                ? Center(
                    child: Text(
                      'Tidak ada data log habit.',
                      style: TextStyle(color: textSecondary, fontSize: 13),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (touchedSpot) => isDark
                              ? const Color(0xff1e293b).withOpacity(0.9)
                              : Colors.white.withOpacity(0.9),
                          tooltipBorder: BorderSide(
                            color: AppTheme.accentPrimary.withOpacity(0.3),
                            width: 1,
                          ),
                          tooltipRoundedRadius: 8,
                          getTooltipItems: (List<LineBarSpot> touchedSpots) {
                            return touchedSpots.map((barSpot) {
                              final index = barSpot.x.toInt();
                              if (index < 0 || index >= filteredData.length) return null;
                              final dp = filteredData[index];
                              
                              // Format tanggal
                              final dateLabel = '${dp.date.day}/${dp.date.month}';
                              final percentVal = (dp.rate * 100).toStringAsFixed(0);

                              return LineTooltipItem(
                                '$dateLabel\n',
                                TextStyle(
                                  color: textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                children: [
                                  TextSpan(
                                    text: '$percentVal% Selesai',
                                    style: const TextStyle(
                                      color: AppTheme.accentPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              );
                            }).toList();
                          },
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 25,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 50,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}%',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            interval: _selectedDaysFilter == 7 ? 2 : 7,
                            getTitlesWidget: (value, meta) {
                              final int index = value.toInt();
                              if (index < 0 || index >= filteredData.length) {
                                return const SizedBox.shrink();
                              }
                              final date = filteredData[index].date;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Text(
                                  '${date.day}/${date.month}',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (filteredData.length - 1).toDouble(),
                      minY: 0,
                      maxY: 100,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          preventCurveOverShooting: true,
                          gradient: const LinearGradient(
                            colors: [AppTheme.accentPrimary, Color(0xff4ade80)],
                          ),
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: _selectedDaysFilter == 7, // Tampilkan dot hanya di filter 7 hari agar tidak sumpek
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: isDark ? const Color(0xff1a1d24) : Colors.white,
                                strokeWidth: 3,
                                strokeColor: AppTheme.accentPrimary,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.accentPrimary.withOpacity(0.25),
                                AppTheme.accentPrimary.withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(int days, String label) {
    final isSelected = _selectedDaysFilter == days;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDaysFilter = days;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xff1a1d24) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? (isDark ? const Color(0xffe2e8f0) : Colors.black87)
                : (isDark ? const Color(0xff64748b) : Colors.grey),
          ),
        ),
      ),
    );
  }
}
