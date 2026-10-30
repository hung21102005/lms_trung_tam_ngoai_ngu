import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/data/models/course_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/presentation/screens/lesson_detail_screen.dart';

void main() {
  const lesson = LessonModel(
    id: 'lesson-1',
    moduleId: 'module-1',
    title: 'Speaking practice',
    order: 2,
    content: 'Luyện phát âm và hội thoại.',
    durationMinutes: 90,
  );
  for (final width in [320.0, 375.0, 393.0, 430.0, 800.0, 1200.0]) {
    testWidgets('chi tiết bài học thích ứng ở $width px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: LessonDetailScreen(moduleTitle: 'Unit 1', lesson: lesson),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Speaking practice'), findsWidgets);
      expect(
        find.byKey(const ValueKey('student-lesson-mobile')),
        width < 600 ? findsOneWidget : findsNothing,
      );
      expect(find.textContaining('example.com'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
