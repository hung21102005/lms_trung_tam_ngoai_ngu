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
  final int page;

  FetchInvoicesEvent({
    this.status,
    this.search,
    this.studentId,
    this.classId,
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

  FinanceBloc({required this.repository}) : super(FinanceInitialState()) {
    on<FetchInvoicesEvent>(_onFetchInvoices);
    on<FetchMyInvoicesEvent>(_onFetchMyInvoices);
    on<FetchInvoiceDetailEvent>(_onFetchInvoiceDetail);
    on<CreateInvoiceEvent>(_onCreateInvoice);
    on<RecordPaymentEvent>(_onRecordPayment);
    on<CancelInvoiceEvent>(_onCancelInvoice);
    on<RefundInvoiceEvent>(_onRefundInvoice);
    on<PayOnlineEvent>(_onPayOnline);
    on<ValidatePromotionEvent>(_onValidatePromotion);
  }

  Future<void> _onFetchInvoices(
    FetchInvoicesEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(FinanceLoadingState());
    try {
      final response = await repository.getInvoices(
        status: event.status,
        search: event.search,
        studentId: event.studentId,
        classId: event.classId,
        page: event.page,
      );
      emit(InvoicesLoadedState(response));
    } catch (e) {
      emit(FinanceErrorState(e.toString()));
    }
  }

  Future<void> _onFetchMyInvoices(
    FetchMyInvoicesEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(FinanceLoadingState());
    try {
      final invoices = await repository.getMyInvoices();
      emit(MyInvoicesLoadedState(invoices));
    } catch (e) {
      emit(FinanceErrorState(e.toString()));
    }
  }

  Future<void> _onFetchInvoiceDetail(
    FetchInvoiceDetailEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(FinanceLoadingState());
    try {
      final invoice = await repository.getInvoiceDetail(event.id);
      emit(InvoiceDetailLoadedState(invoice));
    } catch (e) {
      emit(FinanceErrorState(e.toString()));
    }
  }

  Future<void> _onCreateInvoice(
    CreateInvoiceEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(FinanceLoadingState());
    try {
      final invoice = await repository.createInvoice(event.data);
      emit(InvoiceCreatedSuccessState(invoice));
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
