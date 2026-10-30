import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/network/api_client.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/dashboard/presentation/views/class_registrations_admin_screen.dart';

class _FakeApiClient implements ApiClient {
  String status = 'PENDING';
  bool guest = false;
  bool converted = false;
  String? lastPath;
  Map<String, dynamic>? lastBody;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    dynamic options,
  }) async => [
    {
      'id': 'request-1',
      'fullName': 'Nguyễn Văn An',
      'phone': '0988776655',
      'email': 'an@example.com',
      'status': status,
      'studentId': guest ? null : 'student-1',
      'lead': guest ? {'convertedUserId': converted ? 'student-1' : null} : null,
      'class': {'name': 'English A1 K01', 'code': 'A1-K01'},
    },
  ];

  @override
  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    dynamic options,
  }) async {
    lastPath = path;
    lastBody = Map<String, dynamic>.from(data as Map);
    status = lastBody!['status'] as String;
    return {'id': 'request-1', 'status': status};
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    dynamic options,
  }) async {
    lastPath = path;
    status = 'APPROVED';
    return {'id': 'request-1', 'status': status};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'registration queue adapts to mobile and desktop, review calls API',
    (tester) async {
      for (final width in [320.0, 375.0, 393.0, 430.0, 800.0, 1200.0]) {
        final api = _FakeApiClient();
        await tester.binding.setSurfaceSize(Size(width, 800));
        await tester.pumpWidget(
          MaterialApp(
            home: ClassRegistrationsAdminScreen(
              key: ValueKey(width),
              apiClient: api,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Nguyễn Văn An'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'width $width');
        await tester.tap(find.widgetWithText(OutlinedButton, 'Đã liên hệ'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Xác nhận'));
        await tester.pumpAndSettle();
        expect(api.lastPath, '/admissions/registrations/request-1/review');
        expect(api.lastBody, {'status': 'CONTACTED'});
        expect(find.text('Đã liên hệ'), findsWidgets);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('guest request requires a converted student before approval', (
    tester,
  ) async {
    final api = _FakeApiClient()..guest = true;
    await tester.pumpWidget(
      MaterialApp(home: ClassRegistrationsAdminScreen(apiClient: api)),
    );
    await tester.pumpAndSettle();
    FilledButton approve() =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Xác nhận nhập học'));
    expect(approve().onPressed, isNull);
    expect(find.text('Tìm Lead trong CRM'), findsOneWidget);
    api.converted = true;
    await tester.tap(find.byTooltip('Làm mới'));
    await tester.pumpAndSettle();
    expect(approve().onPressed, isNotNull);
  });
}
