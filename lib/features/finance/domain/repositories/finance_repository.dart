import '../../data/models/invoice_model.dart';

abstract class FinanceRepository {
  Future<InvoicesResponseModel> getInvoices({
    String? status,
    String? search,
    String? studentId,
    String? classId,
    String? branchId,
    bool? pendingTransferOnly,
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
  Future<Map<String, dynamic>> submitTransferPayment(
    String invoiceId, {
    required double amount,
    String? transactionId,
    String? notes,
  });
  Future<Map<String, dynamic>> approvePendingPayment(
    String paymentId, {
    String? notes,
  });
  Future<Map<String, dynamic>> rejectPendingPayment(
    String paymentId, {
    String? reason,
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
  Future<Map<String, dynamic>> checkOverdueInvoices();
  Future<List<PromotionModel>> getPromotions({bool? isActive});
  Future<PromotionModel> createPromotion(Map<String, dynamic> data);
  Future<PromotionModel> togglePromotion(String id);
  Future<Map<String, dynamic>> validatePromotion(String code, double orderAmount);
}
