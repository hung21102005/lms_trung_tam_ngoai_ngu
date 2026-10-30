import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/di/injection.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/data/models/assignment_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/domain/repositories/assignments_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/presentation/bloc/assignments_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/presentation/screens/assignment_detail_screen.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/presentation/screens/create_assignment_screen.dart';

class _Repository implements AssignmentsRepository {
  String title = 'Đề bài ban đầu';
  int updateCount = 0;

  @override
  Future<AssignmentModel> getAssignmentDetail(String id) async =>
      AssignmentModel(
        id: id,
        classId: 'class-1',
        className: 'IELTS Foundation',
        title: title,
        description: 'Hướng dẫn https://example.com',
        type: 'WRITING',
        maxScore: 10,
        attachments: const [
          AssignmentAttachmentModel(
            name: 'rubric.pdf',
            url: '/uploads/assignments/rubric.pdf',
            fileType: 'PDF',
          ),
        ],
        createdAt: '2026-10-26T00:00:00Z',
      );

  @override
  Future<AssignmentModel> updateAssignment(
    String id, {
    required String title,
    required String description,
    required String type,
    String? deadline,
    required double maxScore,
    required List<Map<String, dynamic>> attachments,
  }) async {
    expect(attachments.single['name'], 'rubric.pdf');
    this.title = title;
    updateCount++;
    return getAssignmentDetail(id);
  }

  @override
  Future<AssignmentSubmissionsResponseModel> getAssignmentSubmissions(
    String assignmentId,
  ) async => AssignmentSubmissionsResponseModel(
    assignmentId: assignmentId,
    title: title,
    maxScore: 10,
    type: 'WRITING',
    totalEnrolled: 1,
    submittedCount: 0,
    gradedCount: 0,
    lateCount: 0,
    notSubmittedCount: 1,
    students: const [
      StudentSubmissionItemModel(
        studentId: 'student-1',
        userCode: 'HV-01',
        fullName: 'Học viên A',
        hasSubmitted: false,
      ),
    ],
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('giảng viên xem nội dung, danh sách và sửa bài tập', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _Repository();
    getIt.registerSingleton<AssignmentsRepository>(repository);
    getIt.registerFactory<AssignmentsBloc>(
      () => AssignmentsBloc(repository: repository),
    );
    addTearDown(() async => getIt.reset());
    final router = GoRouter(
      initialLocation: '/assignments/assignment-1',
      routes: [
        GoRoute(
          path: '/assignments/:id',
          builder: (context, state) => BlocProvider(
            create: (_) => AssignmentsBloc(repository: repository),
            child: AssignmentDetailScreen(
              assignmentId: state.pathParameters['id']!,
              isTeacher: true,
            ),
          ),
        ),
        GoRoute(
          path: '/assignments/:id/edit',
          builder: (context, state) => BlocProvider(
            create: (_) => AssignmentsBloc(repository: repository),
            child: CreateAssignmentScreen(
              classId: '',
              assignmentId: state.pathParameters['id']!,
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Nội dung bài tập'), findsOneWidget);
    expect(find.text('Đề bài ban đầu'), findsOneWidget);
    expect(find.text('rubric.pdf'), findsOneWidget);
    expect(find.text('Học viên A'), findsNothing);

    await tester.tap(find.text('Danh sách học viên'));
    await tester.pumpAndSettle();
    expect(find.text('Học viên A'), findsOneWidget);
    expect(find.text('Chưa nộp bài'), findsOneWidget);

    await tester.tap(find.text('Nội dung bài tập'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sửa bài tập'));
    await tester.pumpAndSettle();
    expect(find.text('rubric.pdf'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Đề bài đã sửa');
    await tester.ensureVisible(find.text('Lưu thay đổi'));
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();

    expect(repository.updateCount, 1);
    expect(find.text('Đề bài đã sửa'), findsOneWidget);
  });
}
