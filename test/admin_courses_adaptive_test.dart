import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/data/models/course_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/domain/repositories/courses_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/presentation/bloc/courses_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/presentation/screens/course_list_screen.dart';

class _CoursesRepository extends Fake implements CoursesRepository {
  _CoursesRepository({this.empty = false, this.fail = false, this.waitFor});

  final bool empty;
  final bool fail;
  final Completer<void>? waitFor;

  @override
  Future<List<CourseModel>> getCourses({
    String? search,
    String? language,
    bool? isActive,
    int page = 1,
    int limit = 50,
  }) async {
    if (waitFor != null) await waitFor!.future;
    if (fail) throw StateError('Lỗi tải khóa học');
    if (empty) return [];
    return const [
      CourseModel(
        id: 'course-1',
        code: 'IELTS-F',
        title: 'IELTS Foundation',
        description: 'Luyện nền tảng tiếng Anh',
        levelsCount: 2,
        classesCount: 3,
      ),
      CourseModel(
        id: 'course-2',
        code: 'COMM-A1',
        title: 'Giao tiếp A1',
        isActive: false,
      ),
    ];
  }
}

Widget _app(_CoursesRepository repository) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => BlocProvider(
          create: (_) => CoursesBloc(repository: repository),
          child: const CourseListScreen(showAppBar: false),
        ),
      ),
      GoRoute(
        path: '/courses/:id',
        builder: (context, state) =>
            Scaffold(body: Text('Chi tiết ${state.pathParameters['id']}')),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  for (final width in [320.0, 375.0, 393.0, 430.0, 800.0, 1200.0]) {
    testWidgets('danh sách khóa học ở $width px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app(_CoursesRepository()));
      await tester.pumpAndSettle();
      expect(find.text('IELTS Foundation'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Mobile tìm kiếm với bàn phím và lọc trạng thái', (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(_app(_CoursesRepository()));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -350));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'COMM');
    await tester.pumpAndSettle();
    expect(find.text('Giao tiếp A1'), findsOneWidget);
    await tester.ensureVisible(find.text('Đang hoạt động'));
    await tester.tap(find.text('Đang hoạt động'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Không có khóa học phù hợp').first,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Không có khóa học phù hợp'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile hiển thị loading', (tester) async {
    tester.view.physicalSize = const Size(375, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final gate = Completer<void>();
    await tester.pumpWidget(_app(_CoursesRepository(waitFor: gate)));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('IELTS Foundation'), findsOneWidget);
  });

  testWidgets('Mobile hiển thị empty và API error', (tester) async {
    tester.view.physicalSize = const Size(393, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(_CoursesRepository(empty: true)));
    await tester.pumpAndSettle();
    expect(find.text('Không có khóa học phù hợp'), findsOneWidget);
    await tester.pumpWidget(_app(_CoursesRepository(fail: true)));
    await tester.pumpAndSettle();
    expect(find.text('Thử lại'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile mở chi tiết khóa học theo ID', (tester) async {
    tester.view.physicalSize = const Size(430, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(_CoursesRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('IELTS Foundation').first);
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết course-1'), findsOneWidget);
  });
}
