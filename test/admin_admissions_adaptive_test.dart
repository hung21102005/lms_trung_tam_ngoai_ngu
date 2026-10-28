import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/di/injection.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/network/api_client.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/dashboard/presentation/views/admissions_crm_view.dart';

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
    if (path == '/admissions/leads') {
      return {
        'data': {
          'items': [
            {
              'id': 'lead-1',
              'fullName': 'Nguyễn Minh Anh',
              'phone': '0901234567',
              'targetCourse': 'IELTS Foundation',
              'status': 'NEW',
              'source': 'FACEBOOK',
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
    testWidgets('tuyển sinh ở $width px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: AdmissionsCrmView()));
      await tester.pumpAndSettle();
      expect(find.text('Nguyễn Minh Anh'), findsWidgets);
      if (width < 1024) {
        expect(find.text('Hồ sơ tuyển sinh'), findsOneWidget);
        expect(find.textContaining('Mới (1)'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Mobile lọc giai đoạn và tìm kiếm hồ sơ', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: AdmissionsCrmView()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Mới (1)'));
    await tester.tap(find.text('Mới (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Nguyễn Minh Anh'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'không tồn tại');
    await tester.pumpAndSettle();
    expect(find.text('Không có hồ sơ phù hợp'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
