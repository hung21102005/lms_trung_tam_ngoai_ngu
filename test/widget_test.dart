import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/domain/repositories/auth_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/domain/entities/user_entity.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/data/models/login_response_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/presentation/screens/login_screen.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Future<LoginResponseModel> login(String identifier, String password) async {
    throw UnimplementedError();
  }

  @override
  Future<UserEntity> getMe() async {
    throw UnimplementedError();
  }

  @override
  Future<UserEntity?> getSavedUser() async => null;

  @override
  Future<bool> isLoggedIn() async => false;

  @override
  Future<void> logout() async {}

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {}

  @override
  Future<LoginResponseModel> firstLoginSetup(String newPassword, String confirmPassword) async {
    throw UnimplementedError();
  }

  @override
  Future<void> forgotPassword(String email) async {}

  @override
  Future<void> resetPassword(String email, String otp, String newPassword) async {}
}

void main() {
  late AuthBloc authBloc;

  setUp(() {
    authBloc = AuthBloc(authRepository: FakeAuthRepository());
  });

  tearDown(() {
    authBloc.close();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: const LoginScreen(),
      ),
    );
  }

  testWidgets('LoginScreen renders header, text fields, and login button', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Header checks
    expect(find.text('Đăng Nhập LMS'), findsOneWidget);
    expect(find.text('Tài khoản đăng nhập'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(find.text('Quên mật khẩu?'), findsOneWidget);
  });

  testWidgets('LoginForm shows validation error when submitted empty', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Nhấp nút Đăng nhập khi chưa điền thông tin
    await tester.tap(find.text('Đăng nhập'));
    await tester.pump();

    // Kiểm tra thông báo lỗi validation hiển thị
    expect(find.text('Vui lòng nhập email, số điện thoại hoặc mã người dùng'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
  });
}
