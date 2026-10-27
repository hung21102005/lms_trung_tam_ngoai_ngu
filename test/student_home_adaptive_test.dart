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
import 'package:lms_trung_tam_ngoai_ngu/features/classes/presentation/bloc/classes_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/dashboard/presentation/screens/student_home_screen.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/notifications/presentation/bloc/notification_bloc.dart';

class _Auth implements AuthRepository {
  @override
  Future<bool> isLoggedIn() async => true;
  @override
  Future<UserEntity> getMe() async => const UserEntity(
    id: 'student-1',
    userCode: 'HV-01',
    fullName: 'Nguyễn Minh Anh',
    status: 'ACTIVE',
    isFirstLogin: false,
    roles: ['student'],
    permissions: [],
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Classes implements ClassesRepository {
  @override
  Future<List<ClassModel>> getMyClasses() async => [];
  @override
  Future<List<ClassSessionModel>> getMySchedule({
    String? fromDate,
    String? toDate,
  }) async => [
    ClassSessionModel(
      id: 'session-1',
      classId: 'class-1',
      className: 'IELTS Foundation',
      title: 'Bài học',
      date: DateTime.now().add(const Duration(days: 1)),
      startTime: '18:00',
      endTime: '19:30',
    ),
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Notifications implements NotificationsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final width in [320.0, 375.0, 393.0, 430.0, 800.0, 1200.0]) {
    testWidgets('trang chủ học viên thích ứng ở $width px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final classes = _Classes();
      getIt.registerSingleton<ClassesRepository>(classes);
      addTearDown(() async => getIt.reset());
      final auth = AuthBloc(authRepository: _Auth());
      final classesBloc = ClassesBloc(repository: classes);
      final notifications = NotificationBloc(repository: _Notifications());
      addTearDown(auth.close);
      addTearDown(classesBloc.close);
      addTearDown(notifications.close);
      auth.add(CheckAuthStatusEvent());
      await auth.stream.firstWhere((state) => state is AuthenticatedState);
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: auth),
            BlocProvider<ClassesBloc>.value(value: classesBloc),
            BlocProvider<NotificationBloc>.value(value: notifications),
          ],
          child: const MaterialApp(home: StudentHomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('student-mobile-dashboard')),
        width < 1024 ? findsOneWidget : findsNothing,
      );
      expect(find.textContaining('IELTS Foundation'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}
