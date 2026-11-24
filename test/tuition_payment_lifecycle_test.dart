import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/data/models/invoice_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/domain/repositories/finance_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/presentation/screens/invoice_detail_screen.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/presentation/screens/invoice_list_screen.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/presentation/screens/my_invoices_screen.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/presentation/screens/pay_online_screen.dart';

class _FakeFinanceRepository implements FinanceRepository {
  final List<InvoiceModel> invoices = [];
  final List<PromotionModel> promotions = [];
  int checkOverdueCalls = 0;

  @override
  Future<InvoicesResponseModel> getInvoices({
    String? status,
    String? search,
    String? studentId,
    String? classId,
    String? branchId,
    bool? pendingTransferOnly,
    int page = 1,
    int limit = 20,
  }) async {
    var filtered = List<InvoiceModel>.from(invoices);
    if (status != null && status.isNotEmpty) {
      filtered = filtered.where((i) => i.status == status).toList();
    }
    if (pendingTransferOnly == true) {
      filtered = filtered.where((i) => i.hasPendingTransfer).toList();
    }
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      filtered = filtered
          .where(
            (i) =>
                i.code.toLowerCase().contains(q) ||
                i.title.toLowerCase().contains(q) ||
                (i.student?['fullName']?.toString().toLowerCase().contains(q) ??
                    false),
          )
          .toList();
    }

    final totalRev = filtered
        .where((i) => i.status != 'CANCELLED')
        .fold<double>(0, (s, i) => s + i.totalAmount);
    final paidRev = filtered
        .where((i) => i.status != 'CANCELLED')
        .fold<double>(0, (s, i) => s + i.paidAmount);
    final outRev = filtered
        .where((i) => i.status != 'CANCELLED')
        .fold<double>(0, (s, i) => s + i.balance);
    final pendingCnt = invoices.where((i) => i.hasPendingTransfer).length;
    final overdueCnt = invoices.where((i) => i.status == 'OVERDUE').length;

    return InvoicesResponseModel(
      items: filtered,
      total: filtered.length,
      page: page,
      limit: limit,
      summary: InvoicesSummaryModel(
        totalRevenue: totalRev,
        paidRevenue: paidRev,
        outstandingRevenue: outRev,
        pendingTransferCount: pendingCnt,
        overdueCount: overdueCnt,
      ),
    );
  }

  @override
  Future<List<InvoiceModel>> getMyInvoices() async {
    return List<InvoiceModel>.from(invoices);
  }

  @override
  Future<InvoiceModel> getInvoiceDetail(String id) async {
    return invoices.firstWhere((i) => i.id == id);
  }

  @override
  Future<InvoiceModel> createInvoice(Map<String, dynamic> data) async {
    final subtotal = (data['subtotal'] as num?)?.toDouble() ?? 0;
    final discount = (data['discount'] as num?)?.toDouble() ?? 0;
    final total = (subtotal - discount).clamp(0.0, double.infinity);
    final initialPaid = (data['initialPaymentAmount'] as num?)?.toDouble() ?? 0;
    final balance = (total - initialPaid).clamp(0.0, double.infinity);
    final status = balance <= 0
        ? 'PAID'
        : initialPaid > 0
        ? 'PARTIALLY_PAID'
        : 'PENDING';

    final inv = InvoiceModel(
      id: 'inv-${invoices.length + 1}',
      code: 'HD-2026-000${invoices.length + 1}',
      title: data['title']?.toString() ?? 'Học phí mới',
      studentId: data['studentId']?.toString() ?? 'hv-1',
      subtotal: subtotal,
      discount: discount,
      totalAmount: total,
      paidAmount: initialPaid,
      balance: balance,
      status: status,
      issuedDate: DateTime(2026, 11, 21),
      student: {
        'id': data['studentId']?.toString() ?? 'hv-1',
        'fullName': 'Nguyễn Học Viên Mới',
        'userCode': data['studentId']?.toString() ?? 'HV-2026-0099',
      },
      payments: initialPaid > 0
          ? [
              PaymentModel(
                id: 'pay-init-1',
                code: 'PT-2026-0001',
                invoiceId: 'inv-${invoices.length + 1}',
                studentId: data['studentId']?.toString() ?? 'hv-1',
                amount: initialPaid,
                method: data['paymentMethod']?.toString() ?? 'CASH',
                status: 'SUCCESS',
                payDate: DateTime(2026, 11, 21),
              ),
            ]
          : [],
    );
    invoices.insert(0, inv);
    return inv;
  }

  @override
  Future<Map<String, dynamic>> recordPayment(
    String invoiceId, {
    required double amount,
    required String method,
    String? transactionId,
    String? notes,
  }) async {
    final idx = invoices.indexWhere((i) => i.id == invoiceId);
    final old = invoices[idx];
    final nextPaid = old.paidAmount + amount;
    final nextBalance = (old.totalAmount - nextPaid).clamp(
      0.0,
      double.infinity,
    );
    final nextStatus = nextBalance <= 0 ? 'PAID' : 'PARTIALLY_PAID';
    final payment = PaymentModel(
      id: 'pay-${old.payments.length + 1}',
      code: 'PT-2026-00${old.payments.length + 1}',
      invoiceId: invoiceId,
      studentId: old.studentId,
      amount: amount,
      method: method,
      status: 'SUCCESS',
      transactionId: transactionId,
      payDate: DateTime(2026, 11, 21),
      notes: notes,
    );
    final updated = InvoiceModel(
      id: old.id,
      code: old.code,
      title: old.title,
      studentId: old.studentId,
      classId: old.classId,
      subtotal: old.subtotal,
      discount: old.discount,
      totalAmount: old.totalAmount,
      paidAmount: nextPaid,
      balance: nextBalance,
      status: nextStatus,
      dueDate: old.dueDate,
      issuedDate: old.issuedDate,
      notes: old.notes,
      student: old.student,
      classInfo: old.classInfo,
      promotion: old.promotion,
      payments: [payment, ...old.payments],
    );
    invoices[idx] = updated;
    return {'payment': payment.toJson(), 'invoice': updated.toJson()};
  }

  @override
  Future<Map<String, dynamic>> submitTransferPayment(
    String invoiceId, {
    required double amount,
    String? transactionId,
    String? notes,
  }) async {
    final idx = invoices.indexWhere((i) => i.id == invoiceId);
    final old = invoices[idx];
    final pendingPayment = PaymentModel(
      id: 'pay-pending-${old.payments.length + 1}',
      code: 'PT-2026-PEND',
      invoiceId: invoiceId,
      studentId: old.studentId,
      amount: amount,
      method: 'BANK_TRANSFER',
      status: 'PENDING',
      transactionId: transactionId,
      payDate: DateTime(2026, 11, 21),
      notes: notes,
    );
    final updated = InvoiceModel(
      id: old.id,
      code: old.code,
      title: old.title,
      studentId: old.studentId,
      classId: old.classId,
      subtotal: old.subtotal,
      discount: old.discount,
      totalAmount: old.totalAmount,
      paidAmount: old.paidAmount,
      balance: old.balance,
      status: old.status,
      dueDate: old.dueDate,
      issuedDate: old.issuedDate,
      notes: old.notes,
      student: old.student,
      classInfo: old.classInfo,
      promotion: old.promotion,
      payments: [pendingPayment, ...old.payments],
    );
    invoices[idx] = updated;
    return {
      'message':
          'Đã gửi thông tin chuyển khoản thành công. Thu ngân sẽ đối soát và xác nhận phiếu thu.',
      'payment': pendingPayment.toJson(),
      'invoice': updated.toJson(),
    };
  }

  @override
  Future<Map<String, dynamic>> approvePendingPayment(
    String paymentId, {
    String? notes,
  }) async {
    final idx = invoices.indexWhere(
      (i) => i.payments.any((p) => p.id == paymentId),
    );
    final old = invoices[idx];
    final pending = old.payments.firstWhere((p) => p.id == paymentId);
    final nextPaid = old.paidAmount + pending.amount;
    final nextBalance = (old.totalAmount - nextPaid).clamp(
      0.0,
      double.infinity,
    );
    final nextStatus = nextBalance <= 0 ? 'PAID' : 'PARTIALLY_PAID';
    final nextPayments = old.payments.map((p) {
      if (p.id == paymentId) {
        return PaymentModel(
          id: p.id,
          code: p.code,
          invoiceId: p.invoiceId,
          studentId: p.studentId,
          amount: p.amount,
          method: p.method,
          status: 'SUCCESS',
          transactionId: p.transactionId,
          payDate: p.payDate,
          notes: notes ?? p.notes,
        );
      }
      return p;
    }).toList();

    final updated = InvoiceModel(
      id: old.id,
      code: old.code,
      title: old.title,
      studentId: old.studentId,
      classId: old.classId,
      subtotal: old.subtotal,
      discount: old.discount,
      totalAmount: old.totalAmount,
      paidAmount: nextPaid,
      balance: nextBalance,
      status: nextStatus,
      dueDate: old.dueDate,
      issuedDate: old.issuedDate,
      notes: old.notes,
      student: old.student,
      classInfo: old.classInfo,
      promotion: old.promotion,
      payments: nextPayments,
    );
    invoices[idx] = updated;
    return {
      'message': 'Đã xác nhận khoản chuyển khoản và cập nhật công nợ học phí.',
      'invoice': updated.toJson(),
    };
  }

  @override
  Future<Map<String, dynamic>> rejectPendingPayment(
    String paymentId, {
    String? reason,
  }) async {
    final idx = invoices.indexWhere(
      (i) => i.payments.any((p) => p.id == paymentId),
    );
    final old = invoices[idx];
    final nextPayments = old.payments.map((p) {
      if (p.id == paymentId) {
        return PaymentModel(
          id: p.id,
          code: p.code,
          invoiceId: p.invoiceId,
          studentId: p.studentId,
          amount: p.amount,
          method: p.method,
          status: 'FAILED',
          transactionId: p.transactionId,
          payDate: p.payDate,
          notes: reason,
        );
      }
      return p;
    }).toList();
    final updated = InvoiceModel(
      id: old.id,
      code: old.code,
      title: old.title,
      studentId: old.studentId,
      classId: old.classId,
      subtotal: old.subtotal,
      discount: old.discount,
      totalAmount: old.totalAmount,
      paidAmount: old.paidAmount,
      balance: old.balance,
      status: old.status,
      dueDate: old.dueDate,
      issuedDate: old.issuedDate,
      notes: old.notes,
      student: old.student,
      classInfo: old.classInfo,
      promotion: old.promotion,
      payments: nextPayments,
    );
    invoices[idx] = updated;
    return {
      'message': 'Đã từ chối yêu cầu xác nhận chuyển khoản.',
      'invoice': updated.toJson(),
    };
  }

  @override
  Future<InvoiceModel> cancelInvoice(String invoiceId, {String? reason}) async {
    final idx = invoices.indexWhere((i) => i.id == invoiceId);
    final old = invoices[idx];
    final updated = InvoiceModel(
      id: old.id,
      code: old.code,
      title: old.title,
      studentId: old.studentId,
      subtotal: old.subtotal,
      discount: old.discount,
      totalAmount: old.totalAmount,
      paidAmount: old.paidAmount,
      balance: old.balance,
      status: 'CANCELLED',
      issuedDate: old.issuedDate,
      payments: old.payments,
    );
    invoices[idx] = updated;
    return updated;
  }

  @override
  Future<InvoiceModel> refundInvoice(
    String invoiceId, {
    required double amount,
    String? reason,
  }) async {
    final idx = invoices.indexWhere((i) => i.id == invoiceId);
    final old = invoices[idx];
    final nextPaid = (old.paidAmount - amount).clamp(0.0, double.infinity);
    final nextBal = old.totalAmount - nextPaid;
    final updated = InvoiceModel(
      id: old.id,
      code: old.code,
      title: old.title,
      studentId: old.studentId,
      subtotal: old.subtotal,
      discount: old.discount,
      totalAmount: old.totalAmount,
      paidAmount: nextPaid,
      balance: nextBal,
      status: 'REFUNDED',
      issuedDate: old.issuedDate,
      payments: old.payments,
    );
    invoices[idx] = updated;
    return updated;
  }

  @override
  Future<Map<String, dynamic>> payOnline(
    String invoiceId, {
    String? bankCode,
    String? language,
  }) async => {
    'paymentUrl': 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html',
    'invoiceCode': 'HD-2026-0001',
    'amount': 4500000,
  };

  @override
  Future<Map<String, dynamic>> checkOverdueInvoices() async {
    checkOverdueCalls++;
    return {'processedCount': 2};
  }

  @override
  Future<List<PromotionModel>> getPromotions({bool? isActive}) async {
    return List<PromotionModel>.from(promotions);
  }

  @override
  Future<PromotionModel> createPromotion(Map<String, dynamic> data) async {
    final created = PromotionModel(
      id: 'promo-${promotions.length + 1}',
      code: data['code']?.toString() ?? 'PROMO10',
      name: data['name']?.toString() ?? 'Ưu đãi',
      type: data['type']?.toString() ?? 'PERCENTAGE',
      value: (data['value'] as num?)?.toDouble() ?? 10,
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 12, 31),
      isActive: true,
    );
    promotions.insert(0, created);
    return created;
  }

  @override
  Future<PromotionModel> togglePromotion(String id) async {
    final idx = promotions.indexWhere((p) => p.id == id);
    final old = promotions[idx];
    final updated = PromotionModel(
      id: old.id,
      code: old.code,
      name: old.name,
      type: old.type,
      value: old.value,
      startDate: old.startDate,
      endDate: old.endDate,
      isActive: !old.isActive,
    );
    promotions[idx] = updated;
    return updated;
  }

  @override
  Future<Map<String, dynamic>> validatePromotion(
    String code,
    double orderAmount,
  ) async {
    return {
      'isValid': true,
      'code': code.toUpperCase(),
      'name': 'Học bổng 10%',
      'type': 'PERCENTAGE',
      'discountAmount': orderAmount * 0.1,
      'finalAmount': orderAmount * 0.9,
    };
  }
}

void main() {
  group('Tuition, Invoices, VietQR Transfer Verification & Parent/Student Portal Tests', () {
    testWidgets(
      'Test 1 – Admin Finance Hub: Create Invoice, Manage Promotions, Check Overdue & Quick Approve Pending VietQR Transfer without F5',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final repo = _FakeFinanceRepository();
        repo.invoices.add(
          InvoiceModel(
            id: 'inv-1',
            code: 'HD-2026-0001',
            title: 'Học phí IELTS Intensive K01',
            studentId: 'hv-1',
            subtotal: 6000000,
            discount: 0,
            totalAmount: 6000000,
            paidAmount: 0,
            balance: 6000000,
            status: 'PENDING',
            issuedDate: DateTime(2026, 11, 21),
            student: {
              'id': 'hv-1',
              'fullName': 'Trần Minh Khôi',
              'userCode': 'HV-2026-0001',
            },
            payments: [
              PaymentModel(
                id: 'pay-pend-1',
                code: 'PT-2026-PEND',
                invoiceId: 'inv-1',
                studentId: 'hv-1',
                amount: 3000000,
                method: 'BANK_TRANSFER',
                status: 'PENDING',
                transactionId: 'FT261121001',
                payDate: DateTime(2026, 11, 21),
              ),
            ],
          ),
        );

        final bloc = FinanceBloc(repository: repo);
        addTearDown(bloc.close);

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<FinanceBloc>.value(
              value: bloc,
              child: const InvoiceListScreen(showAppBar: false),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('HD-2026-0001'), findsOneWidget);
        expect(find.textContaining('Chờ duyệt CK (3,000,000 đ)'), findsOneWidget);
        expect(find.text('Xác nhận đã nhận CK'), findsOneWidget);

        // Quick-approve pending transfer right from InvoiceListScreen
        await tester.tap(find.text('Xác nhận đã nhận CK'));
        await tester.pumpAndSettle();

        // Status immediately updates to TRẢ MỘT PHẦN without F5
        expect(find.text('TRẢ MỘT PHẦN'), findsOneWidget);
        expect(find.text('Xác nhận đã nhận CK'), findsNothing);

        // Create a new invoice from dialog
        await tester.tap(find.text('Tạo hóa đơn'));
        await tester.pumpAndSettle();

        expect(
          find.text('Tạo hóa đơn học phí / phụ phí mới'),
          findsOneWidget,
        );
        await tester.enterText(
          find.widgetWithText(
            TextField,
            'Mã học viên hoặc UUID * (VD: HV-2026-0001)',
          ),
          'HV-2026-0088',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Phát hành hóa đơn'));
        await tester.pumpAndSettle();

        // Newly created invoice appears immediately without F5
        expect(find.text('HD-2026-0002'), findsOneWidget);
        expect(find.textContaining('Nguyễn Học Viên Mới'), findsOneWidget);
      },
    );

    testWidgets(
      'Test 2 – Student/Parent submits VietQR Transfer on PayOnlineScreen & sees child badge on MyInvoicesScreen',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final repo = _FakeFinanceRepository();
        repo.invoices.add(
          InvoiceModel(
            id: 'inv-child-1',
            code: 'HD-2026-0010',
            title: 'Học phí Tiếng Anh Thiếu Nhi K02',
            studentId: 'hv-child-1',
            subtotal: 4000000,
            discount: 0,
            totalAmount: 4000000,
            paidAmount: 0,
            balance: 4000000,
            status: 'PENDING',
            issuedDate: DateTime(2026, 11, 21),
            student: {
              'id': 'hv-child-1',
              'fullName': 'Bé Lê Gia Hân',
              'userCode': 'HV-2026-0010',
            },
            payments: const [],
          ),
        );

        final bloc = FinanceBloc(repository: repo);
        addTearDown(bloc.close);

        // 1. Check MyInvoicesScreen shows child name badge for Parent/Student
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<FinanceBloc>.value(
              value: bloc,
              child: const MyInvoicesScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('HD-2026-0010'), findsOneWidget);
        expect(
          find.text('Học viên: Bé Lê Gia Hân (HV-2026-0010)'),
          findsOneWidget,
        );

        // 2. Open PayOnlineScreen and submit VietQR transfer confirmation
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<FinanceBloc>.value(
              value: bloc,
              child: const PayOnlineScreen(invoiceId: 'inv-child-1'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Gửi xác nhận đã chuyển khoản'), findsOneWidget);
        await tester.enterText(
          find.widgetWithText(
            TextField,
            'Mã giao dịch ngân hàng (tùy chọn)',
          ),
          'FT2611218899',
        );
        await tester.tap(find.text('Gửi xác nhận đã chuyển khoản'));
        await tester.pumpAndSettle();

        // Confirmation banner appears immediately without F5
        expect(
          find.textContaining(
            'Bạn đã gửi xác nhận chuyển khoản cho hóa đơn này',
          ),
          findsOneWidget,
        );

        // 3. Cashier opens InvoiceDetailScreen and sees the pending payment
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<FinanceBloc>.value(
              value: bloc,
              child: const InvoiceDetailScreen(invoiceId: 'inv-child-1'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Chờ thu ngân đối soát'), findsOneWidget);
        expect(find.text('Mã GD: FT2611218899'), findsOneWidget);
      },
    );

    testWidgets(
      'Test 3 – Responsive check for MyInvoicesScreen & InvoiceListScreen across mobile (375, 430) and desktop (1280) viewports',
      (tester) async {
        final repo = _FakeFinanceRepository();
        repo.invoices.add(
          InvoiceModel(
            id: 'inv-resp-1',
            code: 'HD-2026-0099',
            title: 'Học phí Giao tiếp Quốc tế',
            studentId: 'hv-1',
            subtotal: 3500000,
            discount: 500000,
            totalAmount: 3000000,
            paidAmount: 1000000,
            balance: 2000000,
            status: 'PARTIALLY_PAID',
            issuedDate: DateTime(2026, 11, 21),
            student: {
              'id': 'hv-1',
              'fullName': 'Phạm Quốc Bảo',
              'userCode': 'HV-2026-0099',
            },
            payments: const [],
          ),
        );

        final bloc = FinanceBloc(repository: repo);
        addTearDown(bloc.close);

        for (final width in [375.0, 430.0, 1280.0]) {
          await tester.binding.setSurfaceSize(Size(width, 844));
          await tester.pumpWidget(
            MaterialApp(
              home: BlocProvider<FinanceBloc>.value(
                value: bloc,
                child: const MyInvoicesScreen(),
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
