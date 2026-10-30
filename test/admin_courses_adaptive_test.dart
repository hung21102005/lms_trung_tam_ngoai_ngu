import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/data/models/course_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/network/api_client.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/data/repositories/program_catalog_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/domain/repositories/courses_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/presentation/bloc/courses_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/presentation/screens/course_list_screen.dart';

class _CoursesRepository extends Fake implements CoursesRepository {
  _CoursesRepository({this.empty = false, this.fail = false, this.waitFor});

  final bool empty;
  final bool fail;
  final Completer<void>? waitFor;
  String? createdCode;
  String? createdTitle;

  @override
  Future<CourseModel> createCourse({
    required String code,
    required String title,
    String? description,
    String? targetAudience,
    String language = 'English',
    String? thumbnailUrl,
  }) async {
    createdCode = code;
    createdTitle = title;
    return CourseModel(id: 'new-course', code: code, title: title);
  }

  @override
  Future<List<CourseModel>> getCourses({
    String? search,
    String? language,
    bool? isActive,
    int page = 1,
    int limit = 50,
  }) async {
    if (waitFor != null) await waitFor!.future;
    if (fail) throw StateError('Lỗi tải khóa học');
    if (empty) return [];
    return const [
      CourseModel(
        id: 'course-1',
        code: 'IELTS-F',
        title: 'IELTS Foundation',
        description: 'Luyện nền tảng tiếng Anh',
        levelsCount: 2,
        classesCount: 3,
      ),
      CourseModel(
        id: 'course-2',
        code: 'COMM-A1',
        title: 'Giao tiếp A1',
        isActive: false,
      ),
    ];
  }
}

class _CatalogApi extends Fake implements ApiClient {
  Map<String, dynamic>? saved;
  String? savedPath;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    dynamic options,
  }) async {
    if (path == '/programs') {
      return [
        {'id': 'program-1', 'nameVi': 'Tiếng Anh tổng quát', 'status': 'DRAFT'},
      ];
    }
    if (path == '/courses/course-1') {
      return {
        'id': 'course-1',
        'code': 'IELTS-F',
        'title': 'IELTS Foundation',
        'programId': 'program-1',
        'publicationStatus': 'DRAFT',
        'slug': 'ielts-foundation',
        'language': 'English',
      };
    }
    throw StateError(path);
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    dynamic options,
  }) async {
    savedPath = path;
    saved = Map<String, dynamic>.from(data as Map);
    return {'id': 'new-course'};
  }

  @override
  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    dynamic options,
  }) async {
    savedPath = path;
    saved = Map<String, dynamic>.from(data as Map);
    return {};
  }
}

Widget _app(
  _CoursesRepository repository, {
  ProgramCatalogRepository? catalogRepository,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => BlocProvider(
          create: (_) => CoursesBloc(repository: repository),
          child: CourseListScreen(
            showAppBar: false,
            catalogRepository: catalogRepository,
          ),
        ),
      ),
      GoRoute(
        path: '/courses/:id',
        builder: (context, state) =>
            Scaffold(body: Text('Chi tiết ${state.pathParameters['id']}')),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  for (final width in [320.0, 375.0, 393.0, 430.0, 800.0, 1200.0]) {
    testWidgets('danh sách khóa học ở $width px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app(_CoursesRepository()));
      await tester.pumpAndSettle();
      expect(find.text('IELTS Foundation'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Mobile tìm kiếm với bàn phím và lọc trạng thái', (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(_app(_CoursesRepository()));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -350));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'COMM');
    await tester.pumpAndSettle();
    expect(find.text('Giao tiếp A1'), findsOneWidget);
    await tester.ensureVisible(find.text('Đang hoạt động'));
    await tester.tap(find.text('Đang hoạt động'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Không có khóa học phù hợp').first,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Không có khóa học phù hợp'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile hiển thị loading', (tester) async {
    tester.view.physicalSize = const Size(375, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final gate = Completer<void>();
    await tester.pumpWidget(_app(_CoursesRepository(waitFor: gate)));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('IELTS Foundation'), findsOneWidget);
  });

  testWidgets('Mobile hiển thị empty và API error', (tester) async {
    tester.view.physicalSize = const Size(393, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(_CoursesRepository(empty: true)));
    await tester.pumpAndSettle();
    expect(find.text('Không có khóa học phù hợp'), findsOneWidget);
    await tester.pumpWidget(_app(_CoursesRepository(fail: true)));
    await tester.pumpAndSettle();
    expect(find.text('Thử lại'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile mở chi tiết khóa học theo ID', (tester) async {
    tester.view.physicalSize = const Size(430, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(_CoursesRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('IELTS Foundation').first);
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết course-1'), findsOneWidget);
  });

  testWidgets('Mobile tạo khóa học với chương trình qua API', (tester) async {
    tester.view.physicalSize = const Size(375, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _CoursesRepository();
    final api = _CatalogApi();
    await tester.pumpWidget(
      _app(repository, catalogRepository: ProgramCatalogRepository(api)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạo khóa học mới'));
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng chọn chương trình đào tạo'), findsNothing);
    await tester.tap(find.text('Chương trình đào tạo').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếng Anh tổng quát').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mã khóa học'),
      'CRS-A1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tên khóa học'),
      'Giao tiếp A1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Đường dẫn công khai'),
      'giao-tiep-a1',
    );
    await tester.ensureVisible(find.text('Lưu khóa học'));
    await tester.tap(find.text('Lưu khóa học'));
    await tester.pumpAndSettle();
    expect(api.savedPath, '/courses');
    expect(api.saved?['programId'], 'program-1');
    expect(api.saved?['code'], 'CRS-A1');
    expect(api.saved?['title'], 'Giao tiếp A1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile sửa khóa trực tiếp từ danh sách với đầy đủ trường', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _CatalogApi();
    await tester.pumpWidget(
      _app(
        _CoursesRepository(),
        catalogRepository: ProgramCatalogRepository(api),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Chỉnh sửa').first,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Chỉnh sửa').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Đối tượng học'),
      'Người bắt đầu',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'URL ảnh đại diện'),
      'https://example.com/course.png',
    );
    await tester.ensureVisible(find.text('Lưu khóa học'));
    await tester.tap(find.text('Lưu khóa học'));
    await tester.pumpAndSettle();
    expect(api.savedPath, '/courses/course-1');
    expect(api.saved?['targetAudience'], 'Người bắt đầu');
    expect(api.saved?['thumbnailUrl'], 'https://example.com/course.png');
    expect(api.saved?['curriculumVersion'], '1.0');
    expect(tester.takeException(), isNull);
  });
}
