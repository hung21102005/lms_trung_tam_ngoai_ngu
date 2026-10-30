import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/di/injection.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/network/api_client.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/network/api_exception.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/domain/entities/user_entity.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/domain/repositories/auth_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/data/models/login_response_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/presentation/bloc/auth_state.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/dashboard/presentation/views/users_management_view.dart';

class _FakeAuthRepo implements AuthRepository {
  @override
  Future<LoginResponseModel> login(String identifier, String password) =>
      throw UnimplementedError();
  @override
  Future<UserEntity> getMe() => throw UnimplementedError();
  @override
  Future<UserEntity?> getSavedUser() async => null;
  @override
  Future<bool> isLoggedIn() async => true;
  @override
  Future<void> logout() async {}
  @override
  Future<void> changePassword(String o, String n) async {}
  @override
  Future<LoginResponseModel> firstLoginSetup(String p, String c) =>
      throw UnimplementedError();
  @override
  Future<void> forgotPassword(String e) async {}
  @override
  Future<void> resetPassword(String e, String o, String n) async {}
}

class _MockDeleteApiClient extends Fake implements ApiClient {
  bool deleteCalled = false;
  String? deletedPath;
  Duration delay = Duration.zero;
  Exception? errorToThrow;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (path == '/branches') {
      return {'data': <dynamic>[]};
    }
    if (path == '/users') {
      if (deleteCalled) {
        return {
          'data': {
            'items': <dynamic>[],
            'totalPages': 0,
          },
        };
      }
      return {
        'data': {
          'items': [
            {
              'id': 'test-user-id',
              'userCode': 'TEST-USER-001',
              'fullName': 'Tài Khoản Thử Nghiệm',
              'email': 'test@edulms.vn',
              'phone': '0901234567',
              'status': 'ACTIVE',
              'roles': [
                {'code': 'student', 'name': 'Học viên'},
              ],
            },
          ],
          'totalPages': 1,
        },
      };
    }
    throw StateError('Unexpected GET $path');
  }

  @override
  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    deleteCalled = true;
    deletedPath = path;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return {'success': true, 'message': 'Đã xóa người dùng thành công.'};
  }
}

void main() {
  late _MockDeleteApiClient apiClient;
  late AuthBloc authBloc;

  setUp(() {
    apiClient = _MockDeleteApiClient();
    if (getIt.isRegistered<ApiClient>()) {
      getIt.unregister<ApiClient>();
    }
    getIt.registerSingleton<ApiClient>(apiClient);

    authBloc = AuthBloc(authRepository: _FakeAuthRepo());
    authBloc.emit(
      const AuthenticatedState(
        user: UserEntity(
          id: 'admin-actor-id',
          userCode: 'ADMIN-001',
          fullName: 'Super Administrator',
          email: 'admin@edulms.vn',
          status: 'ACTIVE',
          isFirstLogin: false,
          roles: ['super_admin'],
          permissions: ['*'],
        ),
      ),
    );
  });

  tearDown(() {
    if (getIt.isRegistered<ApiClient>()) {
      getIt.unregister<ApiClient>();
    }
    authBloc.close();
  });

  Widget buildTestApp() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: const UsersManagementView(),
      ),
    );
  }

  testWidgets(
    'Xóa người dùng thành công: hiển thị loading in-dialog, xóa sạch không lỗi disposed controller, cập nhật danh sách',
    (tester) async {
      apiClient.delay = const Duration(milliseconds: 100);

      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Tài Khoản Thử Nghiệm'), findsOneWidget);

      // Nhấn nút xóa ở table desktop (IconButton với tooltip 'Xóa tài khoản')
      final deleteBtn = find.byTooltip('Xóa tài khoản');
      expect(deleteBtn, findsOneWidget);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Kiểm tra dialog xác nhận xóa hiện ra
      expect(find.text('Xác nhận xóa tài khoản'), findsOneWidget);
      expect(
        find.textContaining('TEST-USER-001'),
        findsWidgets,
      );

      // Thử submit khi chưa nhập mã định danh
      final confirmDeleteBtn =
          find.widgetWithText(FilledButton, 'Xác nhận xóa vĩnh viễn');
      expect(confirmDeleteBtn, findsOneWidget);
      await tester.tap(confirmDeleteBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Vui lòng nhập chính xác mã: TEST-USER-001'),
        findsOneWidget,
      );
      expect(apiClient.deleteCalled, isFalse);

      // Nhập đúng mã định danh
      await tester.enterText(find.byType(TextFormField), 'TEST-USER-001');
      await tester.pumpAndSettle();

      // Nhấn xác nhận xóa
      await tester.tap(confirmDeleteBtn);
      // Pump frame để hiển thị in-dialog loading state
      await tester.pump(const Duration(milliseconds: 20));

      expect(find.text('Đang xóa...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Chờ hoàn thành API call (100ms)
      await tester.pump(const Duration(milliseconds: 120));
      // Chờ route pop hoàn tất
      await tester.pump(const Duration(milliseconds: 300));
      // Pump frame cho SnackBar và cập nhật danh sách
      await tester.pump();

      // Xác nhận API DELETE đã được gọi chính xác
      expect(apiClient.deleteCalled, isTrue);
      expect(apiClient.deletedPath, '/users/test-user-id');

      // Xác nhận dialog đã đóng và KHÔNG ném ngoại lệ disposed controller
      expect(find.text('Xác nhận xóa tài khoản'), findsNothing);
      expect(tester.takeException(), isNull);

      // Xác nhận SnackBar thành công hiển thị
      expect(
        find.textContaining('Đã xóa vĩnh viễn tài khoản Tài Khoản Thử Nghiệm'),
        findsOneWidget,
      );

      // Xác nhận danh sách đã được refresh và tài khoản không còn
      expect(find.text('Tài Khoản Thử Nghiệm'), findsNothing);

      // Xả hết các animation/timer còn lại
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Xóa người dùng có lịch sử học vụ: hiển thị cảnh báo nghiệp vụ và đề xuất khóa tài khoản',
    (tester) async {
      apiClient.errorToThrow = const ApiException(
        message:
            'Tài khoản đã có lịch sử vận hành (lớp học, điểm danh). Vui lòng chọn VÔ HIỆU HÓA để bảo toàn lịch sử.',
      );

      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final deleteBtn = find.byTooltip('Xóa tài khoản');
      expect(deleteBtn, findsOneWidget);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'TEST-USER-001');
      await tester.pumpAndSettle();

      final confirmDeleteBtn =
          find.widgetWithText(FilledButton, 'Xác nhận xóa vĩnh viễn');
      await tester.tap(confirmDeleteBtn);
      await tester.pumpAndSettle();

      // Phải hiển thị modal thông báo không thể xóa do có dữ liệu
      expect(find.text('Không thể xóa do có dữ liệu'), findsOneWidget);
      expect(
        find.textContaining('Tài khoản đã có lịch sử vận hành'),
        findsOneWidget,
      );
      expect(find.text('Khóa tài khoản ngay'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Xóa người dùng gặp lỗi mạng/chung: hiển thị lỗi inline trong dialog, không sập ứng dụng',
    (tester) async {
      apiClient.errorToThrow = const ApiException(
        message: 'Lỗi kết nối máy chủ (500 Internal Server Error)',
      );

      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final deleteBtn = find.byTooltip('Xóa tài khoản');
      expect(deleteBtn, findsOneWidget);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'TEST-USER-001');
      await tester.pumpAndSettle();

      final confirmDeleteBtn =
          find.widgetWithText(FilledButton, 'Xác nhận xóa vĩnh viễn');
      await tester.tap(confirmDeleteBtn);
      await tester.pumpAndSettle();

      // Dialog vẫn mở, hiển thị lỗi inline
      expect(find.text('Xác nhận xóa tài khoản'), findsOneWidget);
      expect(
        find.text('Lỗi kết nối máy chủ (500 Internal Server Error)'),
        findsOneWidget,
      );
      // Nút xóa được khôi phục, cho phép thử lại
      expect(find.text('Xác nhận xóa vĩnh viễn'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
