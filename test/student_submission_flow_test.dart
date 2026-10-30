import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
  String? submittedContent;
  List<Map<String, dynamic>>? submittedFiles;
  final uploadedNames = <String>[];

  @override
  Future<SubmissionModel> submitAssignment(
    String assignmentId, {
    String? content,
    List<Map<String, dynamic>>? fileUrls,
  }) async {
    submittedContent = content;
    submittedFiles = fileUrls;
    return SubmissionModel.fromJson({
      'id': 'submitted-1',
      'assignmentId': assignmentId,
      'studentId': 'student-1',
      'content': content,
      'fileUrls': fileUrls ?? [],
      'status': 'SUBMITTED',
      'submittedAt': '2026-10-27T12:00:00Z',
    });
  }

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
  ) async {
    uploadedNames.add(fileName);
    return AssignmentAttachmentModel(
      name: fileName,
      url: '/uploads/assignments/$fileName',
      fileType: fileName.endsWith('.wav') ? 'AUDIO' : 'DOCUMENT',
      size: bytes.length,
    );
  }

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

final class _MemoryFile extends PlatformFile {
  _MemoryFile(this.name, this.bytes);
  @override
  final String name;
  final Uint8List bytes;
  @override
  Uri get uri => Uri.dataFromBytes(bytes);
  @override
  Never get xFile => throw UnimplementedError();
  @override
  int? lengthSync() => bytes.length;
  @override
  Future<int?> length() async => bytes.length;
  @override
  Future<Uint8List> readAsBytes() async => bytes;
  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(bytes);
}

class _Picker extends FilePickerPlatform {
  _Picker(this.files);
  final List<PlatformFile> files;
  List<String>? requestedExtensions;

  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    requestedExtensions = allowedExtensions;
    return files;
  }
}

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

Future<_Repository> _pumpMobileRoute(
  WidgetTester tester,
  AssignmentModel assignment,
) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repository = _Repository(assignment);
  getIt.registerSingleton<AssignmentsRepository>(repository);
  addTearDown(() async => getIt.reset());
  final bloc = AssignmentsBloc(repository: repository);
  addTearDown(bloc.close);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('Home')),
      ),
      GoRoute(
        path: '/submit',
        builder: (_, _) => BlocProvider.value(
          value: bloc,
          child: const SubmitAssignmentScreen(assignmentId: 'assignment-1'),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  router.push('/submit');
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets('mobile upload TXT ZIP RAR rồi nộp qua repository', (
    tester,
  ) async {
    final originalPicker = FilePickerPlatform.instance;
    final picker = _Picker([
      _MemoryFile('notes.txt', Uint8List.fromList([1, 2])),
      _MemoryFile('project.zip', Uint8List.fromList([3, 4])),
      _MemoryFile('archive.rar', Uint8List.fromList([5, 6])),
    ]);
    FilePickerPlatform.instance = picker;
    addTearDown(() => FilePickerPlatform.instance = originalPicker);
    final repository = await _pumpMobileRoute(tester, _assignment('PROJECT'));
    await tester.scrollUntilVisible(
      find.text('Chọn tệp từ máy'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Chọn tệp từ máy'));
    await tester.pumpAndSettle();
    expect(picker.requestedExtensions, containsAll(['txt', 'zip', 'rar']));
    expect(find.text('notes.txt'), findsOneWidget);
    await tester.tap(find.text('Nộp bài'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      repository.uploadedNames,
      containsAll(['notes.txt', 'project.zip', 'archive.rar']),
    );
    expect(repository.submittedFiles, hasLength(3));
    expect(find.text('Nộp bài thành công'), findsOneWidget);
    await tester.tap(find.text('Xem bài tập'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile ghi âm chuyển bytes vào upload và submit', (
    tester,
  ) async {
    final repository = await _pumpMobileRoute(tester, _assignment('SPEAKING'));
    tester
        .widget<AudioRecorderWidget>(find.byType(AudioRecorderWidget))
        .onAudioRecorded('speaking.wav', Uint8List.fromList([1, 2, 3]), 3);
    await tester.pump();
    await tester.tap(find.text('Nộp bài'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(repository.uploadedNames, contains('speaking.wav'));
    expect(repository.submittedFiles, hasLength(1));
    expect(find.text('Nộp bài thành công'), findsOneWidget);
    await tester.tap(find.text('Xem bài tập'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile sửa và nộp lại bài còn hạn', (tester) async {
    final repository = await _pumpMobileRoute(
      tester,
      _assignment('WRITING', submission: _submission()),
    );
    await tester.enterText(find.byType(TextField).first, 'Bài viết đã sửa');
    await tester.tap(find.text('Cập nhật bài'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(repository.submittedContent, 'Bài viết đã sửa');
    expect(find.text('Nộp bài thành công'), findsOneWidget);
    await tester.tap(find.text('Xem bài tập'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile bàn phím không che nút nộp', (tester) async {
    await _pumpMobileRoute(tester, _assignment('WRITING'));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    final submit = find.widgetWithText(FilledButton, 'Nộp bài');
    expect(submit, findsOneWidget);
    expect(tester.getBottomLeft(submit).dy, lessThanOrEqualTo(552));
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile lưu nháp và nộp bài viết qua repository', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _Repository(_assignment('WRITING'));
    getIt.registerSingleton<AssignmentsRepository>(repository);
    addTearDown(() async => getIt.reset());
    final bloc = AssignmentsBloc(repository: repository);
    addTearDown(bloc.close);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/submit',
          builder: (_, _) => BlocProvider.value(
            value: bloc,
            child: const SubmitAssignmentScreen(assignmentId: 'assignment-1'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.push('/submit');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Bài viết mobile');
    await tester.tap(find.text('Lưu nháp'));
    await tester.pumpAndSettle();
    expect(repository.savedContent, 'Bài viết mobile');
    ScaffoldMessenger.of(tester.element(find.byType(SubmitAssignmentScreen)))
        .removeCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nộp bài'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(repository.submittedContent, 'Bài viết mobile');
    expect(find.text('Nộp bài thành công'), findsOneWidget);
    await tester.tap(find.text('Xem bài tập'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 375.0, 393.0, 430.0, 800.0, 1200.0]) {
    testWidgets('workspace HOMEWORK không tràn ở chiều rộng $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pump(tester, _assignment('HOMEWORK'));
      expect(
        find.text(width < 600 ? 'Đề bài & hướng dẫn' : 'Yêu cầu bài tập'),
        findsOneWidget,
      );
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
