import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/domain/entities/user_entity.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/domain/repositories/auth_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/presentation/bloc/auth_event.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/presentation/bloc/auth_state.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/data/models/invoice_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/domain/repositories/finance_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/presentation/screens/invoice_detail_screen.dart';

class _AuthRepository implements AuthRepository {
  @override
  Future<bool> isLoggedIn() async => true;

  @override
  Future<UserEntity> getMe() async => const UserEntity(
    id: 'student-1',
    userCode: 'HV001',
    fullName: 'Học viên',
    status: 'ACTIVE',
    isFirstLogin: false,
    roles: ['student'],
    permissions: [],
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
        'dueDate': '2026-11-01',
        'class': {'name': 'IELTS Foundation'},
        'payments': [
          {
            'id': 'p1',
            'code': 'PT-001',
            'invoiceId': id,
            'studentId': 'student-1',
            'amount': 1000000,
            'method': 'BANK_TRANSFER',
            'payDate': '2026-10-28',
          },
        ],
      });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final width in [320.0, 375.0, 393.0, 430.0, 800.0, 1200.0]) {
    testWidgets('chi tiết học phí thích ứng ở $width px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final authBloc = AuthBloc(authRepository: _AuthRepository());
      final financeBloc = FinanceBloc(repository: _FinanceRepository());
      addTearDown(authBloc.close);
      addTearDown(financeBloc.close);
      authBloc.add(CheckAuthStatusEvent());
      await authBloc.stream.firstWhere((state) => state is AuthenticatedState);
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<FinanceBloc>.value(value: financeBloc),
          ],
          child: const MaterialApp(
            home: InvoiceDetailScreen(invoiceId: 'invoice-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('HD-001'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('invoice-detail-mobile')),
        width < 600 ? findsOneWidget : findsNothing,
      );
      expect(find.text('Thu tiền mặt / CK'), findsNothing);
      expect(find.text('Hủy hóa đơn này'), findsNothing);
      if (width < 600) {
        expect(find.text('Thanh toán trực tuyến'), findsOneWidget);
        expect(find.text('PT-001'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
