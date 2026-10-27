import '../../domain/repositories/finance_repository.dart';
import '../datasources/finance_remote_datasource.dart';
import '../models/invoice_model.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  final FinanceRemoteDataSource remoteDataSource;

  FinanceRepositoryImpl({required this.remoteDataSource});

  @override
  Future<InvoicesResponseModel> getInvoices({
    String? status,
    String? search,
    String? studentId,
    String? classId,
    int page = 1,
    int limit = 20,
  }) {
    return remoteDataSource.getInvoices(
      status: status,
      search: search,
      studentId: studentId,
      classId: classId,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<List<InvoiceModel>> getMyInvoices() {
    return remoteDataSource.getMyInvoices();
  }

  @override
  Future<InvoiceModel> getInvoiceDetail(String id) {
    return remoteDataSource.getInvoiceDetail(id);
  }

  @override
  Future<InvoiceModel> createInvoice(Map<String, dynamic> data) {
    return remoteDataSource.createInvoice(data);
  }

  @override
  Future<Map<String, dynamic>> recordPayment(
    String invoiceId, {
    required double amount,
    required String method,
    String? transactionId,
    String? notes,
  }) {
    return remoteDataSource.recordPayment(
      invoiceId,
      amount: amount,
      method: method,
      transactionId: transactionId,
      notes: notes,
    );
  }

  @override
  Future<InvoiceModel> cancelInvoice(String invoiceId, {String? reason}) {
    return remoteDataSource.cancelInvoice(invoiceId, reason: reason);
  }

  @override
  Future<InvoiceModel> refundInvoice(
    String invoiceId, {
    required double amount,
    String? reason,
  }) {
    return remoteDataSource.refundInvoice(
      invoiceId,
      amount: amount,
      reason: reason,
    );
  }

  @override
  Future<Map<String, dynamic>> payOnline(
    String invoiceId, {
    String? bankCode,
    String? language,
  }) {
    return remoteDataSource.payOnline(
      invoiceId,
      bankCode: bankCode,
      language: language,
    );
  }

  @override
  Future<List<PromotionModel>> getPromotions({bool? isActive}) {
    return remoteDataSource.getPromotions(isActive: isActive);
  }

  @override
  Future<Map<String, dynamic>> validatePromotion(String code, double orderAmount) {
    return remoteDataSource.validatePromotion(code, orderAmount);
  }
}
