import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/report_model.dart';
import '../../domain/repositories/reports_repository.dart';

// EVENTS
abstract class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object?> get props => [];
}

class FetchDashboardOverviewEvent extends ReportsEvent {
  final bool forceRefresh;

  const FetchDashboardOverviewEvent({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class FetchRevenueReportEvent extends ReportsEvent {
  final int? year;
  final String? branchId;

  const FetchRevenueReportEvent({this.year, this.branchId});

  @override
  List<Object?> get props => [year, branchId];
}

class FetchAttendanceReportEvent extends ReportsEvent {
  final String? classId;
  final String? startDate;
  final String? endDate;

  const FetchAttendanceReportEvent({this.classId, this.startDate, this.endDate});

  @override
  List<Object?> get props => [classId, startDate, endDate];
}

class FetchDebtsReportEvent extends ReportsEvent {
  final String? branchId;
  final String? search;
  final int page;
  final int limit;

  const FetchDebtsReportEvent({
    this.branchId,
    this.search,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [branchId, search, page, limit];
}

class FetchTeacherWorkloadEvent extends ReportsEvent {}

class FetchAcademicReportEvent extends ReportsEvent {
  final String? classId;
  final String? examId;

  const FetchAcademicReportEvent({this.classId, this.examId});

  @override
  List<Object?> get props => [classId, examId];
}

// STATES
abstract class ReportsState extends Equatable {
  const ReportsState();

  @override
  List<Object?> get props => [];
}

class ReportsInitialState extends ReportsState {}

class ReportsLoadingState extends ReportsState {}

class DashboardOverviewLoadedState extends ReportsState {
  final DashboardOverviewModel data;

  const DashboardOverviewLoadedState(this.data);

  @override
  List<Object?> get props => [data];
}

class RevenueReportLoadedState extends ReportsState {
  final RevenueReportModel data;

  const RevenueReportLoadedState(this.data);

  @override
  List<Object?> get props => [data];
}

class AttendanceReportLoadedState extends ReportsState {
  final AttendanceReportModel data;

  const AttendanceReportLoadedState(this.data);

  @override
  List<Object?> get props => [data];
}

class DebtsReportLoadedState extends ReportsState {
  final DebtsReportModel data;

  const DebtsReportLoadedState(this.data);

  @override
  List<Object?> get props => [data];
}

class TeacherWorkloadLoadedState extends ReportsState {
  final List<TeacherWorkloadModel> data;

  const TeacherWorkloadLoadedState(this.data);

  @override
  List<Object?> get props => [data];
}

class AcademicReportLoadedState extends ReportsState {
  final AcademicReportModel data;

  const AcademicReportLoadedState(this.data);

  @override
  List<Object?> get props => [data];
}

class ReportsErrorState extends ReportsState {
  final String message;

  const ReportsErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

// BLOC
class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final ReportsRepository repository;

  ReportsBloc({required this.repository}) : super(ReportsInitialState()) {
    on<FetchDashboardOverviewEvent>(_onFetchDashboardOverview);
    on<FetchRevenueReportEvent>(_onFetchRevenueReport);
    on<FetchAttendanceReportEvent>(_onFetchAttendanceReport);
    on<FetchDebtsReportEvent>(_onFetchDebtsReport);
    on<FetchTeacherWorkloadEvent>(_onFetchTeacherWorkload);
    on<FetchAcademicReportEvent>(_onFetchAcademicReport);
  }

  Future<void> _onFetchDashboardOverview(
    FetchDashboardOverviewEvent event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoadingState());
    try {
      if (event.forceRefresh) {
        await repository.refreshDashboardCache();
      }
      final data = await repository.getDashboardOverview();
      emit(DashboardOverviewLoadedState(data));
    } catch (e) {
      emit(ReportsErrorState(e.toString()));
    }
  }

  Future<void> _onFetchRevenueReport(
    FetchRevenueReportEvent event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoadingState());
    try {
      final data = await repository.getRevenueReport(
        year: event.year,
        branchId: event.branchId,
      );
      emit(RevenueReportLoadedState(data));
    } catch (e) {
      emit(ReportsErrorState(e.toString()));
    }
  }

  Future<void> _onFetchAttendanceReport(
    FetchAttendanceReportEvent event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoadingState());
    try {
      final data = await repository.getAttendanceReport(
        classId: event.classId,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(AttendanceReportLoadedState(data));
    } catch (e) {
      emit(ReportsErrorState(e.toString()));
    }
  }

  Future<void> _onFetchDebtsReport(
    FetchDebtsReportEvent event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoadingState());
    try {
      final data = await repository.getDebtsReport(
        branchId: event.branchId,
        search: event.search,
        page: event.page,
        limit: event.limit,
      );
      emit(DebtsReportLoadedState(data));
    } catch (e) {
      emit(ReportsErrorState(e.toString()));
    }
  }

  Future<void> _onFetchTeacherWorkload(
    FetchTeacherWorkloadEvent event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoadingState());
    try {
      final data = await repository.getTeacherWorkloadReport();
      emit(TeacherWorkloadLoadedState(data));
    } catch (e) {
      emit(ReportsErrorState(e.toString()));
    }
  }

  Future<void> _onFetchAcademicReport(
    FetchAcademicReportEvent event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoadingState());
    try {
      final data = await repository.getAcademicReport(
        classId: event.classId,
        examId: event.examId,
      );
      emit(AcademicReportLoadedState(data));
    } catch (e) {
      emit(ReportsErrorState(e.toString()));
    }
  }
}
