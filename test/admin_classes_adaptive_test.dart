import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/data/models/class_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/domain/repositories/classes_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/presentation/bloc/classes_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/presentation/screens/class_list_screen.dart';

class _ClassesRepository extends Fake implements ClassesRepository {
  _ClassesRepository({this.empty = false, this.fail = false, this.waitFor});

  final bool empty;
  final bool fail;
  final Completer<void>? waitFor;

  @override
  Future<List<ClassModel>> getClasses({
    String? search,
    String? status,
    String? branchId,
    String? courseId,
    String? teacherId,
    int page = 1,
    int limit = 50,
  }) async {
    if (waitFor != null) await waitFor!.future;
    if (fail) throw StateError('Không thể tải lớp');
    if (empty) return [];
    return const [
      ClassModel(
        id: 'class-1',
        code: 'IELTS-F-01',
        name: 'Lớp IELTS Foundation K01',
        courseId: 'course-1',
        courseTitle: 'IELTS Foundation',
        levelId: 'level-1',
        branchId: 'branch-1',
        branchName: 'Quận 1',
        roomName: 'Phòng Smart 101',
        mainTeacherName: 'Nguyễn Văn Dũng',
        status: 'IN_PROGRESS',
        scheduleDays: ['MONDAY', 'WEDNESDAY'],
        startTime: '18:00',
        endTime: '19:30',
        studentsCount: 12,
        maxCapacity: 20,
      ),
    ];
  }
}

void main() {
  for (final width in [320.0, 375.0, 393.0, 430.0, 800.0, 1200.0]) {
    testWidgets('quản lý lớp ở $width px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => ClassesBloc(repository: _ClassesRepository()),
            child: const ClassListScreen(showAppBar: false),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Lớp IELTS Foundation K01'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Mobile tìm kiếm với bàn phím và trạng thái rỗng', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => ClassesBloc(repository: _ClassesRepository()),
          child: const ClassListScreen(showAppBar: false),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'không có lớp này');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Không có lớp học phù hợp'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Không có lớp học phù hợp'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile lọc lớp theo trạng thái thật', (tester) async {
    tester.view.physicalSize = const Size(375, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => ClassesBloc(repository: _ClassesRepository()),
          child: const ClassListScreen(showAppBar: false),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final completedChip = find.text('Đã kết thúc');
    await tester.ensureVisible(completedChip);
    await tester.tap(completedChip);
    await tester.pumpAndSettle();
    expect(find.text('Không có lớp học phù hợp'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile hiển thị loading trước khi API trả dữ liệu', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final waitFor = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) =>
              ClassesBloc(repository: _ClassesRepository(waitFor: waitFor)),
          child: const ClassListScreen(showAppBar: false),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Đang tải danh sách lớp...'), findsOneWidget);
    waitFor.complete();
    await tester.pumpAndSettle();
    expect(find.text('Lớp IELTS Foundation K01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile mở chi tiết lớp và màn tạo lớp', (tester) async {
    tester.view.physicalSize = const Size(375, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
        builder: (_, _) => const ClassListScreen(showAppBar: false),
        ),
        GoRoute(
          path: '/classes/create',
        builder: (_, _) => const Scaffold(body: Text('Màn tạo lớp')),
        ),
        GoRoute(
          path: '/classes/:id',
          builder: (_, state) =>
              Scaffold(body: Text('Chi tiết ${state.pathParameters['id']}')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => ClassesBloc(repository: _ClassesRepository()),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    final detail = find.text('Xem lớp học và điểm danh');
    await tester.ensureVisible(detail);
    await tester.tap(detail);
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết class-1'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    final create = find.text('Tạo lớp học');
    await tester.ensureVisible(create);
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(find.text('Màn tạo lớp'), findsOneWidget);
  });

  for (final scenario in ['empty', 'error']) {
    testWidgets('Mobile $scenario state ở 320 px', (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => ClassesBloc(
              repository: _ClassesRepository(
                empty: scenario == 'empty',
                fail: scenario == 'error',
              ),
            ),
            child: const ClassListScreen(showAppBar: false),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(scenario == 'empty' ? 'Không có lớp học phù hợp' : 'Thử lại'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
