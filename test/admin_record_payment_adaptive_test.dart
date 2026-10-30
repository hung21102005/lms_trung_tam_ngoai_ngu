import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/data/models/invoice_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/domain/repositories/finance_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/presentation/screens/record_payment_screen.dart';

class _FinanceRepository extends Fake implements FinanceRepository {
  _FinanceRepository({this.fail = false, this.loadFail = false, this.loadGate});
  final bool fail;
  final bool loadFail;
  final Completer<void>? loadGate;
  double? recordedAmount;
  String? recordedMethod;
  String? recordedInvoiceId;

  @override
  Future<InvoiceModel> getInvoiceDetail(String id) async {
    if (loadGate != null) await loadGate!.future;
    if (loadFail) throw StateError('Không tải được hóa đơn');
    return InvoiceModel(
      id: id,
      code: 'HD-2026-01',
      title: 'Học phí khóa IELTS Foundation với tên hóa đơn dài',
      studentId: 'student-1',
      subtotal: 2000000,
      discount: 0,
      totalAmount: 2000000,
      paidAmount: 0,
      balance: 2000000,
      status: 'PENDING',
      issuedDate: DateTime(2026, 10, 28),
      payments: const [],
    );
  }

  @override
  Future<Map<String, dynamic>> recordPayment(
    String invoiceId, {
    required double amount,
    required String method,
    String? transactionId,
    String? notes,
  }) async {
    recordedInvoiceId = invoiceId;
    recordedAmount = amount;
    recordedMethod = method;
    if (fail) throw StateError('Không thể ghi nhận thanh toán');
    return {'id': 'payment-1'};
  }
}

Widget _app(_FinanceRepository repository) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/record'),
            child: const Text('Mở thu tiền'),
          ),
        ),
      ),
      GoRoute(
        path: '/record',
        builder: (_, _) => const RecordPaymentScreen(invoiceId: 'invoice-1'),
      ),
    ],
  );
  return BlocProvider(
    create: (_) => FinanceBloc(repository: repository),
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _open(WidgetTester tester, _FinanceRepository repository) async {
  await tester.pumpWidget(_app(repository));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Mở thu tiền'));
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 375.0, 393.0, 430.0, 800.0, 1200.0]) {
    testWidgets('record payment $width px', (tester) async {
      tester.view.physicalSize = Size(width, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _open(tester, _FinanceRepository());
      expect(find.textContaining('HD-2026-01'), findsWidgets);
      expect(
        find.byKey(const ValueKey('record-payment-mobile')),
        width < 1024 ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('mobile validates balance with keyboard and records payment', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FinanceRepository();
    await _open(tester, repository);
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Ghi nhận thanh toán'));
    await tester.pumpAndSettle();
    expect(repository.recordedAmount, 2000000);
    expect(repository.recordedMethod, 'CASH');
    expect(repository.recordedInvoiceId, 'invoice-1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile rejects overpayment without calling repository', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FinanceRepository();
    await _open(tester, repository);
    await tester.enterText(find.byType(TextFormField).first, '3000000');
    await tester.tap(find.widgetWithText(FilledButton, 'Ghi nhận thanh toán'));
    await tester.pumpAndSettle();
    expect(repository.recordedAmount, isNull);
    expect(find.textContaining('Số tiền vượt quá số dư'), findsOneWidget);
  });

  testWidgets('mobile keeps form after API save error', (tester) async {
    tester.view.physicalSize = const Size(375, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _open(tester, _FinanceRepository(fail: true));
    await tester.tap(find.widgetWithText(FilledButton, 'Ghi nhận thanh toán'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Không thể ghi nhận thanh toán'), findsWidgets);
    expect(find.byKey(const ValueKey('record-payment-mobile')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile shows invoice loading and fetch error', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final gate = Completer<void>();
    final repository = _FinanceRepository(loadFail: true, loadGate: gate);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mở thu tiền'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Tải lại hóa đơn'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
