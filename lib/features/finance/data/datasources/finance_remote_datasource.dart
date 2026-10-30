import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/invoice_model.dart';

abstract class FinanceRemoteDataSource {
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

class FinanceRemoteDataSourceImpl implements FinanceRemoteDataSource {
  final ApiClient apiClient;

  FinanceRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<InvoicesResponseModel> getInvoices({
    String? status,
    String? search,
    String? studentId,
    String? classId,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (studentId != null && studentId.isNotEmpty) queryParams['studentId'] = studentId;
    if (classId != null && classId.isNotEmpty) queryParams['classId'] = classId;

    final response = await apiClient.get(
      ApiEndpoints.invoices,
      queryParameters: queryParams,
    );
    final data = response is Map<String, dynamic> ? (response['data'] ?? response) : response;
    return InvoicesResponseModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<List<InvoiceModel>> getMyInvoices() async {
    final response = await apiClient.get(ApiEndpoints.myInvoices);
    final data = response is Map<String, dynamic> ? (response['data'] ?? response) : response;
    final list = data is List
        ? data
        : (data is Map<String, dynamic> && data['items'] is List ? data['items'] as List : []);
    return list
        .map((e) => InvoiceModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<InvoiceModel> getInvoiceDetail(String id) async {
    final response = await apiClient.get(ApiEndpoints.invoiceDetail(id));
    final data = response is Map<String, dynamic> ? (response['data'] ?? response) : response;
    return InvoiceModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<InvoiceModel> createInvoice(Map<String, dynamic> data) async {
    final response = await apiClient.post(ApiEndpoints.invoices, data: data);
    final resData = response is Map<String, dynamic> ? (response['data'] ?? response) : response;
    return InvoiceModel.fromJson(Map<String, dynamic>.from(resData as Map));
  }

  @override
  Future<Map<String, dynamic>> recordPayment(
    String invoiceId, {
    required double amount,
    required String method,
    String? transactionId,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'amount': amount,
      'method': method,
    };
    if (transactionId != null) {
      body['transactionId'] = transactionId;
    }
    if (notes != null) {
      body['notes'] = notes;
    }
    final response = await apiClient.post(
      ApiEndpoints.recordPayment(invoiceId),
      data: body,
    );
    final data = response is Map<String, dynamic> ? (response['data'] ?? response) : response;
    return Map<String, dynamic>.from(data as Map);
  }

  @override
  Future<InvoiceModel> cancelInvoice(String invoiceId, {String? reason}) async {
    final response = await apiClient.post(
      ApiEndpoints.cancelInvoice(invoiceId),
      data: {'reason': reason},
    );
    final data = response is Map<String, dynamic> ? (response['data'] ?? response) : response;
    return InvoiceModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<InvoiceModel> refundInvoice(
    String invoiceId, {
    required double amount,
    String? reason,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.refundInvoice(invoiceId),
      data: {'amount': amount, 'reason': reason},
    );
    final data = response is Map<String, dynamic> ? (response['data'] ?? response) : response;
    return InvoiceModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<Map<String, dynamic>> payOnline(
    String invoiceId, {
    String? bankCode,
    String? language,
  }) async {
    final body = <String, dynamic>{};
    if (bankCode != null) {
      body['bankCode'] = bankCode;
    }
    if (language != null) {
      body['language'] = language;
    }
    final response = await apiClient.post(
      ApiEndpoints.payOnline(invoiceId),
      data: body,
    );
    final data = response is Map<String, dynamic> ? (response['data'] ?? response) : response;
    return Map<String, dynamic>.from(data as Map);
  }

  @override
  Future<List<PromotionModel>> getPromotions({bool? isActive}) async {
    final queryParams = <String, dynamic>{};
    if (isActive != null) queryParams['isActive'] = isActive;

    final response = await apiClient.get(
      ApiEndpoints.promotions,
      queryParameters: queryParams,
    );
    final data = response is Map<String, dynamic> ? (response['data'] ?? response) : response;
    final list = data is List
        ? data
        : (data is Map<String, dynamic> && data['items'] is List ? data['items'] as List : []);
    return list
        .map((e) => PromotionModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> validatePromotion(String code, double orderAmount) async {
    final response = await apiClient.post(
      ApiEndpoints.validatePromotion,
      data: {'code': code, 'orderAmount': orderAmount},
    );
    final data = response is Map<String, dynamic> ? (response['data'] ?? response) : response;
    return Map<String, dynamic>.from(data as Map);
  }
}
