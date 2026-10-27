class InvoiceModel {
  final String id;
  final String code;
  final String title;
  final String studentId;
  final String? classId;
  final double subtotal;
  final double discount;
  final double totalAmount;
  final double paidAmount;
  final double balance;
  final String status;
  final DateTime? dueDate;
  final DateTime issuedDate;
  final String? notes;
  final Map<String, dynamic>? student;
  final Map<String, dynamic>? classInfo;
  final PromotionModel? promotion;
  final List<PaymentModel> payments;

  InvoiceModel({
    required this.id,
    required this.code,
    required this.title,
    required this.studentId,
    this.classId,
    required this.subtotal,
    required this.discount,
    required this.totalAmount,
    required this.paidAmount,
    required this.balance,
    required this.status,
    this.dueDate,
    required this.issuedDate,
    this.notes,
    this.student,
    this.classInfo,
    this.promotion,
    required this.payments,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      classId: json['classId'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'PENDING',
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate'].toString()) : null,
      issuedDate: json['issuedDate'] != null
          ? DateTime.tryParse(json['issuedDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      notes: json['notes'] as String?,
      student: json['student'] != null ? Map<String, dynamic>.from(json['student'] as Map) : null,
      classInfo: json['class'] != null ? Map<String, dynamic>.from(json['class'] as Map) : null,
      promotion: json['promotion'] != null
          ? PromotionModel.fromJson(Map<String, dynamic>.from(json['promotion'] as Map))
          : null,
      payments: json['payments'] != null
          ? (json['payments'] as List<dynamic>)
              .map((p) => PaymentModel.fromJson(Map<String, dynamic>.from(p as Map)))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'studentId': studentId,
      'classId': classId,
      'subtotal': subtotal,
      'discount': discount,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'balance': balance,
      'status': status,
      'dueDate': dueDate?.toIso8601String(),
      'issuedDate': issuedDate.toIso8601String(),
      'notes': notes,
      'student': student,
      'class': classInfo,
      'promotion': promotion?.toJson(),
      'payments': payments.map((p) => p.toJson()).toList(),
    };
  }
}

class PaymentModel {
  final String id;
  final String code;
  final String invoiceId;
  final String studentId;
  final double amount;
  final String method;
  final String status;
  final String? transactionId;
  final DateTime payDate;
  final String? notes;
  final Map<String, dynamic>? receivedBy;

  PaymentModel({
    required this.id,
    required this.code,
    required this.invoiceId,
    required this.studentId,
    required this.amount,
    required this.method,
    required this.status,
    this.transactionId,
    required this.payDate,
    this.notes,
    this.receivedBy,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      invoiceId: json['invoiceId'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      method: json['method'] as String? ?? 'CASH',
      status: json['status'] as String? ?? 'SUCCESS',
      transactionId: json['transactionId'] as String?,
      payDate: json['payDate'] != null
          ? DateTime.tryParse(json['payDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      notes: json['notes'] as String?,
      receivedBy: json['receivedBy'] != null
          ? Map<String, dynamic>.from(json['receivedBy'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'invoiceId': invoiceId,
      'studentId': studentId,
      'amount': amount,
      'method': method,
      'status': status,
      'transactionId': transactionId,
      'payDate': payDate.toIso8601String(),
      'notes': notes,
      'receivedBy': receivedBy,
    };
  }
}

class PromotionModel {
  final String id;
  final String code;
  final String name;
  final String? description;
  final String type;
  final double value;
  final double? minOrderValue;
  final double? maxDiscount;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  PromotionModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.type,
    required this.value,
    this.minOrderValue,
    this.maxDiscount,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      type: json['type'] as String? ?? 'PERCENTAGE',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      minOrderValue: (json['minOrderValue'] as num?)?.toDouble(),
      maxDiscount: (json['maxDiscount'] as num?)?.toDouble(),
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'type': type,
      'value': value,
      'minOrderValue': minOrderValue,
      'maxDiscount': maxDiscount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
    };
  }
}

class InvoicesSummaryModel {
  final double totalRevenue;
  final double paidRevenue;
  final double outstandingRevenue;

  InvoicesSummaryModel({
    required this.totalRevenue,
    required this.paidRevenue,
    required this.outstandingRevenue,
  });

  factory InvoicesSummaryModel.fromJson(Map<String, dynamic> json) {
    return InvoicesSummaryModel(
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      paidRevenue: (json['paidRevenue'] as num?)?.toDouble() ?? 0.0,
      outstandingRevenue: (json['outstandingRevenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class InvoicesResponseModel {
  final List<InvoiceModel> items;
  final int total;
  final int page;
  final int limit;
  final InvoicesSummaryModel summary;

  InvoicesResponseModel({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.summary,
  });

  factory InvoicesResponseModel.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List<dynamic>? ?? [];
    return InvoicesResponseModel(
      items: list.map((e) => InvoiceModel.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      summary: json['summary'] != null
          ? InvoicesSummaryModel.fromJson(Map<String, dynamic>.from(json['summary'] as Map))
          : InvoicesSummaryModel(totalRevenue: 0, paidRevenue: 0, outstandingRevenue: 0),
    );
  }
}
