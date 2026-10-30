import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/data/models/invoice_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/domain/repositories/finance_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/presentation/screens/my_invoices_screen.dart';

class _Finance implements FinanceRepository {
  @override
  Future<List<InvoiceModel>> getMyInvoices() async => [
    InvoiceModel.fromJson({
      'id': 'invoice-1',
      'code': 'HD-001',
      'title': 'Học phí IELTS',
      'studentId': 'student-1',
      'totalAmount': 4000000,
      'paidAmount': 1000000,
      'balance': 3000000,
      'status': 'PARTIALLY_PAID',
      'issuedDate': '2026-10-27',
      'dueDate': '2026-11-01',
      'class': {'name': 'IELTS Foundation'},
    }),
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final width in [320.0, 375.0, 393.0, 430.0, 800.0, 1200.0]) {
    testWidgets('học phí thích ứng ở $width px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bloc = FinanceBloc(repository: _Finance());
      addTearDown(bloc.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: const MaterialApp(home: MyInvoicesScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('HD-001'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('student-invoices-mobile')),
        width < 600 ? findsOneWidget : findsNothing,
      );
      if (width < 600) {
        expect(find.text('3,000,000 đ'), findsWidgets);
        final paidFilter = find.widgetWithText(ChoiceChip, 'Đã thanh toán');
        await Scrollable.ensureVisible(
          tester.element(paidFilter),
          alignment: 0.5,
        );
        await tester.pumpAndSettle();
        await tester.tap(paidFilter);
        await tester.pumpAndSettle();
        expect(find.text('HD-001'), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
