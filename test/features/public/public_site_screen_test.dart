import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/network/api_client.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/router/route_names.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/public/data/public_catalog_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/public/presentation/public_site_screen.dart';

class _FakeApiClient implements ApiClient {
  final Map<String, dynamic> responses = {
    '/public/programs': <Map<String, dynamic>>[],
    '/public/courses': <Map<String, dynamic>>[],
    '/public/classes': {
      'items': <Map<String, dynamic>>[],
      'total': 0,
      'totalPages': 0,
    },
    '/my/registrations': <Map<String, dynamic>>[],
  };
  bool failLead = false;
  int leadCalls = 0;
  String? lastPostPath;
  Map<String, dynamic>? leadData;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    dynamic options,
  }) async => responses[path];

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    dynamic options,
  }) async {
    leadCalls++;
    lastPostPath = path;
    leadData = Map<String, dynamic>.from(data as Map);
    if (failLead) throw Exception('Mất kết nối');
    return {'id': 'lead-1'};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

GoRouter _router(
  PublicCatalogRepository repository,
  String initialLocation, {
  bool student = false,
}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: RouteNames.publicHome,
      builder: (_, _) =>
          PublicSiteScreen(repository: repository, page: PublicPage.home),
    ),
    GoRoute(
      path: RouteNames.publicPrograms,
      builder: (_, _) =>
          PublicSiteScreen(repository: repository, page: PublicPage.programs),
    ),
    GoRoute(
      path: RouteNames.publicCourses,
      builder: (_, state) => PublicSiteScreen(
        repository: repository,
        page: PublicPage.courses,
        programSlug: state.uri.queryParameters['chuong-trinh'],
      ),
    ),
    GoRoute(
      path: RouteNames.publicClasses,
      builder: (_, _) =>
          PublicSiteScreen(repository: repository, page: PublicPage.classes),
    ),
    GoRoute(
      path: RouteNames.publicConsultation,
      builder: (_, _) => PublicSiteScreen(
        repository: repository,
        page: PublicPage.consultation,
      ),
    ),
    GoRoute(
      path: RouteNames.publicRegistration,
      builder: (_, state) => PublicSiteScreen(
        repository: repository,
        page: PublicPage.registration,
        classId: state.pathParameters['id'],
        isStudent: student,
        studentName: student ? 'Học viên An' : null,
      ),
    ),
    GoRoute(
      path: RouteNames.myRegistrations,
      builder: (_, _) => PublicSiteScreen(
        repository: repository,
        page: PublicPage.myRegistrations,
        isStudent: true,
      ),
    ),
    GoRoute(
      path: RouteNames.login,
      builder: (_, _) => const Scaffold(body: Text('Đăng nhập')),
    ),
  ],
);

void main() {
  testWidgets('program listing and course listing use distinct destinations', (
    tester,
  ) async {
    final api = _FakeApiClient();
    api.responses['/public/programs'] = [
      {'slug': 'ielts', 'nameVi': 'IELTS Preparation'},
    ];
    api.responses['/public/courses'] = [
      {
        'slug': 'ielts-a',
        'title': 'IELTS A',
        'program': {'slug': 'ielts', 'nameVi': 'IELTS Preparation'},
        'levels': <Map<String, dynamic>>[],
      },
      {
        'slug': 'general-a',
        'title': 'General A',
        'program': {'slug': 'general', 'nameVi': 'General English'},
        'levels': <Map<String, dynamic>>[],
      },
    ];
    final router = _router(PublicCatalogRepository(api), RouteNames.publicHome);
    await tester.binding.setSurfaceSize(const Size(1200, 850));
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xem tất cả').first);
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      RouteNames.publicPrograms,
    );
    expect(find.text('IELTS Preparation'), findsWidgets);
    await tester.tap(find.text('IELTS Preparation').last);
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      RouteNames.publicCourses,
    );
    expect(find.text('IELTS A'), findsOneWidget);
    expect(find.text('General A'), findsNothing);
    expect(tester.takeException(), isNull);
    router.dispose();
  });

  testWidgets(
    'public pages keep mobile navigation and empty state across widths',
    (tester) async {
      for (final width in [320.0, 375.0, 393.0, 430.0, 800.0, 1200.0]) {
        final api = _FakeApiClient();
        final router = _router(
          PublicCatalogRepository(api),
          RouteNames.publicHome,
        );
        await tester.binding.setSurfaceSize(Size(width, 850));
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();
        expect(
          find.text('Chương trình đang được chuẩn bị công bố.'),
          findsOneWidget,
        );
        expect(
          find.byType(NavigationBar),
          width < 1000 ? findsOneWidget : findsNothing,
        );
        expect(tester.takeException(), isNull, reason: 'width $width');
        router.dispose();
      }
    },
  );

  testWidgets('course list displays only backend results', (tester) async {
    final api = _FakeApiClient();
    api.responses['/public/courses'] = [
      {
        'slug': 'english-a1',
        'title': 'English A1',
        'publicDescription': 'Chương trình tiếng Anh cơ bản',
        'program': {'nameVi': 'Tiếng Anh giao tiếp'},
        'levels': <Map<String, dynamic>>[],
      },
    ];
    final router = _router(
      PublicCatalogRepository(api),
      RouteNames.publicCourses,
    );
    await tester.binding.setSurfaceSize(const Size(375, 800));
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('English A1'), findsOneWidget);
    expect(find.textContaining('Tiếng Anh giao tiếp'), findsOneWidget);
    expect(tester.takeException(), isNull);
    router.dispose();
  });

  testWidgets('consultation validates and submits once after API success', (
    tester,
  ) async {
    final api = _FakeApiClient();
    final router = _router(
      PublicCatalogRepository(api),
      RouteNames.publicConsultation,
    );
    await tester.binding.setSurfaceSize(const Size(375, 800));
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Gửi yêu cầu tư vấn'));
    await tester.pump();
    expect(find.text('Vui lòng nhập họ tên'), findsOneWidget);
    expect(api.leadCalls, 0);
    await tester.enterText(find.byType(TextFormField).at(0), 'Nguyễn Văn An');
    await tester.enterText(find.byType(TextFormField).at(1), '0988776655');
    tester.testTextInput.hide();
    await tester.ensureVisible(find.text('Gửi yêu cầu tư vấn'));
    await tester.tap(find.text('Gửi yêu cầu tư vấn'));
    await tester.pumpAndSettle();
    expect(api.leadCalls, 1);
    expect(api.leadData?['source'], 'WEBSITE');
    expect(find.text('Đã gửi yêu cầu tư vấn'), findsOneWidget);
    expect(tester.takeException(), isNull);
    router.dispose();
  });

  testWidgets('consultation retains input on API failure', (tester) async {
    final api = _FakeApiClient()..failLead = true;
    final router = _router(
      PublicCatalogRepository(api),
      RouteNames.publicConsultation,
    );
    await tester.binding.setSurfaceSize(const Size(320, 750));
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.enterText(find.byType(TextFormField).at(0), 'Nguyễn Văn An');
    await tester.enterText(find.byType(TextFormField).at(1), '0988776655');
    tester.testTextInput.hide();
    await tester.ensureVisible(find.text('Gửi yêu cầu tư vấn'));
    await tester.tap(find.text('Gửi yêu cầu tư vấn'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Mất kết nối'), findsOneWidget);
    expect(find.text('Đã gửi yêu cầu tư vấn'), findsNothing);
    expect(find.text('Nguyễn Văn An'), findsOneWidget);
    expect(tester.takeException(), isNull);
    router.dispose();
  });

  testWidgets(
    'consultation submit stays reachable with mobile keyboard inset',
    (tester) async {
      final api = _FakeApiClient();
      final router = _router(
        PublicCatalogRepository(api),
        RouteNames.publicConsultation,
      );
      await tester.binding.setSurfaceSize(const Size(320, 700));
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(() => tester.view.resetViewInsets());
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.enterText(find.byType(TextFormField).at(0), 'Nguyễn Văn An');
      await tester.enterText(find.byType(TextFormField).at(1), '0988776655');
      await tester.ensureVisible(find.text('Gửi yêu cầu tư vấn'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Gửi yêu cầu tư vấn'));
      await tester.pumpAndSettle();
      expect(api.leadCalls, 1);
      router.dispose();
    },
  );

  testWidgets('guest registration uses the selected class', (tester) async {
    final api = _FakeApiClient();
    api.responses['/public/classes/class-1'] = {
      'id': 'class-1',
      'name': 'English A1 K01',
      'remainingSeats': 3,
      'course': {'title': 'English A1'},
      'branch': {'name': 'Quận 1'},
    };
    final router = _router(
      PublicCatalogRepository(api),
      '/dang-ky-lop/class-1',
    );
    await tester.binding.setSurfaceSize(const Size(375, 800));
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('English A1 K01'), findsOneWidget);
    await tester.ensureVisible(find.text('Gửi đăng ký lớp'));
    await tester.tap(find.text('Gửi đăng ký lớp'));
    await tester.pump();
    expect(api.leadCalls, 0);
    await tester.enterText(find.byType(TextFormField).at(0), 'Nguyễn Văn An');
    await tester.enterText(find.byType(TextFormField).at(1), '0988776655');
    tester.testTextInput.hide();
    await tester.ensureVisible(find.text('Gửi đăng ký lớp'));
    await tester.tap(find.text('Gửi đăng ký lớp'));
    await tester.pumpAndSettle();
    expect(api.lastPostPath, '/public/registrations');
    expect(api.leadData?['classId'], 'class-1');
    expect(find.text('Đã tiếp nhận đăng ký'), findsOneWidget);
    expect(tester.takeException(), isNull);
    router.dispose();
  });

  testWidgets('existing student registration sends only class and note', (
    tester,
  ) async {
    final api = _FakeApiClient();
    api.responses['/public/classes/class-1'] = {
      'id': 'class-1',
      'name': 'English A1 K01',
      'remainingSeats': 3,
      'course': {'title': 'English A1'},
      'branch': {'name': 'Quận 1'},
    };
    final router = _router(
      PublicCatalogRepository(api),
      '/dang-ky-lop/class-1',
      student: true,
    );
    await tester.binding.setSurfaceSize(const Size(320, 800));
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.textContaining('Học viên An'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    await tester.ensureVisible(find.text('Gửi đăng ký lớp'));
    await tester.tap(find.text('Gửi đăng ký lớp'));
    await tester.pumpAndSettle();
    expect(api.lastPostPath, '/my/registrations');
    expect(api.leadData, {'classId': 'class-1'});
    expect(tester.takeException(), isNull);
    router.dispose();
  });

  testWidgets('student sees registration status from API', (tester) async {
    final api = _FakeApiClient();
    api.responses['/my/registrations'] = [
      {
        'id': 'request-1',
        'status': 'CONTACTED',
        'class': {
          'name': 'English A1 K01',
          'course': {'title': 'English A1'},
        },
      },
    ];
    final router = _router(
      PublicCatalogRepository(api),
      RouteNames.myRegistrations,
    );
    await tester.binding.setSurfaceSize(const Size(375, 800));
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('English A1 K01'), findsOneWidget);
    expect(find.text('Học vụ đã liên hệ'), findsOneWidget);
    expect(tester.takeException(), isNull);
    router.dispose();
  });
}
