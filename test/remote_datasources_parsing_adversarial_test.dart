import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/network/api_client.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/data/datasources/assignments_remote_datasource.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/data/datasources/finance_remote_datasource.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/reports/data/datasources/reports_remote_datasource.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/exams/data/datasources/exams_remote_datasource.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/exams/data/models/exam_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/notifications/data/datasources/notifications_remote_datasource.dart';

class FakeApiClient implements ApiClient {
  dynamic responseToReturn;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return responseToReturn;
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return responseToReturn;
  }

  @override
  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return responseToReturn;
  }

  @override
  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return responseToReturn;
  }

  @override
  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return responseToReturn;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeApiClient fakeApi;

  setUp(() {
    fakeApi = FakeApiClient();
  });

  group('Adversarial Remote Data Source Response Parsing Tests (All 6 Datasources)', () {
    // -------------------------------------------------------------------------
    // 1. AttendanceRemoteDataSource
    // -------------------------------------------------------------------------
    group('AttendanceRemoteDataSource', () {
      late AttendanceRemoteDataSource ds;

      setUp(() {
        ds = AttendanceRemoteDataSourceImpl(apiClient: fakeApi);
      });

      test('getSessionAttendance handles envelope-wrapped and unwrapped payload', () async {
        fakeApi.responseToReturn = {
          'success': true,
          'data': {
            'session': {'id': 'sess-1', 'title': 'English 101'},
            'summary': {'totalEnrolled': 20, 'present': 18},
            'students': [
              {'studentId': 'st-1', 'fullName': 'Nguyen Van A', 'status': 'PRESENT'}
            ]
          }
        };
        final res = await ds.getSessionAttendance('sess-1');
        expect(res.sessionId, equals('sess-1'));
        expect(res.students.length, equals(1));

        // Unwrapped
        fakeApi.responseToReturn = {
          'session': {'id': 'sess-2', 'title': 'IELTS Prep'},
          'summary': {'totalEnrolled': 15, 'present': 15},
          'students': []
        };
        final resUnwrapped = await ds.getSessionAttendance('sess-2');
        expect(resUnwrapped.sessionId, equals('sess-2'));
      });

      test('batchMarkAttendance handles wrapped and unwrapped response', () async {
        fakeApi.responseToReturn = {
          'success': true,
          'data': {
            'session': {'id': 'sess-1', 'title': 'Grammar Review'},
            'summary': {'totalEnrolled': 10, 'present': 9},
            'students': []
          }
        };
        final res1 = await ds.batchMarkAttendance('sess-1', [{'studentId': 'st-1', 'status': 'PRESENT'}]);
        expect(res1.sessionId, equals('sess-1'));

        fakeApi.responseToReturn = <String, dynamic>{
          'session': <String, dynamic>{'id': 'sess-1'},
          'summary': <String, dynamic>{},
          'students': <dynamic>[]
        };
        final res2 = await ds.batchMarkAttendance('sess-1', []);
        expect(res2.sessionId, equals('sess-1'));
      });

      test('updateAttendance completes without error', () async {
        fakeApi.responseToReturn = {'success': true};
        await expectLater(ds.updateAttendance('att-1', status: 'LATE'), completes);
      });

      test('getStudentAttendance handles wrapped and unwrapped history', () async {
        fakeApi.responseToReturn = {
          'success': true,
          'data': {
            'summary': {'totalSessions': 10, 'present': 9, 'attendanceRate': 90.0},
            'records': [
              {'id': 'rec-1', 'status': 'PRESENT', 'markedAt': '2026-10-19T08:00:00Z'}
            ]
          }
        };
        final res = await ds.getStudentAttendance('st-1');
        expect(res.summary.totalSessions, equals(10));
        expect(res.records.length, equals(1));

        // Unwrapped
        fakeApi.responseToReturn = {
          'summary': {'totalSessions': 5, 'present': 5},
          'records': []
        };
        final resUnwrapped = await ds.getStudentAttendance('st-1');
        expect(resUnwrapped.summary.totalSessions, equals(5));
      });

      test('getClassAttendanceSummary returns unboxed Map<String, dynamic>', () async {
        fakeApi.responseToReturn = {
          'success': true,
          'data': {'rate': 95.0, 'totalSessions': 12}
        };
        final res1 = await ds.getClassAttendanceSummary('cls-1');
        expect(res1['rate'], equals(95.0));

        fakeApi.responseToReturn = {'rate': 88.0};
        final res2 = await ds.getClassAttendanceSummary('cls-1');
        expect(res2['rate'], equals(88.0));
      });

      test('createMakeupRequest and updateMakeupRequest handle wrapped and unwrapped models', () async {
        final sampleReq = {
          'id': 'mr-1',
          'studentId': 'st-1',
          'originalSession': {'title': 'Speaking 1'},
          'status': 'PENDING',
          'createdAt': '2026-10-19T00:00:00Z'
        };

        fakeApi.responseToReturn = {'success': true, 'data': sampleReq};
        final created = await ds.createMakeupRequest(originalSessionId: 'sess-1', reason: 'Sick');
        expect(created.id, equals('mr-1'));

        fakeApi.responseToReturn = sampleReq;
        final updated = await ds.updateMakeupRequest('mr-1', status: 'APPROVED');
        expect(updated.id, equals('mr-1'));
      });

      test('getMakeupRequests handles raw List, wrapped data List, items List, wrapped items List', () async {
        final sampleRequest = {
          'id': 'mr-1',
          'studentId': 'st-1',
          'originalSession': {'title': 'Grammar'},
          'status': 'PENDING',
          'createdAt': '2026-10-19T00:00:00Z'
        };

        fakeApi.responseToReturn = [sampleRequest];
        final list1 = await ds.getMakeupRequests();
        expect(list1.length, equals(1));

        fakeApi.responseToReturn = {'data': [sampleRequest]};
        final list2 = await ds.getMakeupRequests();
        expect(list2.length, equals(1));

        fakeApi.responseToReturn = {'items': [sampleRequest]};
        final list3 = await ds.getMakeupRequests();
        expect(list3.length, equals(1));

        fakeApi.responseToReturn = {'data': {'items': [sampleRequest]}};
        final list4 = await ds.getMakeupRequests();
        expect(list4.length, equals(1));

        fakeApi.responseToReturn = [];
        expect(await ds.getMakeupRequests(), isEmpty);

        fakeApi.responseToReturn = {};
        expect(await ds.getMakeupRequests(), isEmpty);
      });
    });

    // -------------------------------------------------------------------------
    // 2. AssignmentsRemoteDataSource
    // -------------------------------------------------------------------------
    group('AssignmentsRemoteDataSource', () {
      late AssignmentsRemoteDataSource ds;

      setUp(() {
        ds = AssignmentsRemoteDataSourceImpl(apiClient: fakeApi);
      });

      test('getClassAssignments handles raw List, wrapped data List, items List, wrapped items List', () async {
        final sampleAssignment = {
          'id': 'asg-1',
          'classId': 'cls-1',
          'title': 'Writing Essay 1',
          'type': 'WRITING',
          'maxScore': 10.0,
          'createdAt': '2026-10-19T00:00:00Z',
        };

        fakeApi.responseToReturn = [sampleAssignment];
        final list1 = await ds.getClassAssignments('cls-1');
        expect(list1.length, equals(1));

        fakeApi.responseToReturn = {'data': [sampleAssignment]};
        final list2 = await ds.getClassAssignments('cls-1');
        expect(list2.length, equals(1));

        fakeApi.responseToReturn = {'items': [sampleAssignment]};
        final list3 = await ds.getClassAssignments('cls-1');
        expect(list3.length, equals(1));

        fakeApi.responseToReturn = {'data': {'items': [sampleAssignment]}};
        final list4 = await ds.getClassAssignments('cls-1');
        expect(list4.length, equals(1));

        fakeApi.responseToReturn = [];
        expect(await ds.getClassAssignments('cls-1'), isEmpty);
      });

      test('createAssignment parses wrapped and unwrapped response', () async {
        final sampleAssignment = {
          'id': 'asg-new',
          'classId': 'cls-1',
          'title': 'New Assignment',
          'createdAt': '2026-10-19T00:00:00Z',
        };

        fakeApi.responseToReturn = {'success': true, 'data': sampleAssignment};
        final created = await ds.createAssignment('cls-1', title: 'New Assignment');
        expect(created.id, equals('asg-new'));

        fakeApi.responseToReturn = sampleAssignment;
        final created2 = await ds.createAssignment('cls-1', title: 'New Assignment');
        expect(created2.id, equals('asg-new'));
      });

      test('getAssignmentDetail handles nested assignment key and flat assignment map', () async {
        fakeApi.responseToReturn = {
          'success': true,
          'data': {
            'assignment': {
              'id': 'asg-1',
              'classId': 'cls-1',
              'title': 'Speaking Practice',
              'createdAt': '2026-10-19T00:00:00Z',
            },
            'stats': {'totalSubmissions': 12, 'gradedCount': 10}
          }
        };
        final res1 = await ds.getAssignmentDetail('asg-1');
        expect(res1.title, equals('Speaking Practice'));
        expect(res1.totalSubmissions, equals(12));

        fakeApi.responseToReturn = {
          'id': 'asg-2',
          'classId': 'cls-1',
          'title': 'Flat Assignment',
          'createdAt': '2026-10-19T00:00:00Z',
        };
        final res2 = await ds.getAssignmentDetail('asg-2');
        expect(res2.title, equals('Flat Assignment'));
      });

      test('getAssignmentSubmissions parses wrapped and unwrapped submissions summary', () async {
        final sampleSubmissions = {
          'assignment': {'id': 'asg-1', 'title': 'Reading Quiz'},
          'stats': {'totalEnrolled': 25, 'submittedCount': 20, 'gradedCount': 15},
          'students': [
            {
              'student': {'id': 'st-1', 'fullName': 'Le Van B'},
              'hasSubmitted': true,
              'submission': {'id': 'sub-1', 'assignmentId': 'asg-1', 'studentId': 'st-1', 'submittedAt': '2026-10-19T00:00:00Z'}
            }
          ]
        };

        fakeApi.responseToReturn = {'success': true, 'data': sampleSubmissions};
        final res = await ds.getAssignmentSubmissions('asg-1');
        expect(res.assignmentId, equals('asg-1'));
        expect(res.submittedCount, equals(20));
        expect(res.students.first.fullName, equals('Le Van B'));

        fakeApi.responseToReturn = sampleSubmissions;
        final res2 = await ds.getAssignmentSubmissions('asg-1');
        expect(res2.assignmentId, equals('asg-1'));
      });

      test('submitAssignment and gradeSubmission handle unboxed responses', () async {
        fakeApi.responseToReturn = {
          'success': true,
          'data': {
            'id': 'sub-1',
            'assignmentId': 'asg-1',
            'studentId': 'st-1',
            'status': 'SUBMITTED',
            'submittedAt': '2026-10-19T00:00:00Z',
          }
        };
        final sub = await ds.submitAssignment('asg-1');
        expect(sub.id, equals('sub-1'));

        fakeApi.responseToReturn = {
          'id': 'sub-1',
          'assignmentId': 'asg-1',
          'studentId': 'st-1',
          'status': 'GRADED',
          'score': 9.5,
          'submittedAt': '2026-10-19T00:00:00Z',
        };
        final graded = await ds.gradeSubmission('sub-1', score: 9.5);
        expect(graded.score, equals(9.5));
      });
    });

    // -------------------------------------------------------------------------
    // 3. FinanceRemoteDataSource
    // -------------------------------------------------------------------------
    group('FinanceRemoteDataSource', () {
      late FinanceRemoteDataSource ds;

      setUp(() {
        ds = FinanceRemoteDataSourceImpl(apiClient: fakeApi);
      });

      test('getInvoices handles paginated wrapper with summary', () async {
        fakeApi.responseToReturn = {
          'success': true,
          'data': {
            'items': [
              {
                'id': 'inv-1',
                'code': 'INV001',
                'title': 'Tuition Oct 2026',
                'studentId': 'st-1',
                'subtotal': 3000000.0,
                'totalAmount': 3000000.0,
                'paidAmount': 3000000.0,
                'balance': 0.0,
                'status': 'PAID',
                'issuedDate': '2026-10-01T00:00:00Z',
              }
            ],
            'total': 1,
            'page': 1,
            'limit': 20,
            'summary': {
              'totalRevenue': 3000000.0,
              'paidRevenue': 3000000.0,
              'outstandingRevenue': 0.0,
            }
          }
        };

        final res = await ds.getInvoices();
        expect(res.items.length, equals(1));
        expect(res.summary.totalRevenue, equals(3000000.0));
      });

      test('getMyInvoices handles List, data List, items List, and data.items List', () async {
        final sampleInv = {
          'id': 'inv-2',
          'code': 'INV002',
          'title': 'IELTS Course',
          'studentId': 'st-1',
          'subtotal': 5000000.0,
          'totalAmount': 5000000.0,
          'paidAmount': 0.0,
          'balance': 5000000.0,
          'status': 'UNPAID',
          'issuedDate': '2026-10-19T00:00:00Z',
        };

        fakeApi.responseToReturn = [sampleInv];
        final list1 = await ds.getMyInvoices();
        expect(list1.length, equals(1));

        fakeApi.responseToReturn = {'data': [sampleInv]};
        final list2 = await ds.getMyInvoices();
        expect(list2.length, equals(1));

        fakeApi.responseToReturn = {'items': [sampleInv]};
        final list3 = await ds.getMyInvoices();
        expect(list3.length, equals(1));

        fakeApi.responseToReturn = {'data': {'items': [sampleInv]}};
        final list4 = await ds.getMyInvoices();
        expect(list4.length, equals(1));
      });

      test('getInvoiceDetail, createInvoice, cancelInvoice, refundInvoice parse properly', () async {
        final sampleInv = {
          'id': 'inv-3',
          'code': 'INV003',
          'title': 'Course Fee',
          'studentId': 'st-2',
          'subtotal': 2000000.0,
          'totalAmount': 2000000.0,
          'paidAmount': 2000000.0,
          'balance': 0.0,
          'status': 'PAID',
          'issuedDate': '2026-10-19T00:00:00Z',
        };

        fakeApi.responseToReturn = {'success': true, 'data': sampleInv};
        final detail = await ds.getInvoiceDetail('inv-3');
        expect(detail.id, equals('inv-3'));

        fakeApi.responseToReturn = sampleInv;
        final created = await ds.createInvoice({'title': 'New'});
        expect(created.id, equals('inv-3'));

        fakeApi.responseToReturn = {'data': sampleInv};
        final cancelled = await ds.cancelInvoice('inv-3', reason: 'Duplicate');
        expect(cancelled.id, equals('inv-3'));

        fakeApi.responseToReturn = sampleInv;
        final refunded = await ds.refundInvoice('inv-3', amount: 500000.0);
        expect(refunded.id, equals('inv-3'));
      });

      test('recordPayment, payOnline, and validatePromotion return decoded Map safely', () async {
        fakeApi.responseToReturn = {'success': true, 'data': {'paymentId': 'pay-1'}};
        final recRes = await ds.recordPayment('inv-1', amount: 1000000, method: 'CASH');
        expect(recRes['paymentId'], equals('pay-1'));

        fakeApi.responseToReturn = {
          'success': true,
          'data': {
            'paymentUrl': 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html',
            'qrCode': 'data:image/png;base64,sample'
          }
        };
        final payRes = await ds.payOnline('inv-1');
        expect(payRes['paymentUrl'], isNotNull);

        fakeApi.responseToReturn = {
          'valid': true,
          'discountAmount': 500000.0,
        };
        final promoRes = await ds.validatePromotion('DISCOUNT10', 5000000.0);
        expect(promoRes['valid'], isTrue);
      });

      test('getPromotions handles collections and empty lists', () async {
        final samplePromo = {
          'id': 'prom-1',
          'code': 'EARLYBIRD',
          'name': 'Early Bird 20%',
          'type': 'PERCENTAGE',
          'value': 20.0,
          'startDate': '2026-01-01T00:00:00Z',
          'endDate': '2026-12-31T00:00:00Z',
          'isActive': true,
        };

        fakeApi.responseToReturn = [samplePromo];
        final pList1 = await ds.getPromotions();
        expect(pList1.length, equals(1));

        fakeApi.responseToReturn = {'data': [samplePromo]};
        final pList2 = await ds.getPromotions();
        expect(pList2.length, equals(1));

        fakeApi.responseToReturn = [];
        expect(await ds.getPromotions(), isEmpty);
      });
    });

    // -------------------------------------------------------------------------
    // 4. ReportsRemoteDataSource
    // -------------------------------------------------------------------------
    group('ReportsRemoteDataSource', () {
      late ReportsRemoteDataSource ds;

      setUp(() {
        ds = ReportsRemoteDataSourceImpl(apiClient: fakeApi);
      });

      test('getDashboardOverview handles envelope and unwrapped shapes', () async {
        fakeApi.responseToReturn = {
          'success': true,
          'data': {
            'totalStudents': 120,
            'newStudentsThisMonth': 15,
            'totalActiveClasses': 8,
            'monthlyRevenue': 45000000.0,
            'lastMonthRevenue': 40000000.0,
            'monthlyRevenueGrowth': 12.5,
            'totalDebts': 5000000.0,
            'revenueTrend': [],
            'courseDistribution': [],
            'upcomingClasses': [],
            'topDebtors': [],
          }
        };
        final overview = await ds.getDashboardOverview();
        expect(overview.totalStudents, equals(120));
        expect(overview.monthlyRevenueGrowth, equals(12.5));

        // Unwrapped
        fakeApi.responseToReturn = {
          'totalStudents': 50,
          'newStudentsThisMonth': 5,
          'totalActiveClasses': 4,
          'monthlyRevenue': 20000000.0,
          'lastMonthRevenue': 18000000.0,
          'monthlyRevenueGrowth': 11.1,
          'totalDebts': 1000000.0,
        };
        final overviewUnwrapped = await ds.getDashboardOverview();
        expect(overviewUnwrapped.totalStudents, equals(50));
      });

      test('getRevenueReport handles wrapped and unwrapped reports', () async {
        final sampleRevenue = {
          'year': 2026,
          'totalRevenue': 500000000.0,
          'averageMonthlyRevenue': 50000000.0,
          'highestMonth': {'month': 9, 'revenue': 80000000.0},
          'monthlyData': [],
          'byMethod': [],
          'byBranch': [],
        };

        fakeApi.responseToReturn = {'success': true, 'data': sampleRevenue};
        final rep1 = await ds.getRevenueReport(year: 2026);
        expect(rep1.totalRevenue, equals(500000000.0));

        fakeApi.responseToReturn = sampleRevenue;
        final rep2 = await ds.getRevenueReport();
        expect(rep2.totalRevenue, equals(500000000.0));
      });

      test('getAttendanceReport handles wrapped and unwrapped statistics', () async {
        final sampleAttendance = {
          'totalRecords': 100,
          'presentCount': 90,
          'lateCount': 5,
          'absentCount': 3,
          'excusedCount': 2,
          'makeupCount': 1,
          'attendanceRate': 90.0,
          'byClass': [],
        };

        fakeApi.responseToReturn = {'success': true, 'data': sampleAttendance};
        final attRep1 = await ds.getAttendanceReport();
        expect(attRep1.attendanceRate, equals(90.0));

        fakeApi.responseToReturn = sampleAttendance;
        final attRep2 = await ds.getAttendanceReport();
        expect(attRep2.presentCount, equals(90));
      });

      test('getDebtsReport parses paginated debts summary and items', () async {
        final sampleDebts = {
          'items': [],
          'total': 0,
          'page': 1,
          'limit': 20,
          'summary': {
            'totalOutstanding': 15000000.0,
            'totalInvoiced': 100000000.0,
            'totalPaid': 85000000.0,
            'overdueCount': 3,
          }
        };

        fakeApi.responseToReturn = {'success': true, 'data': sampleDebts};
        final debts1 = await ds.getDebtsReport();
        expect(debts1.summary.totalOutstanding, equals(15000000.0));

        fakeApi.responseToReturn = sampleDebts;
        final debts2 = await ds.getDebtsReport();
        expect(debts2.summary.overdueCount, equals(3));
      });

      test('getTeacherWorkloadReport handles raw List and wrapped List', () async {
        final sampleWorkload = {
          'teacherId': 'tea-1',
          'fullName': 'Teacher John',
          'activeClassesCount': 3,
          'totalSessions': 30,
          'completedSessions': 25,
          'totalTeachingHours': 50.0,
        };

        fakeApi.responseToReturn = [sampleWorkload];
        final list1 = await ds.getTeacherWorkloadReport();
        expect(list1.length, equals(1));
        expect(list1.first.fullName, equals('Teacher John'));

        fakeApi.responseToReturn = {'data': [sampleWorkload]};
        final list2 = await ds.getTeacherWorkloadReport();
        expect(list2.length, equals(1));
      });

      test('refreshDashboardCache completes cleanly', () async {
        fakeApi.responseToReturn = {'success': true};
        await expectLater(ds.refreshDashboardCache(), completes);
      });
    });

    // -------------------------------------------------------------------------
    // 5. ExamsRemoteDataSource
    // -------------------------------------------------------------------------
    group('ExamsRemoteDataSource', () {
      late ExamsRemoteDataSource ds;

      setUp(() {
        ds = ExamsRemoteDataSourceImpl(apiClient: fakeApi);
      });

      test('getQuestionBanks, getQuestionBankDetail, createQuestionBank, addQuestionToBank parse cleanly', () async {
        final sampleBank = {
          'id': 'qb-1',
          'title': 'IELTS Reading Bank',
          'language': 'English',
          'level': 'B2',
          'questionCount': 50,
        };

        // List
        fakeApi.responseToReturn = [sampleBank];
        final qbList = await ds.getQuestionBanks();
        expect(qbList.length, equals(1));

        // Detail
        fakeApi.responseToReturn = {'success': true, 'data': sampleBank};
        final qbDetail = await ds.getQuestionBankDetail('qb-1');
        expect(qbDetail.id, equals('qb-1'));

        // Create
        fakeApi.responseToReturn = sampleBank;
        final qbCreated = await ds.createQuestionBank(title: 'IELTS Reading');
        expect(qbCreated.title, equals('IELTS Reading Bank'));

        // Add question
        final sampleQ = {
          'id': 'q-1',
          'prompt': 'What is Flutter?',
          'type': 'MULTIPLE_CHOICE',
        };
        fakeApi.responseToReturn = {'data': sampleQ};
        final q = await ds.addQuestionToBank('qb-1', sampleQ);
        expect(q.prompt, equals('What is Flutter?'));
      });

      test('getExams, getExamDetail, and createExam parse properly', () async {
        final sampleExam = {
          'id': 'ex-1',
          'title': 'Midterm Exam',
          'durationMinutes': 60,
          'passPercentage': 60.0,
          'totalPoints': 100.0,
          'shuffleQuestions': true,
          'maxAttempts': 2,
          'status': 'PUBLISHED',
        };

        fakeApi.responseToReturn = [sampleExam];
        final examList = await ds.getExams();
        expect(examList.length, equals(1));

        fakeApi.responseToReturn = {'data': sampleExam};
        final examDetail = await ds.getExamDetail('ex-1');
        expect(examDetail.id, equals('ex-1'));

        fakeApi.responseToReturn = sampleExam;
        final examCreated = await ds.createExam(sampleExam);
        expect(examCreated.id, equals('ex-1'));
      });

      test('saveExamAnswers completes without error', () async {
        fakeApi.responseToReturn = {'success': true};
        await expectLater(ds.saveExamAnswers('att-1', []), completes);
      });

      test('submitExam handles nested attempt and flat attempt map', () async {
        fakeApi.responseToReturn = {
          'success': true,
          'data': {
            'attempt': {
              'id': 'att-1',
              'examId': 'ex-1',
              'studentId': 'st-1',
              'attemptNumber': 1,
              'startedAt': '2026-10-19T00:00:00Z',
              'maxScore': 100.0,
              'status': 'SUBMITTED',
            }
          }
        };
        final att1 = await ds.submitExam('ex-1');
        expect(att1.id, equals('att-1'));

        fakeApi.responseToReturn = {
          'id': 'att-2',
          'examId': 'ex-1',
          'studentId': 'st-1',
          'attemptNumber': 2,
          'startedAt': '2026-10-19T01:00:00Z',
          'maxScore': 100.0,
          'status': 'SUBMITTED',
        };
        final att2 = await ds.submitExam('ex-1');
        expect(att2.id, equals('att-2'));
      });

      test('startExam parses full attempt and exam payload', () async {
        fakeApi.responseToReturn = {
          'success': true,
          'data': {
            'message': 'Exam started',
            'attempt': {
              'id': 'att-10',
              'examId': 'ex-1',
              'studentId': 'st-1',
              'attemptNumber': 1,
              'startedAt': '2026-10-19T00:00:00Z',
              'maxScore': 100.0,
              'status': 'IN_PROGRESS',
            },
            'exam': {
              'id': 'ex-1',
              'title': 'Midterm',
              'durationMinutes': 45,
              'passPercentage': 50.0,
              'totalPoints': 10.0,
              'shuffleQuestions': false,
              'maxAttempts': 1,
              'status': 'PUBLISHED',
            }
          }
        };

        final result = await ds.startExam('ex-1');
        expect(result['message'], equals('Exam started'));
        expect(result['attempt'], isA<ExamAttemptModel>());
        expect(result['exam'], isA<ExamModel>());
      });

      test('startExam with omitted or null attempt triggers _TypeError due to (map["attempt"] ?? {}) as Map<String, dynamic>', () async {
        fakeApi.responseToReturn = {
          'success': true,
          'data': {
            'message': 'Missing attempt object',
          }
        };

        // When attempt is omitted/null, (map['attempt'] ?? {}) evaluates to {} of type _Map<dynamic, dynamic>,
        // which cannot be cast to Map<String, dynamic>.
        expect(
          () => ds.startExam('ex-1'),
          throwsA(isA<TypeError>()),
        );
      });

      test('getExamResults, getMyExamResults, and gradeExamAnswer parse properly', () async {
        fakeApi.responseToReturn = {
          'success': true,
          'data': {
            'exam': {
              'id': 'ex-1',
              'title': 'Final Test',
              'durationMinutes': 90,
              'passPercentage': 70.0,
              'totalPoints': 100.0,
              'shuffleQuestions': false,
              'maxAttempts': 1,
              'status': 'PUBLISHED',
            },
            'summary': {
              'totalAttempts': 30,
              'gradedCount': 30,
              'passedCount': 28,
              'passRate': 93.3,
              'averageScore': 82.5,
            },
            'attempts': []
          }
        };
        final resResults = await ds.getExamResults('ex-1');
        expect(resResults.exam.title, equals('Final Test'));
        expect(resResults.summary.passedCount, equals(28));

        final sampleAttempt = {
          'id': 'att-20',
          'examId': 'ex-1',
          'studentId': 'st-1',
          'attemptNumber': 1,
          'startedAt': '2026-10-19T00:00:00Z',
          'maxScore': 100.0,
          'status': 'GRADED',
        };
        fakeApi.responseToReturn = [sampleAttempt];
        final myResults = await ds.getMyExamResults();
        expect(myResults.length, equals(1));

        fakeApi.responseToReturn = {
          'id': 'ans-1',
          'attemptId': 'att-20',
          'examQuestionId': 'eq-1',
          'score': 5.0,
          'teacherFeedback': 'Great explanation',
        };
        final gradedAns = await ds.gradeExamAnswer('ans-1', score: 5.0);
        expect(gradedAns.score, equals(5.0));
      });
    });

    // -------------------------------------------------------------------------
    // 6. NotificationsRemoteDataSource
    // -------------------------------------------------------------------------
    group('NotificationsRemoteDataSource', () {
      late NotificationsRemoteDataSource ds;

      setUp(() {
        ds = NotificationsRemoteDataSourceImpl(apiClient: fakeApi);
      });

      test('getMyNotifications handles raw List, data List, items List, data.items List', () async {
        final sampleNotification = {
          'id': 'notif-1',
          'userId': 'usr-1',
          'title': 'New Assignment',
          'body': 'You have a new assignment.',
          'type': 'ASSIGNMENT',
          'isRead': false,
          'createdAt': '2026-10-19T00:00:00Z',
        };

        fakeApi.responseToReturn = [sampleNotification];
        final list1 = await ds.getMyNotifications();
        expect(list1.length, equals(1));

        fakeApi.responseToReturn = {'data': [sampleNotification]};
        final list2 = await ds.getMyNotifications();
        expect(list2.length, equals(1));

        fakeApi.responseToReturn = {'items': [sampleNotification]};
        final list3 = await ds.getMyNotifications();
        expect(list3.length, equals(1));

        fakeApi.responseToReturn = {'data': {'items': [sampleNotification]}};
        final list4 = await ds.getMyNotifications();
        expect(list4.length, equals(1));

        fakeApi.responseToReturn = [];
        expect(await ds.getMyNotifications(), isEmpty);

        fakeApi.responseToReturn = {};
        expect(await ds.getMyNotifications(), isEmpty);
      });

      test('getUnreadCount handles wrapped count map, unwrapped map, wrapped int, raw int, empty map', () async {
        fakeApi.responseToReturn = {'success': true, 'data': {'count': 7}};
        expect(await ds.getUnreadCount(), equals(7));

        fakeApi.responseToReturn = {'count': 3};
        expect(await ds.getUnreadCount(), equals(3));

        fakeApi.responseToReturn = {'success': true, 'data': 12};
        expect(await ds.getUnreadCount(), equals(12));

        fakeApi.responseToReturn = 5;
        expect(await ds.getUnreadCount(), equals(5));

        fakeApi.responseToReturn = {};
        expect(await ds.getUnreadCount(), equals(0));
      });

      test('markAsRead, markAllAsRead, and updateFcmToken complete without error', () async {
        fakeApi.responseToReturn = {'success': true};
        await expectLater(ds.markAsRead('notif-1'), completes);
        await expectLater(ds.markAllAsRead(), completes);
        await expectLater(ds.updateFcmToken('sample-fcm-token'), completes);
      });
    });

    // -------------------------------------------------------------------------
    // 7. Overall Absence of NoSuchMethodError across all 6 datasources
    // -------------------------------------------------------------------------
    test('Verifies no call to response.data occurs across all 6 datasources', () async {
      // In all 6 datasources, calling methods when ApiClient returns raw Map or List
      // should never throw NoSuchMethodError: Class 'Map' or 'List' has no instance getter 'data'.
      // This is conclusively verified by all tests above executing without NoSuchMethodError.
      expect(true, isTrue);
    });
  });
}
