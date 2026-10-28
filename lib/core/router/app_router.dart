import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'route_names.dart';
import '../di/injection.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/first_login_screen.dart';
import '../../features/dashboard/presentation/screens/student_home_screen.dart';
import '../../features/dashboard/presentation/screens/admin_home_screen.dart';
import '../../features/dashboard/presentation/screens/teacher_home_screen.dart';
import '../../features/dashboard/presentation/views/teacher_class_workflow_view.dart';
import '../../features/dashboard/presentation/screens/parent_home_screen.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/change_password_screen.dart';
import '../../features/courses/presentation/bloc/courses_bloc.dart';
import '../../features/courses/presentation/screens/course_list_screen.dart';
import '../../features/courses/presentation/screens/course_detail_screen.dart';
import '../../features/courses/presentation/screens/student_courses_screen.dart';
import '../../features/courses/presentation/screens/program_catalog_screen.dart';
import '../../features/courses/data/repositories/program_catalog_repository.dart';
import '../network/api_client.dart';
import '../../features/classes/presentation/bloc/classes_bloc.dart';
import '../../features/classes/presentation/screens/class_list_screen.dart';
import '../../features/classes/presentation/screens/class_create_screen.dart';
import '../../features/classes/presentation/screens/class_detail_screen.dart';
import '../../features/classes/presentation/screens/schedule_screen.dart';
import '../../features/attendance/presentation/bloc/attendance_bloc.dart';
import '../../features/attendance/presentation/screens/attendance_mark_screen.dart';
import '../../features/attendance/presentation/screens/my_attendance_screen.dart';
import '../../features/assignments/presentation/bloc/assignments_bloc.dart';
import '../../features/assignments/presentation/screens/assignment_list_screen.dart';
import '../../features/assignments/presentation/screens/assignment_detail_screen.dart';
import '../../features/assignments/presentation/screens/create_assignment_screen.dart';
import '../../features/assignments/presentation/screens/submit_assignment_screen.dart';
import '../../features/assignments/presentation/screens/submission_review_screen.dart';
import '../../features/assignments/presentation/screens/grade_submission_screen.dart';
import '../../features/exams/presentation/bloc/exams_bloc.dart';
import '../../features/exams/presentation/screens/exam_list_screen.dart';
import '../../features/exams/presentation/screens/take_exam_screen.dart';
import '../../features/exams/presentation/screens/exam_result_screen.dart';
import '../../features/exams/presentation/screens/my_exam_results_screen.dart';
import '../../features/exams/presentation/screens/create_exam_screen.dart';
import '../../features/exams/presentation/screens/question_bank_list_screen.dart';
import '../../features/notifications/presentation/bloc/notification_bloc.dart';
import '../../features/notifications/presentation/screens/notification_list_screen.dart';
import '../../features/finance/presentation/bloc/finance_bloc.dart';
import '../../features/finance/presentation/screens/invoice_list_screen.dart';
import '../../features/finance/presentation/screens/invoice_detail_screen.dart';
import '../../features/finance/presentation/screens/record_payment_screen.dart';
import '../../features/finance/presentation/screens/pay_online_screen.dart';
import '../../features/finance/presentation/screens/my_invoices_screen.dart';
import '../../features/reports/presentation/bloc/reports_bloc.dart';
import '../../features/reports/presentation/screens/admin_dashboard_screen.dart';
import '../../features/reports/presentation/screens/reports_overview_screen.dart';
import '../../features/reports/presentation/screens/debts_report_screen.dart';
import '../../features/reports/presentation/screens/teacher_dashboard_live_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: RouteNames.splash,
  routes: [
    GoRoute(
      path: RouteNames.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: RouteNames.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: RouteNames.forgotPassword,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: RouteNames.firstLoginSetup,
      builder: (context, state) => const FirstLoginScreen(),
    ),
    GoRoute(
      path: RouteNames.studentHome,
      builder: (context, state) => const StudentHomeScreen(),
    ),
    GoRoute(
      path: RouteNames.adminHome,
      builder: (context, state) => const AdminHomeScreen(),
    ),
    GoRoute(
      path: RouteNames.teacherHome,
      builder: (context, state) => const TeacherHomeScreen(),
    ),
    GoRoute(
      path: RouteNames.parentHome,
      builder: (context, state) => const ParentHomeScreen(),
    ),
    // Profile Routes
    GoRoute(
      path: RouteNames.profile,
      builder: (context, state) => BlocProvider<ProfileBloc>(
        create: (_) => getIt<ProfileBloc>(),
        child: const ProfileScreen(),
      ),
    ),
    GoRoute(
      path: RouteNames.editProfile,
      builder: (context, state) => BlocProvider<ProfileBloc>(
        create: (_) => getIt<ProfileBloc>(),
        child: const EditProfileScreen(),
      ),
    ),
    GoRoute(
      path: RouteNames.changePassword,
      builder: (context, state) => BlocProvider<ProfileBloc>(
        create: (_) => getIt<ProfileBloc>(),
        child: const ChangePasswordScreen(),
      ),
    ),
    // Courses & Curriculum Routes
    GoRoute(
      path: RouteNames.programs,
      builder: (context, state) {
        final auth = context.read<AuthBloc>().state;
        if (auth is! AuthenticatedState ||
            !(auth.user.isSuperAdmin ||
                auth.user.isBranchAdmin ||
                auth.user.isAcademicStaff)) {
          return const Scaffold(
            body: Center(child: Text('Không có quyền truy cập')),
          );
        }
        return ProgramCatalogScreen(
          repository: ProgramCatalogRepository(getIt<ApiClient>()),
        );
      },
    ),
    GoRoute(
      path: RouteNames.courses,
      builder: (context, state) {
        final auth = context.read<AuthBloc>().state;
        if (auth is AuthenticatedState && auth.user.isStudent) {
          return const StudentCoursesScreen(showAppBar: true);
        }
        return BlocProvider<CoursesBloc>(
          create: (_) => getIt<CoursesBloc>(),
          child: const CourseListScreen(),
        );
      },
    ),
    GoRoute(
      path: RouteNames.courseDetail,
      builder: (context, state) {
        final auth = context.read<AuthBloc>().state;
        if (auth is AuthenticatedState && auth.user.isStudent) {
          return const StudentCoursesScreen(showAppBar: true);
        }
        final id = state.pathParameters['id'] ?? '';
        return BlocProvider<CoursesBloc>(
          create: (_) => getIt<CoursesBloc>(),
          child: CourseDetailScreen(courseId: id),
        );
      },
    ),
    // Classes & Scheduling Routes
    GoRoute(
      path: RouteNames.classes,
      builder: (context, state) => BlocProvider<ClassesBloc>(
        create: (_) => getIt<ClassesBloc>(),
        child: const ClassListScreen(),
      ),
    ),
    GoRoute(
      path: RouteNames.classCreate,
      builder: (context, state) => BlocProvider<ClassesBloc>(
        create: (_) => getIt<ClassesBloc>(),
        child: const ClassCreateScreen(),
      ),
    ),
    GoRoute(
      path: RouteNames.classDetail,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return BlocProvider<ClassesBloc>(
          create: (_) => getIt<ClassesBloc>(),
          child: ClassDetailScreen(classId: id),
        );
      },
    ),
    GoRoute(
      path: RouteNames.schedule,
      builder: (context, state) => BlocProvider<ClassesBloc>(
        create: (_) => getIt<ClassesBloc>(),
        child: const ScheduleScreen(),
      ),
    ),
    // Attendance Routes
    GoRoute(
      path: RouteNames.attendanceMark,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return BlocProvider<AttendanceBloc>(
          create: (_) => getIt<AttendanceBloc>(),
          child: AttendanceMarkScreen(sessionId: id),
        );
      },
    ),
    GoRoute(
      path: RouteNames.myAttendance,
      builder: (context, state) {
        final studentId = state.extra as String? ?? '';
        return BlocProvider<AttendanceBloc>(
          create: (_) => getIt<AttendanceBloc>(),
          child: MyAttendanceScreen(studentId: studentId),
        );
      },
    ),
    // Assignments Routes
    GoRoute(
      path: RouteNames.teacherAssignments,
      builder: (context, state) =>
          const TeacherClassWorkflowView(mode: TeacherWorkflowMode.assignments),
    ),
    GoRoute(
      path: RouteNames.assignments,
      builder: (context, state) {
        final classId = state.extra as String? ?? '';
        final auth = context.read<AuthBloc>().state;
        final isTeacher = auth is AuthenticatedState && auth.user.isTeacher;
        return BlocProvider<AssignmentsBloc>(
          create: (_) => getIt<AssignmentsBloc>(),
          child: AssignmentListScreen(classId: classId, isTeacher: isTeacher),
        );
      },
    ),
    GoRoute(
      path: RouteNames.classAssignments,
      builder: (context, state) {
        final classId = state.pathParameters['classId'] ?? '';
        final auth = context.read<AuthBloc>().state;
        final isTeacher =
            state.extra as bool? ??
            (auth is AuthenticatedState && auth.user.isTeacher);
        return BlocProvider<AssignmentsBloc>(
          create: (_) => getIt<AssignmentsBloc>(),
          child: AssignmentListScreen(classId: classId, isTeacher: isTeacher),
        );
      },
    ),
    GoRoute(
      path: RouteNames.createAssignment,
      builder: (context, state) {
        final classId = state.pathParameters['classId'] ?? '';
        return BlocProvider<AssignmentsBloc>(
          create: (_) => getIt<AssignmentsBloc>(),
          child: CreateAssignmentScreen(classId: classId),
        );
      },
    ),
    GoRoute(
      path: RouteNames.assignmentDetail,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        final isTeacher =
            state.extra as bool? ??
            state.uri.queryParameters['teacher'] == 'true';
        return BlocProvider<AssignmentsBloc>(
          create: (_) => getIt<AssignmentsBloc>(),
          child: AssignmentDetailScreen(assignmentId: id, isTeacher: isTeacher),
        );
      },
    ),
    GoRoute(
      path: RouteNames.editAssignment,
      builder: (context, state) => BlocProvider<AssignmentsBloc>(
        create: (_) => getIt<AssignmentsBloc>(),
        child: CreateAssignmentScreen(
          classId: '',
          assignmentId: state.pathParameters['id'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: RouteNames.submitAssignment,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return BlocProvider<AssignmentsBloc>(
          create: (_) => getIt<AssignmentsBloc>(),
          child: SubmitAssignmentScreen(assignmentId: id),
        );
      },
    ),
    GoRoute(
      path: RouteNames.gradeSubmissions,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return BlocProvider<AssignmentsBloc>(
          create: (_) => getIt<AssignmentsBloc>(),
          child: GradeSubmissionScreen(assignmentId: id),
        );
      },
    ),
    GoRoute(
      path: RouteNames.reviewSubmission,
      builder: (context, state) => BlocProvider<AssignmentsBloc>(
        create: (_) => getIt<AssignmentsBloc>(),
        child: SubmissionReviewScreen(
          assignmentId: state.pathParameters['id'] ?? '',
          studentId: state.pathParameters['studentId'] ?? '',
          focusScore: state.uri.queryParameters['edit'] == 'true',
        ),
      ),
    ),
    // Exams & Assessments Routes
    GoRoute(
      path: RouteNames.exams,
      builder: (context, state) {
        final classId = state.extra as String?;
        final authState = context.read<AuthBloc>().state;
        final user = authState is AuthenticatedState ? authState.user : null;
        final canManageExams =
            user?.isTeacher == true ||
            user?.isAcademicStaff == true ||
            user?.isBranchAdmin == true ||
            user?.isSuperAdmin == true;
        return BlocProvider<ExamsBloc>(
          create: (_) => getIt<ExamsBloc>(),
          child: ExamListScreen(classId: classId, isTeacher: canManageExams),
        );
      },
    ),
    GoRoute(
      path: RouteNames.createExam,
      builder: (context, state) {
        final classId = state.extra as String?;
        return BlocProvider<ExamsBloc>(
          create: (_) => getIt<ExamsBloc>(),
          child: CreateExamScreen(classId: classId),
        );
      },
    ),
    GoRoute(
      path: RouteNames.takeExam,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return BlocProvider<ExamsBloc>(
          create: (_) => getIt<ExamsBloc>(),
          child: TakeExamScreen(examId: id),
        );
      },
    ),
    GoRoute(
      path: RouteNames.examResults,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return BlocProvider<ExamsBloc>(
          create: (_) => getIt<ExamsBloc>(),
          child: ExamResultScreen(examId: id),
        );
      },
    ),
    GoRoute(
      path: RouteNames.myExamResults,
      builder: (context, state) => BlocProvider<ExamsBloc>(
        create: (_) => getIt<ExamsBloc>(),
        child: const MyExamResultsScreen(),
      ),
    ),
    GoRoute(
      path: RouteNames.questionBanks,
      builder: (context, state) => BlocProvider<ExamsBloc>(
        create: (_) => getIt<ExamsBloc>(),
        child: const QuestionBankListScreen(),
      ),
    ),
    // Notifications Route
    GoRoute(
      path: RouteNames.notifications,
      builder: (context, state) => BlocProvider.value(
        value: getIt<NotificationBloc>(),
        child: const NotificationListScreen(),
      ),
    ),
    // Finance Routes
    GoRoute(
      path: RouteNames.invoices,
      builder: (context, state) => BlocProvider<FinanceBloc>(
        create: (_) => getIt<FinanceBloc>(),
        child: const InvoiceListScreen(),
      ),
    ),
    GoRoute(
      path: RouteNames.myInvoices,
      builder: (context, state) => BlocProvider<FinanceBloc>(
        create: (_) => getIt<FinanceBloc>(),
        child: const MyInvoicesScreen(),
      ),
    ),
    GoRoute(
      path: RouteNames.invoiceDetail,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return BlocProvider<FinanceBloc>(
          create: (_) => getIt<FinanceBloc>(),
          child: InvoiceDetailScreen(invoiceId: id),
        );
      },
    ),
    GoRoute(
      path: RouteNames.recordPayment,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return BlocProvider<FinanceBloc>(
          create: (_) => getIt<FinanceBloc>(),
          child: RecordPaymentScreen(invoiceId: id),
        );
      },
    ),
    GoRoute(
      path: RouteNames.payOnline,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return BlocProvider<FinanceBloc>(
          create: (_) => getIt<FinanceBloc>(),
          child: PayOnlineScreen(invoiceId: id),
        );
      },
    ),
    GoRoute(
      path: RouteNames.adminDashboard,
      builder: (context, state) => BlocProvider<ReportsBloc>(
        create: (_) => getIt<ReportsBloc>(),
        child: const AdminDashboardScreen(),
      ),
    ),
    GoRoute(
      path: RouteNames.reportsOverview,
      builder: (context, state) => BlocProvider<ReportsBloc>(
        create: (_) => getIt<ReportsBloc>(),
        child: const ReportsOverviewScreen(),
      ),
    ),
    GoRoute(
      path: RouteNames.debtsReport,
      builder: (context, state) => BlocProvider<ReportsBloc>(
        create: (_) => getIt<ReportsBloc>(),
        child: const DebtsReportScreen(),
      ),
    ),
    GoRoute(
      path: RouteNames.teacherDashboard,
      builder: (context, state) => BlocProvider<ReportsBloc>(
        create: (_) => getIt<ReportsBloc>(),
        child: const TeacherDashboardLiveScreen(),
      ),
    ),
  ],
);
