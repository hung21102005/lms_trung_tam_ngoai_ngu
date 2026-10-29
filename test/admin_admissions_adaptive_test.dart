import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/di/injection.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/network/api_client.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/dashboard/presentation/views/admissions_crm_view.dart';

class _ApiClient extends Fake implements ApiClient {
  String leadStatus = 'NEW';
  bool converted = false;

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
              'status': leadStatus,
              'source': 'FACEBOOK',
            },
          ],
          'totalPages': 1,
        },
      };
    }
    if (path == '/admissions/registrations') {
      return [
        {
          'id': 'registration-1',
          'fullName': 'Nguyễn Minh Anh',
          'phone': '0901234567',
          'status': 'PENDING',
          'studentId': null,
          'lead': {'convertedUserId': converted ? 'student-1' : null},
          'class': {'name': 'English A1', 'code': 'A1-01'},
        },
      ];
    }
    throw StateError('Unexpected GET $path');
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (path == '/admissions/leads/lead-1/convert') {
      converted = true;
      leadStatus = 'ENROLLED';
      return {
        'student': {
          'userCode': 'HV-2026-0010',
          'temporaryPassword': 'temporary-test-only',
        },
      };
    }
    throw StateError('Unexpected POST $path');
  }
}

void main() {
  final api = _ApiClient();
  setUpAll(() => getIt.registerSingleton<ApiClient>(api));
  tearDownAll(() => getIt.unregister<ApiClient>());
  setUp(() {
    api.leadStatus = 'NEW';
    api.converted = false;
  });
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

  testWidgets(
    'CRM returns to registration approval after converting its Lead',
    (tester) async {
      api.leadStatus = 'TEST_SCHEDULED';
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: AdmissionsCrmView()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đơn đăng ký lớp'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tìm Lead trong CRM'));
      await tester.pumpAndSettle();
      expect(find.text('Nguyễn Minh Anh'), findsWidgets);
      await tester.ensureVisible(find.text('Chốt ghi danh'));
      await tester.tap(find.text('Chốt ghi danh'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      expect(find.text('Đã tạo tài khoản học viên'), findsOneWidget);
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      expect(find.text('Đơn đăng ký lớp'), findsWidgets);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Xác nhận nhập học'),
            )
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
