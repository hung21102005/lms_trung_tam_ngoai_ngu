import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/reports/data/models/report_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/reports/presentation/widgets/student_distribution_pie_chart.dart';

void main() {
  testWidgets('long course distribution remains inside dashboard card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 520,
              child: StudentDistributionPieChart(
                distribution: List.generate(
                  50,
                  (index) => CourseDistributionItem(
                    courseId: 'course-$index',
                    courseName: 'Khóa học có tên rất dài $index',
                    studentCount: 50 - index,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Khác ('), findsOneWidget);
  });
}
