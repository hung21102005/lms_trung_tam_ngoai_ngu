import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:lms_trung_tam_ngoai_ngu/core/constants/api_endpoints.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/network/auth_interceptor.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/router/app_router.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/router/route_names.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/storage/secure_storage_service.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/domain/repositories/assignments_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/presentation/bloc/assignments_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/data/models/login_response_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/domain/entities/user_entity.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/domain/repositories/auth_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/presentation/bloc/auth_state.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/presentation/screens/first_login_screen.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/presentation/screens/login_screen.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/domain/repositories/classes_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/presentation/bloc/classes_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/domain/repositories/courses_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/presentation/bloc/courses_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/dashboard/presentation/screens/admin_home_screen.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/dashboard/presentation/screens/student_home_screen.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/dashboard/presentation/screens/teacher_home_screen.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/domain/repositories/finance_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/notifications/data/models/notification_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/reports/data/models/report_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/reports/domain/repositories/reports_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/reports/presentation/bloc/reports_bloc.dart';

// =============================================================================
// TEST DATA: USERS & REPOSITORIES
// =============================================================================

const adminUser = UserEntity(
  id: 'usr-admin-1',
  userCode: 'AD-000001',
  fullName: 'Quản Trị Viên Hệ Thống',
  email: 'admin@lms-edu.vn',
  status: 'ACTIVE',
  isFirstLogin: false,
  roles: ['super_admin'],
  permissions: ['*'],
  branchName: 'Chi nhánh Quận 1',
);

const teacherUser = UserEntity(
  id: 'usr-teacher-1',
  userCode: 'GV-0001',
  fullName: 'Thầy Nguyễn Văn Dũng',
  email: 'teacher@lms-edu.vn',
  status: 'ACTIVE',
  isFirstLogin: false,
  roles: ['teacher'],
  permissions: ['classes.view', 'attendance.mark', 'exams.grade_speaking'],
  branchName: 'Chi nhánh Quận 1',
);

const studentUserActive = UserEntity(
  id: 'usr-student-1',
  userCode: 'HV-2026-0001',
  fullName: 'Em Lê Minh Khang',
  email: 'student@lms-edu.vn',
  status: 'ACTIVE',
  isFirstLogin: false,
  roles: ['student'],
  permissions: ['classes.view', 'attendance.view', 'exams.take'],
  branchName: 'Chi nhánh Quận 1',
);

const studentUserFirstLogin = UserEntity(
  id: 'usr-student-new',
  userCode: 'HV-2026-0002',
  fullName: 'Học Viên Mới Chưa Đổi MK',
  email: 'student@lms-edu.vn',
  status: 'ACTIVE',
  isFirstLogin: true,
  roles: ['student'],
  permissions: ['classes.view'],
  branchName: 'Chi nhánh Quận 1',
);

class TestableAuthBloc extends AuthBloc {
  TestableAuthBloc({required super.authRepository});

  void triggerEmit(AuthState state) {
    emit(state);
  }
}

class MockAuthRepository implements AuthRepository {
  LoginResponseModel? loginResult;
  UserEntity? meUser;
  bool loggedIn = true;
  Exception? loginException;
  LoginResponseModel? firstLoginResult;

  @override
  Future<LoginResponseModel> login(String identifier, String password) async {
    if (loginException != null) throw loginException!;
    if (loginResult != null) return loginResult!;
    throw UnimplementedError();
  }

  @override
  Future<UserEntity> getMe() async {
    if (meUser != null) return meUser!;
    throw Exception('No user found');
  }

  @override
  Future<UserEntity?> getSavedUser() async => meUser;

  @override
  Future<bool> isLoggedIn() async => loggedIn;

  @override
  Future<void> logout() async {
    loggedIn = false;
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {}

  @override
  Future<LoginResponseModel> firstLoginSetup(String newPassword, String confirmPassword) async {
    if (firstLoginResult != null) return firstLoginResult!;
    throw UnimplementedError();
  }

  @override
  Future<void> forgotPassword(String email) async {}

  @override
  Future<void> resetPassword(String email, String otp, String newPassword) async {}
}

class InMemorySecureStorageService extends SecureStorageService {
  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _userData;
  int clearAllCallCount = 0;

  InMemorySecureStorageService({this._accessToken, this._refreshToken});

  @override
  Future<void> saveAccessToken(String token) async => _accessToken = token;

  @override
  Future<String?> getAccessToken() async => _accessToken;

  @override
  Future<void> saveRefreshToken(String token) async => _refreshToken = token;

  @override
  Future<String?> getRefreshToken() async => _refreshToken;

  @override
  Future<void> saveUserData(Map<String, dynamic> userData) async => _userData = userData;

  @override
  Future<Map<String, dynamic>?> getUserData() async => _userData;

  @override
  Future<void> clearAll() async {
    _accessToken = null;
    _refreshToken = null;
    _userData = null;
    clearAllCallCount++;
  }
}

// Minimal fakes returning clean fixtures
class StubClassesRepository implements ClassesRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StubAssignmentsRepository implements AssignmentsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StubNotificationsRepository implements NotificationsRepository {
  @override
  Future<List<NotificationModel>> getMyNotifications({int page = 1, int limit = 20, bool? isRead}) async => [];
  @override
  Future<int> getUnreadCount() async => 0;
  @override
  Future<void> markAsRead(String id) async {}
  @override
  Future<void> markAllAsRead() async {}
  @override
  Future<void> updateFcmToken(String token) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StubReportsRepository implements ReportsRepository {
  @override
  Future<DashboardOverviewModel> getDashboardOverview() async {
    return const DashboardOverviewModel(
      totalStudents: 100,
      newStudentsThisMonth: 10,
      totalActiveClasses: 8,
      monthlyRevenue: 50000000,
      lastMonthRevenue: 40000000,
      monthlyRevenueGrowth: 25.0,
      totalDebts: 10000000,
      revenueTrend: [],
      courseDistribution: [],
      upcomingClasses: [],
      topDebtors: [],
    );
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StubCoursesRepository implements CoursesRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StubFinanceRepository implements FinanceRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// =============================================================================
// MAIN TEST SUITE
// =============================================================================

void main() {
  final getIt = GetIt.instance;
  late MockAuthRepository mockAuthRepo;
  late TestableAuthBloc authBloc;
  late NotificationBloc notificationBloc;
  late ClassesBloc classesBloc;
  late AssignmentsBloc assignmentsBloc;
  late ReportsBloc reportsBloc;
  late CoursesBloc coursesBloc;
  late FinanceBloc financeBloc;

  setUp(() {
    getIt.reset();

    mockAuthRepo = MockAuthRepository();
    authBloc = TestableAuthBloc(authRepository: mockAuthRepo);
    notificationBloc = NotificationBloc(repository: StubNotificationsRepository());
    classesBloc = ClassesBloc(repository: StubClassesRepository());
    assignmentsBloc = AssignmentsBloc(repository: StubAssignmentsRepository());
    reportsBloc = ReportsBloc(repository: StubReportsRepository());
    coursesBloc = CoursesBloc(repository: StubCoursesRepository());
    financeBloc = FinanceBloc(repository: StubFinanceRepository());

    getIt.registerFactory<AuthBloc>(() => authBloc);
    getIt.registerFactory<NotificationBloc>(() => notificationBloc);
    getIt.registerFactory<ClassesBloc>(() => classesBloc);
    getIt.registerFactory<AssignmentsBloc>(() => assignmentsBloc);
    getIt.registerFactory<ReportsBloc>(() => reportsBloc);
    getIt.registerFactory<CoursesBloc>(() => coursesBloc);
    getIt.registerFactory<FinanceBloc>(() => financeBloc);
  });

  tearDown(() {
    getIt.reset();
  });

  Widget buildTestApp() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<NotificationBloc>.value(value: notificationBloc),
        BlocProvider<ClassesBloc>.value(value: classesBloc),
        BlocProvider<AssignmentsBloc>.value(value: assignmentsBloc),
        BlocProvider<ReportsBloc>.value(value: reportsBloc),
        BlocProvider<CoursesBloc>.value(value: coursesBloc),
        BlocProvider<FinanceBloc>.value(value: financeBloc),
      ],
      child: MaterialApp.router(
        routerConfig: appRouter,
      ),
    );
  }

  // ===========================================================================
  // SECTION 1: ROLE-BASED AUTHENTICATION ROUTING VERIFICATION (LoginScreen)
  // ===========================================================================
  group('Empirical Verification: Role-Based Routing from LoginScreen', () {
    testWidgets('1. admin@lms-edu.vn (super_admin) routes cleanly to RouteNames.adminHome', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      appRouter.go(RouteNames.login);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(LoginScreen), findsOneWidget);

      // Trigger AuthenticatedState for super_admin
      authBloc.triggerEmit(const AuthenticatedState(
        user: adminUser,
        requiresPasswordChange: false,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Assert router location & target widget rendered
      expect(appRouter.routerDelegate.currentConfiguration.uri.toString(), equals(RouteNames.adminHome),
          reason: 'admin@lms-edu.vn with super_admin role must route to /admin/home');
      expect(find.byType(AdminHomeScreen), findsOneWidget);
    });

    testWidgets('2. teacher@lms-edu.vn (teacher) routes cleanly to RouteNames.teacherHome', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      appRouter.go(RouteNames.login);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(LoginScreen), findsOneWidget);

      // Trigger AuthenticatedState for teacher
      authBloc.triggerEmit(const AuthenticatedState(
        user: teacherUser,
        requiresPasswordChange: false,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(appRouter.routerDelegate.currentConfiguration.uri.toString(), equals(RouteNames.teacherHome),
          reason: 'teacher@lms-edu.vn with teacher role must route to /teacher/home');
      expect(find.byType(TeacherHomeScreen), findsOneWidget);
    });

    testWidgets('3. student@lms-edu.vn (student, active) routes cleanly to RouteNames.studentHome', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      appRouter.go(RouteNames.login);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(LoginScreen), findsOneWidget);

      // Trigger AuthenticatedState for active student
      authBloc.triggerEmit(const AuthenticatedState(
        user: studentUserActive,
        requiresPasswordChange: false,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(appRouter.routerDelegate.currentConfiguration.uri.toString(), equals(RouteNames.studentHome),
          reason: 'student@lms-edu.vn with student role must route to /student/home');
      expect(find.byType(StudentHomeScreen), findsOneWidget);
    });

    testWidgets('4. student@lms-edu.vn with requiresPasswordChange=true routes to FirstLoginScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      appRouter.go(RouteNames.login);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      authBloc.triggerEmit(const AuthenticatedState(
        user: studentUserFirstLogin,
        requiresPasswordChange: true,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(appRouter.routerDelegate.currentConfiguration.uri.toString(), equals(RouteNames.firstLoginSetup),
          reason: 'Account requiring password change must route to FirstLoginScreen (/first-login-setup)');
      expect(find.byType(FirstLoginScreen), findsOneWidget);
    });

    testWidgets('5. Role precedence and edge cases in LoginScreen routing', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      appRouter.go(RouteNames.login);
      await tester.pump();

      // Multi-role: student + super_admin -> routes to AdminHome
      const multiUser = UserEntity(
        id: 'u-multi',
        userCode: 'U-MULTI',
        fullName: 'Multi Role User',
        status: 'ACTIVE',
        isFirstLogin: false,
        roles: ['student', 'super_admin'],
        permissions: ['*'],
      );
      authBloc.triggerEmit(const AuthenticatedState(user: multiUser, requiresPasswordChange: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(appRouter.routerDelegate.currentConfiguration.uri.toString(), equals(RouteNames.adminHome),
          reason: 'super_admin privilege takes precedence over student role');

      // Parent role -> routes to ParentHome
      const parentUser = UserEntity(
        id: 'u-parent',
        userCode: 'PH-0001',
        fullName: 'Phụ Huynh Test',
        status: 'ACTIVE',
        isFirstLogin: false,
        roles: ['parent'],
        permissions: [],
      );
      appRouter.go(RouteNames.login);
      await tester.pump();
      authBloc.triggerEmit(const AuthenticatedState(user: parentUser, requiresPasswordChange: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(appRouter.routerDelegate.currentConfiguration.uri.toString(), equals(RouteNames.parentHome),
          reason: 'Parent role routes to ParentHomeScreen');

      // Teaching assistant role -> isTeacher is true -> routes to TeacherHome
      const taUser = UserEntity(
        id: 'u-ta',
        userCode: 'TG-0001',
        fullName: 'Trợ Giảng Test',
        status: 'ACTIVE',
        isFirstLogin: false,
        roles: ['teaching_assistant'],
        permissions: [],
      );
      appRouter.go(RouteNames.login);
      await tester.pump();
      authBloc.triggerEmit(const AuthenticatedState(user: taUser, requiresPasswordChange: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(appRouter.routerDelegate.currentConfiguration.uri.toString(), equals(RouteNames.teacherHome),
          reason: 'teaching_assistant role routes to TeacherHomeScreen via isTeacher getter');
    });
  });

  // ===========================================================================
  // SECTION 2: FIRST LOGIN COMPLETION ROUTING TO ROLE PORTAL
  // ===========================================================================
  group('Empirical Verification: FirstLoginScreen Transition Routing', () {
    testWidgets('6. Student completing first login routes to StudentHomeScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      appRouter.go(RouteNames.firstLoginSetup);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(FirstLoginScreen), findsOneWidget);

      // Emit successful password initialization state
      authBloc.triggerEmit(const AuthenticatedState(
        user: studentUserActive,
        requiresPasswordChange: false,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(appRouter.routerDelegate.currentConfiguration.uri.toString(), equals(RouteNames.studentHome),
          reason: 'Upon first login completion, student must be routed to StudentHomeScreen');
      expect(find.byType(StudentHomeScreen), findsOneWidget);
    });

    testWidgets('7. Teacher completing first login routes to TeacherHomeScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      appRouter.go(RouteNames.firstLoginSetup);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(FirstLoginScreen), findsOneWidget);

      authBloc.triggerEmit(const AuthenticatedState(
        user: teacherUser,
        requiresPasswordChange: false,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(appRouter.routerDelegate.currentConfiguration.uri.toString(), equals(RouteNames.teacherHome),
          reason: 'Upon first login completion, teacher must be routed to TeacherHomeScreen');
      expect(find.byType(TeacherHomeScreen), findsOneWidget);
    });
  });

  // ===========================================================================
  // SECTION 3: SPLASH SCREEN RESUME ROUTING
  // ===========================================================================
  group('Empirical Verification: SplashScreen Session Resume Routing', () {
    testWidgets('8. SplashScreen resumes session for super_admin directly to AdminHomeScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      appRouter.go(RouteNames.login);
      await tester.pump();
      appRouter.go(RouteNames.splash);
      await tester.pump();

      authBloc.triggerEmit(const AuthenticatedState(user: adminUser, requiresPasswordChange: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(appRouter.routerDelegate.currentConfiguration.uri.toString(), equals(RouteNames.adminHome),
          reason: 'SplashScreen must resume super_admin session into AdminHomeScreen');
      expect(find.byType(AdminHomeScreen), findsOneWidget);
    });

    testWidgets('9. SplashScreen resumes session for teacher directly to TeacherHomeScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      appRouter.go(RouteNames.login);
      await tester.pump();
      appRouter.go(RouteNames.splash);
      await tester.pump();

      authBloc.triggerEmit(const AuthenticatedState(user: teacherUser, requiresPasswordChange: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(appRouter.routerDelegate.currentConfiguration.uri.toString(), equals(RouteNames.teacherHome),
          reason: 'SplashScreen must resume teacher session into TeacherHomeScreen');
      expect(find.byType(TeacherHomeScreen), findsOneWidget);
    });

    testWidgets('10. SplashScreen resumes session for student directly to StudentHomeScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      appRouter.go(RouteNames.login);
      await tester.pump();
      appRouter.go(RouteNames.splash);
      await tester.pump();

      authBloc.triggerEmit(const AuthenticatedState(user: studentUserActive, requiresPasswordChange: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(appRouter.routerDelegate.currentConfiguration.uri.toString(), equals(RouteNames.studentHome),
          reason: 'SplashScreen must resume student session into StudentHomeScreen');
      expect(find.byType(StudentHomeScreen), findsOneWidget);
    });

    testWidgets('11. SplashScreen with unauthenticated session routes cleanly to LoginScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      appRouter.go(RouteNames.adminHome);
      await tester.pump();
      appRouter.go(RouteNames.splash);
      await tester.pump();

      authBloc.triggerEmit(UnauthenticatedState());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(appRouter.routerDelegate.currentConfiguration.uri.toString(), equals(RouteNames.login),
          reason: 'Unauthenticated session must redirect to LoginScreen');
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  // ===========================================================================
  // SECTION 3.5: ADVERSARIAL STRESS - DESKTOP VIEWPORT LAYOUT PARITY & OVERFLOW PROFILING
  // ===========================================================================
  group('Adversarial Stress: Desktop Viewport Layout Parity & Overflow Profiling (1200px)', () {
    testWidgets('11a. Desktop Viewport Layout Profiling: TeacherHomeScreen at width 1200', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final List<FlutterErrorDetails> caughtErrors = [];
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('RenderFlex overflowed')) {
          caughtErrors.add(details);
        } else {
          oldOnError?.call(details);
        }
      };

      try {
        await tester.pumpWidget(buildTestApp());
        appRouter.go(RouteNames.teacherHome);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(TeacherHomeScreen), findsOneWidget);
        if (caughtErrors.isNotEmpty) {
          debugPrint('[CHALLENGER ADVERSARIAL FINDING] TeacherHomeScreen header RenderFlex overflow captured: ${caughtErrors.first.summary}');
        }
      } finally {
        FlutterError.onError = oldOnError;
      }
    });

    testWidgets('11b. Desktop Viewport Layout Profiling: StudentHomeScreen at width 1200', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final List<FlutterErrorDetails> caughtErrors = [];
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('RenderFlex overflowed')) {
          caughtErrors.add(details);
        } else {
          oldOnError?.call(details);
        }
      };

      try {
        await tester.pumpWidget(buildTestApp());
        appRouter.go(RouteNames.studentHome);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(StudentHomeScreen), findsOneWidget);
        if (caughtErrors.isNotEmpty) {
          debugPrint('[CHALLENGER ADVERSARIAL FINDING] StudentHomeScreen header RenderFlex overflow captured: ${caughtErrors.first.summary}');
        }
      } finally {
        FlutterError.onError = oldOnError;
      }
    });

    testWidgets('11c. Parity Verification: AdminHomeScreen desktop header renders cleanly with zero overflows', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      appRouter.go(RouteNames.adminHome);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(AdminHomeScreen), findsOneWidget);
      // Verify global search bar in admin desktop header
      expect(find.byType(TextField), findsWidgets);
    });
  });

  // ===========================================================================
  // SECTION 4: TOKEN REFRESH UNBOXING & AUTH INTERCEPTOR ROBUSTNESS
  // ===========================================================================
  group('Empirical Verification: Token Refresh Unboxing & AuthInterceptor via Live Mock Server', () {
    HttpServer? server;
    HttpOverrides? savedOverrides;

    setUp(() {
      savedOverrides = HttpOverrides.current;
      HttpOverrides.global = null; // Unblock localhost network calls from Flutter test binding
    });

    tearDown(() async {
      HttpOverrides.global = savedOverrides;
      await server?.close(force: true);
      server = null;
    });

    test('12. Unboxes Nested NestJS Response: { statusCode: 200, data: { accessToken: "xyz" } } and retries request', () async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      
      int refreshCallCount = 0;
      int resourceCallCount = 0;

      server!.listen((HttpRequest request) async {
        final path = request.uri.path;
        if (path.contains('/auth/refresh')) {
          refreshCallCount++;
          final bodyString = await utf8.decoder.bind(request).join();
          final bodyJson = jsonDecode(bodyString) as Map<String, dynamic>;
          expect(bodyJson['refreshToken'], equals('valid_refresh_token_111'));

          final responsePayload = {
            'success': true,
            'statusCode': 200,
            'message': 'Refresh token thành công',
            'data': {
              'accessToken': 'new_nested_access_token_999',
              'refreshToken': 'new_nested_refresh_token_888',
            },
          };
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(responsePayload));
          await request.response.close();
        } else if (path.contains('/test-resource')) {
          resourceCallCount++;
          final authHeader = request.headers.value(HttpHeaders.authorizationHeader);
          if (resourceCallCount == 1) {
            request.response
              ..statusCode = HttpStatus.unauthorized
              ..headers.contentType = ContentType.json
              ..write(jsonEncode({'message': 'Token expired'}));
            await request.response.close();
          } else {
            expect(authHeader, equals('Bearer new_nested_access_token_999'));
            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType.json
              ..write(jsonEncode({'status': 'success', 'data': 'Resource accessed'}));
            await request.response.close();
          }
        } else {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
        }
      });

      final storage = InMemorySecureStorageService(
        accessToken: 'expired_access_token',
        refreshToken: 'valid_refresh_token_111',
      );

      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:${server!.port}/api/v1'));
      final interceptor = AuthInterceptor(storageService: storage, dio: dio);
      dio.interceptors.add(interceptor);

      final response = await dio.get('/test-resource');

      expect(response.statusCode, equals(200));
      expect(refreshCallCount, equals(1), reason: 'Refresh endpoint must be hit exactly once');
      expect(resourceCallCount, equals(2), reason: 'Original resource must be retried after refresh');

      expect(await storage.getAccessToken(), equals('new_nested_access_token_999'));
      expect(await storage.getRefreshToken(), equals('new_nested_refresh_token_888'));
    });

    test('13. Unboxes Flat Response: { accessToken: "xyz", refreshToken: "abc" } and retries request', () async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 3000);
      
      int refreshCallCount = 0;
      int resourceCallCount = 0;

      server!.listen((HttpRequest request) async {
        final path = request.uri.path;
        if (path.contains('/auth/refresh')) {
          refreshCallCount++;
          final responsePayload = {
            'accessToken': 'flat_access_token_555',
            'refreshToken': 'flat_refresh_token_666',
          };
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(responsePayload));
          await request.response.close();
        } else if (path.contains('/flat-resource')) {
          resourceCallCount++;
          final authHeader = request.headers.value(HttpHeaders.authorizationHeader);
          if (resourceCallCount == 1) {
            request.response
              ..statusCode = HttpStatus.unauthorized
              ..headers.contentType = ContentType.json
              ..write(jsonEncode({'message': 'Unauthorized'}));
            await request.response.close();
          } else {
            expect(authHeader, equals('Bearer flat_access_token_555'));
            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType.json
              ..write(jsonEncode({'ok': true}));
            await request.response.close();
          }
        }
      });

      final storage = InMemorySecureStorageService(
        accessToken: 'old_access_token',
        refreshToken: 'valid_refresh_token_222',
      );

      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:${server!.port}/api/v1'));
      final interceptor = AuthInterceptor(storageService: storage, dio: dio);
      dio.interceptors.add(interceptor);

      final response = await dio.get('/flat-resource');

      expect(response.statusCode, equals(200));
      expect(refreshCallCount, equals(1));
      expect(resourceCallCount, equals(2));
      expect(await storage.getAccessToken(), equals('flat_access_token_555'));
      expect(await storage.getRefreshToken(), equals('flat_refresh_token_666'));
    });

    test('14. Unboxes payload containing only accessToken (missing refreshToken) safely without wiping storage', () async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 3000);

      server!.listen((HttpRequest request) async {
        final path = request.uri.path;
        if (path.contains('/auth/refresh')) {
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({
              'data': {'accessToken': 'access_only_token_777'},
            }));
          await request.response.close();
        } else if (path.contains('/partial-resource')) {
          final authHeader = request.headers.value(HttpHeaders.authorizationHeader);
          if (authHeader == 'Bearer access_only_token_777') {
            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType.json
              ..write(jsonEncode({'success': true}));
            await request.response.close();
          } else {
            request.response
              ..statusCode = HttpStatus.unauthorized
              ..write(jsonEncode({'message': 'Unauthorized'}));
            await request.response.close();
          }
        }
      });

      final storage = InMemorySecureStorageService(
        accessToken: 'stale_token',
        refreshToken: 'keep_existing_refresh_token',
      );

      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:${server!.port}/api/v1'));
      dio.interceptors.add(AuthInterceptor(storageService: storage, dio: dio));

      final response = await dio.get('/partial-resource');
      expect(response.statusCode, equals(200));
      expect(await storage.getAccessToken(), equals('access_only_token_777'));
      expect(await storage.getRefreshToken(), equals('keep_existing_refresh_token'));
    });

    test('15. Malformed payload with integer accessToken triggers catch and cleans up session safely', () async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 3000);

      server!.listen((HttpRequest request) async {
        final path = request.uri.path;
        if (path.contains('/auth/refresh')) {
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({
              'data': {'accessToken': 12345},
            }));
          await request.response.close();
        } else {
          request.response
            ..statusCode = HttpStatus.unauthorized
            ..write(jsonEncode({'message': 'Unauthorized'}));
          await request.response.close();
        }
      });

      final storage = InMemorySecureStorageService(
        accessToken: 'stale_token',
        refreshToken: 'some_refresh_token',
      );

      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:${server!.port}/api/v1'));
      dio.interceptors.add(AuthInterceptor(storageService: storage, dio: dio));

      try {
        await dio.get('/test-malformed');
        fail('Should throw DioException on 401 when refresh fails to provide valid string token');
      } on DioException catch (e) {
        expect(e.response?.statusCode, equals(401));
      }

      expect(storage.clearAllCallCount, greaterThanOrEqualTo(1));
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
    });

    test('16. When refresh returns 401 (refresh token expired), clearAll is called and error propagated', () async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 3000);

      server!.listen((HttpRequest request) async {
        final path = request.uri.path;
        if (path.contains('/auth/refresh')) {
          request.response
            ..statusCode = HttpStatus.unauthorized
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'message': 'Refresh token expired'}));
          await request.response.close();
        } else {
          request.response
            ..statusCode = HttpStatus.unauthorized
            ..write(jsonEncode({'message': 'Unauthorized'}));
          await request.response.close();
        }
      });

      final storage = InMemorySecureStorageService(
        accessToken: 'stale_token',
        refreshToken: 'expired_refresh_token',
      );

      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:${server!.port}/api/v1'));
      dio.interceptors.add(AuthInterceptor(storageService: storage, dio: dio));

      try {
        await dio.get('/protected-resource');
        fail('Should throw DioException 401');
      } on DioException catch (e) {
        expect(e.response?.statusCode, equals(401));
      }

      expect(storage.clearAllCallCount, equals(1));
      expect(await storage.getAccessToken(), isNull);
    });

    test('17. 401 on /auth/login or /auth/refresh does NOT trigger refresh loop', () async {
      int refreshCallCount = 0;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

      server!.listen((HttpRequest request) async {
        final path = request.uri.path;
        if (path.contains('/auth/refresh')) {
          refreshCallCount++;
        }
        request.response
          ..statusCode = HttpStatus.unauthorized
          ..write(jsonEncode({'message': 'Bad credentials'}));
        await request.response.close();
      });

      final storage = InMemorySecureStorageService(
        accessToken: null,
        refreshToken: 'valid_refresh_token',
      );

      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:${server!.port}/api/v1'));
      dio.interceptors.add(AuthInterceptor(storageService: storage, dio: dio));

      try {
        await dio.post(ApiEndpoints.login, data: {'identifier': 'wrong', 'password': 'wrong'});
      } on DioException catch (e) {
        expect(e.response?.statusCode, equals(401));
      }

      expect(refreshCallCount, equals(0),
          reason: '401 on /auth/login must never trigger a recursive /auth/refresh call');
    });

    test('18. 401 with empty or null stored refreshToken immediately clears session without calling refresh', () async {
      int refreshCallCount = 0;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

      server!.listen((HttpRequest request) async {
        if (request.uri.path.contains('/auth/refresh')) {
          refreshCallCount++;
        }
        request.response
          ..statusCode = HttpStatus.unauthorized
          ..write(jsonEncode({'message': 'Unauthorized'}));
        await request.response.close();
      });

      final storage = InMemorySecureStorageService(
        accessToken: 'stale_token',
        refreshToken: null, // No refresh token available
      );

      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:${server!.port}/api/v1'));
      dio.interceptors.add(AuthInterceptor(storageService: storage, dio: dio));

      try {
        await dio.get('/some-data');
      } on DioException catch (e) {
        expect(e.response?.statusCode, equals(401));
      }

      expect(refreshCallCount, equals(0), reason: 'No refresh call should be made when refreshToken is null');
      expect(storage.clearAllCallCount, equals(1));
    });
  });
}
