import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/domain/entities/user_entity.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/domain/repositories/auth_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/presentation/bloc/auth_event.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/presentation/bloc/auth_state.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/data/models/class_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/domain/repositories/classes_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/presentation/bloc/classes_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/presentation/screens/schedule_screen.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/di/injection.dart';

class _AuthRepository implements AuthRepository {
  final List<String> roles;

  _AuthRepository(this.roles);

  @override
  Future<bool> isLoggedIn() async => true;

  @override
  Future<UserEntity> getMe() async => UserEntity(
        id: 'student-1',
        userCode: 'HV001',
        fullName: 'Học viên',
        status: 'ACTIVE',
        isFirstLogin: false,
        roles: roles,
        permissions: const [],
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ClassesRepository implements ClassesRepository {
  final List<ClassSessionModel> sessions;
  final List<ClassModel> classes;
  final ranges = <String>[];

  _ClassesRepository(this.sessions, {this.classes = const []});

  @override
  Future<List<ClassModel>> getMyClasses() async => classes;

  @override
  Future<List<ClassSessionModel>> getMySchedule({String? fromDate, String? toDate}) async {
    ranges.add('$fromDate/$toDate');
    final start = DateTime.parse(fromDate!);
    final end = DateTime.parse(toDate!);
    return sessions.where((session) {
      final date = session.date!;
      return !date.isBefore(start) && !date.isAfter(end);
    }).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('lịch học hiển thị buổi thật và tải tuần mới khi chuyển tuần', (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final today = DateTime.now();
    final monday = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday - 1));
    final repository = _ClassesRepository([
      ClassSessionModel(
        id: 'session-1',
        classId: 'class-1',
        className: 'Tiếng Anh giao tiếp',
        title: 'Buổi học thật',
        date: monday,
        startTime: '18:00',
        endTime: '19:30',
      ),
      ClassSessionModel(
        id: 'session-2',
        classId: 'class-2',
        className: 'IELTS nâng cao',
        title: 'Buổi tuần sau',
        date: monday.add(const Duration(days: 7)),
        startTime: '19:45',
        endTime: '21:15',
      ),
    ]);
    final authBloc = AuthBloc(authRepository: _AuthRepository(['student']));
    final classesBloc = ClassesBloc(repository: repository);
    addTearDown(authBloc.close);
    addTearDown(classesBloc.close);
    authBloc.add(CheckAuthStatusEvent());
    await authBloc.stream.firstWhere((state) => state is AuthenticatedState);

    await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<ClassesBloc>.value(value: classesBloc),
      ],
      child: const MaterialApp(home: ScheduleScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Tiếng Anh giao tiếp'), findsOneWidget);
    expect(find.text('IELTS nâng cao'), findsNothing);
    expect(find.text('Điểm danh'), findsNothing);

    await tester.tap(find.byTooltip('Kỳ sau'));
    await tester.pumpAndSettle();

    expect(find.text('Tiếng Anh giao tiếp'), findsNothing);
    expect(find.text('IELTS nâng cao'), findsOneWidget);
    expect(repository.ranges, hasLength(2));
    expect(repository.ranges.first, isNot(repository.ranges.last));
  });

  testWidgets('giảng viên thấy lịch dạy và thao tác điểm danh cho buổi thật', (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final today = DateTime.now();
    final repository = _ClassesRepository([
      ClassSessionModel(
        id: 'session-teacher',
        classId: 'class-teacher',
        className: 'Lớp giáo viên phụ trách',
        title: 'Buổi 1',
        date: today,
        startTime: '18:00',
        endTime: '19:30',
      ),
    ]);
    final authBloc = AuthBloc(authRepository: _AuthRepository(['teacher']));
    final classesBloc = ClassesBloc(repository: repository);
    addTearDown(authBloc.close);
    addTearDown(classesBloc.close);
    authBloc.add(CheckAuthStatusEvent());
    await authBloc.stream.firstWhere((state) => state is AuthenticatedState);

    await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<ClassesBloc>.value(value: classesBloc),
      ],
      child: const MaterialApp(home: ScheduleScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Lịch giảng dạy'), findsWidgets);
    expect(find.text('Lớp giáo viên phụ trách'), findsOneWidget);
    expect(find.text('Điểm danh'), findsOneWidget);
  });

  testWidgets('phụ huynh lọc lịch theo từng con', (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final today = DateTime.now();
    final monday = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday - 1));
    final repository = _ClassesRepository([
      ClassSessionModel(id: 's1', classId: 'c1', className: 'Lớp của An',
          title: 'Buổi An', date: monday, startTime: '08:00', endTime: '09:30'),
      ClassSessionModel(id: 's2', classId: 'c2', className: 'Lớp của Bình',
          title: 'Buổi Bình', date: monday, startTime: '10:00', endTime: '11:30'),
    ], classes: [
      const ClassModel(id: 'c1', code: 'C1', name: 'Lớp của An', courseId: 'course',
          levelId: 'level', branchId: 'branch', startTime: '08:00', endTime: '09:30',
          students: [ClassStudentModel(id: 'e1', classId: 'c1', studentId: 'an', studentName: 'Bé An')]),
      const ClassModel(id: 'c2', code: 'C2', name: 'Lớp của Bình', courseId: 'course',
          levelId: 'level', branchId: 'branch', startTime: '10:00', endTime: '11:30',
          students: [ClassStudentModel(id: 'e2', classId: 'c2', studentId: 'binh', studentName: 'Bé Bình')]),
    ]);
    getIt.registerSingleton<ClassesRepository>(repository);
    addTearDown(() => getIt.unregister<ClassesRepository>());
    final authBloc = AuthBloc(authRepository: _AuthRepository(['parent']));
    final classesBloc = ClassesBloc(repository: repository);
    addTearDown(authBloc.close);
    addTearDown(classesBloc.close);
    authBloc.add(CheckAuthStatusEvent());
    await authBloc.stream.firstWhere((state) => state is AuthenticatedState);

    await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<ClassesBloc>.value(value: classesBloc),
      ],
      child: const MaterialApp(home: ScheduleScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Lớp của An'), findsOneWidget);
    expect(find.text('Lớp của Bình'), findsOneWidget);

    await tester.tap(find.text('Tất cả con'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bé An').last);
    await tester.pumpAndSettle();

    expect(find.text('Lớp của An'), findsOneWidget);
    expect(find.text('Lớp của Bình'), findsNothing);
  });
}
