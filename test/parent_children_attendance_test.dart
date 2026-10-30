import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/di/injection.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/router/route_names.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/domain/entities/user_entity.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/domain/repositories/auth_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/presentation/bloc/auth_event.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/presentation/bloc/auth_state.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/data/models/class_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/domain/repositories/classes_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/dashboard/presentation/screens/parent_home_screen.dart';

class _AuthRepository implements AuthRepository {
  @override
  Future<bool> isLoggedIn() async => true;

  @override
  Future<UserEntity> getMe() async => const UserEntity(
        id: 'parent-1',
        userCode: 'PH-01',
        fullName: 'Phụ huynh',
        status: 'ACTIVE',
        isFirstLogin: false,
        roles: ['parent'],
        permissions: [],
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ClassesRepository implements ClassesRepository {
  final List<ClassStudentModel> children;
  _ClassesRepository(this.children);

  @override
  Future<List<ClassModel>> getMyClasses() async => [
        ClassModel(
          id: 'class-1',
          code: 'IELTS-01',
          name: 'IELTS Foundation',
          courseId: 'course-1',
          levelId: 'level-1',
          branchId: 'branch-1',
          startTime: '16:00',
          endTime: '17:30',
          students: children,
        ),
      ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ClassStudentModel _child(String id, String name) => ClassStudentModel(
      id: 'enrollment-$id',
      classId: 'class-1',
      studentId: id,
      studentName: name,
    );

void main() {
  Future<void> mountParent(WidgetTester tester, List<ClassStudentModel> children) async {
    getIt.registerSingleton<ClassesRepository>(_ClassesRepository(children));
    final authBloc = AuthBloc(authRepository: _AuthRepository());
    addTearDown(authBloc.close);
    authBloc.add(CheckAuthStatusEvent());
    await authBloc.stream.firstWhere((state) => state is AuthenticatedState);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (context, state) => const ParentHomeScreen()),
      GoRoute(
        path: RouteNames.myAttendance,
        builder: (context, state) => Scaffold(
          body: Text('Chuyên cần: ${state.extra}'),
        ),
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
  }

  tearDown(() async => getIt.reset());

  testWidgets('phụ huynh một con mở thẳng chuyên cần của con', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mountParent(tester, [_child('child-1', 'Minh Anh')]);

    await tester.tap(find.text('Theo Dõi Điểm Danh'));
    await tester.pumpAndSettle();

    expect(find.text('Chuyên cần: child-1'), findsOneWidget);
  });

  testWidgets('phụ huynh hai con chọn đúng con trước khi xem', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mountParent(tester, [
      _child('child-1', 'Minh Anh'),
      _child('child-2', 'Gia Bảo'),
    ]);

    await tester.tap(find.text('Theo Dõi Điểm Danh'));
    await tester.pumpAndSettle();
    expect(find.text('Minh Anh'), findsOneWidget);
    expect(find.text('Gia Bảo'), findsOneWidget);

    await tester.tap(find.text('Gia Bảo'));
    await tester.pumpAndSettle();
    expect(find.text('Chuyên cần: child-2'), findsOneWidget);
  });
}
