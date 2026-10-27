import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/di/injection.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/data/models/assignment_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/domain/repositories/assignments_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/presentation/bloc/assignments_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/presentation/screens/submit_assignment_screen.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/presentation/widgets/audio_recorder_widget.dart';
import 'package:lms_trung_tam_ngoai_ngu/shared/widgets/app_text_field.dart';

class _Repository implements AssignmentsRepository {
  _Repository(this.assignment);

  final AssignmentModel assignment;
  String? savedContent;

  @override
  Future<SubmissionModel> saveDraft(
    String assignmentId, {
    String? content,
    List<Map<String, dynamic>>? fileUrls,
  }) async {
    savedContent = content;
    return SubmissionModel.fromJson({
      'id': 'draft-1',
      'assignmentId': assignmentId,
      'studentId': 'student-1',
      'content': content,
      'fileUrls': fileUrls ?? [],
      'status': 'DRAFT',
      'updatedAt': '2026-10-27T12:00:00Z',
    });
  }

  @override
  Future<AssignmentModel> getAssignmentDetail(String id) async => assignment;

  @override
  Future<AssignmentAttachmentModel> uploadAttachment(
    String fileName,
    Uint8List bytes,
  ) async => AssignmentAttachmentModel(
    name: fileName,
    url: '/uploads/assignments/$fileName',
    fileType: 'DOCUMENT',
    size: bytes.length,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AssignmentModel _assignment(
  String type, {
  SubmissionModel? submission,
  String deadline = '2099-10-30T23:59:59Z',
}) => AssignmentModel(
  id: 'assignment-1',
  classId: 'class-1',
  title: '$type practice',
  type: type,
  deadline: deadline,
  maxScore: 10,
  attachments: const [],
  createdAt: '2026-10-26T00:00:00Z',
  mySubmission: submission,
);

SubmissionModel _submission() => const SubmissionModel(
  id: 'submission-1',
  assignmentId: 'assignment-1',
  studentId: 'student-1',
  content: 'Bài làm đã lưu',
  fileUrls: [],
  submittedAt: '2026-10-26T00:00:00Z',
  status: 'SUBMITTED',
);

Future<void> _pump(WidgetTester tester, AssignmentModel assignment) async {
  final repository = _Repository(assignment);
  getIt.registerSingleton<AssignmentsRepository>(repository);
  addTearDown(() async => getIt.reset());
  final bloc = AssignmentsBloc(repository: repository);
  addTearDown(bloc.close);
  await tester.pumpWidget(
    BlocProvider.value(
      value: bloc,
      child: const MaterialApp(
        home: SubmitAssignmentScreen(assignmentId: 'assignment-1'),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  for (final width in [393.0, 1200.0]) {
    testWidgets('workspace HOMEWORK không tràn ở chiều rộng $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pump(tester, _assignment('HOMEWORK'));
      expect(find.text('Yêu cầu bài tập'), findsOneWidget);
      expect(find.text('Bài làm của bạn'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Speaking gộp ghi âm và đính kèm trong một trang', (
    tester,
  ) async {
    await _pump(tester, _assignment('SPEAKING'));

    expect(find.byType(AudioRecorderWidget), findsOneWidget);
    expect(find.byType(AppTextField), findsNothing);
    expect(find.text('Chọn tệp từ máy', skipOffstage: false), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
  });

  testWidgets('Writing gộp bài viết và đính kèm trong một trang', (
    tester,
  ) async {
    await _pump(tester, _assignment('WRITING'));

    expect(find.byType(AudioRecorderWidget), findsNothing);
    expect(find.byType(AppTextField), findsOneWidget);
    expect(find.text('Chọn tệp từ máy', skipOffstage: false), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
  });

  testWidgets('Homework cho phép đủ ba cách làm bài', (tester) async {
    await _pump(tester, _assignment('HOMEWORK'));

    expect(find.byType(AudioRecorderWidget), findsOneWidget);
    expect(find.byType(AppTextField), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Chọn tệp từ máy'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Chọn tệp từ máy', skipOffstage: false), findsOneWidget);
  });

  testWidgets('bài đã nộp còn hạn được nạp lại để sửa', (tester) async {
    await _pump(tester, _assignment('WRITING', submission: _submission()));

    expect(find.text('Cập nhật bài nộp'), findsOneWidget);
    expect(find.text('Bài làm đã lưu'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(
      find.byType(ElevatedButton).last,
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('bài đã nộp hết hạn chỉ được xem', (tester) async {
    await _pump(
      tester,
      _assignment(
        'WRITING',
        submission: _submission(),
        deadline: '2020-01-01T00:00:00Z',
      ),
    );

    expect(find.textContaining('chỉ có thể xem'), findsOneWidget);
    expect(find.text('Bài làm đã lưu'), findsOneWidget);
  });

  testWidgets(
    'lưu nháp gửi nội dung tới repository và chỉ báo đã lưu sau phản hồi',
    (tester) async {
      await _pump(tester, _assignment('WRITING'));
      await tester.enterText(
        find.byType(TextField).first,
        'Bài viết đang soạn',
      );
      await tester.tap(find.text('Lưu bản nháp'));
      await tester.pumpAndSettle();

      final repository = getIt<AssignmentsRepository>() as _Repository;
      expect(repository.savedContent, 'Bài viết đang soạn');
      expect(find.textContaining('Bản nháp đã lưu'), findsOneWidget);
    },
  );
}
