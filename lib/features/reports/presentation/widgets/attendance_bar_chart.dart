import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/report_model.dart';

class AttendanceBarChart extends StatelessWidget {
  final List<ClassAttendanceStatItem> classStats;

  const AttendanceBarChart({super.key, required this.classStats});

  @override
  Widget build(BuildContext context) {
    if (classStats.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('Chưa có dữ liệu chuyên cần lớp học')),
      );
    }

    final topClasses = classStats.take(6).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tỷ lệ chuyên cần theo lớp (%)',
                style: AppTextStyles.h4(context).copyWith(fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.bar_chart, color: AppColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.primary,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = topClasses[groupIndex];
                      return BarTooltipItem(
                        '${item.name}\n${rod.toY.toStringAsFixed(1)}%',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        if (value % 25 == 0) {
                          return Text('${value.toInt()}%', style: const TextStyle(fontSize: 9, color: AppColors.textSecondaryLight));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < topClasses.length) {
                          final name = topClasses[idx].name;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              name.length > 8 ? '${name.substring(0, 8)}...' : name,
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => const FlLine(color: AppColors.neutral200, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(topClasses.length, (i) {
                  final rate = topClasses[i].attendanceRate;
                  final color = rate >= 80
                      ? AppColors.success
                      : rate >= 60
                          ? AppColors.warning
                          : AppColors.error;

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: rate,
                        color: color,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
