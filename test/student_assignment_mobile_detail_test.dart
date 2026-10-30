import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/data/models/assignment_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/domain/repositories/assignments_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/presentation/bloc/assignments_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/presentation/screens/assignment_detail_screen.dart';

class _DetailRepository implements AssignmentsRepository {
  _DetailRepository(this.assignment);

  final AssignmentModel assignment;

  @override
  Future<AssignmentModel> getAssignmentDetail(String id) async => assignment;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AssignmentModel _assignment(String status) => AssignmentModel.fromJson({
  'id': 'assignment-1',
  'classId': 'class-1',
  'className': 'IELTS Foundation',
  'title': 'Writing Task 1',
  'description': 'Viết về quê hương.',
  'type': 'WRITING',
  'maxScore': 10,
  'deadline': '2099-10-30T23:59:00Z',
  'createdAt': '2026-10-27T00:00:00Z',
  'mySubmission': {
    'id': 'sub-1',
    'assignmentId': 'assignment-1',
    'studentId': 'student-1',
    'status': status,
    'content': 'My hometown is quiet.',
    'score': 8.5,
    'feedback': 'Good structure.',
    'fileUrls': [],
  },
});

void main() {
  for (final width in [320.0, 375.0, 393.0, 430.0]) {
    testWidgets('chi tiết mobile không tràn ở $width px', (tester) async {
      tester.view.physicalSize = Size(width, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bloc = AssignmentsBloc(
        repository: _DetailRepository(_assignment('GRADED')),
      );
      addTearDown(bloc.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: const MaterialApp(
            home: AssignmentDetailScreen(assignmentId: 'assignment-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('student-assignment-mobile-detail')),
        findsOneWidget,
      );
      expect(find.text('Đã chấm'), findsOneWidget);
      expect(find.text('8.5 / 10.0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('điểm chưa công bố không hiện trên mobile', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bloc = AssignmentsBloc(
      repository: _DetailRepository(_assignment('GRADED_PENDING')),
    );
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: const MaterialApp(
          home: AssignmentDetailScreen(assignmentId: 'assignment-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chờ công bố'), findsOneWidget);
    expect(find.text('8.5 / 10.0'), findsNothing);
    expect(find.text('Good structure.'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
