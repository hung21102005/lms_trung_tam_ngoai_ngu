import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/di/injection.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/network/api_client.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/dashboard/presentation/views/users_management_view.dart';

class _ApiClient extends Fake implements ApiClient {
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
      return {
        'data': {
          'items': [
            {
              'id': 'user-1',
              'userCode': 'HV-001',
              'fullName': 'Nguyễn Minh Anh',
              'email': 'minhanh@example.com',
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
}

void main() {
  setUpAll(() => getIt.registerSingleton<ApiClient>(_ApiClient()));
  tearDownAll(() => getIt.unregister<ApiClient>());
  for (final width in [320.0, 375.0, 393.0, 430.0, 800.0, 1200.0]) {
    testWidgets('quản lý người dùng ở $width px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: UsersManagementView()));
      await tester.pumpAndSettle();
      expect(find.text('Nguyễn Minh Anh'), findsWidgets);
      if (width == 320) {
        await tester.enterText(find.byType(TextField).first, 'không có');
        await tester.pumpAndSettle();
        expect(find.text('Nguyễn Minh Anh'), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
