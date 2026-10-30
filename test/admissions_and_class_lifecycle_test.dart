import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/network/api_client.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/data/models/class_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/domain/repositories/classes_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/presentation/bloc/classes_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/presentation/screens/class_list_screen.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/dashboard/presentation/views/admissions_crm_view.dart';

class _FakeAdmissionsApiClient implements ApiClient {
  final List<Map<String, dynamic>> leads = [];
  final List<Map<String, dynamic>> registrations = [];

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (path == '/admissions/leads') {
      return leads.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (path == '/admissions/registrations') {
      return registrations.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (path == '/admissions/leads') {
      final body = Map<String, dynamic>.from(data as Map);
      final created = <String, dynamic>{
        'id': 'lead-${leads.length + 1}',
        'fullName': body['fullName'] ?? 'Lead Mới',
        'phone': body['phone'] ?? '0900000000',
        'email': body['email'],
        'targetCourse': body['targetCourse'],
        'status': 'NEW',
        'notes': body['notes'] ?? '',
        'isArchived': false,
        'canDelete': true,
      };
      leads.insert(0, created);
      return created;
    }

    final closeMatch = RegExp(r'^/admissions/leads/([^/]+)/close$').firstMatch(path);
    if (closeMatch != null) {
      final id = closeMatch.group(1)!;
      final body = Map<String, dynamic>.from((data as Map?) ?? {});
      final reason = body['reason']?.toString() ?? 'Không còn nhu cầu';
      final note = (body['notes'] ?? body['note'])?.toString() ?? '';
      final index = leads.indexWhere((l) => l['id'] == id);
      if (index >= 0) {
        final currentNotes = leads[index]['notes']?.toString() ?? '';
        final tag = note.isNotEmpty
            ? '[ĐÓNG LEAD - $reason]: $note'
            : '[ĐÓNG LEAD - $reason]';
        leads[index] = {
          ...leads[index],
          'status': 'CANCELLED',
          'closeReason': reason,
          'notes': currentNotes.isEmpty ? tag : '$currentNotes\n$tag',
        };
        return {
          'message': 'Đã đóng hồ sơ Lead ($reason).',
          'lead': leads[index],
        };
      }
    }

    final archiveMatch = RegExp(r'^/admissions/leads/([^/]+)/archive$').firstMatch(path);
    if (archiveMatch != null) {
      final id = archiveMatch.group(1)!;
      final index = leads.indexWhere((l) => l['id'] == id);
      if (index >= 0) {
        final prevStatus = leads[index]['status']?.toString() ?? 'NEW';
        final currentNotes = leads[index]['notes']?.toString() ?? '';
        leads[index] = {
          ...leads[index],
          'isArchived': true,
          'archivedPreviousStatus': prevStatus,
          'notes': '$currentNotes\n[ARCHIVED:$prevStatus:2026-10-30]'.trim(),
        };
        return {
          'message': 'Đã lưu trữ hồ sơ Lead thành công.',
          'lead': leads[index],
        };
      }
    }

    final restoreMatch = RegExp(r'^/admissions/leads/([^/]+)/restore$').firstMatch(path);
    if (restoreMatch != null) {
      final id = restoreMatch.group(1)!;
      final index = leads.indexWhere((l) => l['id'] == id);
      if (index >= 0) {
        final prevStatus =
            leads[index]['archivedPreviousStatus']?.toString() ?? 'NEW';
        final cleanedNotes = (leads[index]['notes']?.toString() ?? '')
            .replaceAll(RegExp(r'\[ARCHIVED:[^\]]+\]'), '')
            .trim();
        leads[index] = {
          ...leads[index],
          'isArchived': false,
          'status': prevStatus,
          'notes': cleanedNotes,
        };
        return {
          'message': 'Đã khôi phục hồ sơ Lead về danh sách đang hoạt động.',
          'lead': leads[index],
        };
      }
    }

    return {};
  }

  @override
  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final reviewMatch =
        RegExp(r'^/admissions/registrations/([^/]+)/review$').firstMatch(path);
    if (reviewMatch != null) {
      final id = reviewMatch.group(1)!;
      final body = Map<String, dynamic>.from((data as Map?) ?? {});
      final action = body['action']?.toString().toUpperCase() ?? '';
      final note = body['note']?.toString() ?? '';
      final index = registrations.indexWhere((r) => r['id'] == id);
      if (index >= 0) {
        String nextStatus = registrations[index]['status']?.toString() ?? 'PENDING';
        if (action == 'REJECT' || action == 'REJECTED') {
          nextStatus = 'REJECTED';
        } else if (action == 'CANCEL' || action == 'CANCELLED') {
          nextStatus = 'CANCELLED';
        } else if (action == 'CONTACTED') {
          nextStatus = 'CONTACTED';
        } else if (action == 'REOPEN') {
          nextStatus = 'PENDING';
        } else if (action == 'APPROVE') {
          nextStatus = 'APPROVED';
        }
        final isTerminal = nextStatus == 'REJECTED' || nextStatus == 'CANCELLED';
        registrations[index] = {
          ...registrations[index],
          'status': nextStatus,
          'notes': note.isNotEmpty ? note : registrations[index]['notes'],
          'isActiveDependency': !isTerminal,
          'isHistoricalRecord': isTerminal,
          'canDelete': isTerminal,
        };
        return registrations[index];
      }
    }

    final leadPatchMatch = RegExp(r'^/admissions/leads/([^/]+)$').firstMatch(path);
    if (leadPatchMatch != null) {
      final id = leadPatchMatch.group(1)!;
      final body = Map<String, dynamic>.from((data as Map?) ?? {});
      final index = leads.indexWhere((l) => l['id'] == id);
      if (index >= 0) {
        leads[index] = {
          ...leads[index],
          ...body,
        };
        return leads[index];
      }
    }
    return {};
  }

  @override
  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final regDeleteMatch =
        RegExp(r'^/admissions/registrations/([^/]+)$').firstMatch(path);
    if (regDeleteMatch != null) {
      final id = regDeleteMatch.group(1)!;
      registrations.removeWhere((r) => r['id'] == id);
      return {'message': 'Đã xóa đơn đăng ký thử nghiệm.'};
    }

    final leadDeleteMatch = RegExp(r'^/admissions/leads/([^/]+)$').firstMatch(path);
    if (leadDeleteMatch != null) {
      final id = leadDeleteMatch.group(1)!;
      leads.removeWhere((l) => l['id'] == id);
      return {'message': 'Đã xóa hồ sơ Lead thử nghiệm thành công.'};
    }
    return {};
  }

  @override
  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async =>
      {};

  @override
  Future<Uint8List> download(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async =>
      Uint8List(0);
}

class _FakeClassesRepository implements ClassesRepository {
  List<ClassModel> classes = [];
  int deleteCount = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<ClassModel>> getClasses({
    String? search,
    String? status,
    String? branchId,
    String? courseId,
    String? teacherId,
    int page = 1,
    int limit = 50,
  }) async {
    return List<ClassModel>.from(classes);
  }

  @override
  Future<ClassModel> getClassDetail(String id) async {
    return classes.firstWhere((c) => c.id == id);
  }

  @override
  Future<ClassModel> updateClass(
    String id, {
    String? code,
    String? name,
    String? roomId,
    String? mainTeacherId,
    String? assistantTeacherId,
    String? status,
    String? startDate,
    List<String>? scheduleDays,
    String? startTime,
    String? endTime,
    int? maxCapacity,
    double? tuitionFee,
    String? registrationOpenAt,
    String? registrationCloseAt,
    String? notes,
  }) async {
    final idx = classes.indexWhere((c) => c.id == id);
    final old = classes[idx];
    final nextNotes = notes ?? old.notes;
    final updated = old.copyWith(
      status: status ?? old.status,
      notes: nextNotes,
      isArchived: nextNotes != null && nextNotes.contains('[ARCHIVED]'),
    );
    classes[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteClass(String id) async {
    deleteCount++;
    classes.removeWhere((c) => c.id == id);
  }
}

void main() {
  group('Priority Task – Registration Lifecycle, Class Archive/Delete & CRM Lead Management', () {
    testWidgets(
      'Test A & D – Registration Rejected updates metrics (Chờ xử lý: 0, Đã từ chối / Đã đóng: 1), marks historical record, and allows deleting terminal test registration without F5',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final apiClient = _FakeAdmissionsApiClient();
        apiClient.registrations.add({
          'id': 'reg-demo-1',
          'registrationType': 'GUEST',
          'fullName': 'Nguyễn Văn Thử Nghiệm',
          'phone': '0912345678',
          'email': 'guest.demo@example.com',
          'status': 'PENDING',
          'notes': 'Đăng ký thử từ landing page',
          'createdAt': '2026-10-30T01:00:00.000Z',
          'isActiveDependency': true,
          'isHistoricalRecord': false,
          'canDelete': false,
          'class': {
            'id': 'class-demo-1',
            'code': 'DEMO-CLASS-01',
            'name': 'Lớp IELTS Demo',
            'status': 'PLANNED',
            'maxCapacity': 20,
            'enrolledCount': 0,
            'remainingSeats': 20,
          },
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AdmissionsCrmView(
                initialTab: 1,
                apiClient: apiClient,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Nguyễn Văn Thử Nghiệm'), findsOneWidget);
        expect(find.text('Từ chối'), findsOneWidget);

        // Click Từ chối
        await tester.tap(find.text('Từ chối'));
        await tester.pumpAndSettle();

        expect(find.text('Từ chối đơn đăng ký'), findsOneWidget);
        await tester.enterText(
          find.byType(TextField).last,
          'Hồ sơ thử nghiệm không có nhu cầu thật',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận từ chối'));
        await tester.pumpAndSettle();

        // Status updated to REJECTED without F5
        expect(
          find.text('Hồ sơ lịch sử • Không giữ chỗ trong lớp'),
          findsOneWidget,
        );
        expect(find.text('Đã từ chối / Đã đóng'), findsOneWidget);
        expect(find.text('Mở lại đơn'), findsOneWidget);
        expect(find.text('Xóa đơn thử nghiệm'), findsOneWidget);

        // Delete terminal test registration so the demo class can be hard-deleted
        await tester.tap(find.text('Xóa đơn thử nghiệm'));
        await tester.pumpAndSettle();

        expect(find.text('Xóa đơn đăng ký thử nghiệm'), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, 'Xóa vĩnh viễn'));
        await tester.pumpAndSettle();

        expect(find.text('Nguyễn Văn Thử Nghiệm'), findsNothing);
      },
    );

    testWidgets(
      'Test B – Class Delete Policy with Rejected Registration shows accurate historical message, supports Archive/Unarchive, and allows hard-delete once terminal test registration is removed',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final repo = _FakeClassesRepository();
        repo.classes = [
          const ClassModel(
            id: 'class-demo-1',
            code: 'DEMO-CLASS-01',
            name: 'Lớp IELTS Demo',
            courseId: 'course-1',
            courseTitle: 'IELTS Intensive',
            levelId: 'level-1',
            branchId: 'branch-1',
            branchName: 'Cơ sở 1',
            status: 'PLANNED',
            scheduleDays: ['Mon', 'Wed'],
            startTime: '18:00',
            endTime: '20:00',
            studentsCount: 0,
            maxCapacity: 20,
            activeRegistrationsCount: 0,
            historicalRegistrationsCount: 1,
            rejectedRegistrationsCount: 1,
            cancelledRegistrationsCount: 0,
          ),
        ];

        final bloc = ClassesBloc(repository: repo);
        addTearDown(bloc.close);

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<ClassesBloc>.value(
              value: bloc,
              child: const ClassListScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('DEMO-CLASS-01'), findsOneWidget);

        // Open 3-dot action menu
        await tester.tap(find.byTooltip('Thao tác lớp học').first);
        await tester.pumpAndSettle();

        // Since historicalRegistrationsCount == 1, hard delete is disabled and 'Lý do không thể xóa' + 'Lưu trữ lớp học' are shown
        expect(find.text('Lý do không thể xóa'), findsOneWidget);
        expect(find.text('Lưu trữ lớp học'), findsOneWidget);

        await tester.tap(find.text('Lý do không thể xóa'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('1 đơn đăng ký đã từ chối được lưu trong lịch sử'),
          findsOneWidget,
        );
        expect(find.text('Xem đơn liên quan'), findsOneWidget);
        expect(find.text('Lưu trữ lớp'), findsOneWidget);
        expect(find.text('Hủy lớp'), findsOneWidget);

        // Click 'Lưu trữ lớp' directly from the dependency dialog
        await tester.tap(find.widgetWithText(FilledButton, 'Lưu trữ lớp'));
        await tester.pumpAndSettle();

        // Confirm Archive dialog
        expect(find.text('Lưu trữ lớp học'), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, 'Lưu trữ lớp'));
        await tester.pumpAndSettle();

        // Archived class disappears immediately from default active view without F5
        expect(find.text('DEMO-CLASS-01'), findsNothing);

        // Switch status filter to 'Đã lưu trữ' (ARCHIVED)
        await tester.tap(find.byKey(const Key('class_status_filter')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Đã lưu trữ').last);
        await tester.pumpAndSettle();

        expect(find.text('DEMO-CLASS-01'), findsOneWidget);

        // Unarchive class
        await tester.tap(find.byTooltip('Thao tác lớp học').first);
        await tester.pumpAndSettle();
        expect(find.text('Khôi phục khỏi lưu trữ'), findsOneWidget);
        await tester.tap(find.text('Khôi phục khỏi lưu trữ'));
        await tester.pumpAndSettle();

        // Switch back to 'Tất cả trạng thái'
        await tester.tap(find.byKey(const Key('class_status_filter')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tất cả trạng thái').last);
        await tester.pumpAndSettle();

        expect(find.text('DEMO-CLASS-01'), findsOneWidget);
      },
    );

    testWidgets(
      'Test C & D – Lead Lifecycle: Close with reason, Archive, Restore, Delete eligible test Lead, and block deleting converted Lead',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final apiClient = _FakeAdmissionsApiClient();
        apiClient.leads.addAll([
          {
            'id': 'lead-test-1',
            'fullName': 'Trần Thị Thử Nghiệm',
            'phone': '0988111222',
            'email': 'lead.test@example.com',
            'targetCourse': 'IELTS 6.5',
            'status': 'NEW',
            'notes': 'Lead test cần đóng/lưu trữ/xóa',
            'isArchived': false,
            'canDelete': true,
          },
          {
            'id': 'lead-enrolled-1',
            'fullName': 'Lê Học Viên Chính Thức',
            'phone': '0977333444',
            'email': 'student.real@example.com',
            'targetCourse': 'TOEIC 750',
            'status': 'ENROLLED',
            'notes': 'Đã đóng tiền và tạo học viên',
            'isArchived': false,
            'canDelete': false,
            'deleteBlockReason':
                'Không thể xóa hồ sơ Lead đã chuyển đổi thành học viên chính thức.',
          },
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AdmissionsCrmView(
                initialTab: 0,
                apiClient: apiClient,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Trần Thị Thử Nghiệm'), findsOneWidget);
        expect(find.text('Lê Học Viên Chính Thức'), findsOneWidget);

        // 1. Close Lead with reason
        final menuButtons = find.byTooltip('Thao tác hồ sơ Lead');
        expect(menuButtons, findsWidgets);

        await tester.tap(menuButtons.first);
        await tester.pumpAndSettle();

        expect(find.text('Đóng Lead (Không nhu cầu)'), findsOneWidget);
        await tester.tap(find.text('Đóng Lead (Không nhu cầu)'));
        await tester.pumpAndSettle();

        expect(find.text('Đóng hồ sơ Lead (Không nhu cầu)'), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận đóng Lead'));
        await tester.pumpAndSettle();

        // 2. Archive Lead
        await tester.tap(find.byTooltip('Thao tác hồ sơ Lead').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lưu trữ Lead'));
        await tester.pumpAndSettle();

        // Disappears from active pipeline immediately without F5
        expect(find.text('Trần Thị Thử Nghiệm'), findsNothing);

        // 3. Switch to 'Đã lưu trữ' filter chip -> visible
        await tester.tap(find.textContaining('Đã lưu trữ'));
        await tester.pumpAndSettle();
        expect(find.text('Trần Thị Thử Nghiệm'), findsOneWidget);

        // 4. Restore Lead
        await tester.tap(find.byTooltip('Thao tác hồ sơ Lead').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Khôi phục Lead'));
        await tester.pumpAndSettle();

        // Switch back to 'Pipeline đang hoạt động'
        await tester.tap(find.textContaining('Pipeline đang hoạt động'));
        await tester.pumpAndSettle();
        expect(find.text('Trần Thị Thử Nghiệm'), findsOneWidget);

        // 5. Delete eligible test Lead
        await tester.tap(find.byTooltip('Thao tác hồ sơ Lead').first);
        await tester.pumpAndSettle();
        expect(find.text('Xóa Lead thử nghiệm'), findsOneWidget);
        await tester.tap(find.text('Xóa Lead thử nghiệm'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(FilledButton, 'Xóa vĩnh viễn'));
        await tester.pumpAndSettle();

        expect(find.text('Trần Thị Thử Nghiệm'), findsNothing);

        // 6. Verify converted Lead ('ENROLLED') cannot be deleted and shows 'Lý do không thể xóa'
        await tester.tap(find.byTooltip('Thao tác hồ sơ Lead').first);
        await tester.pumpAndSettle();
        expect(find.text('Lý do không thể xóa'), findsOneWidget);
        await tester.tap(find.text('Lý do không thể xóa'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Không thể xóa hồ sơ Lead đã chuyển đổi thành học viên'),
          findsOneWidget,
        );
        await tester.tap(find.text('Đã hiểu'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Test E – Responsive check across 320, 375, 393, 430, 800, 1200 viewports without overflow',
      (tester) async {
        final apiClient = _FakeAdmissionsApiClient();
        apiClient.leads.add({
          'id': 'lead-resp-1',
          'fullName': 'Nguyễn Văn Responsive',
          'phone': '0911222333',
          'targetCourse': 'Giao tiếp Quốc tế',
          'status': 'CONTACTED',
          'notes': 'Ghi chú kiểm thử màn hình nhỏ',
          'isArchived': false,
          'canDelete': true,
        });

        for (final width in [320.0, 375.0, 393.0, 430.0, 800.0, 1200.0]) {
          await tester.binding.setSurfaceSize(Size(width, 844));
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: AdmissionsCrmView(
                  initialTab: 0,
                  apiClient: apiClient,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        await tester.binding.setSurfaceSize(null);
      },
    );
  });
}
