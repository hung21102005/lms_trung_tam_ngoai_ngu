import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/notifications/presentation/bloc/notification_bloc.dart';
import 'features/courses/presentation/bloc/courses_bloc.dart';
import 'features/classes/presentation/bloc/classes_bloc.dart';
import 'features/attendance/presentation/bloc/attendance_bloc.dart';
import 'features/assignments/presentation/bloc/assignments_bloc.dart';
import 'features/exams/presentation/bloc/exams_bloc.dart';
import 'features/finance/presentation/bloc/finance_bloc.dart';
import 'features/reports/presentation/bloc/reports_bloc.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Dependency Injection Locator (GetIt)
  await setupLocator();

  runApp(const LMSApp());
}

class LMSApp extends StatelessWidget {
  const LMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => getIt<AuthBloc>()..add(CheckAuthStatusEvent()),
        ),
        BlocProvider<NotificationBloc>(
          create: (_) => getIt<NotificationBloc>()..add(FetchUnreadCountEvent()),
        ),
        BlocProvider<CoursesBloc>(
          create: (_) => getIt<CoursesBloc>(),
        ),
        BlocProvider<ClassesBloc>(
          create: (_) => getIt<ClassesBloc>(),
        ),
        BlocProvider<AttendanceBloc>(
          create: (_) => getIt<AttendanceBloc>(),
        ),
        BlocProvider<AssignmentsBloc>(
          create: (_) => getIt<AssignmentsBloc>(),
        ),
        BlocProvider<ExamsBloc>(
          create: (_) => getIt<ExamsBloc>(),
        ),
        BlocProvider<FinanceBloc>(
          create: (_) => getIt<FinanceBloc>(),
        ),
        BlocProvider<ReportsBloc>(
          create: (_) => getIt<ReportsBloc>(),
        ),
        BlocProvider<ProfileBloc>(
          create: (_) => getIt<ProfileBloc>(),
        ),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: appRouter,
      ),
    );
  }
}
