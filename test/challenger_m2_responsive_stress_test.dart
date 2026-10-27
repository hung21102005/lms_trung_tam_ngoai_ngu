import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:lms_trung_tam_ngoai_ngu/core/router/route_names.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/router/app_router.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/presentation/bloc/auth_state.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/domain/repositories/auth_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/domain/entities/user_entity.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/data/models/login_response_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/presentation/bloc/classes_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/domain/repositories/classes_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/data/models/class_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/presentation/bloc/assignments_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/domain/repositories/assignments_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/data/models/assignment_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/notifications/data/models/notification_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/reports/presentation/bloc/reports_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/reports/domain/repositories/reports_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/reports/data/models/report_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/presentation/bloc/courses_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/domain/repositories/courses_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/data/models/course_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/domain/repositories/finance_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/data/models/invoice_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/profile/domain/repositories/profile_repository.dart';

// ==================== FAKE USERS ====================

const adminTestUser = UserEntity(
  id: 'usr-admin-1',
  userCode: 'ADM-01',
  fullName: 'Quản Trị Viên Test',
  email: 'admin@lms-edu.vn',
  status: 'ACTIVE',
  isFirstLogin: false,
  roles: ['admin', 'super_admin'],
  permissions: ['*'],
  branchName: 'Chi nhánh Quận 1',
);

const teacherTestUser = UserEntity(
  id: 'usr-teacher-1',
  userCode: 'GV-001',
  fullName: 'Thầy David Nguyễn',
  email: 'teacher@lms-edu.vn',
  status: 'ACTIVE',
  isFirstLogin: false,
  roles: ['teacher'],
  permissions: ['*'],
  branchName: 'Chi nhánh Quận 1',
);

const studentTestUser = UserEntity(
  id: 'usr-student-1',
  userCode: 'HV-2026-0001',
  fullName: 'Nguyễn Văn Học Viên',
  email: 'student@lms-edu.vn',
  status: 'ACTIVE',
  isFirstLogin: false,
  roles: ['student'],
  permissions: ['*'],
  branchName: 'Chi nhánh Quận 1',
);

// ==================== FAKE REPOSITORIES ====================

class FakeAuthRepository implements AuthRepository {
  UserEntity _currentUser = adminTestUser;

  void setCurrentUser(UserEntity user) {
    _currentUser = user;
  }

  @override
  Future<LoginResponseModel> login(String identifier, String password) async =>
      throw UnimplementedError();
  @override
  Future<UserEntity> getMe() async => _currentUser;
  @override
  Future<UserEntity?> getSavedUser() async => _currentUser;
  @override
  Future<bool> isLoggedIn() async => true;
  @override
  Future<void> logout() async {}
  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {}
  @override
  Future<LoginResponseModel> firstLoginSetup(
    String newPassword,
    String confirmPassword,
  ) async => throw UnimplementedError();
  @override
  Future<void> forgotPassword(String email) async {}
  @override
  Future<void> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {}
}

class FakeClassesRepository implements ClassesRepository {
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
  Future<ClassModel> getClassDetail(String id) async =>
      throw UnimplementedError();
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
  }) async => throw UnimplementedError();
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
  }) async => throw UnimplementedError();
  @override
  Future<ClassStudentModel> enrollStudent(
    String classId, {
    required String studentId,
    double tuitionPaid = 0,
    String? notes,
  }) async => throw UnimplementedError();
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
  }) async => throw UnimplementedError();
  @override
  Future<List<ClassModel>> getMyClasses() async => [];
  @override
  Future<List<ClassSessionModel>> getMySchedule({
    String? fromDate,
    String? toDate,
  }) async => [];
}

class FakeAssignmentsRepository implements AssignmentsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<AssignmentAttachmentModel> uploadAttachment(
    String fileName,
    Uint8List bytes,
  ) async => throw UnimplementedError();
  @override
  Future<AssignmentModel> updateAssignment(
    String id, {
    required String title,
    required String description,
    required String type,
    String? deadline,
    required double maxScore,
    required List<Map<String, dynamic>> attachments,
  }) async => throw UnimplementedError();
  @override
  Future<List<AssignmentModel>> getClassAssignments(String classId) async => [];
  @override
  Future<AssignmentModel> createAssignment(
    String classId, {
    required String title,
    String? description,
    String? type,
    String? deadline,
    double? maxScore,
    List<Map<String, dynamic>>? attachments,
  }) async => throw UnimplementedError();
  @override
  Future<AssignmentModel> getAssignmentDetail(String id) async =>
      throw UnimplementedError();
  @override
  Future<SubmissionModel> submitAssignment(
    String assignmentId, {
    String? content,
    List<Map<String, dynamic>>? fileUrls,
  }) async => throw UnimplementedError();
  @override
  Future<AssignmentSubmissionsResponseModel> getAssignmentSubmissions(
    String assignmentId,
  ) async => throw UnimplementedError();
  @override
  Future<SubmissionModel> gradeSubmission(
    String submissionId, {
    required double score,
    String? feedback,
  }) async => throw UnimplementedError();
}

class FakeNotificationsRepository implements NotificationsRepository {
  @override
  Future<List<NotificationModel>> getMyNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
  }) async => [];
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
      totalStudents: 120,
      newStudentsThisMonth: 15,
      totalActiveClasses: 10,
      monthlyRevenue: 60000000,
      lastMonthRevenue: 50000000,
      monthlyRevenueGrowth: 20.0,
      totalDebts: 8000000,
      revenueTrend: [],
      courseDistribution: [],
      upcomingClasses: [],
      topDebtors: [],
    );
  }

  @override
  Future<RevenueReportModel> getRevenueReport({
    int? year,
    String? branchId,
  }) async => throw UnimplementedError();
  @override
  Future<AttendanceReportModel> getAttendanceReport({
    String? classId,
    String? startDate,
    String? endDate,
  }) async => throw UnimplementedError();
  @override
  Future<DebtsReportModel> getDebtsReport({
    String? branchId,
    String? search,
    int page = 1,
    int limit = 20,
  }) async => throw UnimplementedError();
  @override
  Future<List<TeacherWorkloadModel>> getTeacherWorkloadReport() async => [];
  @override
  Future<void> refreshDashboardCache() async {}
}

class FakeCoursesRepository implements CoursesRepository {
  @override
  Future<List<CourseModel>> getCourses({
    String? search,
    String? language,
    bool? isActive,
    int page = 1,
    int limit = 50,
  }) async => [];
  @override
  Future<CourseModel> getCourseDetail(String id) async =>
      throw UnimplementedError();
  @override
  Future<CourseModel> createCourse({
    required String code,
    required String title,
    String? description,
    String? targetAudience,
    String language = 'English',
    String? thumbnailUrl,
  }) async => throw UnimplementedError();
  @override
  Future<CourseModel> updateCourse(
    String id, {
    String? code,
    String? title,
    String? description,
    String? targetAudience,
    String? language,
    String? thumbnailUrl,
    bool? isActive,
  }) async => throw UnimplementedError();
  @override
  Future<CourseLevelModel> createLevel(
    String courseId, {
    required String code,
    required String name,
    String? description,
    int order = 1,
    int estimatedSessions = 24,
    double tuitionFee = 0,
  }) async => throw UnimplementedError();
  @override
  Future<ModuleModel> createModule(
    String levelId, {
    required String title,
    int order = 1,
    String? description,
  }) async => throw UnimplementedError();
  @override
  Future<LessonModel> createLesson(
    String moduleId, {
    required String title,
    int order = 1,
    String? content,
    int durationMinutes = 90,
  }) async => throw UnimplementedError();
  @override
  Future<LessonMaterialModel> createMaterial(
    String lessonId, {
    required String title,
    required String fileUrl,
    String fileType = 'DOCUMENT',
    int? fileSizeBytes,
  }) async => throw UnimplementedError();
}

class FakeFinanceRepository implements FinanceRepository {
  @override
  Future<InvoicesResponseModel> getInvoices({
    String? status,
    String? search,
    String? studentId,
    String? classId,
    int page = 1,
    int limit = 20,
  }) async {
    return InvoicesResponseModel(
      items: [],
      total: 0,
      page: 1,
      limit: 20,
      summary: InvoicesSummaryModel(
        totalRevenue: 0,
        paidRevenue: 0,
        outstandingRevenue: 0,
      ),
    );
  }

  @override
  Future<List<InvoiceModel>> getMyInvoices() async => [];
  @override
  Future<InvoiceModel> getInvoiceDetail(String id) async =>
      throw UnimplementedError();
  @override
  Future<InvoiceModel> createInvoice(Map<String, dynamic> data) async =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> recordPayment(
    String invoiceId, {
    required double amount,
    required String method,
    String? transactionId,
    String? notes,
  }) async => throw UnimplementedError();
  @override
  Future<InvoiceModel> cancelInvoice(
    String invoiceId, {
    String? reason,
  }) async => throw UnimplementedError();
  @override
  Future<InvoiceModel> refundInvoice(
    String invoiceId, {
    required double amount,
    String? reason,
  }) async => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> payOnline(
    String invoiceId, {
    String? bankCode,
    String? language,
  }) async => throw UnimplementedError();
  @override
  Future<List<PromotionModel>> getPromotions({bool? isActive}) async => [];
  @override
  Future<Map<String, dynamic>> validatePromotion(
    String code,
    double orderAmount,
  ) async => throw UnimplementedError();
}

class FakeProfileRepository implements ProfileRepository {
  @override
  Future<UserEntity> getMyProfile() async => adminTestUser;
  @override
  Future<UserEntity> updateProfile({
    String? fullName,
    String? phone,
    String? address,
    String? gender,
    String? dateOfBirth,
    String? avatarUrl,
  }) async => adminTestUser;
  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {}
}

// ==================== TEST SUITE ====================

void main() {
  final getIt = GetIt.instance;
  late FakeAuthRepository authRepo;
  late AuthBloc authBloc;
  late NotificationBloc notificationBloc;
  late ClassesBloc classesBloc;
  late AssignmentsBloc assignmentsBloc;
  late ReportsBloc reportsBloc;
  late CoursesBloc coursesBloc;
  late FinanceBloc financeBloc;
  late ProfileBloc profileBloc;

  setUp(() {
    getIt.reset();

    authRepo = FakeAuthRepository();
    final classesRepo = FakeClassesRepository();
    final assignmentsRepo = FakeAssignmentsRepository();
    final notificationsRepo = FakeNotificationsRepository();
    final reportsRepo = FakeReportsRepository();
    final coursesRepo = FakeCoursesRepository();
    final financeRepo = FakeFinanceRepository();
    final profileRepo = FakeProfileRepository();

    authBloc = AuthBloc(authRepository: authRepo);
    notificationBloc = NotificationBloc(repository: notificationsRepo);
    classesBloc = ClassesBloc(repository: classesRepo);
    assignmentsBloc = AssignmentsBloc(repository: assignmentsRepo);
    reportsBloc = ReportsBloc(repository: reportsRepo);
    coursesBloc = CoursesBloc(repository: coursesRepo);
    financeBloc = FinanceBloc(repository: financeRepo);
    profileBloc = ProfileBloc(repository: profileRepo);

    getIt.registerFactory<AuthBloc>(() => authBloc);
    getIt.registerFactory<NotificationBloc>(() => notificationBloc);
    getIt.registerFactory<ClassesBloc>(() => classesBloc);
    getIt.registerFactory<AssignmentsBloc>(() => assignmentsBloc);
    getIt.registerFactory<ReportsBloc>(() => reportsBloc);
    getIt.registerFactory<CoursesBloc>(() => coursesBloc);
    getIt.registerFactory<FinanceBloc>(() => financeBloc);
    getIt.registerFactory<ProfileBloc>(() => profileBloc);
  });

  tearDown(() {
    getIt.reset();
  });

  Widget buildRouterApp({UserEntity user = adminTestUser}) {
    authRepo.setCurrentUser(user);
    authBloc.emit(AuthenticatedState(user: user));

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<NotificationBloc>.value(value: notificationBloc),
        BlocProvider<ClassesBloc>.value(value: classesBloc),
        BlocProvider<AssignmentsBloc>.value(value: assignmentsBloc),
        BlocProvider<ReportsBloc>.value(value: reportsBloc),
        BlocProvider<CoursesBloc>.value(value: coursesBloc),
        BlocProvider<FinanceBloc>.value(value: financeBloc),
        BlocProvider<ProfileBloc>.value(value: profileBloc),
      ],
      child: MaterialApp.router(routerConfig: appRouter),
    );
  }

  void setupScreenSize(WidgetTester tester, double width, double height) {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Future<void> pumpFrames(WidgetTester tester, [int millis = 300]) async {
    await tester.pump();
    await tester.pump(Duration(milliseconds: millis));
  }

  group(
    'Pixel 9 Mobile (393 x 852): Cross-Portal Responsiveness & Shell Tests',
    () {
      testWidgets(
        'AdminHomeScreen renders AppBar, Drawer, and BottomNavigationBar with 0 horizontal overflows',
        (tester) async {
          setupScreenSize(tester, 393, 852);

          await tester.pumpWidget(buildRouterApp(user: adminTestUser));
          appRouter.go(RouteNames.adminHome);
          await pumpFrames(tester);

          // 1. Verify AppBar presence
          expect(find.byType(AppBar), findsOneWidget);
          expect(find.text('Tổng quan'), findsWidgets);

          // 2. Verify BottomNavigationBar presence
          expect(find.byType(BottomNavigationBar), findsOneWidget);

          // 3. Verify persistent 260px desktop sidebar is NOT rendered
          final desktopSidebar = find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.constraints?.maxWidth == 260 &&
                w.constraints?.minWidth == 260,
          );
          expect(desktopSidebar, findsNothing);

          // 4. Verify Drawer can be opened
          final scaffoldFinder = find.byType(Scaffold);
          expect(scaffoldFinder, findsWidgets);
          final scaffoldState = tester.state<ScaffoldState>(
            scaffoldFinder.first,
          );
          scaffoldState.openDrawer();
          await pumpFrames(tester);

          expect(find.byType(Drawer), findsOneWidget);
          expect(
            find.descendant(
              of: find.byType(Drawer),
              matching: find.text('Quản Trị Viên Test'),
            ),
            findsOneWidget,
          );
          expect(find.text('Quản lý người dùng'), findsOneWidget);

          // Close drawer
          scaffoldState.closeDrawer();
          await pumpFrames(tester);

          // 5. Test switching BottomNavigationBar items
          await tester.tap(find.text('Lớp học'));
          await pumpFrames(tester);
          expect(find.byType(BottomNavigationBar), findsOneWidget);

          await tester.tap(find.text('Khóa học'));
          await pumpFrames(tester);
          expect(find.byType(BottomNavigationBar), findsOneWidget);

          await tester.tap(find.text('Báo cáo'));
          await pumpFrames(tester);
          expect(find.byType(BottomNavigationBar), findsOneWidget);
        },
      );

      testWidgets(
        'TeacherHomeScreen renders AppBar, Drawer, and NavigationBar with 0 horizontal overflows',
        (tester) async {
          setupScreenSize(tester, 393, 852);

          await tester.pumpWidget(buildRouterApp(user: teacherTestUser));
          appRouter.go(RouteNames.teacherHome);
          await pumpFrames(tester);

          // 1. Verify AppBar presence
          expect(find.byType(AppBar), findsOneWidget);
          expect(find.text('Tổng quan giảng dạy'), findsWidgets);

          // 2. Verify NavigationBar presence (Material 3 Bottom Navigation)
          expect(find.byType(NavigationBar), findsOneWidget);

          // 3. Verify persistent 260px desktop sidebar is NOT rendered
          final desktopSidebar = find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.constraints?.maxWidth == 260 &&
                w.constraints?.minWidth == 260,
          );
          expect(desktopSidebar, findsNothing);

          // 4. Verify Drawer can be opened
          final scaffoldFinder = find.byType(Scaffold);
          final scaffoldState = tester.state<ScaffoldState>(
            scaffoldFinder.first,
          );
          scaffoldState.openDrawer();
          await pumpFrames(tester);

          expect(find.byType(Drawer), findsOneWidget);
          expect(
            find.descendant(
              of: find.byType(Drawer),
              matching: find.text('Thầy David Nguyễn'),
            ),
            findsOneWidget,
          );
          expect(find.text('Điểm danh & Sổ đầu bài'), findsOneWidget);

          // Close drawer
          scaffoldState.closeDrawer();
          await pumpFrames(tester);

          // 5. Test switching destinations
          await tester.tap(find.text('Lịch dạy'));
          await pumpFrames(tester);
          expect(find.byType(NavigationBar), findsOneWidget);

          await tester.tap(find.text('Chấm bài'));
          await pumpFrames(tester);
          expect(find.byType(NavigationBar), findsOneWidget);
        },
      );

      testWidgets(
        'StudentHomeScreen renders AppBar, Drawer, and BottomNavigationBar with 0 horizontal overflows',
        (tester) async {
          setupScreenSize(tester, 393, 852);

          await tester.pumpWidget(buildRouterApp(user: studentTestUser));
          appRouter.go(RouteNames.studentHome);
          await pumpFrames(tester);

          // 1. Verify AppBar presence
          expect(find.byType(AppBar), findsOneWidget);
          expect(find.text('Trang chủ'), findsWidgets);

          // 2. Verify BottomNavigationBar presence
          expect(find.byType(BottomNavigationBar), findsOneWidget);

          // 3. Verify persistent 260px desktop sidebar is NOT rendered
          final desktopSidebar = find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.constraints?.maxWidth == 260 &&
                w.constraints?.minWidth == 260,
          );
          expect(desktopSidebar, findsNothing);

          // 4. Verify Drawer can be opened
          final scaffoldFinder = find.byType(Scaffold);
          final scaffoldState = tester.state<ScaffoldState>(
            scaffoldFinder.first,
          );
          scaffoldState.openDrawer();
          await pumpFrames(tester);

          expect(find.byType(Drawer), findsOneWidget);
          expect(
            find.descendant(
              of: find.byType(Drawer),
              matching: find.text('Nguyễn Văn Học Viên'),
            ),
            findsOneWidget,
          );
          expect(find.text('Bảng điểm'), findsOneWidget);

          // Close drawer
          scaffoldState.closeDrawer();
          await pumpFrames(tester);

          // 5. Test switching BottomNavigationBar tabs
          await tester.tap(find.text('Lịch học'));
          await pumpFrames(tester);
          expect(find.byType(BottomNavigationBar), findsOneWidget);

          await tester.tap(find.text('Khóa học'));
          await pumpFrames(tester);
          expect(find.byType(BottomNavigationBar), findsOneWidget);

          await tester.tap(find.text('Bài tập'));
          await pumpFrames(tester);
          expect(find.byType(BottomNavigationBar), findsOneWidget);

          await tester.tap(find.text('Học phí'));
          await pumpFrames(tester);
          expect(find.byType(BottomNavigationBar), findsOneWidget);
        },
      );
    },
  );

  group(
    'Web Desktop Compact (1024 x 768): Persistent 260px Sidebar & Header Tests',
    () {
      testWidgets(
        'AdminHomeScreen renders persistent 260px sidebar and header with 0 overflows',
        (tester) async {
          setupScreenSize(tester, 1024, 768);

          await tester.pumpWidget(buildRouterApp(user: adminTestUser));
          appRouter.go(RouteNames.adminHome);
          await pumpFrames(tester);

          // 1. Verify persistent 260px sidebar
          final sidebarFinder = find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.constraints?.maxWidth == 260 &&
                w.constraints?.minWidth == 260,
          );
          expect(sidebarFinder, findsOneWidget);
          final RenderBox sidebarBox = tester.renderObject(sidebarFinder);
          expect(sidebarBox.size.width, equals(260.0));

          // 2. Verify top header bar (64px)
          final headerFinder = find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.constraints?.maxHeight == 64 &&
                w.constraints?.minHeight == 64,
          );
          expect(headerFinder, findsOneWidget);
          final RenderBox headerBox = tester.renderObject(headerFinder);
          expect(headerBox.size.height, equals(64.0));

          // 3. Verify desktop header elements
          expect(find.byType(TextField), findsOneWidget);
          expect(find.text('CN 1: Quận 1'), findsOneWidget);
          expect(find.text('Mở Lớp Học Mới'), findsOneWidget);

          // 4. Verify NO mobile drawer or bottom navigation bar
          expect(find.byType(Drawer), findsNothing);
          expect(find.byType(BottomNavigationBar), findsNothing);
        },
      );

      testWidgets(
        'TeacherHomeScreen renders persistent 260px sidebar and header with 0 overflows',
        (tester) async {
          setupScreenSize(tester, 1024, 768);

          await tester.pumpWidget(buildRouterApp(user: teacherTestUser));
          appRouter.go(RouteNames.teacherHome);
          await pumpFrames(tester);

          // 1. Verify persistent 260px sidebar
          final sidebarFinder = find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.constraints?.maxWidth == 260 &&
                w.constraints?.minWidth == 260,
          );
          expect(sidebarFinder, findsOneWidget);
          final RenderBox sidebarBox = tester.renderObject(sidebarFinder);
          expect(sidebarBox.size.width, equals(260.0));

          // 2. Verify top header bar (64px)
          final headerFinder = find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.constraints?.maxHeight == 64 &&
                w.constraints?.minHeight == 64,
          );
          expect(headerFinder, findsOneWidget);
          final RenderBox headerBox = tester.renderObject(headerFinder);
          expect(headerBox.size.height, equals(64.0));

          // 3. Verify desktop quick action button
          expect(find.text('+ Giao bài tập mới'), findsOneWidget);

          // 4. Verify NO mobile drawer or NavigationBar
          expect(find.byType(Drawer), findsNothing);
          expect(find.byType(NavigationBar), findsNothing);
        },
      );

      testWidgets(
        'StudentHomeScreen renders persistent 260px sidebar and header with 0 overflows',
        (tester) async {
          setupScreenSize(tester, 1024, 768);

          await tester.pumpWidget(buildRouterApp(user: studentTestUser));
          appRouter.go(RouteNames.studentHome);
          await pumpFrames(tester);

          // 1. Verify persistent 260px sidebar
          final sidebarFinder = find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.constraints?.maxWidth == 260 &&
                w.constraints?.minWidth == 260,
          );
          expect(sidebarFinder, findsOneWidget);
          final RenderBox sidebarBox = tester.renderObject(sidebarFinder);
          expect(sidebarBox.size.width, equals(260.0));

          // 2. Verify top header bar (64px)
          final headerFinder = find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.constraints?.maxHeight == 64 &&
                w.constraints?.minHeight == 64,
          );
          expect(headerFinder, findsOneWidget);
          final RenderBox headerBox = tester.renderObject(headerFinder);
          expect(headerBox.size.height, equals(64.0));

          // 3. Verify desktop quick action button
          expect(find.text('+ Nộp bài tập ngay'), findsOneWidget);

          // 4. Verify NO mobile drawer or BottomNavigationBar
          expect(find.byType(Drawer), findsNothing);
          expect(find.byType(BottomNavigationBar), findsNothing);
        },
      );
    },
  );

  group('Web Desktop Standard (1440 x 900): High-Resolution Canvas Tests', () {
    testWidgets('AdminHomeScreen renders at 1440x900 without overflows', (
      tester,
    ) async {
      setupScreenSize(tester, 1440, 900);

      await tester.pumpWidget(buildRouterApp(user: adminTestUser));
      appRouter.go(RouteNames.adminHome);
      await pumpFrames(tester);

      expect(find.text('Mở Lớp Học Mới'), findsOneWidget);
      expect(find.text('CN 1: Quận 1'), findsOneWidget);
    });

    testWidgets('TeacherHomeScreen renders at 1440x900 without overflows', (
      tester,
    ) async {
      setupScreenSize(tester, 1440, 900);

      await tester.pumpWidget(buildRouterApp(user: teacherTestUser));
      appRouter.go(RouteNames.teacherHome);
      await pumpFrames(tester);

      expect(find.text('+ Giao bài tập mới'), findsOneWidget);
      expect(find.text('EduLMS - Cổng Thông Tin Giảng Viên'), findsOneWidget);
    });

    testWidgets('StudentHomeScreen renders at 1440x900 without overflows', (
      tester,
    ) async {
      setupScreenSize(tester, 1440, 900);

      await tester.pumpWidget(buildRouterApp(user: studentTestUser));
      appRouter.go(RouteNames.studentHome);
      await pumpFrames(tester);

      expect(find.text('+ Nộp bài tập ngay'), findsOneWidget);
      expect(find.text('Cổng Học Viên'), findsOneWidget);
    });

    testWidgets(
      'ParentHomeScreen renders at 393x852, 1024x768, and 1440x900 without overflows',
      (tester) async {
        setupScreenSize(tester, 393, 852);
        await tester.pumpWidget(buildRouterApp(user: studentTestUser));
        appRouter.go(RouteNames.parentHome);
        await pumpFrames(tester);

        expect(find.text('Góc Phụ Huynh'), findsOneWidget);
        expect(find.text('Theo Dõi Con Em'), findsOneWidget);

        tester.view.physicalSize = const Size(1024, 768);
        await pumpFrames(tester);
        expect(find.text('Góc Phụ Huynh'), findsOneWidget);

        tester.view.physicalSize = const Size(1440, 900);
        await pumpFrames(tester);
        expect(find.text('Góc Phụ Huynh'), findsOneWidget);
      },
    );
  });

  group('Adversarial Breakpoint Boundary (900px vs 901px)', () {
    testWidgets(
      'AdminHomeScreen flips exactly between mobile (<=900) and desktop (>900)',
      (tester) async {
        // Test at exactly 900px -> Mobile
        setupScreenSize(tester, 900, 700);
        await tester.pumpWidget(buildRouterApp(user: adminTestUser));
        appRouter.go(RouteNames.adminHome);
        await pumpFrames(tester);

        expect(find.byType(BottomNavigationBar), findsOneWidget);
        expect(find.text('Mở Lớp Học Mới'), findsNothing);

        // Test at 901px -> Desktop
        tester.view.physicalSize = const Size(901, 700);
        await pumpFrames(tester);

        expect(find.byType(BottomNavigationBar), findsNothing);
        expect(find.text('Mở Lớp Học Mới'), findsOneWidget);
      },
    );

    testWidgets(
      'StudentHomeScreen flips exactly between mobile (<=900) and desktop (>900)',
      (tester) async {
        // Test at exactly 900px -> Mobile
        setupScreenSize(tester, 900, 700);
        await tester.pumpWidget(buildRouterApp(user: studentTestUser));
        appRouter.go(RouteNames.studentHome);
        await pumpFrames(tester);

        expect(find.byType(BottomNavigationBar), findsOneWidget);
        expect(find.text('+ Nộp bài tập ngay'), findsNothing);

        // Test at 901px -> Desktop
        tester.view.physicalSize = const Size(901, 700);
        await pumpFrames(tester);

        expect(find.byType(BottomNavigationBar), findsNothing);
        expect(find.text('+ Nộp bài tập ngay'), findsOneWidget);
      },
    );
  });
}
