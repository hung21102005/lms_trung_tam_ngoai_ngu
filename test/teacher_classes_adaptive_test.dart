import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/di/injection.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/data/models/class_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/domain/repositories/classes_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/presentation/screens/teacher_my_classes_screen.dart';

class _ClassesRepository implements ClassesRepository {
  @override
  Future<List<ClassModel>> getMyClasses() async => const [
    ClassModel(
      id: 'class-1',
      code: 'IELTS-F',
      name: 'IELTS Foundation',
      courseId: 'course-1',
      levelId: 'level-1',
      branchId: 'branch-1',
      startTime: '18:00',
      endTime: '19:30',
      status: 'IN_PROGRESS',
      studentsCount: 12,
      sessionsCount: 4,
      totalSessions: 24,
      scheduleDays: ['MONDAY', 'WEDNESDAY'],
    ),
    ClassModel(
      id: 'class-2',
      code: 'COMM-A1',
      name: 'Giao tiếp A1',
      courseId: 'course-2',
      levelId: 'level-1',
      branchId: 'branch-1',
      startTime: '19:30',
      endTime: '21:00',
      status: 'OPEN_FOR_ENROLLMENT',
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(
    () => getIt.registerSingleton<ClassesRepository>(_ClassesRepository()),
  );
  tearDownAll(() => getIt.unregister<ClassesRepository>());

  for (final width in [320.0, 375.0, 393.0, 430.0, 800.0, 1200.0]) {
    testWidgets('teacher class list thích ứng ở $width px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(home: TeacherMyClassesScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('IELTS Foundation'), findsOneWidget);
      if (width < 600) {
        expect(
          find.byKey(const ValueKey('teacher-classes-mobile')),
          findsOneWidget,
        );
        await tester.tap(find.text('Đang học').first);
        await tester.pumpAndSettle();
        expect(find.text('Giao tiếp A1'), findsNothing);
      } else {
        expect(
          find.byKey(const ValueKey('teacher-classes-mobile')),
          findsNothing,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
}
