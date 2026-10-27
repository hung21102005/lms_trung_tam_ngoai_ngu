import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/di/injection.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/data/models/assignment_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/domain/repositories/assignments_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/presentation/screens/student_assignments_view.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/data/models/class_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/domain/repositories/classes_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/presentation/bloc/classes_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/presentation/bloc/classes_event.dart';

class _Classes implements ClassesRepository {
  @override
  Future<List<ClassModel>> getMyClasses() async => [
    ClassModel.fromJson({
      'id': 'class-1',
      'code': 'IELTS-01',
      'name': 'IELTS Foundation',
      'courseId': 'course-1',
      'course': {'title': 'IELTS'},
      'levelId': 'level-1',
      'branchId': 'branch-1',
      'startTime': '18:00',
      'endTime': '19:30',
    }),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Assignments implements AssignmentsRepository {
  @override
  Future<List<AssignmentModel>> getClassAssignments(String classId) async => [
    AssignmentModel.fromJson({
      'id': 'assignment-1',
      'classId': classId,
      'title': 'Writing Task 1',
      'type': 'WRITING',
      'maxScore': '20',
      'createdAt': '2026-10-27T00:00:00Z',
      'deadline': '2099-10-30T23:59:00Z',
    }),
    AssignmentModel.fromJson({
      'id': 'assignment-2',
      'classId': classId,
      'title': 'Speaking Practice',
      'type': 'SPEAKING',
      'maxScore': '10',
      'createdAt': '2026-10-26T00:00:00Z',
      'mySubmission': {
        'id': 'sub-2',
        'assignmentId': 'assignment-2',
        'studentId': 'student-1',
        'status': 'GRADED_PENDING',
        'score': null,
        'fileUrls': [],
      },
    }),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('mobile tìm kiếm và mở bộ lọc bài tập', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    getIt.registerSingleton<AssignmentsRepository>(_Assignments());
    addTearDown(() async => getIt.reset());
    final bloc = ClassesBloc(repository: _Classes())
      ..add(const FetchMyClasses());
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: const MaterialApp(
          home: Scaffold(body: StudentAssignmentsView()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('student-assignments-mobile-search')),
      'Speaking',
    );
    await tester.pumpAndSettle();
    expect(find.text('Speaking Practice'), findsOneWidget);
    expect(find.text('Writing Task 1'), findsNothing);
    await tester.tap(find.byTooltip('Lọc và sắp xếp'));
    await tester.pumpAndSettle();
    expect(find.text('Lọc và sắp xếp'), findsOneWidget);
    expect(find.text('Sắp xếp'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 375.0, 430.0, 800.0, 1200.0]) {
    testWidgets('danh sách bài tập không tràn ở $width px', (tester) async {
      tester.view.physicalSize = Size(width, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      getIt.registerSingleton<AssignmentsRepository>(_Assignments());
      addTearDown(() async => getIt.reset());
      final bloc = ClassesBloc(repository: _Classes())
        ..add(const FetchMyClasses());
      addTearDown(bloc.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: const MaterialApp(
            home: Scaffold(body: StudentAssignmentsView()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bài tập của tôi'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'danh sách dùng dữ liệu lớp thật, thống kê và lọc đúng trạng thái',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      getIt.registerSingleton<AssignmentsRepository>(_Assignments());
      addTearDown(() async => getIt.reset());
      final classesBloc = ClassesBloc(repository: _Classes())
        ..add(const FetchMyClasses());
      addTearDown(classesBloc.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: classesBloc,
          child: const MaterialApp(
            home: Scaffold(body: StudentAssignmentsView()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bài tập của tôi'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Writing Task 1'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Writing Task 1'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Speaking Practice'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Speaking Practice'), findsOneWidget);
      expect(find.text('Chờ công bố'), findsOneWidget);
      expect(find.textContaining('Thang 20 điểm'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.widgetWithText(ChoiceChip, 'Cần làm'),
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Cần làm'));
      await tester.pumpAndSettle();
      expect(find.text('Writing Task 1'), findsOneWidget);
      expect(find.text('Speaking Practice'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
