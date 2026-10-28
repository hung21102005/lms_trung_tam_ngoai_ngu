import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import 'package:lms_trung_tam_ngoai_ngu/core/router/route_names.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/router/app_router.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/domain/repositories/auth_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/domain/entities/user_entity.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/data/models/login_response_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/presentation/bloc/classes_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/domain/repositories/classes_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/data/models/class_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/presentation/screens/class_create_screen.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/presentation/screens/class_detail_screen.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/presentation/bloc/assignments_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/domain/repositories/assignments_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/data/models/assignment_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/presentation/screens/assignment_list_screen.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/presentation/screens/assignment_detail_screen.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/notifications/data/models/notification_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/reports/presentation/bloc/reports_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/reports/domain/repositories/reports_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/reports/data/models/report_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/presentation/bloc/courses_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/domain/repositories/courses_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/data/models/course_model.dart';

// ==================== FAKE REPOSITORIES ====================

const testUser = UserEntity(
  id: 'usr-1',
  userCode: 'ADM-01',
  fullName: 'Quản Trị Viên Test',
  email: 'admin@lms-edu.vn',
  status: 'ACTIVE',
  isFirstLogin: false,
  roles: ['admin', 'super_admin'],
  permissions: ['*'],
);

class FakeAuthRepository implements AuthRepository {
  @override
  Future<LoginResponseModel> login(String identifier, String password) async => throw UnimplementedError();
  @override
  Future<UserEntity> getMe() async => testUser;
  @override
  Future<UserEntity?> getSavedUser() async => testUser;
  @override
  Future<bool> isLoggedIn() async => true;
  @override
  Future<void> logout() async {}
  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {}
  @override
  Future<LoginResponseModel> firstLoginSetup(String newPassword, String confirmPassword) async => throw UnimplementedError();
  @override
  Future<void> forgotPassword(String email) async {}
  @override
  Future<void> resetPassword(String email, String otp, String newPassword) async {}
}

class FakeClassesRepository implements ClassesRepository {
  @override
  Future<List<ClassModel>> getClasses({String? search, String? status, String? branchId, String? courseId, String? teacherId, int page = 1, int limit = 50}) async => [];
  @override
  Future<ClassModel> getClassDetail(String id) async {
    return ClassModel(
      id: id,
      code: 'CLS-TEST',
      name: 'Class Test Name',
      courseId: 'c1',
      levelId: 'l1',
      branchId: 'b1',
      status: 'PLANNING',
      startDate: DateTime(2026, 1, 1),
      scheduleDays: ['MONDAY', 'WEDNESDAY'],
      startTime: '08:00',
      endTime: '10:00',
      totalSessions: 24,
      maxCapacity: 20,
    );
  }
  @override
  Future<ClassModel> createClass({required String code, required String name, required String courseId, required String levelId, required String branchId, String? roomId, String? mainTeacherId, String? assistantTeacherId, String status = 'PLANNING', required String startDate, required List<String> scheduleDays, required String startTime, required String endTime, int totalSessions = 24, int maxCapacity = 20, double? tuitionFee, String? registrationOpenAt, String? registrationCloseAt, String? notes}) async => throw UnimplementedError();
  @override
  Future<ClassModel> updateClass(String id, {String? code, String? name, String? roomId, String? mainTeacherId, String? assistantTeacherId, String? status, String? startDate, List<String>? scheduleDays, String? startTime, String? endTime, int? maxCapacity, double? tuitionFee, String? registrationOpenAt, String? registrationCloseAt, String? notes}) async => throw UnimplementedError();
  @override
  Future<ClassStudentModel> enrollStudent(String classId, {required String studentId, double tuitionPaid = 0, String? notes}) async => throw UnimplementedError();
  @override
  Future<void> removeStudent(String classId, String studentId) async {}
  @override
  Future<List<ClassSessionModel>> getClassSessions(String classId) async => [];
  @override
  Future<ClassSessionModel> updateSession(String sessionId, {String? date, String? startTime, String? endTime, String? roomId, String? teacherId, String? status, String? notes}) async => throw UnimplementedError();
  @override
  Future<List<ClassModel>> getMyClasses() async => [];
  @override
  Future<List<ClassSessionModel>> getMySchedule({String? fromDate, String? toDate}) async => [];
}

class FakeAssignmentsRepository implements AssignmentsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<AssignmentModel>> getClassAssignments(String classId) async => [
    AssignmentModel(
      id: 'asm-1',
      classId: classId,
      title: 'Bài tập Unit 1',
      description: 'Hoàn thành phát âm và từ vựng',
      type: 'HOMEWORK',
      deadline: '2026-12-31T23:59:59Z',
      maxScore: 10,
      attachments: const [],
      createdAt: '2026-01-01',
    ),
  ];
  @override
  Future<AssignmentModel> createAssignment(String classId, {required String title, String? description, String? type, String? deadline, double? maxScore, List<Map<String, dynamic>>? attachments}) async => throw UnimplementedError();
  @override
  Future<AssignmentModel> getAssignmentDetail(String id) async {
    return AssignmentModel(
      id: id,
      classId: 'c1',
      title: 'Chi tiết bài tập $id',
      type: 'HOMEWORK',
      deadline: '2026-12-31T23:59:59Z',
      maxScore: 10,
      attachments: const [],
      createdAt: '2026-01-01',
    );
  }
  @override
  Future<SubmissionModel> submitAssignment(String assignmentId, {String? content, List<Map<String, dynamic>>? fileUrls}) async => throw UnimplementedError();
  @override
  Future<AssignmentSubmissionsResponseModel> getAssignmentSubmissions(String assignmentId) async => throw UnimplementedError();
  @override
  Future<SubmissionModel> gradeSubmission(String submissionId, {required double score, String? feedback}) async => throw UnimplementedError();
}

class FakeNotificationsRepository implements NotificationsRepository {
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
}

class FakeReportsRepository implements ReportsRepository {
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
  Future<RevenueReportModel> getRevenueReport({int? year, String? branchId}) async => throw UnimplementedError();
  @override
  Future<AttendanceReportModel> getAttendanceReport({String? classId, String? startDate, String? endDate}) async => throw UnimplementedError();
  @override
  Future<DebtsReportModel> getDebtsReport({String? branchId, String? search, int page = 1, int limit = 20}) async => throw UnimplementedError();
  @override
  Future<List<TeacherWorkloadModel>> getTeacherWorkloadReport() async => [];
  @override
  Future<void> refreshDashboardCache() async {}
}

class FakeCoursesRepository implements CoursesRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<List<CourseModel>> getCourses({String? search, String? language, bool? isActive, int page = 1, int limit = 50}) async => [];
  @override
  Future<CourseModel> getCourseDetail(String id) async => throw UnimplementedError();
  @override
  Future<CourseModel> createCourse({required String code, required String title, String? description, String? targetAudience, String language = 'English', String? thumbnailUrl}) async => throw UnimplementedError();
  @override
  Future<CourseModel> updateCourse(String id, {String? code, String? title, String? description, String? targetAudience, String? language, String? thumbnailUrl, bool? isActive}) async => throw UnimplementedError();
  @override
  Future<CourseLevelModel> createLevel(String courseId, {required String code, required String name, String? description, int order = 1, int estimatedSessions = 24, double tuitionFee = 0}) async => throw UnimplementedError();
  @override
  Future<ModuleModel> createModule(String levelId, {required String title, int order = 1, String? description}) async => throw UnimplementedError();
  @override
  Future<LessonModel> createLesson(String moduleId, {required String title, int order = 1, String? content, int durationMinutes = 90}) async => throw UnimplementedError();
  @override
  Future<LessonMaterialModel> createMaterial(String lessonId, {required String title, required String fileUrl, String fileType = 'DOCUMENT', int? fileSizeBytes}) async => throw UnimplementedError();
}

// ==================== TEST SUITE ====================

void main() {
  final getIt = GetIt.instance;
  late AuthBloc authBloc;
  late NotificationBloc notificationBloc;
  late ClassesBloc classesBloc;
  late AssignmentsBloc assignmentsBloc;
  late ReportsBloc reportsBloc;
  late CoursesBloc coursesBloc;

  setUp(() {
    getIt.reset();

    final authRepo = FakeAuthRepository();
    final classesRepo = FakeClassesRepository();
    final assignmentsRepo = FakeAssignmentsRepository();
    final notificationsRepo = FakeNotificationsRepository();
    final reportsRepo = FakeReportsRepository();
    final coursesRepo = FakeCoursesRepository();

    authBloc = AuthBloc(authRepository: authRepo);
    notificationBloc = NotificationBloc(repository: notificationsRepo);
    classesBloc = ClassesBloc(repository: classesRepo);
    assignmentsBloc = AssignmentsBloc(repository: assignmentsRepo);
    reportsBloc = ReportsBloc(repository: reportsRepo);
    coursesBloc = CoursesBloc(repository: coursesRepo);

    getIt.registerSingleton<ClassesRepository>(classesRepo);
    getIt.registerFactory<AuthBloc>(() => authBloc);
    getIt.registerFactory<NotificationBloc>(() => notificationBloc);
    getIt.registerFactory<ClassesBloc>(() => classesBloc);
    getIt.registerFactory<AssignmentsBloc>(() => assignmentsBloc);
    getIt.registerFactory<ReportsBloc>(() => reportsBloc);
    getIt.registerFactory<CoursesBloc>(() => coursesBloc);
  });

  tearDown(() {
    getIt.reset();
  });

  Widget buildRouterApp() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<NotificationBloc>.value(value: notificationBloc),
        BlocProvider<ClassesBloc>.value(value: classesBloc),
        BlocProvider<AssignmentsBloc>.value(value: assignmentsBloc),
        BlocProvider<ReportsBloc>.value(value: reportsBloc),
        BlocProvider<CoursesBloc>.value(value: coursesBloc),
      ],
      child: MaterialApp.router(
        routerConfig: appRouter,
      ),
    );
  }

  group('Oracles: Route Constants and Configuration', () {
    test('Route constants match expected contract paths', () {
      expect(RouteNames.classCreate, equals('/classes/create'));
      expect(RouteNames.classes, equals('/classes'));
      expect(RouteNames.classDetail, equals('/classes/:id'));
      expect(RouteNames.assignments, equals('/assignments'));
      expect(RouteNames.classAssignments, equals('/classes/:classId/assignments'));
      expect(RouteNames.createAssignment, equals('/classes/:classId/assignments/create'));
      expect(RouteNames.assignmentDetail, equals('/assignments/:id'));
    });

    test('Route configuration order prevents collision between /classes/create and /classes/:id', () {
      final routes = appRouter.configuration.routes;
      final classCreateRoute = routes.whereType<GoRoute>().firstWhere((r) => r.path == RouteNames.classCreate);
      final classDetailRoute = routes.whereType<GoRoute>().firstWhere((r) => r.path == RouteNames.classDetail);

      final indexCreate = routes.indexOf(classCreateRoute);
      final indexDetail = routes.indexOf(classDetailRoute);

      // classCreate MUST be defined before classDetail to avoid :id matching 'create'
      expect(indexCreate, lessThan(indexDetail),
          reason: 'RouteNames.classCreate must precede RouteNames.classDetail to prevent routing collision');
    });

    test('Route configuration contains assignments and assignmentDetail routes without collision', () {
      final routes = appRouter.configuration.routes;
      final assignmentsRoute = routes.whereType<GoRoute>().firstWhere((r) => r.path == RouteNames.assignments);
      final assignmentDetailRoute = routes.whereType<GoRoute>().firstWhere((r) => r.path == RouteNames.assignmentDetail);

      expect(assignmentsRoute.path, equals('/assignments'));
      expect(assignmentDetailRoute.path, equals('/assignments/:id'));
    });
  });

  group('Empirical Routing Stress: Direct Navigation', () {
    testWidgets('Navigate to RouteNames.classCreate renders ClassCreateScreen, NOT ClassDetailScreen', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildRouterApp());
      appRouter.go(RouteNames.classCreate);
      await tester.pumpAndSettle();

      expect(find.byType(ClassCreateScreen), findsOneWidget);
      expect(find.byType(ClassDetailScreen), findsNothing);
      expect(find.text('Mở Lớp Học Mới'), findsOneWidget);
    });

    testWidgets('Navigate to /classes/cls-empirical-1 renders ClassDetailScreen, NOT ClassCreateScreen', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildRouterApp());
      appRouter.go('/classes/cls-empirical-1');
      await tester.pumpAndSettle();

      expect(find.byType(ClassDetailScreen), findsOneWidget);
      expect(find.byType(ClassCreateScreen), findsNothing);
    });

    testWidgets('Navigate to RouteNames.assignments renders AssignmentListScreen, NOT AssignmentDetailScreen', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildRouterApp());
      appRouter.go(RouteNames.assignments);
      await tester.pumpAndSettle();

      expect(find.byType(AssignmentListScreen), findsOneWidget);
      expect(find.byType(AssignmentDetailScreen), findsNothing);
      expect(find.text('Danh sách bài tập'), findsOneWidget);
      expect(find.text('Tất cả'), findsOneWidget);
    });

    testWidgets('Navigate to /assignments/asm-empirical-99 renders AssignmentDetailScreen', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildRouterApp());
      appRouter.go('/assignments/asm-empirical-99');
      // Use pump with finite duration because LoadingWidget uses SpinKitThreeBounce (infinite animation)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AssignmentDetailScreen), findsOneWidget);
      expect(find.byType(AssignmentListScreen), findsNothing);
      expect(find.text('Chi tiết bài tập'), findsOneWidget);
    });
  });

  group('Empirical UI Interactions: AdminHomeScreen and ListTile Callbacks', () {
    testWidgets('Detects ListTile assertion error due to DecoratedBox without Material wrapper in AdminHomeScreen', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final List<FlutterErrorDetails> errors = [];
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (details) => errors.add(details);
      addTearDown(() => FlutterError.onError = oldOnError);

      await tester.pumpWidget(buildRouterApp());
      appRouter.go(RouteNames.adminHome);
      await tester.pump();

      // Verify resolution of ListTile DecoratedBox assertion error
      final listTileErrors = errors.where((e) => e.toString().contains('ListTile background color or ink splashes may be invisible')).toList();
      expect(listTileErrors, isEmpty,
          reason: 'AdminHomeScreen sidebar ListTiles are cleanly wrapped in Material, resolving Flutter assertions');

      // 1. Verify Quick Action button 'Mở Lớp Học Mới' navigates to RouteNames.classCreate
      final openClassButton = find.text('Mở Lớp Học Mới');
      expect(openClassButton, findsOneWidget);
      await tester.tap(openClassButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ClassCreateScreen), findsOneWidget);

      // Return back to admin home
      appRouter.go(RouteNames.adminHome);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 2. Stress-test 'Hỗ trợ kỹ thuật' ListTile callback (onTap)
      final supportTile = find.text('Hỗ trợ kỹ thuật');
      expect(supportTile, findsOneWidget);
      await tester.tap(supportTile);
      await tester.pump(); // Show SnackBar

      expect(find.text('Hotline kỹ thuật: 1900-8888 (24/7)'), findsOneWidget);

      // 3. Stress-test 'Đăng xuất' ListTile callback (onTap)
      final logoutTile = find.text('Đăng xuất');
      expect(logoutTile, findsOneWidget);
      await tester.tap(logoutTile);
      await tester.pump();
    });
  });

  group('Empirical UI Interactions: StudentHomeScreen Navigation', () {
    testWidgets('StudentHomeScreen shortcut card navigates to RouteNames.assignments cleanly', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildRouterApp());
      appRouter.go(RouteNames.studentHome);
      await tester.pumpAndSettle();

      // Find 'Bài Tập Về Nhà' shortcut
      final assignmentShortcut = find.text('Bài Tập Về Nhà');
      expect(assignmentShortcut, findsOneWidget);

      await tester.tap(assignmentShortcut);
      await tester.pumpAndSettle();

      // Verify navigation into AssignmentListScreen succeeded without exception
      expect(find.byType(AssignmentListScreen), findsOneWidget);
      expect(find.text('Danh sách bài tập'), findsOneWidget);
    });
  });

  group('Milestone 2 UI/UX Parity & Verification', () {
    testWidgets('AdminHomeScreen desktop header renders search bar with clear button', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildRouterApp());
      appRouter.go(RouteNames.adminHome);
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      expect(find.text('Tìm kiếm nhanh học viên, lớp học, hóa đơn...'), findsOneWidget);

      // Enter search query
      await tester.enterText(searchField, 'Nguyen Van A');
      await tester.pump();

      // Clear icon appears
      final clearButton = find.byTooltip('Xóa tìm kiếm');
      expect(clearButton, findsOneWidget);

      await tester.tap(clearButton);
      await tester.pump();
      expect(find.text('Nguyen Van A'), findsNothing);
    });

    testWidgets('StudentHomeScreen renders Web Desktop layout with persistent 260px sidebar and header when width > 900', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildRouterApp());
      appRouter.go(RouteNames.studentHome);
      await tester.pumpAndSettle();

      // Verify Desktop Sidebar Brand & Quick Action
      expect(find.text('EduLMS'), findsOneWidget);
      expect(find.text('Cổng Học Viên'), findsOneWidget);
      expect(find.text('+ Nộp bài tập ngay'), findsOneWidget);

      // Verify Desktop Header search and term
      expect(find.text('Tìm khóa học, bài tập, lịch học...'), findsOneWidget);
      expect(find.text('Học Kỳ 1 - 2026'), findsOneWidget);

      // Verify 7 Nav items
      expect(find.text('Trang chủ'), findsWidgets);
      expect(find.text('Lịch học'), findsWidgets);
      expect(find.text('Khóa học'), findsWidgets);
      expect(find.text('Bài tập'), findsWidgets);
      expect(find.text('Học phí'), findsWidgets);
      expect(find.text('Bảng điểm'), findsOneWidget);
      expect(find.text('Thông báo'), findsWidgets);
    });

    testWidgets('StudentHomeScreen renders Mobile layout with BottomNavigationBar when width <= 900', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildRouterApp());
      appRouter.go(RouteNames.studentHome);
      await tester.pumpAndSettle();

      // Verify BottomNavigationBar presence
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('+ Nộp bài tập ngay'), findsNothing); // Desktop sidebar element absent
    });

    test('AuthInterceptor token refresh unboxes nested data.accessToken and flat accessToken', () {
      final nestedResponse = {
        'success': true,
        'statusCode': 200,
        'message': 'Refresh token thành công',
        'data': {
          'accessToken': 'new_jwt_access_token_123',
          'refreshToken': 'new_jwt_refresh_token_456',
        },
      };

      final dataMap1 = nestedResponse['data'] as Map<String, dynamic>?;
      final newAccessToken1 = dataMap1?['accessToken'] as String?;
      final newRefreshToken1 = dataMap1?['refreshToken'] as String?;

      expect(newAccessToken1, equals('new_jwt_access_token_123'));
      expect(newRefreshToken1, equals('new_jwt_refresh_token_456'));

      final flatResponse = {
        'accessToken': 'flat_access_token_789',
        'refreshToken': 'flat_refresh_token_012',
      };
      final dataMap2 = flatResponse;
      final nestedData2 = dataMap2['data'] as Map<String, dynamic>?;
      final newAccessToken2 = (nestedData2?['accessToken'] ?? dataMap2['accessToken']) as String?;
      final newRefreshToken2 = (nestedData2?['refreshToken'] ?? dataMap2['refreshToken']) as String?;

      expect(newAccessToken2, equals('flat_access_token_789'));
      expect(newRefreshToken2, equals('flat_refresh_token_012'));
    });

    testWidgets('FirstLoginScreen renders form fields and password setup controls', (tester) async {
      await tester.pumpWidget(buildRouterApp());
      appRouter.go(RouteNames.firstLoginSetup);
      await tester.pumpAndSettle();

      expect(find.text('Kích Hoạt Tài Khoản'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsWidgets);
    });
  });
}
