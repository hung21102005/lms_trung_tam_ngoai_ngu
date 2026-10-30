import '../../data/models/invoice_model.dart';

abstract class FinanceRepository {
  Future<InvoicesResponseModel> getInvoices({
    String? status,
    String? search,
    String? studentId,
    String? classId,
    int page = 1,
    int limit = 20,
  });
  Future<List<InvoiceModel>> getMyInvoices();
  Future<InvoiceModel> getInvoiceDetail(String id);
  Future<InvoiceModel> createInvoice(Map<String, dynamic> data);
  Future<Map<String, dynamic>> recordPayment(
    String invoiceId, {
    required double amount,
    required String method,
    String? transactionId,
    String? notes,
  });
  Future<InvoiceModel> cancelInvoice(String invoiceId, {String? reason});
  Future<InvoiceModel> refundInvoice(
    String invoiceId, {
    required double amount,
    String? reason,
  });
  Future<Map<String, dynamic>> payOnline(
    String invoiceId, {
    String? bankCode,
    String? language,
  });
  Future<List<PromotionModel>> getPromotions({bool? isActive});
  Future<Map<String, dynamic>> validatePromotion(String code, double orderAmount);
}
