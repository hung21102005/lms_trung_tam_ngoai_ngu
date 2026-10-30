import 'package:dio/dio.dart' show Options;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lms_trung_tam_ngoai_ngu/core/di/injection.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/network/api_client.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/router/route_names.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/data/models/login_response_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/data/models/user_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/domain/entities/user_entity.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/domain/repositories/auth_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/presentation/bloc/auth_event.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/presentation/bloc/auth_state.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/presentation/screens/first_login_screen.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/data/models/class_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/domain/repositories/classes_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/presentation/bloc/classes_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/presentation/screens/class_create_screen.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/profile/domain/repositories/profile_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/profile/presentation/screens/profile_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  LoginResponseModel? loginResponse;
  LoginResponseModel? firstLoginResponse;
  UserEntity? meUser;
  UserEntity? savedUser;
  bool loggedIn = true;

  @override
  Future<LoginResponseModel> login(String identifier, String password) async {
    return loginResponse!;
  }

  @override
  Future<UserEntity> getMe() async {
    if (meUser != null) return meUser!;
    throw Exception('getMe not configured');
  }

  @override
  Future<UserEntity?> getSavedUser() async => savedUser;

  @override
  Future<bool> isLoggedIn() async => loggedIn;

  @override
  Future<void> logout() async {
    loggedIn = false;
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {}

  @override
  Future<LoginResponseModel> firstLoginSetup(
    String newPassword,
    String confirmPassword,
  ) async {
    return firstLoginResponse!;
  }

  @override
  Future<void> forgotPassword(String email) async {}

  @override
  Future<void> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {}
}

class _FakeProfileRepository implements ProfileRepository {
  UserEntity user;

  _FakeProfileRepository(this.user);

  @override
  Future<UserEntity> getMyProfile() async => user;

  @override
  Future<UserEntity> updateProfile({
    String? fullName,
    String? phone,
    String? address,
    String? gender,
    String? dateOfBirth,
    String? avatarUrl,
  }) async =>
      user;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {}
}

class _FakeApiClient extends Fake implements ApiClient {
  final List<String> requestedPaths = [];

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    requestedPaths.add(path);
    return <String, dynamic>{'data': <dynamic>[]};
  }
}

class _FakeClassesRepository extends Fake implements ClassesRepository {
  Map<String, String?>? createdSelection;

  @override
  Future<List<ClassModel>> getClasses({
    String? search,
    String? status,
    String? branchId,
    String? courseId,
    String? teacherId,
    int page = 1,
    int limit = 50,
  }) async =>
      [];

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
    String? registrationOpenAt,
    String? registrationCloseAt,
    String? notes,
  }) async {
    createdSelection = {
      'courseId': courseId,
      'levelId': levelId,
      'branchId': branchId,
      'roomId': roomId,
      'mainTeacherId': mainTeacherId,
    };
    throw StateError('Captured createClass');
  }
}

void main() {
  late _FakeApiClient fakeApiClient;

  setUp(() async {
    await getIt.reset();
    fakeApiClient = _FakeApiClient();
    getIt.registerSingleton<ApiClient>(fakeApiClient);
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('Test A – First Login Role Routing & Role Resolution', () {
    testWidgets(
      'Giảng viên mới (Phạm Minh Nguyệt) đổi mật khẩu lần đầu -> điều hướng thẳng vào Teacher Dashboard (không bao giờ rơi vào Student Dashboard)',
      (tester) async {
        final fakeAuthRepo = _FakeAuthRepository();
        const initialTeacher = UserModel(
          id: 'teacher-nguyet-id',
          userCode: 'GV-2026-0009',
          fullName: 'Phạm Minh Nguyệt',
          email: 'nguyet.pham@edulms.vn',
          status: 'ACTIVE',
          isFirstLogin: true,
          roles: ['teacher'],
          permissions: [],
        );

        // Giả lập trường hợp response trả về đầy đủ hoặc thậm chí thiếu roles nhưng AuthBloc bảo toàn/hydrate từ getMe
        fakeAuthRepo.firstLoginResponse = const LoginResponseModel(
          message: 'Kích hoạt thành công',
          accessToken: 'new-access-token',
          refreshToken: 'new-refresh-token',
          requiresPasswordChange: false,
          user: UserModel(
            id: 'teacher-nguyet-id',
            userCode: 'GV-2026-0009',
            fullName: 'Phạm Minh Nguyệt',
            email: 'nguyet.pham@edulms.vn',
            status: 'ACTIVE',
            isFirstLogin: false,
            roles: ['teacher'],
            permissions: [],
          ),
        );

        final authBloc = AuthBloc(authRepository: fakeAuthRepo);
        addTearDown(authBloc.close);

        String? currentRoute;
        final router = GoRouter(
          initialLocation: RouteNames.firstLoginSetup,
          routes: [
            GoRoute(
              path: RouteNames.firstLoginSetup,
              builder: (_, _) => const FirstLoginScreen(),
            ),
            GoRoute(
              path: RouteNames.teacherHome,
              builder: (_, _) {
                currentRoute = RouteNames.teacherHome;
                return const Scaffold(body: Text('TEACHER_DASHBOARD_PORTAL'));
              },
            ),
            GoRoute(
              path: RouteNames.studentHome,
              builder: (_, _) {
                currentRoute = RouteNames.studentHome;
                return const Scaffold(body: Text('STUDENT_DASHBOARD_PORTAL'));
              },
            ),
            GoRoute(
              path: RouteNames.adminHome,
              builder: (_, _) {
                currentRoute = RouteNames.adminHome;
                return const Scaffold(body: Text('ADMIN_DASHBOARD_PORTAL'));
              },
            ),
          ],
        );

        authBloc.emit(
          const AuthenticatedState(
            user: initialTeacher,
            requiresPasswordChange: true,
          ),
        );

        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        final passwordFields = find.byType(TextFormField);
        expect(passwordFields, findsNWidgets(2));
        await tester.enterText(passwordFields.at(0), 'NewTeacher@2026');
        await tester.enterText(passwordFields.at(1), 'NewTeacher@2026');

        await tester.tap(find.text('Hoàn tất & Vào hệ thống'));
        await tester.pumpAndSettle();

        expect(currentRoute, equals(RouteNames.teacherHome));
        expect(find.text('TEACHER_DASHBOARD_PORTAL'), findsOneWidget);
        expect(find.text('STUDENT_DASHBOARD_PORTAL'), findsNothing);
      },
    );

    test(
      'Khi response firstLoginSetup không kèm roles, AuthBloc tự động bảo toàn role từ trạng thái trước hoặc gọi getMe()',
      () async {
        final fakeAuthRepo = _FakeAuthRepository();
        fakeAuthRepo.firstLoginResponse = const LoginResponseModel(
          message: 'OK',
          accessToken: 'token-1',
          refreshToken: 'refresh-1',
          requiresPasswordChange: false,
          user: UserModel(
            id: 'teacher-nguyet-id',
            userCode: 'GV-2026-0009',
            fullName: 'Phạm Minh Nguyệt',
            status: 'ACTIVE',
            isFirstLogin: false,
            roles: [], // Giả lập payload thiếu roles
            permissions: [],
          ),
        );
        fakeAuthRepo.meUser = const UserModel(
          id: 'teacher-nguyet-id',
          userCode: 'GV-2026-0009',
          fullName: 'Phạm Minh Nguyệt',
          status: 'ACTIVE',
          isFirstLogin: false,
          roles: ['teacher'],
          permissions: [],
        );

        final authBloc = AuthBloc(authRepository: fakeAuthRepo);
        addTearDown(authBloc.close);

        authBloc.add(
          const FirstLoginSetupSubmittedEvent(
            newPassword: 'Password@123',
            confirmPassword: 'Password@123',
          ),
        );

        await expectLater(
          authBloc.stream,
          emitsThrough(
            isA<AuthenticatedState>()
                .having((s) => s.user.isTeacher, 'isTeacher', isTrue)
                .having(
                  (s) => s.user.dashboardRoute,
                  'dashboardRoute',
                  equals(RouteNames.teacherHome),
                ),
          ),
        );
      },
    );

    test(
      'UserEntity.dashboardRoute trả về đúng route cho từng role và trả về null (không fallback studentHome) khi role rỗng/không xác định',
      () {
        UserModel buildUser(List<String> roles) => UserModel(
              id: 'u1',
              userCode: 'CODE-1',
              fullName: 'Test User',
              status: 'ACTIVE',
              isFirstLogin: false,
              roles: roles,
              permissions: const [],
            );

        expect(
          buildUser(['teacher']).dashboardRoute,
          equals(RouteNames.teacherHome),
        );
        expect(
          buildUser(['student']).dashboardRoute,
          equals(RouteNames.studentHome),
        );
        expect(
          buildUser(['super_admin']).dashboardRoute,
          equals(RouteNames.adminHome),
        );
        expect(
          buildUser(['branch_admin']).dashboardRoute,
          equals(RouteNames.adminHome),
        );
        expect(
          buildUser(['academic_staff']).dashboardRoute,
          equals(RouteNames.adminHome),
        );
        expect(
          buildUser(['parent']).dashboardRoute,
          equals(RouteNames.parentHome),
        );
        expect(buildUser(const []).dashboardRoute, isNull);
        expect(buildUser(const ['unknown_role']).dashboardRoute, isNull);
      },
    );
  });

  group('Test B – New Teacher Sync & ClassCreateScreen Selector', () {
    testWidgets(
      'Giảng viên mới tạo (Phạm Minh Nguyệt) xuất hiện trong dropdown Giáo viên phụ trách chính khi mở lớp mới mà không bị gán chuyên môn giả',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final classesRepo = _FakeClassesRepository();
        final classesBloc = ClassesBloc(repository: classesRepo);
        addTearDown(classesBloc.close);

        Future<dynamic> catalogFetch(
          String path, {
          Map<String, dynamic>? queryParameters,
        }) async {
          if (path == '/courses') {
            return {
              'items': [
                {
                  'id': 'course-ielts',
                  'title': 'Luyện thi IELTS Academic',
                  'code': 'IELTS',
                  'publicationStatus': 'PUBLISHED',
                  'isActive': true,
                },
              ],
              'totalPages': 1,
            };
          }
          if (path == '/branches') {
            return [
              {'id': 'branch-q1', 'name': 'Cơ sở Quận 1', 'code': 'CS-Q1'},
            ];
          }
          if (path == '/branches/branch-q1/rooms') {
            return [
              {'id': 'room-101', 'name': 'Phòng 101', 'code': 'P101'},
            ];
          }
          if (path == '/users/teachers/lookup') {
            return [
              {
                'id': 'teacher-user-nguyet-id',
                'userCode': 'GV-2026-0009',
                'fullName': 'Phạm Minh Nguyệt',
                'branchId': null, // Giảng viên liên cơ sở / vừa tạo
                'specialties': null,
              },
              {
                'id': 'teacher-user-old-id',
                'userCode': 'GV-2026-0001',
                'fullName': 'Đỗ Minh Quân',
                'branchId': 'branch-q1',
                'specialties': 'IELTS Speaking',
              },
            ];
          }
          return <dynamic>[];
        }

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<ClassesBloc>.value(
              value: classesBloc,
              child: ClassCreateScreen(catalogFetch: catalogFetch),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Chọn chi nhánh Cơ sở Quận 1
        final branchField = find.text('Chi nhánh *');
        await tester.scrollUntilVisible(
          branchField,
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tapAt(tester.getCenter(branchField));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cơ sở Quận 1 (CS-Q1)').last);
        await tester.pumpAndSettle();

        // Mở dropdown Giáo viên phụ trách chính
        final teacherField = find.text('Giáo viên phụ trách chính');
        await tester.scrollUntilVisible(
          teacherField,
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tapAt(tester.getCenter(teacherField));
        await tester.pumpAndSettle();

        // Kiểm tra giảng viên mới Phạm Minh Nguyệt xuất hiện và không bị gắn chuyên môn giả
        expect(find.text('Phạm Minh Nguyệt (GV-2026-0009)'), findsWidgets);
        expect(
          find.text('Đỗ Minh Quân (GV-2026-0001) • IELTS Speaking'),
          findsWidgets,
        );

        await tester.tap(find.text('Phạm Minh Nguyệt (GV-2026-0009)').last);
        await tester.pumpAndSettle();

        expect(find.text('Phạm Minh Nguyệt (GV-2026-0009)'), findsWidgets);
      },
    );
  });

  group('Test C & D – Profile Real Statistics & Adaptive Viewports', () {
    testWidgets(
      'Giảng viên mới chưa có lớp hiển thị đúng 0 lớp, 0 HV và không gọi /users hay hiển thị số giả 5 TK, 1 cơ sở, 2 lớp',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const newTeacher = UserModel(
          id: 'teacher-nguyet-id',
          userCode: 'GV-2026-0009',
          fullName: 'Phạm Minh Nguyệt',
          email: 'nguyet.pham@edulms.vn',
          phone: '0909123456',
          status: 'ACTIVE',
          isFirstLogin: false,
          roles: ['teacher'],
          permissions: [],
          linkedStats: {
            'activeClassesCount': 0,
            'totalClassesCount': 0,
            'totalStudentsCount': 0,
          },
        );

        final profileBloc = ProfileBloc(
          repository: _FakeProfileRepository(newTeacher),
        );
        final authBloc = AuthBloc(authRepository: _FakeAuthRepository());
        addTearDown(profileBloc.close);
        addTearDown(authBloc.close);

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<ProfileBloc>.value(value: profileBloc),
              BlocProvider<AuthBloc>.value(value: authBloc),
            ],
            child: const MaterialApp(home: ProfileScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Không hiển thị thống kê giả của toàn hệ thống
        expect(find.text('5 TK'), findsNothing);
        expect(find.text('Tổng người dùng'), findsNothing);
        expect(
          fakeApiClient.requestedPaths.contains('/users'),
          isFalse,
        );

        // Hiển thị đúng thống kê thực tế của giảng viên mới
        expect(find.text('Lớp đang phụ trách'), findsOneWidget);
        expect(find.text('Tổng lớp giảng dạy'), findsOneWidget);
        expect(find.text('Học viên phụ trách'), findsOneWidget);
        expect(find.text('0 HV'), findsOneWidget);
        expect(
          find.textContaining('Phụ trách 0 lớp học (Chưa phân công lớp)'),
          findsOneWidget,
        );
      },
    );

    for (final width in [320.0, 375.0, 393.0, 430.0, 800.0, 1200.0]) {
      testWidgets(
        'ProfileScreen hiển thị ổn định không lỗi overflow ở kích thước $width px',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          const teacherWithClasses = UserModel(
            id: 'teacher-1',
            userCode: 'GV-2026-0001',
            fullName: 'Phạm Minh Nguyệt',
            email: 'nguyet.pham@edulms.vn',
            phone: '0909123456',
            branchId: 'branch-q1',
            branchName: 'Cơ sở Quận 1',
            status: 'ACTIVE',
            isFirstLogin: false,
            roles: ['teacher'],
            permissions: [],
            linkedStats: {
              'activeClassesCount': 2,
              'totalClassesCount': 3,
              'totalStudentsCount': 38,
            },
          );

          final profileBloc = ProfileBloc(
            repository: _FakeProfileRepository(teacherWithClasses),
          );
          final authBloc = AuthBloc(authRepository: _FakeAuthRepository());
          addTearDown(profileBloc.close);
          addTearDown(authBloc.close);

          await tester.pumpWidget(
            MultiBlocProvider(
              providers: [
                BlocProvider<ProfileBloc>.value(value: profileBloc),
                BlocProvider<AuthBloc>.value(value: authBloc),
              ],
              child: const MaterialApp(home: ProfileScreen()),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
