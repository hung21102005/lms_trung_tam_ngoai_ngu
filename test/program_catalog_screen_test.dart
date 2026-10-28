import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/network/api_client.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/data/repositories/program_catalog_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/presentation/screens/program_catalog_screen.dart';

class _Api extends Fake implements ApiClient {
  final List<Map<String, dynamic>> programs = [
    {
      'id': 'program-1',
      'code': 'PRG-GEN',
      'slug': 'general-english',
      'nameVi': 'Tiếng Anh tổng quát',
      'nameEn': 'General English',
      'category': 'GENERAL',
      'description': 'Lộ trình từ cơ bản',
      'targetAudience': 'Người học',
      'status': 'DRAFT',
      'isPublic': false,
      '_count': {'courses': 1},
    },
  ];
  final calls = <String>[];

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    calls.add('GET $path');
    if (path == '/programs') return programs;
    if (path == '/programs/program-1') {
      return {
        ...programs.first,
        'courses': [
          {
            'id': 'course-1',
            'code': 'GEN-A1',
            'title': 'General A1',
            'publicationStatus': 'DRAFT',
            'isActive': false,
          },
        ],
      };
    }
    throw StateError(path);
  }

  @override
  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    calls.add('PATCH $path ${data['status'] ?? ''}');
    if (path == '/programs/program-1/status') {
      programs.first['status'] = data['status'];
    }
    return {};
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    calls.add('POST $path');
    programs.add({
      'id': 'program-2',
      ...Map<String, dynamic>.from(data as Map),
      'status': 'DRAFT',
      'isPublic': false,
      '_count': {'courses': 0},
    });
    return programs.last;
  }
}

void main() {
  for (final width in <double>[320, 375, 393, 430, 800, 1200]) {
    testWidgets('program catalog renders at $width px', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = _Api();
      await tester.pumpWidget(
        MaterialApp(
          home: ProgramCatalogScreen(repository: ProgramCatalogRepository(api)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tiếng Anh tổng quát'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('details submits review transition through API', (tester) async {
    final api = _Api();
    await tester.pumpWidget(
      MaterialApp(
        home: ProgramCatalogScreen(repository: ProgramCatalogRepository(api)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếng Anh tổng quát'));
    await tester.pumpAndSettle();
    expect(find.text('General A1'), findsOneWidget);
    await tester.tap(find.text('Gửi duyệt'));
    await tester.pumpAndSettle();
    expect(api.calls, contains('PATCH /programs/program-1/status IN_REVIEW'));
  });

  testWidgets('create form sends real API request', (tester) async {
    final api = _Api();
    await tester.pumpWidget(
      MaterialApp(
        home: ProgramCatalogScreen(repository: ProgramCatalogRepository(api)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm chương trình'));
    await tester.pumpAndSettle();
    for (final pair in [
      ('Mã chương trình', 'PRG-NEW'),
      ('Đường dẫn công khai', 'new-program'),
      ('Tên tiếng Việt', 'Chương trình mới'),
      ('Tên tiếng Anh', 'New Program'),
      ('Danh mục', 'GENERAL'),
    ]) {
      await tester.enterText(
        find.widgetWithText(TextFormField, pair.$1),
        pair.$2,
      );
    }
    await tester.ensureVisible(find.text('Lưu chương trình'));
    await tester.tap(find.text('Lưu chương trình'));
    await tester.pumpAndSettle();
    expect(api.calls, contains('POST /programs'));
    expect(find.text('Chương trình mới'), findsOneWidget);
  });
}
