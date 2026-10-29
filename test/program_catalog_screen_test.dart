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
  final course = <String, dynamic>{
    'id': 'course-1',
    'code': 'GEN-A1',
    'title': 'General A1',
    'slug': 'general-a1',
    'description': 'Nội dung nội bộ',
    'publicDescription': 'Nội dung công khai',
    'programId': 'program-1',
    'publicationStatus': 'DRAFT',
    'isActive': false,
  };
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
        'courses': [course],
      };
    }
    if (path == '/courses') {
      return {
        'items': [
          {
            'id': 'course-unassigned',
            'code': 'FREE-01',
            'title': 'Khóa chưa gắn',
            'publicationStatus': 'DRAFT',
            'isActive': false,
            'programId': null,
          },
        ],
      };
    }
    if (path == '/courses/course-1/publication-check') {
      return {
        'canPublish': false,
        'canConfirmReview': true,
        'blockers': ['Cần rà soát và xác nhận nội dung học thuật hiện tại'],
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
    if (path == '/courses/course-1/publication') {
      course['publicationStatus'] = data['status'];
    }
    if (path == '/courses/course-1') {
      course.addAll(Map<String, dynamic>.from(data as Map));
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
    if (path == '/courses') return {'id': 'course-new'};
    if (path == '/courses/course-1/academic-review') return {};
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

  testWidgets('course validation shows blockers and confirms academic review', (
    tester,
  ) async {
    final api = _Api();
    api.course['publicationStatus'] = 'IN_REVIEW';
    await tester.pumpWidget(
      MaterialApp(
        home: ProgramCatalogScreen(repository: ProgramCatalogRepository(api)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếng Anh tổng quát'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Thao tác khóa học'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kiểm tra công bố'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Cần rà soát và xác nhận'), findsWidgets);
    await tester.tap(find.text('Xác nhận đã rà soát'));
    await tester.pumpAndSettle();
    expect(api.calls, contains('GET /courses/course-1/publication-check'));
    expect(api.calls, contains('POST /courses/course-1/academic-review'));
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

  testWidgets('course review action calls publication API', (tester) async {
    final api = _Api();
    await tester.pumpWidget(
      MaterialApp(
        home: ProgramCatalogScreen(repository: ProgramCatalogRepository(api)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếng Anh tổng quát'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Thao tác khóa học'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gửi duyệt khóa'));
    await tester.pumpAndSettle();
    expect(
      api.calls,
      contains('PATCH /courses/course-1/publication IN_REVIEW'),
    );
  });

  testWidgets('draft course editor updates name and code through API', (
    tester,
  ) async {
    final api = _Api();
    await tester.pumpWidget(
      MaterialApp(
        home: ProgramCatalogScreen(repository: ProgramCatalogRepository(api)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếng Anh tổng quát'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Thao tác khóa học'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sửa khóa học'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mã khóa học'),
      'GEN-A1-NEW',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tên khóa học'),
      'General A1 Updated',
    );
    await tester.ensureVisible(find.text('Lưu khóa học'));
    await tester.tap(find.text('Lưu khóa học'));
    await tester.pumpAndSettle();
    expect(
      api.calls.any((call) => call.startsWith('PATCH /courses/course-1')),
      isTrue,
    );
    expect(api.course['code'], 'GEN-A1-NEW');
    expect(api.course['title'], 'General A1 Updated');
  });

  testWidgets('branch admin sees read-only program actions', (tester) async {
    final api = _Api();
    await tester.pumpWidget(
      MaterialApp(
        home: ProgramCatalogScreen(
          repository: ProgramCatalogRepository(api),
          canManage: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Thêm chương trình'), findsNothing);
    await tester.tap(find.text('Tiếng Anh tổng quát'));
    await tester.pumpAndSettle();
    expect(find.text('Gửi duyệt'), findsNothing);
    expect(find.byTooltip('Thao tác khóa học'), findsNothing);
  });

  testWidgets('creates a draft course in selected program', (tester) async {
    final api = _Api();
    await tester.pumpWidget(
      MaterialApp(
        home: ProgramCatalogScreen(repository: ProgramCatalogRepository(api)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếng Anh tổng quát'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Tạo khóa trong chương trình'));
    await tester.tap(find.text('Tạo khóa trong chương trình'));
    await tester.pumpAndSettle();
    for (final pair in [
      ('Mã khóa học', 'GEN-A2'),
      ('Tên khóa học', 'General A2'),
      ('Đường dẫn công khai', 'general-a2'),
      ('Mô tả nội bộ', 'Nội dung A2'),
      ('Mô tả công khai', 'Học tiếng Anh A2'),
    ]) {
      await tester.enterText(
        find.widgetWithText(TextFormField, pair.$1),
        pair.$2,
      );
    }
    await tester.ensureVisible(find.text('Lưu khóa học'));
    await tester.tap(find.text('Lưu khóa học'));
    await tester.pumpAndSettle();
    expect(api.calls, contains('POST /courses'));
  });

  testWidgets('suggests existing unassigned course for attachment', (
    tester,
  ) async {
    final api = _Api();
    await tester.pumpWidget(
      MaterialApp(
        home: ProgramCatalogScreen(repository: ProgramCatalogRepository(api)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếng Anh tổng quát'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Gắn khóa đã có'));
    await tester.tap(find.text('Gắn khóa đã có'));
    await tester.pumpAndSettle();
    expect(find.text('Khóa chưa gắn'), findsOneWidget);
    await tester.tap(find.text('Khóa chưa gắn'));
    await tester.pumpAndSettle();
    expect(
      api.calls.any(
        (call) => call.startsWith('PATCH /courses/course-unassigned'),
      ),
      isTrue,
    );
  });
}
