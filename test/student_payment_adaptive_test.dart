import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/data/models/invoice_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/domain/repositories/finance_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/presentation/screens/pay_online_screen.dart';

class _FinanceRepository implements FinanceRepository {
  @override
  Future<InvoiceModel> getInvoiceDetail(String id) async =>
      InvoiceModel.fromJson({
        'id': id,
        'code': 'HD-001',
        'title': 'Học phí IELTS',
        'studentId': 'student-1',
        'subtotal': 4000000,
        'discount': 0,
        'totalAmount': 4000000,
        'paidAmount': 1000000,
        'balance': 3000000,
        'status': 'PARTIALLY_PAID',
        'issuedDate': '2026-10-28',
      });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final width in [320.0, 375.0, 393.0, 430.0, 800.0, 1200.0]) {
    testWidgets('thanh toán thích ứng ở $width px', (tester) async {
      tester.view.physicalSize = Size(width, 950);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bloc = FinanceBloc(repository: _FinanceRepository());
      addTearDown(bloc.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: const MaterialApp(
            home: PayOnlineScreen(invoiceId: 'invoice-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Số tiền cần thanh toán'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('payment-methods-mobile')),
        width < 600 ? findsOneWidget : findsNothing,
      );
      if (width < 600) {
        final vnpayChip = find.widgetWithText(ChoiceChip, 'Cổng VNPay');
        await Scrollable.ensureVisible(tester.element(vnpayChip));
        await tester.pumpAndSettle();
        await tester.tap(vnpayChip);
        await tester.pumpAndSettle();
        expect(find.text('Tạo liên kết thanh toán VNPay'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
