import 'package:get_it/get_it.dart';
import '../storage/secure_storage_service.dart';
import '../network/api_client.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/courses/data/datasources/courses_remote_datasource.dart';
import '../../features/courses/domain/repositories/courses_repository.dart';
import '../../features/courses/data/repositories/courses_repository_impl.dart';
import '../../features/courses/presentation/bloc/courses_bloc.dart';
import '../../features/classes/data/datasources/classes_remote_datasource.dart';
import '../../features/classes/domain/repositories/classes_repository.dart';
import '../../features/classes/data/repositories/classes_repository_impl.dart';
import '../../features/classes/presentation/bloc/classes_bloc.dart';
import '../../features/attendance/data/datasources/attendance_remote_datasource.dart';
import '../../features/attendance/domain/repositories/attendance_repository.dart';
import '../../features/attendance/data/repositories/attendance_repository_impl.dart';
import '../../features/attendance/presentation/bloc/attendance_bloc.dart';
import '../../features/assignments/data/datasources/assignments_remote_datasource.dart';
import '../../features/assignments/domain/repositories/assignments_repository.dart';
import '../../features/assignments/data/repositories/assignments_repository_impl.dart';
import '../../features/assignments/presentation/bloc/assignments_bloc.dart';
import '../../features/exams/data/datasources/exams_remote_datasource.dart';
import '../../features/exams/domain/repositories/exams_repository.dart';
import '../../features/exams/data/repositories/exams_repository_impl.dart';
import '../../features/exams/presentation/bloc/exams_bloc.dart';
import '../../features/notifications/data/datasources/notifications_remote_datasource.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/presentation/bloc/notification_bloc.dart';
import '../../features/finance/data/datasources/finance_remote_datasource.dart';
import '../../features/finance/domain/repositories/finance_repository.dart';
import '../../features/finance/data/repositories/finance_repository_impl.dart';
import '../../features/finance/presentation/bloc/finance_bloc.dart';
import '../../features/reports/data/datasources/reports_remote_datasource.dart';
import '../../features/reports/domain/repositories/reports_repository.dart';
import '../../features/reports/data/repositories/reports_repository_impl.dart';
import '../../features/reports/presentation/bloc/reports_bloc.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupLocator() async {
  // 1. Storage
  getIt.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(),
  );

  // 2. Network Client
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(storageService: getIt<SecureStorageService>()),
  );

  // 3. Data Sources
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(client: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<CoursesRemoteDataSource>(
    () => CoursesRemoteDataSourceImpl(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<ClassesRemoteDataSource>(
    () => ClassesRemoteDataSourceImpl(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<AttendanceRemoteDataSource>(
    () => AttendanceRemoteDataSourceImpl(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<AssignmentsRemoteDataSource>(
    () => AssignmentsRemoteDataSourceImpl(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<ExamsRemoteDataSource>(
    () => ExamsRemoteDataSourceImpl(apiClient: getIt<ApiClient>()),
  );

  // 4. Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: getIt<AuthRemoteDataSource>(),
      storageService: getIt<SecureStorageService>(),
    ),
  );
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      remoteDataSource: getIt<ProfileRemoteDataSource>(),
    ),
  );
  getIt.registerLazySingleton<CoursesRepository>(
    () => CoursesRepositoryImpl(
      remoteDataSource: getIt<CoursesRemoteDataSource>(),
    ),
  );
  getIt.registerLazySingleton<ClassesRepository>(
    () => ClassesRepositoryImpl(
      remoteDataSource: getIt<ClassesRemoteDataSource>(),
    ),
  );
  getIt.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepositoryImpl(
      remoteDataSource: getIt<AttendanceRemoteDataSource>(),
    ),
  );
  getIt.registerLazySingleton<AssignmentsRepository>(
    () => AssignmentsRepositoryImpl(
      remoteDataSource: getIt<AssignmentsRemoteDataSource>(),
    ),
  );
  getIt.registerLazySingleton<ExamsRepository>(
    () => ExamsRepositoryImpl(
      remoteDataSource: getIt<ExamsRemoteDataSource>(),
    ),
  );
  getIt.registerLazySingleton<NotificationsRemoteDataSource>(
    () => NotificationsRemoteDataSourceImpl(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<FinanceRemoteDataSource>(
    () => FinanceRemoteDataSourceImpl(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<ReportsRemoteDataSource>(
    () => ReportsRemoteDataSourceImpl(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepositoryImpl(
      remoteDataSource: getIt<NotificationsRemoteDataSource>(),
    ),
  );
  getIt.registerLazySingleton<FinanceRepository>(
    () => FinanceRepositoryImpl(
      remoteDataSource: getIt<FinanceRemoteDataSource>(),
    ),
  );
  getIt.registerLazySingleton<ReportsRepository>(
    () => ReportsRepositoryImpl(
      remoteDataSource: getIt<ReportsRemoteDataSource>(),
    ),
  );

  // 5. Use Cases
  getIt.registerLazySingleton<LoginUseCase>(
    () => LoginUseCase(repository: getIt<AuthRepository>()),
  );

  // 6. BLoC
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: getIt<AuthRepository>()),
  );
  getIt.registerFactory<ProfileBloc>(
    () => ProfileBloc(repository: getIt<ProfileRepository>()),
  );
  getIt.registerFactory<CoursesBloc>(
    () => CoursesBloc(repository: getIt<CoursesRepository>()),
  );
  getIt.registerFactory<ClassesBloc>(
    () => ClassesBloc(repository: getIt<ClassesRepository>()),
  );
  getIt.registerFactory<AttendanceBloc>(
    () => AttendanceBloc(repository: getIt<AttendanceRepository>()),
  );
  getIt.registerFactory<AssignmentsBloc>(
    () => AssignmentsBloc(repository: getIt<AssignmentsRepository>()),
  );
  getIt.registerFactory<ExamsBloc>(
    () => ExamsBloc(repository: getIt<ExamsRepository>()),
  );
  getIt.registerLazySingleton<NotificationBloc>(
    () => NotificationBloc(repository: getIt<NotificationsRepository>()),
  );
  getIt.registerFactory<FinanceBloc>(
    () => FinanceBloc(repository: getIt<FinanceRepository>()),
  );
  getIt.registerFactory<ReportsBloc>(
    () => ReportsBloc(repository: getIt<ReportsRepository>()),
  );
}
