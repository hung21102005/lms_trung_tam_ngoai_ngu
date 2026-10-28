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
  };
  bool failLead = false;
  int leadCalls = 0;
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
    leadData = Map<String, dynamic>.from(data as Map);
    if (failLead) throw Exception('Mất kết nối');
    return {'id': 'lead-1'};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

GoRouter _router(
  PublicCatalogRepository repository,
  String initialLocation,
) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: RouteNames.publicHome,
      builder: (_, _) =>
          PublicSiteScreen(repository: repository, page: PublicPage.home),
    ),
    GoRoute(
      path: RouteNames.publicCourses,
      builder: (_, _) =>
          PublicSiteScreen(repository: repository, page: PublicPage.courses),
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
      path: RouteNames.login,
      builder: (_, _) => const Scaffold(body: Text('Đăng nhập')),
    ),
  ],
);

void main() {
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
}
