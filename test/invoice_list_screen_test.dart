import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/domain/repositories/finance_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/data/models/invoice_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/finance/presentation/screens/invoice_list_screen.dart';

class FakeFinanceRepository implements FinanceRepository {
  @override
  Future<InvoicesResponseModel> getInvoices({
    String? status,
    String? search,
    String? studentId,
    String? classId,
    int page = 1,
    int limit = 20,
  }) async {
    return InvoicesResponseModel(
      items: [
        InvoiceModel(
          id: 'inv-1',
          code: 'HD-2026-0001',
          title: 'Học phí IELTS Foundation K01',
          studentId: 'student-1',
          subtotal: 5000000,
          discount: 500000,
          totalAmount: 4500000,
          paidAmount: 2000000,
          balance: 2500000,
          status: 'PARTIALLY_PAID',
          issuedDate: DateTime(2026, 10, 15),
          dueDate: DateTime(2026, 10, 30),
          student: {'fullName': 'Trần Văn Nam', 'userCode': 'HV-2026-0001'},
          classInfo: {'name': 'IELTS Foundation'},
          payments: [],
        ),
      ],
      total: 1,
      page: 1,
      limit: 20,
      summary: InvoicesSummaryModel(
        totalRevenue: 4500000,
        paidRevenue: 2000000,
        outstandingRevenue: 2500000,
      ),
    );
  }

  @override
  Future<List<InvoiceModel>> getMyInvoices() async {
    return [];
  }

  @override
  Future<InvoiceModel> getInvoiceDetail(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<InvoiceModel> createInvoice(Map<String, dynamic> data) async {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> recordPayment(
    String invoiceId, {
    required double amount,
    required String method,
    String? transactionId,
    String? notes,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<InvoiceModel> cancelInvoice(String invoiceId, {String? reason}) async {
    throw UnimplementedError();
  }

  @override
  Future<InvoiceModel> refundInvoice(
    String invoiceId, {
    required double amount,
    String? reason,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> payOnline(
    String invoiceId, {
    String? bankCode,
    String? language,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<PromotionModel>> getPromotions({bool? isActive}) async {
    return [];
  }

  @override
  Future<Map<String, dynamic>> validatePromotion(String code, double orderAmount) async {
    throw UnimplementedError();
  }
}

void main() {
  testWidgets('InvoiceListScreen renders metrics summary and invoice card', (tester) async {
    final fakeRepo = FakeFinanceRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<FinanceBloc>(
          create: (_) => FinanceBloc(repository: fakeRepo),
          child: const InvoiceListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Metrics
    expect(find.text('Quản lý Học phí & Hóa đơn'), findsOneWidget);
    expect(find.text('Tổng hóa đơn'), findsOneWidget);
    expect(find.text('Đã thu'), findsOneWidget);
    expect(find.text('Còn nợ'), findsOneWidget);

    // Verify Invoice item
    expect(find.text('HD-2026-0001'), findsOneWidget);
    expect(find.text('Trần Văn Nam (HV-2026-0001)'), findsOneWidget);
  });
}
