import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/di/injection.dart';
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
    fullName: 'Nguyễn Thị Lan',
    status: 'ACTIVE',
    isFirstLogin: false,
    roles: ['parent'],
    permissions: [],
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ClassesRepository implements ClassesRepository {
  @override
  Future<List<ClassModel>> getMyClasses() async => const [
    ClassModel(
      id: 'class-1',
      code: 'IELTS-F',
      name: 'IELTS Foundation',
      courseId: 'course-1',
      levelId: 'level-1',
      branchId: 'branch-1',
      startTime: '18:00',
      endTime: '19:30',
      students: [
        ClassStudentModel(
          id: 'enroll-1',
          classId: 'class-1',
          studentId: 'child-1',
          studentName: 'Minh Anh',
        ),
        ClassStudentModel(
          id: 'enroll-2',
          classId: 'class-1',
          studentId: 'child-2',
          studentName: 'Gia Bảo',
        ),
      ],
    ),
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(
    () => getIt.registerSingleton<ClassesRepository>(_ClassesRepository()),
  );
  tearDownAll(() => getIt.unregister<ClassesRepository>());
  for (final width in [320.0, 375.0, 393.0, 430.0, 800.0, 1200.0]) {
    testWidgets('phụ huynh theo dõi con ở $width px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bloc = AuthBloc(authRepository: _AuthRepository());
      addTearDown(bloc.close);
      bloc.add(CheckAuthStatusEvent());
      await bloc.stream.firstWhere((state) => state is AuthenticatedState);
      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: bloc,
          child: const MaterialApp(home: ParentHomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      if (width < 600) {
        expect(
          find.byKey(const ValueKey('parent-home-mobile')),
          findsOneWidget,
        );
        expect(find.text('2 con được liên kết'), findsOneWidget);
        expect(find.text('Minh Anh'), findsOneWidget);
        expect(find.text('Gia Bảo'), findsOneWidget);
        expect(find.text('Bảng Điểm & Nhận Xét'), findsNothing);
      } else {
        expect(find.byKey(const ValueKey('parent-home-mobile')), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
