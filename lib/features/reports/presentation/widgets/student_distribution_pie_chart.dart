import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/report_model.dart';

class StudentDistributionPieChart extends StatefulWidget {
  final List<CourseDistributionItem> distribution;

  const StudentDistributionPieChart({super.key, required this.distribution});

  @override
  State<StudentDistributionPieChart> createState() =>
      _StudentDistributionPieChartState();
}

class _StudentDistributionPieChartState
    extends State<StudentDistributionPieChart> {
  int _touchedIndex = -1;

  final List<Color> _colors = const [
    AppColors.primary,
    Color(0xFF0EA5E9), // Sky Blue
    AppColors.success,
    AppColors.accent,
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.distribution.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('Chưa có dữ liệu phân bổ học viên')),
      );
    }

    final enrolled =
        widget.distribution.where((item) => item.studentCount > 0).toList()
          ..sort((a, b) => b.studentCount.compareTo(a.studentCount));
    final total = enrolled.fold<int>(0, (sum, item) => sum + item.studentCount);
    if (total == 0) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('Chưa có học viên nào trong các khóa học')),
      );
    }
    final visible = enrolled.take(5).toList();
    final otherCount = enrolled
        .skip(5)
        .fold<int>(0, (sum, item) => sum + item.studentCount);
    final chartNames = [
      for (final item in visible) item.courseName,
      if (otherCount > 0) 'Khác',
    ];
    final chartCounts = [
      for (final item in visible) item.studentCount,
      if (otherCount > 0) otherCount,
    ];

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
                'Phân bổ học viên theo khóa',
                style: AppTextStyles.h4(context)
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              const Icon(
                Icons.pie_chart_outline,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse
                                .touchedSection!
                                .touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 36,
                      sections: List.generate(chartCounts.length, (i) {
                        final isTouched = i == _touchedIndex;
                        final fontSize = isTouched ? 14.0 : 11.0;
                        final radius = isTouched ? 50.0 : 42.0;
                        final count = chartCounts[i];
                        final pct = ((count / total) * 100).toStringAsFixed(0);
                        final color = _colors[i % _colors.length];

                        return PieChartSectionData(
                          color: color,
                          value: count.toDouble(),
                          title: '$pct%',
                          radius: radius,
                          titleStyle: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(chartCounts.length, (i) {
                      final color = _colors[i % _colors.length];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.0),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${chartNames[i]} (${chartCounts[i]})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
