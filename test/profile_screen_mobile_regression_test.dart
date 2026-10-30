import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/di/injection.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/network/api_client.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/router/route_names.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/domain/entities/user_entity.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/profile/domain/repositories/profile_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/profile/presentation/screens/profile_screen.dart';

const _user = UserEntity(
  id: 'student-1',
  userCode: 'HV-01',
  fullName: 'Nguyễn Minh Anh',
  status: 'ACTIVE',
  isFirstLogin: false,
  roles: ['student'],
  permissions: [],
);

class _Api extends Fake implements ApiClient {
  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    dynamic options,
  }) async => <String, dynamic>{'items': []};
}

class _Repository extends Fake implements ProfileRepository {
  @override
  Future<UserEntity> getMyProfile() async => _user;
}

void main() {
  setUp(() => getIt.registerSingleton<ApiClient>(_Api()));
  tearDown(() async => getIt.reset());

  for (final width in [320.0, 375.0, 393.0, 430.0, 800.0, 1200.0, 1440.0]) {
    testWidgets('Profile preserves its adaptive view at $width px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const ProfileScreen()),
          GoRoute(
            path: RouteNames.editProfile,
            builder: (_, _) => const Scaffold(body: Text('Edit profile route')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        BlocProvider(
          create: (_) => ProfileBloc(repository: _Repository()),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      if (width <= 900) {
        expect(find.text('Hồ sơ & Định danh'), findsOneWidget);
        expect(find.byTooltip('Chỉnh sửa hồ sơ'), findsOneWidget);
      } else {
        expect(find.text('Hồ sơ Cá nhân & Bảo mật Tài khoản'), findsOneWidget);
        expect(find.text('+ Lưu thông tin hồ sơ'), findsOneWidget);
      }
      expect(tester.takeException(), isNull, reason: 'width $width');

      if (width == 393) {
        await tester.tap(find.byTooltip('Chỉnh sửa hồ sơ'));
        await tester.pumpAndSettle();
        expect(find.text('Edit profile route'), findsOneWidget);
      }
    });
  }
}
