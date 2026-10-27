import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/di/injection.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/network/api_client.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/data/models/class_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/domain/repositories/classes_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/presentation/screens/student_courses_screen.dart';

class _Classes implements ClassesRepository {
  @override
  Future<List<ClassModel>> getMyClasses() async => [
    ClassModel.fromJson({
      'id': 'class-1',
      'code': 'IELTS-01',
      'name': 'Lớp IELTS Foundation',
      'courseId': 'course-1',
      'course': {'id': 'course-1', 'title': 'IELTS Foundation'},
      'levelId': 'level-1',
      'level': {'id': 'level-1', 'name': 'Foundation'},
      'branchId': 'branch-1',
      'startTime': '18:00',
      'endTime': '19:30',
    }),
  ];

  @override
  Future<List<ClassSessionModel>> getClassSessions(String classId) async => [
    ClassSessionModel(
      id: 'session-1',
      classId: classId,
      title: 'Buổi 1',
      startTime: '18:00',
      endTime: '19:30',
      status: 'COMPLETED',
      lessonId: 'lesson-1',
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Api implements ApiClient {
  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    dynamic options,
  }) async {
    expect(path, '/levels/level-1/modules');
    return {
      'data': [
        {
          'title': 'Chương 1',
          'lessons': [
            {'id': 'lesson-1', 'title': 'Bài 1: Giới thiệu', 'materials': []},
            {'id': 'lesson-2', 'title': 'Bài 2: Luyện tập', 'materials': []},
          ],
        },
      ],
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    getIt.registerSingleton<ClassesRepository>(_Classes());
    getIt.registerSingleton<ApiClient>(_Api());
  });
  tearDown(() async => getIt.reset());

  testWidgets(
    'học viên chỉ thấy khóa đã ghi danh và tiến độ, không có thao tác quản trị',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StudentCoursesScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Khóa học của tôi'), findsOneWidget);
      expect(find.text('IELTS Foundation'), findsOneWidget);
      expect(find.textContaining('Tạo khóa học'), findsNothing);
      expect(find.textContaining('Xuất khung'), findsNothing);

      await tester.tap(find.text('IELTS Foundation'));
      await tester.pumpAndSettle();
      expect(find.text('1/2 bài học đã hoàn thành'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 375.0, 430.0, 800.0, 1200.0]) {
    testWidgets('khóa học thích ứng ở $width px', (tester) async {
      tester.view.physicalSize = Size(width, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StudentCoursesScreen())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Khóa học của tôi'), findsOneWidget);
      expect(find.text('IELTS Foundation'), findsOneWidget);
      if (width < 600) {
        expect(
          find.byKey(const ValueKey('student-courses-mobile-list')),
          findsOneWidget,
        );
      } else {
        expect(
          find.byKey(const ValueKey('student-courses-mobile-list')),
          findsNothing,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
}
