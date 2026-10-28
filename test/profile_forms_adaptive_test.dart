import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/domain/entities/user_entity.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/profile/domain/repositories/profile_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/profile/presentation/bloc/profile_event.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/profile/presentation/screens/change_password_screen.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/profile/presentation/screens/edit_profile_screen.dart';

const _user = UserEntity(
  id: 'user-1',
  userCode: 'HV-01',
  fullName: 'Nguyễn Minh Anh',
  status: 'ACTIVE',
  isFirstLogin: false,
  roles: ['student'],
  permissions: [],
  phone: '0901234567',
  address: 'Quận 1',
  gender: 'FEMALE',
);

class _ProfileRepository extends Fake implements ProfileRepository {
  String? savedName;
  String? savedPhone;
  String? newPassword;
  bool fail = false;

  @override
  Future<UserEntity> getMyProfile() async => _user;

  @override
  Future<UserEntity> updateProfile({
    String? fullName,
    String? phone,
    String? address,
    String? gender,
    String? dateOfBirth,
    String? avatarUrl,
  }) async {
    savedName = fullName;
    savedPhone = phone;
    if (fail) throw StateError('Không cập nhật được hồ sơ');
    return _user;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    this.newPassword = newPassword;
    if (fail) throw StateError('Không đổi được mật khẩu');
  }
}

Widget _app(_ProfileRepository repo) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: Column(
            children: [
              TextButton(
                onPressed: () => context.push('/edit'),
                child: const Text('Mở sửa hồ sơ'),
              ),
              TextButton(
                onPressed: () => context.push('/password'),
                child: const Text('Mở đổi mật khẩu'),
              ),
            ],
          ),
        ),
      ),
      GoRoute(path: '/edit', builder: (_, _) => const EditProfileScreen()),
      GoRoute(
        path: '/password',
        builder: (_, _) => const ChangePasswordScreen(),
      ),
    ],
  );
  return BlocProvider(
    lazy: false,
    create: (_) => ProfileBloc(repository: repo)..add(const LoadProfileEvent()),
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _open(
  WidgetTester tester,
  _ProfileRepository repo,
  String label,
) async {
  await tester.pumpWidget(_app(repo));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 375.0, 393.0, 430.0, 800.0, 1200.0]) {
    testWidgets('edit profile $width px', (tester) async {
      tester.view.physicalSize = Size(width, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _open(tester, _ProfileRepository(), 'Mở sửa hồ sơ');
      expect(find.text('Nguyễn Minh Anh'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('edit-profile-mobile')),
        width < 1024 ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('change password $width px', (tester) async {
      tester.view.physicalSize = Size(width, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _open(tester, _ProfileRepository(), 'Mở đổi mật khẩu');
      expect(find.text('Mật khẩu hiện tại *'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('change-password-mobile')),
        width < 1024 ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('profile save stays reachable with keyboard', (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = _ProfileRepository();
    await _open(tester, repo, 'Mở sửa hồ sơ');
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(repo.savedName, 'Nguyễn Minh Anh');
    expect(repo.savedPhone, '0901234567');
    expect(tester.takeException(), isNull);
  });

  testWidgets('password validation blocks mismatch', (tester) async {
    tester.view.physicalSize = const Size(393, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = _ProfileRepository();
    await _open(tester, repo, 'Mở đổi mật khẩu');
    await tester.enterText(find.byType(TextField).at(0), 'old123');
    await tester.enterText(find.byType(TextField).at(1), 'New123');
    await tester.enterText(find.byType(TextField).at(2), 'Mismatch');
    await tester.tap(find.text('Cập nhật mật khẩu'));
    await tester.pumpAndSettle();
    expect(find.text('Mật khẩu xác nhận không khớp'), findsOneWidget);
    expect(repo.newPassword, isNull);
  });

  testWidgets('password update sends existing Bloc payload', (tester) async {
    tester.view.physicalSize = const Size(375, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = _ProfileRepository();
    await _open(tester, repo, 'Mở đổi mật khẩu');
    await tester.enterText(find.byType(TextField).at(0), 'old123');
    await tester.enterText(find.byType(TextField).at(1), 'New123');
    await tester.enterText(find.byType(TextField).at(2), 'New123');
    tester.view.viewInsets = const FakeViewPadding(bottom: 250);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cập nhật mật khẩu'));
    await tester.pumpAndSettle();
    expect(repo.newPassword, 'New123');
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile save shows repository error without losing input',
      (tester) async {
    tester.view.physicalSize = const Size(393, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = _ProfileRepository()..fail = true;
    await _open(tester, repo, 'Mở sửa hồ sơ');
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Không cập nhật được hồ sơ'), findsWidgets);
    expect(find.byKey(const ValueKey('edit-profile-mobile')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
