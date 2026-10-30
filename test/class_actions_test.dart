import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/network/api_exception.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/data/models/class_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/domain/repositories/classes_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/presentation/bloc/classes_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/presentation/screens/class_list_screen.dart';

class _MockClassesRepository implements ClassesRepository {
  List<ClassModel> classes = [];
  int deleteCallCount = 0;
  int updateCallCount = 0;
  String? lastUpdatedStatus;
  Object? deleteError;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

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
    return List.from(classes);
  }

  @override
  Future<void> deleteClass(String id) async {
    deleteCallCount++;
    if (deleteError != null) throw deleteError!;
    classes.removeWhere((c) => c.id == id);
  }

  @override
  Future<ClassModel> updateClass(
    String id, {
    String? code,
    String? name,
    String? roomId,
    String? mainTeacherId,
    String? assistantTeacherId,
    String? status,
    String? startDate,
    List<String>? scheduleDays,
    String? startTime,
    String? endTime,
    int? maxCapacity,
    double? tuitionFee,
    String? registrationOpenAt,
    String? registrationCloseAt,
    String? notes,
  }) async {
    updateCallCount++;
    lastUpdatedStatus = status;
    final index = classes.indexWhere((c) => c.id == id);
    if (index >= 0) {
      final old = classes[index];
      final updated = old.copyWith(
        code: code ?? old.code,
        name: name ?? old.name,
        roomName: roomId ?? old.roomName,
        mainTeacherName: mainTeacherId ?? old.mainTeacherName,
        status: status ?? old.status,
        scheduleDays: scheduleDays ?? old.scheduleDays,
        startTime: startTime ?? old.startTime,
        endTime: endTime ?? old.endTime,
        maxCapacity: maxCapacity ?? old.maxCapacity,
        notes: notes ?? old.notes,
      );
      classes[index] = updated;
      return updated;
    }
    throw Exception('Class not found');
  }
}

void main() {
  late _MockClassesRepository repository;
  late ClassesBloc classesBloc;

  setUp(() {
    repository = _MockClassesRepository();
    classesBloc = ClassesBloc(repository: repository);
  });

  tearDown(() {
    classesBloc.close();
  });

  Widget buildSubject({double width = 1200}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 900)),
        child: BlocProvider<ClassesBloc>.value(
          value: classesBloc,
          child: const ClassListScreen(showAppBar: false),
        ),
      ),
    );
  }

  group('Class Actions - Business Rules in Desktop Table View', () {
    testWidgets(
      'PLANNING class with 0 students displays "Xóa lớp học" but NOT "Hủy lớp học"',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        repository.classes = [
          const ClassModel(
            id: 'cls-1',
            code: 'CLS-PLAN-01',
            name: 'Lớp Kế Hoạch 01',
            courseId: 'course-1',
            levelId: 'level-1',
            branchId: 'branch-1',
            startTime: '08:00',
            endTime: '09:30',
            status: 'PLANNING',
            studentsCount: 0,
            maxCapacity: 20,
          ),
        ];

        await tester.pumpWidget(buildSubject(width: 1200));
        await tester.pumpAndSettle();

        final moreButton = find.byTooltip('Tùy chọn lớp học');
        expect(moreButton, findsOneWidget);
        await tester.tap(moreButton);
        await tester.pumpAndSettle();

        expect(find.text('Chi tiết lớp học'), findsOneWidget);
        expect(find.text('Lịch học & Xếp lịch'), findsOneWidget);
        expect(find.text('Đổi trạng thái lớp'), findsOneWidget);
        expect(find.text('Xóa lớp học'), findsOneWidget);
        expect(find.text('Hủy lớp học'), findsNothing);
      },
    );

    testWidgets(
      'IN_PROGRESS class with students displays "Hủy lớp học" but NOT "Xóa lớp học"',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        repository.classes = [
          const ClassModel(
            id: 'cls-2',
            code: 'CLS-RUN-02',
            name: 'Lớp Đang Vận Hành 02',
            courseId: 'course-1',
            levelId: 'level-1',
            branchId: 'branch-1',
            startTime: '18:00',
            endTime: '19:30',
            status: 'IN_PROGRESS',
            studentsCount: 15,
            maxCapacity: 20,
          ),
        ];

        await tester.pumpWidget(buildSubject(width: 1200));
        await tester.pumpAndSettle();

        final moreButton = find.byTooltip('Tùy chọn lớp học');
        expect(moreButton, findsOneWidget);
        await tester.tap(moreButton);
        await tester.pumpAndSettle();

        expect(find.text('Chi tiết lớp học'), findsOneWidget);
        expect(find.text('Lịch học & Xếp lịch'), findsOneWidget);
        expect(find.text('Đổi trạng thái lớp'), findsOneWidget);
        expect(find.text('Hủy lớp học'), findsOneWidget);
        expect(find.text('Xóa lớp học'), findsNothing);
      },
    );

    testWidgets(
      'CANCELLED class displays neither "Xóa lớp học" nor "Hủy lớp học"',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        repository.classes = [
          const ClassModel(
            id: 'cls-3',
            code: 'CLS-CANC-03',
            name: 'Lớp Đã Hủy 03',
            courseId: 'course-1',
            levelId: 'level-1',
            branchId: 'branch-1',
            startTime: '14:00',
            endTime: '15:30',
            status: 'CANCELLED',
            studentsCount: 5,
            maxCapacity: 20,
          ),
        ];

        await tester.pumpWidget(buildSubject(width: 1200));
        await tester.pumpAndSettle();

        final moreButton = find.byTooltip('Tùy chọn lớp học');
        expect(moreButton, findsOneWidget);
        await tester.tap(moreButton);
        await tester.pumpAndSettle();

        expect(find.text('Chi tiết lớp học'), findsOneWidget);
        expect(find.text('Đổi trạng thái lớp'), findsOneWidget);
        expect(find.text('Xóa lớp học'), findsNothing);
        expect(find.text('Hủy lớp học'), findsNothing);
      },
    );
  });

  group('Class Actions - Execution & UI State Updates', () {
    testWidgets(
      'Confirming Cancel Class calls updateClass with CANCELLED and refetches immediately',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        repository.classes = [
          const ClassModel(
            id: 'cls-10',
            code: 'CLS-10',
            name: 'Lớp Chuẩn Bị Hủy',
            courseId: 'course-1',
            levelId: 'level-1',
            branchId: 'branch-1',
            startTime: '18:00',
            endTime: '19:30',
            status: 'IN_PROGRESS',
            studentsCount: 10,
            maxCapacity: 20,
          ),
        ];

        await tester.pumpWidget(buildSubject(width: 1200));
        await tester.pumpAndSettle();

        // Open menu
        await tester.tap(find.byTooltip('Tùy chọn lớp học'));
        await tester.pumpAndSettle();

        // Tap 'Hủy lớp học'
        await tester.tap(find.text('Hủy lớp học'));
        await tester.pumpAndSettle();

        // Confirm dialog appears
        expect(find.text('Xác nhận hủy lớp học'), findsOneWidget);
        expect(find.text('Xác nhận hủy lớp'), findsOneWidget);

        // Tap confirm button
        await tester.tap(find.text('Xác nhận hủy lớp'));
        await tester.pumpAndSettle();

        expect(repository.updateCallCount, 1);
        expect(repository.lastUpdatedStatus, 'CANCELLED');
        expect(
          find.text('Đã hủy lớp học thành công (dữ liệu học vụ đã được lưu trữ).'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Deleting class with matching code calls repository.deleteClass and removes from view without F5',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        repository.classes = [
          const ClassModel(
            id: 'cls-del-1',
            code: 'DEL-001',
            name: 'Lớp Thử Nghiệm Xóa',
            courseId: 'course-1',
            levelId: 'level-1',
            branchId: 'branch-1',
            startTime: '08:00',
            endTime: '09:30',
            status: 'PLANNING',
            studentsCount: 0,
            maxCapacity: 20,
          ),
        ];

        await tester.pumpWidget(buildSubject(width: 1200));
        await tester.pumpAndSettle();

        // Open menu
        await tester.tap(find.byTooltip('Tùy chọn lớp học'));
        await tester.pumpAndSettle();

        // Tap 'Xóa lớp học'
        await tester.tap(find.text('Xóa lớp học'));
        await tester.pumpAndSettle();

        expect(find.text('Xác nhận xóa lớp học'), findsOneWidget);

        // Enter matching code
        await tester.enterText(find.byType(TextField).last, 'DEL-001');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Xác nhận xóa'));
        await tester.pumpAndSettle();

        expect(repository.deleteCallCount, 1);
        expect(find.text('Đã xóa lớp học thành công'), findsOneWidget);
      },
    );

    testWidgets(
      'Backend delete failure preserves state and presents clean domain error dialog without crash',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        repository.classes = [
          const ClassModel(
            id: 'cls-fail-1',
            code: 'FAIL-01',
            name: 'Lớp Lỗi Xóa',
            courseId: 'course-1',
            levelId: 'level-1',
            branchId: 'branch-1',
            startTime: '08:00',
            endTime: '09:30',
            status: 'PLANNING',
            studentsCount: 0,
            maxCapacity: 20,
          ),
        ];
        repository.deleteError = const ApiException(
          message: 'Không thể xóa lớp đã phát sinh dữ liệu liên quan.',
          statusCode: 400,
        );

        await tester.pumpWidget(buildSubject(width: 1200));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Tùy chọn lớp học'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Xóa lớp học'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).last, 'FAIL-01');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Xác nhận xóa'));
        await tester.pumpAndSettle();

        // Friendly dialog shown
        expect(find.text('Không thể xóa lớp'), findsOneWidget);
        expect(
          find.text('Không thể xóa lớp đã phát sinh dữ liệu liên quan.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Class Actions - Mobile Screen Responsiveness', () {
    testWidgets(
      'Mobile card shows delete button for PLANNING 0-student class',
      (tester) async {
        tester.view.physicalSize = const Size(375, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        repository.classes = [
          const ClassModel(
            id: 'mob-1',
            code: 'MOB-PLAN',
            name: 'Mobile Plan Class',
            courseId: 'course-1',
            levelId: 'level-1',
            branchId: 'branch-1',
            startTime: '08:00',
            endTime: '09:30',
            status: 'PLANNING',
            studentsCount: 0,
            maxCapacity: 20,
          ),
        ];

        await tester.pumpWidget(buildSubject(width: 375));
        await tester.pumpAndSettle();

        expect(find.byTooltip('Xóa lớp học'), findsOneWidget);
        expect(find.byTooltip('Hủy lớp học'), findsNothing);
      },
    );

    testWidgets(
      'Mobile card shows cancel button for active class with students',
      (tester) async {
        tester.view.physicalSize = const Size(375, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        repository.classes = [
          const ClassModel(
            id: 'mob-2',
            code: 'MOB-RUN',
            name: 'Mobile Active Class',
            courseId: 'course-1',
            levelId: 'level-1',
            branchId: 'branch-1',
            startTime: '18:00',
            endTime: '19:30',
            status: 'IN_PROGRESS',
            studentsCount: 12,
            maxCapacity: 20,
          ),
        ];

        await tester.pumpWidget(buildSubject(width: 375));
        await tester.pumpAndSettle();

        expect(find.byTooltip('Hủy lớp học'), findsOneWidget);
        expect(find.byTooltip('Xóa lớp học'), findsNothing);
      },
    );
  });
}
