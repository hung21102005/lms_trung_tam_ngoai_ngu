import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/attendance/data/models/attendance_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/attendance/presentation/screens/attendance_mark_screen.dart';

class _Repository extends Fake implements AttendanceRepository {
  _Repository({
    this.empty = false,
    this.fail = false,
    this.failSave = false,
    this.waitFor,
  });

  final bool empty;
  final bool fail;
  final bool failSave;
  final Completer<void>? waitFor;
  List<Map<String, dynamic>>? saved;

  @override
  Future<SessionAttendanceResponseModel> getSessionAttendance(
    String sessionId,
  ) async {
    if (waitFor != null) await waitFor!.future;
    if (fail) throw StateError('Không tải được học viên');
    return SessionAttendanceResponseModel(
      sessionId: sessionId,
      classId: 'class-1',
      className:
          'IELTS Foundation T2-T4-T6 với tên lớp học dài để kiểm tra giao diện',
      classCode: 'IELTS-F-01',
      sessionNumber: 1,
      title: 'Buổi 1: Unit 1 Greetings',
      date: '2026-10-18T00:00:00.000Z',
      startTime: '18:00',
      endTime: '19:30',
      status: 'SCHEDULED',
      summary: const AttendanceSummaryModel(
        totalEnrolled: 2,
        markedCount: 0,
        present: 0,
        absent: 0,
        late: 0,
        excused: 0,
        makeup: 0,
      ),
      students: empty
          ? []
          : [
              StudentAttendanceItemModel(
                studentId: 'student-1',
                userCode: 'HV001',
                fullName: 'Nguyễn Văn A',
                status: 'PRESENT',
              ),
              StudentAttendanceItemModel(
                studentId: 'student-2',
                userCode: 'HV002',
                fullName: 'Trần Thị B',
                status: 'PRESENT',
              ),
            ],
    );
  }

  @override
  Future<SessionAttendanceResponseModel> batchMarkAttendance(
    String sessionId,
    List<Map<String, dynamic>> students, {
    bool lock = false,
  }) async {
    saved = students;
    if (failSave) throw StateError('Lưu thất bại');
    return getSessionAttendance(sessionId);
  }
}

Widget _app(_Repository repository) => MaterialApp(
  home: BlocProvider(
    create: (_) => AttendanceBloc(repository: repository),
    child: const AttendanceMarkScreen(sessionId: 'session-1'),
  ),
);

void main() {
  for (final width in [320.0, 375.0, 393.0, 430.0, 800.0, 1200.0]) {
    testWidgets('điểm danh độc lập ở $width px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app(_Repository()));
      await tester.pumpAndSettle();
      expect(find.text('Nguyễn Văn A'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Mobile đổi trạng thái, ghi chú và lưu qua repository', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _Repository();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    final firstCard = find.byKey(
      const ValueKey('attendance-student-student-1'),
    );
    await tester.tap(
      find.descendant(of: firstCard, matching: find.text('Vắng')),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -170));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(of: firstCard, matching: find.byType(TextField)),
      'Có đơn xin nghỉ',
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu điểm danh'));
    await tester.pumpAndSettle();
    expect(repository.saved, isNotNull);
    expect(repository.saved!.first['status'], 'ABSENT');
    expect(repository.saved!.first['notes'], 'Có đơn xin nghỉ');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile có empty và lỗi API', (tester) async {
    tester.view.physicalSize = const Size(375, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(_Repository(empty: true)));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có học viên trong buổi học'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(_app(_Repository(fail: true)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Không tải được điểm danh'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile loading trước khi API trả dữ liệu', (tester) async {
    tester.view.physicalSize = const Size(393, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final gate = Completer<void>();
    await tester.pumpWidget(_app(_Repository(waitFor: gate)));
    await tester.pump();
    expect(find.text('Đang tải danh sách học viên...'), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Nguyễn Văn A'), findsOneWidget);
  });

  testWidgets('Mobile lọc trạng thái và đánh dấu tất cả có mặt', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(_Repository()));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -180));
    await tester.pumpAndSettle();
    final firstCard = find.byKey(
      const ValueKey('attendance-student-student-1'),
    );
    await tester.tap(
      find.descendant(of: firstCard, matching: find.text('Vắng')),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('attendance-filters')),
      const Offset(-240, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('attendance-filter-ABSENT')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('attendance-student-student-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('attendance-student-student-2')),
      findsNothing,
    );
    await tester.ensureVisible(find.text('Tất cả có mặt'));
    await tester.tap(find.text('Tất cả có mặt'));
    await tester.pumpAndSettle();
    expect(find.text('Không có học viên ở trạng thái này'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lỗi lưu vẫn giữ trạng thái chưa lưu trên Mobile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(_Repository(failSave: true)));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -180));
    await tester.pumpAndSettle();
    final firstCard = find.byKey(
      const ValueKey('attendance-student-student-1'),
    );
    await tester.tap(
      find.descendant(of: firstCard, matching: find.text('Vắng')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu điểm danh'));
    await tester.pumpAndSettle();
    expect(firstCard, findsOneWidget);
    expect(
      find.descendant(of: firstCard, matching: find.text('Ghi chú')),
      findsOneWidget,
    );
    expect(find.textContaining('Lưu thất bại'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
