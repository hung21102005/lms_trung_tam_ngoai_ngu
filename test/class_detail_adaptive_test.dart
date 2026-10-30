import 'package:dio/dio.dart';
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
import 'package:lms_trung_tam_ngoai_ngu/features/classes/presentation/screens/class_detail_screen.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/di/injection.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/network/api_client.dart';

class _ApiClient extends Fake implements ApiClient {
  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async => <dynamic>[];
}

class _AuthRepository implements AuthRepository {
  _AuthRepository({this.roles = const ['student']});

  final List<String> roles;

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
  Map<String, Object?>? updatedClass;
  bool failUpdate = false;

  @override
  Future<ClassModel> getClassDetail(String id) async => ClassModel(
    id: id,
    code: 'IELTS-F',
    name: 'IELTS Foundation',
    courseId: 'course-1',
    levelId: 'level-1',
    branchId: 'branch-1',
    mainTeacherName: 'Giảng viên A',
    roomName: 'Phòng 101',
    startTime: '18:00',
    endTime: '19:30',
    totalSessions: 24,
    studentsCount: 12,
    sessions: [
      ClassSessionModel(
        id: 'session-1',
        classId: id,
        title: 'Speaking practice',
        date: DateTime(2026, 10, 28),
        startTime: '18:00',
        endTime: '19:30',
      ),
    ],
  );

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
    if (failUpdate) throw StateError('Không lưu được lớp');
    updatedClass = {
      'id': id,
      'name': name,
      'status': status,
      'registrationOpenAt': registrationOpenAt,
      'registrationCloseAt': registrationCloseAt,
    };
    return getClassDetail(id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() => getIt.registerSingleton<ApiClient>(_ApiClient()));
  tearDownAll(() => getIt.unregister<ApiClient>());
  for (final width in [320.0, 375.0, 393.0, 430.0, 800.0, 1200.0]) {
    testWidgets('chi tiết lớp thích ứng ở $width px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final authBloc = AuthBloc(authRepository: _AuthRepository());
      final classesBloc = ClassesBloc(repository: _ClassesRepository());
      addTearDown(authBloc.close);
      addTearDown(classesBloc.close);
      authBloc.add(CheckAuthStatusEvent());
      await authBloc.stream.firstWhere((state) => state is AuthenticatedState);
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<ClassesBloc>.value(value: classesBloc),
          ],
          child: const MaterialApp(home: ClassDetailScreen(classId: 'class-1')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('IELTS Foundation'), findsWidgets);
      expect(find.text('Speaking practice'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('class-detail-mobile')),
        width < 600 ? findsOneWidget : findsNothing,
      );
      if (width < 600) {
        expect(find.text('Học viên'), findsNothing);
        expect(find.text('Điểm danh'), findsNothing);
        await tester.tap(find.text('Giáo trình'));
        await tester.pumpAndSettle();
        expect(find.text('Chưa có giáo trình cho cấp độ này.'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [320.0, 1200.0]) {
    testWidgets('quản trị sửa lớp ở $width px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final authBloc = AuthBloc(
        authRepository: _AuthRepository(roles: ['super_admin']),
      );
      final repository = _ClassesRepository();
      final classesBloc = ClassesBloc(repository: repository);
      addTearDown(authBloc.close);
      addTearDown(classesBloc.close);
      authBloc.add(CheckAuthStatusEvent());
      await authBloc.stream.firstWhere((state) => state is AuthenticatedState);
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<ClassesBloc>.value(value: classesBloc),
          ],
          child: const MaterialApp(home: ClassDetailScreen(classId: 'class-1')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Sửa thông tin lớp'));
      await tester.pumpAndSettle();
      expect(find.text('Thời gian nhận đăng ký'), findsOneWidget);
      await tester.tap(find.text('Lưu thông tin lớp'));
      await tester.pumpAndSettle();
      expect(repository.updatedClass?['id'], 'class-1');
      expect(repository.updatedClass?['registrationOpenAt'], isNotNull);
      expect(repository.updatedClass?['registrationCloseAt'], isNotNull);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Mobile giữ form sửa lớp khi API lỗi và bàn phím mở', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 650);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final authBloc = AuthBloc(
      authRepository: _AuthRepository(roles: ['super_admin']),
    );
    final repository = _ClassesRepository()..failUpdate = true;
    final classesBloc = ClassesBloc(repository: repository);
    addTearDown(authBloc.close);
    addTearDown(classesBloc.close);
    authBloc.add(CheckAuthStatusEvent());
    await authBloc.stream.firstWhere((state) => state is AuthenticatedState);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<ClassesBloc>.value(value: classesBloc),
        ],
        child: const MaterialApp(home: ClassDetailScreen(classId: 'class-1')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sửa thông tin lớp'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'opening edit sheet');
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'keyboard opened');
    await tester.ensureVisible(find.text('Lưu thông tin lớp'));
    await tester.tap(find.text('Lưu thông tin lớp'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Không lưu được lớp'), findsOneWidget);
    expect(find.text('Sửa thông tin lớp'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
