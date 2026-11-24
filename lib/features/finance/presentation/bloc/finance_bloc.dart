import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/invoice_model.dart';
import '../../domain/repositories/finance_repository.dart';

// EVENTS
abstract class FinanceEvent {}

class FetchInvoicesEvent extends FinanceEvent {
  final String? status;
  final String? search;
  final String? studentId;
  final String? classId;
  final String? branchId;
  final bool? pendingTransferOnly;
  final int page;

  FetchInvoicesEvent({
    this.status,
    this.search,
    this.studentId,
    this.classId,
    this.branchId,
    this.pendingTransferOnly,
    this.page = 1,
  });
}

class FetchMyInvoicesEvent extends FinanceEvent {}

class FetchInvoiceDetailEvent extends FinanceEvent {
  final String id;

  FetchInvoiceDetailEvent(this.id);
}

class CreateInvoiceEvent extends FinanceEvent {
  final Map<String, dynamic> data;

  CreateInvoiceEvent(this.data);
}

class RecordPaymentEvent extends FinanceEvent {
  final String invoiceId;
  final double amount;
  final String method;
  final String? transactionId;
  final String? notes;

  RecordPaymentEvent({
    required this.invoiceId,
    required this.amount,
    required this.method,
    this.transactionId,
    this.notes,
  });
}

class SubmitTransferPaymentEvent extends FinanceEvent {
  final String invoiceId;
  final double amount;
  final String? transactionId;
  final String? notes;

  SubmitTransferPaymentEvent({
    required this.invoiceId,
    required this.amount,
    this.transactionId,
    this.notes,
  });
}

class ApprovePendingPaymentEvent extends FinanceEvent {
  final String paymentId;
  final String invoiceId;
  final String? notes;

  ApprovePendingPaymentEvent({
    required this.paymentId,
    required this.invoiceId,
    this.notes,
  });
}

class RejectPendingPaymentEvent extends FinanceEvent {
  final String paymentId;
  final String invoiceId;
  final String? reason;

  RejectPendingPaymentEvent({
    required this.paymentId,
    required this.invoiceId,
    this.reason,
  });
}

class CheckOverdueInvoicesEvent extends FinanceEvent {}

class FetchPromotionsEvent extends FinanceEvent {
  final bool? isActive;

  FetchPromotionsEvent({this.isActive});
}

class CreatePromotionEvent extends FinanceEvent {
  final Map<String, dynamic> data;

  CreatePromotionEvent(this.data);
}

class TogglePromotionEvent extends FinanceEvent {
  final String id;

  TogglePromotionEvent(this.id);
}

class CancelInvoiceEvent extends FinanceEvent {
  final String invoiceId;
  final String? reason;

  CancelInvoiceEvent(this.invoiceId, {this.reason});
}

class RefundInvoiceEvent extends FinanceEvent {
  final String invoiceId;
  final double amount;
  final String? reason;

  RefundInvoiceEvent(this.invoiceId, {required this.amount, this.reason});
}

class PayOnlineEvent extends FinanceEvent {
  final String invoiceId;
  final String? bankCode;
  final String? language;

  PayOnlineEvent(this.invoiceId, {this.bankCode, this.language});
}

class ValidatePromotionEvent extends FinanceEvent {
  final String code;
  final double orderAmount;

  ValidatePromotionEvent({required this.code, required this.orderAmount});
}

// STATES
abstract class FinanceState {}

class FinanceInitialState extends FinanceState {}

class FinanceLoadingState extends FinanceState {}

class InvoicesLoadedState extends FinanceState {
  final InvoicesResponseModel response;

  InvoicesLoadedState(this.response);
}

class MyInvoicesLoadedState extends FinanceState {
  final List<InvoiceModel> invoices;

  MyInvoicesLoadedState(this.invoices);
}

class InvoiceDetailLoadedState extends FinanceState {
  final InvoiceModel invoice;

  InvoiceDetailLoadedState(this.invoice);
}

class InvoiceCreatedSuccessState extends FinanceState {
  final InvoiceModel invoice;

  InvoiceCreatedSuccessState(this.invoice);
}

class PaymentRecordedSuccessState extends FinanceState {
  final Map<String, dynamic> result;

  PaymentRecordedSuccessState(this.result);
}

class PayOnlineUrlReadyState extends FinanceState {
  final String paymentUrl;
  final String invoiceCode;
  final double amount;

  PayOnlineUrlReadyState({
    required this.paymentUrl,
    required this.invoiceCode,
    required this.amount,
  });
}

class PromotionValidatedState extends FinanceState {
  final Map<String, dynamic> promoData;

  PromotionValidatedState(this.promoData);
}

class PromotionsLoadedState extends FinanceState {
  final List<PromotionModel> promotions;

  PromotionsLoadedState(this.promotions);
}

class FinanceActionSuccessState extends FinanceState {
  final String message;

  FinanceActionSuccessState(this.message);
}

class FinanceErrorState extends FinanceState {
  final String message;

  FinanceErrorState(this.message);
}

// BLOC
class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {
  final FinanceRepository repository;
  InvoicesResponseModel? _cachedInvoicesResponse;
  List<InvoiceModel> _cachedMyInvoices = [];
  List<PromotionModel> _cachedPromotions = [];
  final Map<String, InvoiceModel> _cachedInvoiceDetails = {};
  FetchInvoicesEvent? _lastFetchInvoicesEvent;

  InvoicesResponseModel? get cachedInvoicesResponse => _cachedInvoicesResponse;
  List<InvoiceModel> get cachedMyInvoices => _cachedMyInvoices;
  List<PromotionModel> get cachedPromotions => _cachedPromotions;
  InvoiceModel? getCachedInvoiceDetail(String id) => _cachedInvoiceDetails[id];

  FinanceBloc({required this.repository}) : super(FinanceInitialState()) {
    on<FetchInvoicesEvent>(_onFetchInvoices);
    on<FetchMyInvoicesEvent>(_onFetchMyInvoices);
    on<FetchInvoiceDetailEvent>(_onFetchInvoiceDetail);
    on<CreateInvoiceEvent>(_onCreateInvoice);
    on<RecordPaymentEvent>(_onRecordPayment);
    on<SubmitTransferPaymentEvent>(_onSubmitTransferPayment);
    on<ApprovePendingPaymentEvent>(_onApprovePendingPayment);
    on<RejectPendingPaymentEvent>(_onRejectPendingPayment);
    on<CancelInvoiceEvent>(_onCancelInvoice);
    on<RefundInvoiceEvent>(_onRefundInvoice);
    on<PayOnlineEvent>(_onPayOnline);
    on<CheckOverdueInvoicesEvent>(_onCheckOverdueInvoices);
    on<FetchPromotionsEvent>(_onFetchPromotions);
    on<CreatePromotionEvent>(_onCreatePromotion);
    on<TogglePromotionEvent>(_onTogglePromotion);
    on<ValidatePromotionEvent>(_onValidatePromotion);
  }

  void _syncCachedInvoice(InvoiceModel updated) {
    _cachedInvoiceDetails[updated.id] = updated;
    if (_cachedMyInvoices.any((i) => i.id == updated.id)) {
      _cachedMyInvoices = _cachedMyInvoices
          .map((i) => i.id == updated.id ? updated : i)
          .toList();
    }
    if (_cachedInvoicesResponse != null) {
      final items = _cachedInvoicesResponse!.items
          .map((i) => i.id == updated.id ? updated : i)
          .toList();
      _cachedInvoicesResponse = InvoicesResponseModel(
        items: items,
        total: _cachedInvoicesResponse!.total,
        page: _cachedInvoicesResponse!.page,
        limit: _cachedInvoicesResponse!.limit,
        summary: _cachedInvoicesResponse!.summary,
      );
    }
  }

  Future<void> _refreshInvoicesSilently(Emitter<FinanceState> emit) async {
    try {
      final lastEvent = _lastFetchInvoicesEvent;
      final response = await repository.getInvoices(
        status: lastEvent?.status,
        search: lastEvent?.search,
        studentId: lastEvent?.studentId,
        classId: lastEvent?.classId,
        branchId: lastEvent?.branchId,
        pendingTransferOnly: lastEvent?.pendingTransferOnly,
        page: lastEvent?.page ?? 1,
      );
      _cachedInvoicesResponse = response;
      for (final item in response.items) {
        _cachedInvoiceDetails[item.id] = item;
      }
      emit(InvoicesLoadedState(response));
    } catch (_) {
      if (_cachedInvoicesResponse != null) {
        emit(InvoicesLoadedState(_cachedInvoicesResponse!));
      }
    }
  }

  Future<void> _onFetchInvoices(
    FetchInvoicesEvent event,
    Emitter<FinanceState> emit,
  ) async {
    _lastFetchInvoicesEvent = event;
    if (_cachedInvoicesResponse == null) {
      emit(FinanceLoadingState());
    }
    try {
      final response = await repository.getInvoices(
        status: event.status,
        search: event.search,
        studentId: event.studentId,
        classId: event.classId,
        branchId: event.branchId,
        pendingTransferOnly: event.pendingTransferOnly,
        page: event.page,
      );
      _cachedInvoicesResponse = response;
      for (final item in response.items) {
        _cachedInvoiceDetails[item.id] = item;
      }
      emit(InvoicesLoadedState(response));
    } catch (e) {
      emit(FinanceErrorState(e.toString()));
      if (_cachedInvoicesResponse != null) {
        emit(InvoicesLoadedState(_cachedInvoicesResponse!));
      }
    }
  }

  Future<void> _onFetchMyInvoices(
    FetchMyInvoicesEvent event,
    Emitter<FinanceState> emit,
  ) async {
    if (_cachedMyInvoices.isEmpty) {
      emit(FinanceLoadingState());
    }
    try {
      final invoices = await repository.getMyInvoices();
      _cachedMyInvoices = invoices;
      for (final item in invoices) {
        _cachedInvoiceDetails[item.id] = item;
      }
      emit(MyInvoicesLoadedState(invoices));
    } catch (e) {
      emit(FinanceErrorState(e.toString()));
      if (_cachedMyInvoices.isNotEmpty) {
        emit(MyInvoicesLoadedState(_cachedMyInvoices));
      }
    }
  }

  Future<void> _onFetchInvoiceDetail(
    FetchInvoiceDetailEvent event,
    Emitter<FinanceState> emit,
  ) async {
    if (!_cachedInvoiceDetails.containsKey(event.id)) {
      emit(FinanceLoadingState());
    }
    try {
      final invoice = await repository.getInvoiceDetail(event.id);
      _cachedInvoiceDetails[invoice.id] = invoice;
      emit(InvoiceDetailLoadedState(invoice));
    } catch (e) {
      emit(FinanceErrorState(e.toString()));
      final cached = _cachedInvoiceDetails[event.id];
      if (cached != null) {
        emit(InvoiceDetailLoadedState(cached));
      }
    }
  }

  Future<void> _onCreateInvoice(
    CreateInvoiceEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(FinanceLoadingState());
    try {
      final invoice = await repository.createInvoice(event.data);
      _cachedInvoiceDetails[invoice.id] = invoice;
      emit(InvoiceCreatedSuccessState(invoice));
      await _refreshInvoicesSilently(emit);
    } catch (e) {
      emit(FinanceErrorState(e.toString()));
    }
  }

  Future<void> _onRecordPayment(
    RecordPaymentEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(FinanceLoadingState());
    try {
      final result = await repository.recordPayment(
        event.invoiceId,
        amount: event.amount,
        method: event.method,
        transactionId: event.transactionId,
        notes: event.notes,
      );
      emit(PaymentRecordedSuccessState(result));
      if (result['invoice'] is Map) {
        final updatedInvoice = InvoiceModel.fromJson(
          Map<String, dynamic>.from(result['invoice'] as Map),
        );
        _syncCachedInvoice(updatedInvoice);
        emit(InvoiceDetailLoadedState(updatedInvoice));
      } else {
        try {
          final updatedInvoice = await repository.getInvoiceDetail(event.invoiceId);
          _syncCachedInvoice(updatedInvoice);
          emit(InvoiceDetailLoadedState(updatedInvoice));
        } catch (_) {}
      }
      await _refreshInvoicesSilently(emit);
    } catch (e) {
      emit(FinanceErrorState(e.toString()));
    }
  }

  Future<void> _onSubmitTransferPayment(
    SubmitTransferPaymentEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(FinanceLoadingState());
    try {
      final result = await repository.submitTransferPayment(
        event.invoiceId,
        amount: event.amount,
        transactionId: event.transactionId,
        notes: event.notes,
      );
      final msg =
          result['message']?.toString() ??
          'Đã gửi xác nhận chuyển khoản chờ Thu ngân đối soát.';
      if (result['invoice'] is Map) {
        final updatedInvoice = InvoiceModel.fromJson(
          Map<String, dynamic>.from(result['invoice'] as Map),
        );
        _syncCachedInvoice(updatedInvoice);
        emit(InvoiceDetailLoadedState(updatedInvoice));
      } else {
        try {
          final updatedInvoice = await repository.getInvoiceDetail(event.invoiceId);
          _syncCachedInvoice(updatedInvoice);
          emit(InvoiceDetailLoadedState(updatedInvoice));
        } catch (_) {}
      }
      emit(FinanceActionSuccessState(msg));
    } catch (e) {
      emit(FinanceErrorState(e.toString()));
    }
  }

  Future<void> _onApprovePendingPayment(
    ApprovePendingPaymentEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(FinanceLoadingState());
    try {
      final result = await repository.approvePendingPayment(
        event.paymentId,
        notes: event.notes,
      );
      final msg =
          result['message']?.toString() ??
          'Đã xác nhận khoản chuyển khoản và cập nhật học phí.';
      if (result['invoice'] is Map) {
        final updatedInvoice = InvoiceModel.fromJson(
          Map<String, dynamic>.from(result['invoice'] as Map),
        );
        _syncCachedInvoice(updatedInvoice);
        emit(InvoiceDetailLoadedState(updatedInvoice));
      } else {
        try {
          final updatedInvoice = await repository.getInvoiceDetail(event.invoiceId);
          _syncCachedInvoice(updatedInvoice);
          emit(InvoiceDetailLoadedState(updatedInvoice));
        } catch (_) {}
      }
      emit(FinanceActionSuccessState(msg));
      await _refreshInvoicesSilently(emit);
    } catch (e) {
      emit(FinanceErrorState(e.toString()));
    }
  }

  Future<void> _onRejectPendingPayment(
    RejectPendingPaymentEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(FinanceLoadingState());
    try {
      final result = await repository.rejectPendingPayment(
        event.paymentId,
        reason: event.reason,
      );
      final msg =
          result['message']?.toString() ??
          'Đã từ chối khoản chuyển khoản chờ duyệt.';
      if (result['invoice'] is Map) {
        final updatedInvoice = InvoiceModel.fromJson(
          Map<String, dynamic>.from(result['invoice'] as Map),
        );
        _syncCachedInvoice(updatedInvoice);
        emit(InvoiceDetailLoadedState(updatedInvoice));
      } else {
        try {
          final updatedInvoice = await repository.getInvoiceDetail(event.invoiceId);
          _syncCachedInvoice(updatedInvoice);
          emit(InvoiceDetailLoadedState(updatedInvoice));
        } catch (_) {}
      }
      emit(FinanceActionSuccessState(msg));
      await _refreshInvoicesSilently(emit);
    } catch (e) {
      emit(FinanceErrorState(e.toString()));
    }
  }

  Future<void> _onCheckOverdueInvoices(
    CheckOverdueInvoicesEvent event,
    Emitter<FinanceState> emit,
  ) async {
    try {
      final res = await repository.checkOverdueInvoices();
      final count = (res['processedCount'] as num?)?.toInt() ?? 0;
      emit(
        FinanceActionSuccessState(
          count > 0
              ? 'Đã quét và gửi nhắc nợ cho $count hóa đơn quá hạn.'
              : 'Đã quét xong: Không phát hiện hóa đơn mới quá hạn.',
        ),
      );
      await _refreshInvoicesSilently(emit);
    } catch (e) {
      emit(FinanceErrorState(e.toString()));
    }
  }

  Future<void> _onFetchPromotions(
    FetchPromotionsEvent event,
    Emitter<FinanceState> emit,
  ) async {
    try {
      final list = await repository.getPromotions(isActive: event.isActive);
      _cachedPromotions = list;
      emit(PromotionsLoadedState(list));
    } catch (e) {
      emit(FinanceErrorState(e.toString()));
    }
  }

  Future<void> _onCreatePromotion(
    CreatePromotionEvent event,
    Emitter<FinanceState> emit,
  ) async {
    try {
      final created = await repository.createPromotion(event.data);
      _cachedPromotions = [created, ..._cachedPromotions];
      emit(PromotionsLoadedState(_cachedPromotions));
      emit(FinanceActionSuccessState('Đã tạo mã khuyến mãi ${created.code} thành công.'));
    } catch (e) {
      emit(FinanceErrorState(e.toString()));
    }
  }

  Future<void> _onTogglePromotion(
    TogglePromotionEvent event,
    Emitter<FinanceState> emit,
  ) async {
    try {
      final updated = await repository.togglePromotion(event.id);
      _cachedPromotions = _cachedPromotions
          .map((p) => p.id == updated.id ? updated : p)
          .toList();
      emit(PromotionsLoadedState(_cachedPromotions));
      emit(
        FinanceActionSuccessState(
          updated.isActive
              ? 'Đã kích hoạt mã khuyến mãi ${updated.code}.'
              : 'Đã tạm khóa mã khuyến mãi ${updated.code}.',
        ),
      );
    } catch (e) {
      emit(FinanceErrorState(e.toString()));
    }
  }

  Future<void> _onCancelInvoice(
    CancelInvoiceEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(FinanceLoadingState());
    try {
      await repository.cancelInvoice(event.invoiceId, reason: event.reason);
      emit(FinanceActionSuccessState('Hủy hóa đơn thành công'));
      try {
        final updatedInvoice = await repository.getInvoiceDetail(event.invoiceId);
        _cachedInvoiceDetails[updatedInvoice.id] = updatedInvoice;
        emit(InvoiceDetailLoadedState(updatedInvoice));
      } catch (_) {}
      await _refreshInvoicesSilently(emit);
    } catch (e) {
      emit(FinanceErrorState(e.toString()));
    }
  }

  Future<void> _onRefundInvoice(
    RefundInvoiceEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(FinanceLoadingState());
    try {
      await repository.refundInvoice(
        event.invoiceId,
        amount: event.amount,
        reason: event.reason,
      );
      emit(FinanceActionSuccessState('Hoàn tiền học phí thành công'));
      try {
        final updatedInvoice = await repository.getInvoiceDetail(event.invoiceId);
        _cachedInvoiceDetails[updatedInvoice.id] = updatedInvoice;
        emit(InvoiceDetailLoadedState(updatedInvoice));
      } catch (_) {}
      await _refreshInvoicesSilently(emit);
    } catch (e) {
      emit(FinanceErrorState(e.toString()));
    }
  }

  Future<void> _onPayOnline(
    PayOnlineEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(FinanceLoadingState());
    try {
      final res = await repository.payOnline(
        event.invoiceId,
        bankCode: event.bankCode,
        language: event.language,
      );
      emit(PayOnlineUrlReadyState(
        paymentUrl: res['paymentUrl'] as String? ?? '',
        invoiceCode: res['invoiceCode'] as String? ?? '',
        amount: (res['amount'] as num?)?.toDouble() ?? 0.0,
      ));
    } catch (e) {
      emit(FinanceErrorState(e.toString()));
    }
  }

  Future<void> _onValidatePromotion(
    ValidatePromotionEvent event,
    Emitter<FinanceState> emit,
  ) async {
    try {
      final res = await repository.validatePromotion(event.code, event.orderAmount);
      emit(PromotionValidatedState(res));
    } catch (e) {
      emit(FinanceErrorState(e.toString()));
    }
  }
}
