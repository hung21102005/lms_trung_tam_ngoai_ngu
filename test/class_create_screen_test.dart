import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/presentation/bloc/classes_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/domain/repositories/classes_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/data/models/class_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/presentation/screens/class_create_screen.dart';

class FakeClassesRepository implements ClassesRepository {
  Map<String, String?>? createdSelection;

  @override
  Future<List<ClassModel>> getClasses({
    String? search,
    String? status,
    String? branchId,
    String? courseId,
    String? teacherId,
    int page = 1,
    int limit = 50,
  }) async => [];

  @override
  Future<ClassModel> getClassDetail(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<ClassModel> createClass({
    required String code,
    required String name,
    required String courseId,
    required String levelId,
    required String branchId,
    String? roomId,
    String? mainTeacherId,
    String? assistantTeacherId,
    String status = 'PLANNING',
    required String startDate,
    required List<String> scheduleDays,
    required String startTime,
    required String endTime,
    int totalSessions = 24,
    int maxCapacity = 20,
    double? tuitionFee,
    String? notes,
  }) async {
    createdSelection = {
      'courseId': courseId,
      'levelId': levelId,
      'branchId': branchId,
      'roomId': roomId,
      'mainTeacherId': mainTeacherId,
    };
    throw StateError('Captured create request');
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
    String? notes,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ClassStudentModel> enrollStudent(
    String classId, {
    required String studentId,
    double tuitionPaid = 0,
    String? notes,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> removeStudent(String classId, String studentId) async {}

  @override
  Future<List<ClassSessionModel>> getClassSessions(String classId) async => [];

  @override
  Future<ClassSessionModel> updateSession(
    String sessionId, {
    String? date,
    String? startTime,
    String? endTime,
    String? roomId,
    String? teacherId,
    String? status,
    String? notes,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<ClassModel>> getMyClasses() async => [];

  @override
  Future<List<ClassSessionModel>> getMySchedule({
    String? fromDate,
    String? toDate,
  }) async => [];
}

void main() {
  late ClassesBloc classesBloc;
  late FakeClassesRepository repository;

  setUp(() {
    repository = FakeClassesRepository();
    classesBloc = ClassesBloc(repository: repository);
  });

  tearDown(() {
    classesBloc.close();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<ClassesBloc>.value(
        value: classesBloc,
        child: ClassCreateScreen(
          catalogFetch: (path, {queryParameters}) async {
            if (path == '/branches') return <dynamic>[];
            return {'items': <dynamic>[], 'totalPages': 1};
          },
        ),
      ),
    );
  }

  testWidgets(
    'ClassCreateScreen renders form fields and validates empty submission',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());

      // Verify fields exist
      expect(find.text('Mở Lớp Học Mới'), findsOneWidget);
      expect(find.text('Mã lớp học *'), findsOneWidget);
      expect(find.text('Tên hiển thị của lớp *'), findsOneWidget);
      expect(find.text('Tạo Lớp & Tự Động Sinh Buổi Học'), findsOneWidget);

      // Tap submit button
      await tester.tap(find.text('Tạo Lớp & Tự Động Sinh Buổi Học'));
      await tester.pump();

      // Verify validation errors appear
      expect(find.text('Vui lòng nhập mã lớp'), findsOneWidget);
      expect(find.text('Vui lòng nhập tên lớp'), findsOneWidget);
    },
  );

  testWidgets('selects existing records and submits their IDs', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<dynamic> fetch(
      String path, {
      Map<String, dynamic>? queryParameters,
    }) async {
      switch (path) {
        case '/courses':
          return {
            'items': [
              {'id': 'course-1', 'title': 'IELTS', 'code': 'IELTS'},
            ],
            'totalPages': 1,
          };
        case '/branches':
          return [
            {'id': 'branch-1', 'name': 'Quận 1', 'code': 'Q1'},
          ];
        case '/courses/course-1/levels':
          return [
            {'id': 'level-1', 'name': 'Foundation', 'code': 'F'},
          ];
        case '/branches/branch-1/rooms':
          return [
            {'id': 'room-1', 'name': 'Phòng 101', 'code': 'P101'},
          ];
        case '/users/teachers/lookup':
          return [
            {
              'id': 'teacher-1',
              'fullName': 'Nguyễn Văn Dũng',
              'userCode': 'GV-0001',
            },
          ];
      }
      throw StateError('Unexpected path: $path');
    }

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<ClassesBloc>.value(
          value: classesBloc,
          child: ClassCreateScreen(catalogFetch: fetch),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> choose(String label, String option) async {
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is DropdownMenu<String> &&
              widget.label is Text &&
              (widget.label! as Text).data == label,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(option).last);
      await tester.pumpAndSettle();
    }

    await choose('Khóa học *', 'IELTS (IELTS)');
    await choose('Cấp độ *', 'Foundation (F)');
    await choose('Chi nhánh *', 'Quận 1 (Q1)');
    await choose('Phòng học', 'Phòng 101 (P101)');
    await choose('Giáo viên phụ trách chính', 'Nguyễn Văn Dũng (GV-0001)');

    await tester.enterText(find.byType(TextFormField).at(0), 'IELTS-01');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'IELTS Foundation',
    );
    await tester.ensureVisible(find.text('Tạo Lớp & Tự Động Sinh Buổi Học'));
    await tester.tap(find.text('Tạo Lớp & Tự Động Sinh Buổi Học'));
    await tester.pumpAndSettle();

    expect(repository.createdSelection, {
      'courseId': 'course-1',
      'levelId': 'level-1',
      'branchId': 'branch-1',
      'roomId': 'room-1',
      'mainTeacherId': 'teacher-1',
    });
  });
}
