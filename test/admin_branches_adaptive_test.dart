import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/di/injection.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/network/api_client.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/dashboard/presentation/views/branches_rooms_view.dart';

class _ApiClient extends Fake implements ApiClient {
  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (path == '/branches') {
      return {
        'data': [
          {'id': 'branch-1', 'name': 'Quận 1', 'code': 'CN1', 'isActive': true},
        ],
      };
    }
    if (path == '/classes') return {'data': <dynamic>[]};
    if (path == '/branches/branch-1/rooms') {
      return {
        'data': [
          {
            'id': 'room-1',
            'name': 'Phòng Smart 101',
            'code': 'S101',
            'capacity': 20,
            'isActive': true,
          },
        ],
      };
    }
    throw StateError('Unexpected GET $path');
  }
}

void main() {
  setUpAll(() => getIt.registerSingleton<ApiClient>(_ApiClient()));
  tearDownAll(() => getIt.unregister<ApiClient>());
  for (final width in [320.0, 375.0, 393.0, 430.0, 800.0, 1200.0]) {
    testWidgets('chi nhánh và phòng ở $width px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: BranchesRoomsView()));
      await tester.pumpAndSettle();
      expect(find.textContaining('Phòng Smart 101'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  for (final tab in [
    'Danh sách chi nhánh',
    'Quản lý trang thiết bị',
    'Lịch bảo trì & Kiểm tra',
  ]) {
    testWidgets('$tab không tràn ở 320 px', (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: BranchesRoomsView()));
      await tester.pumpAndSettle();
      final tabFinder = find.textContaining(tab).first;
      await tester.ensureVisible(tabFinder);
      await tester.tap(tabFinder);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
