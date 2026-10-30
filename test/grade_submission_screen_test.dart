import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/router/route_names.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/data/models/assignment_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/domain/repositories/assignments_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/presentation/bloc/assignments_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/presentation/screens/grade_submission_screen.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/presentation/screens/submission_review_screen.dart';

final _longEssay = List.filled(200, 'Bài luận rất dài. ').join();

class _AssignmentsRepository implements AssignmentsRepository {
  double? score;
  String? feedback;

  @override
  Future<AssignmentSubmissionsResponseModel> getAssignmentSubmissions(
    String assignmentId,
  ) async {
    final submission = SubmissionModel(
      id: 'submission-1',
      assignmentId: assignmentId,
      studentId: 'student-1',
      content: _longEssay,
      fileUrls: const [],
      submittedAt: '2026-10-26T00:00:00.000Z',
      score: score,
      feedback: feedback,
      status: score == null ? 'SUBMITTED' : 'GRADED',
    );
    return AssignmentSubmissionsResponseModel(
      assignmentId: assignmentId,
      title: 'IELTS Writing',
      maxScore: 10,
      type: 'WRITING',
      totalEnrolled: 2,
      submittedCount: 1,
      gradedCount: score == null ? 0 : 1,
      lateCount: 0,
      notSubmittedCount: 1,
      students: [
        StudentSubmissionItemModel(
          studentId: 'student-1',
          userCode: 'HV-01',
          fullName: 'Nguyễn Văn A',
          hasSubmitted: true,
          submission: submission,
        ),
        const StudentSubmissionItemModel(
          studentId: 'student-2',
          userCode: 'HV-02',
          fullName: 'Trần Thị B',
          hasSubmitted: false,
        ),
      ],
    );
  }

  @override
  Future<SubmissionModel> gradeSubmission(
    String submissionId, {
    required double score,
    String? feedback,
  }) async {
    this.score = score;
    this.feedback = feedback;
    return SubmissionModel(
      id: submissionId,
      assignmentId: 'assignment-1',
      studentId: 'student-1',
      content: _longEssay,
      fileUrls: const [],
      submittedAt: '2026-10-26T00:00:00.000Z',
      score: score,
      feedback: feedback,
      status: 'GRADED',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('danh sách chỉ có trạng thái; xem bài làm rồi lưu điểm', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _AssignmentsRepository();
    final bloc = AssignmentsBloc(repository: repository);
    addTearDown(bloc.close);
    final router = GoRouter(
      initialLocation: '/assignments/assignment-1/submissions',
      routes: [
        GoRoute(
          path: RouteNames.gradeSubmissions,
          builder: (context, state) => BlocProvider.value(
            value: bloc,
            child: GradeSubmissionScreen(
              assignmentId: state.pathParameters['id']!,
            ),
          ),
        ),
        GoRoute(
          path: RouteNames.reviewSubmission,
          builder: (context, state) => BlocProvider(
            create: (_) => AssignmentsBloc(repository: repository),
            child: SubmissionReviewScreen(
              assignmentId: state.pathParameters['id']!,
              studentId: state.pathParameters['studentId']!,
              focusScore: state.uri.queryParameters['edit'] == 'true',
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Chưa chấm bài'), findsOneWidget);
    expect(find.text('Chưa nộp bài'), findsOneWidget);
    expect(find.textContaining('Bài luận rất dài.'), findsNothing);

    await tester.tap(find.text('Xem bài làm'));
    await tester.pumpAndSettle();

    expect(find.byType(SubmissionReviewScreen), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Bài làm của học viên'), findsOneWidget);
    expect(find.textContaining('Bài luận rất dài.'), findsOneWidget);
    expect(find.text('Chấm điểm & nhận xét'), findsOneWidget);

    final gradingPosition = tester.getTopLeft(
      find.text('Chấm điểm & nhận xét'),
    );
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -450),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Chấm điểm & nhận xét')),
      gradingPosition,
    );

    await tester.enterText(find.byType(TextFormField).at(0), '8.5');
    await tester.enterText(find.byType(TextFormField).at(1), 'Bài viết rõ ý.');
    await tester.tap(find.text('Lưu điểm và nhận xét'));
    await tester.pumpAndSettle();

    expect(repository.score, 8.5);
    expect(repository.feedback, 'Bài viết rõ ý.');

    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('Sửa'), findsOneWidget);
    expect(find.textContaining('8.5 / 10.0 điểm'), findsOneWidget);

    await tester.tap(find.text('Sửa'));
    await tester.pumpAndSettle();
    expect(find.text('Xem bài làm và sửa điểm'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller
          ?.text,
      '8.5',
    );
  });

  for (final width in [320.0, 375.0, 393.0, 430.0]) {
    testWidgets('xem và chấm bài trên Mobile $width px', (tester) async {
      tester.view.physicalSize = Size(width, width == 320 ? 600 : 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _AssignmentsRepository();
      final bloc = AssignmentsBloc(repository: repository);
      addTearDown(bloc.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: const MaterialApp(
            home: SubmissionReviewScreen(
              assignmentId: 'assignment-1',
              studentId: 'student-1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('submission-review-mobile')),
        findsOneWidget,
      );
      expect(find.text('Bài làm của học viên'), findsOneWidget);
      await tester.tap(find.text('Chấm điểm'));
      await tester.pumpAndSettle();
      expect(find.text('Chấm điểm & nhận xét'), findsOneWidget);
      if (width == 320) {
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).first, '7.5');
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Lưu điểm và nhận xét'),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(find.text('Lưu điểm và nhận xét'));
        await tester.pumpAndSettle();
        expect(repository.score, 7.5);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
