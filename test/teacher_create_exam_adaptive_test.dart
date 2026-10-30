import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/exams/data/models/exam_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/exams/domain/repositories/exams_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/exams/presentation/bloc/exams_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/exams/presentation/screens/create_exam_screen.dart';

class _Repository extends Fake implements ExamsRepository {
  _Repository({this.fail = false, this.waitFor});

  final bool fail;
  final Completer<void>? waitFor;
  Map<String, dynamic>? created;

  @override
  Future<ExamModel> createExam(Map<String, dynamic> examData) async {
    if (waitFor != null) await waitFor!.future;
    if (fail) throw StateError('Không lưu được đề thi');
    created = examData;
    return ExamModel(
      id: 'exam-1',
      title: examData['title'] as String,
      durationMinutes: examData['durationMinutes'] as int,
      passPercentage: examData['passPercentage'] as double,
      totalPoints: examData['totalPoints'] as double,
      shuffleQuestions: examData['shuffleQuestions'] as bool,
      maxAttempts: examData['maxAttempts'] as int,
      status: examData['status'] as String,
    );
  }
}

Widget _app(_Repository repository) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/create'),
            child: const Text('Mở tạo đề thi'),
          ),
        ),
      ),
      GoRoute(
        path: '/create',
        builder: (_, _) => BlocProvider(
          create: (_) => ExamsBloc(repository: repository),
          child: const CreateExamScreen(classId: 'class-1'),
        ),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

Future<void> _open(WidgetTester tester, _Repository repository) async {
  await tester.pumpWidget(_app(repository));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Mở tạo đề thi'));
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 375.0, 393.0, 430.0, 800.0, 1200.0]) {
    testWidgets('form tạo đề thi ở $width px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _open(tester, _Repository());
      expect(find.text('Tạo Đề Thi / Kiểm Tra'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Mobile validate và tạo đề thi khi bàn phím mở', (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _Repository();
    await _open(tester, repository);
    await tester.tap(find.text('Tạo đề thi'));
    await tester.pumpAndSettle();
    expect(find.text('Nhập tiêu đề bài thi'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -220));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tiêu đề bài thi *'),
      'Kiểm tra cuối kỳ',
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạo đề thi'));
    await tester.pumpAndSettle();
    expect(repository.created?['title'], 'Kiểm tra cuối kỳ');
    expect(repository.created?['classId'], 'class-1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile chặn thời gian không hợp lệ', (tester) async {
    tester.view.physicalSize = const Size(393, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _Repository();
    await _open(tester, repository);
    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tiêu đề bài thi *'),
      'Kiểm tra',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Thời gian (phút) *'),
      '0',
    );
    await tester.tap(find.text('Tạo đề thi'));
    await tester.pumpAndSettle();
    expect(repository.created, isNull);
    expect(find.text('Thời gian phải lớn hơn 0'), findsOneWidget);
  });

  testWidgets('Mobile lưu bản nháp với trạng thái đúng', (tester) async {
    tester.view.physicalSize = const Size(375, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _Repository();
    await _open(tester, repository);
    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tiêu đề bài thi *'),
      'Đề nháp',
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu bản nháp').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu bản nháp').last);
    await tester.pumpAndSettle();
    expect(repository.created?['status'], 'DRAFT');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile hiển thị loading và lỗi lưu, giữ nội dung form', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final gate = Completer<void>();
    final repository = _Repository(fail: true, waitFor: gate);
    await _open(tester, repository);
    await tester.drag(find.byType(ListView).first, const Offset(0, -220));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tiêu đề bài thi *'),
      'Kiểm tra thử',
    );
    await tester.tap(find.text('Tạo đề thi'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.textContaining('Không lưu được đề thi'), findsWidgets);
    expect(find.text('Kiểm tra thử'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
