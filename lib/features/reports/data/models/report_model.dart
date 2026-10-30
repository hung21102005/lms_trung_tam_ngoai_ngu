import 'package:equatable/equatable.dart';

// -----------------------------------------------------------------------------
// 1. DASHBOARD OVERVIEW MODEL
// -----------------------------------------------------------------------------
class MonthlyTrendItem extends Equatable {
  final String month;
  final double revenue;

  const MonthlyTrendItem({required this.month, required this.revenue});

  factory MonthlyTrendItem.fromJson(Map<String, dynamic> json) {
    return MonthlyTrendItem(
      month: json['month'] ?? '',
      revenue: (json['revenue'] ?? 0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [month, revenue];
}

class CourseDistributionItem extends Equatable {
  final String courseId;
  final String courseName;
  final int studentCount;

  const CourseDistributionItem({
    required this.courseId,
    required this.courseName,
    required this.studentCount,
  });

  factory CourseDistributionItem.fromJson(Map<String, dynamic> json) {
    return CourseDistributionItem(
      courseId: json['courseId'] ?? '',
      courseName: json['courseName'] ?? '',
      studentCount: json['studentCount'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [courseId, courseName, studentCount];
}

class UpcomingClassItem extends Equatable {
  final String id;
  final String name;
  final String courseName;
  final String teacherName;
  final DateTime startDate;
  final int enrolledCount;
  final int maxStudents;

  const UpcomingClassItem({
    required this.id,
    required this.name,
    required this.courseName,
    required this.teacherName,
    required this.startDate,
    required this.enrolledCount,
    required this.maxStudents,
  });

  factory UpcomingClassItem.fromJson(Map<String, dynamic> json) {
    return UpcomingClassItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      courseName: json['courseName'] ?? '',
      teacherName: json['teacherName'] ?? '',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      enrolledCount: json['enrolledCount'] ?? 0,
      maxStudents: json['maxStudents'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, name, courseName, teacherName, startDate, enrolledCount, maxStudents];
}

class TopDebtorItem extends Equatable {
  final String invoiceId;
  final String invoiceCode;
  final String studentName;
  final String studentCode;
  final String? phone;
  final String className;
  final double balance;
  final DateTime? dueDate;

  const TopDebtorItem({
    required this.invoiceId,
    required this.invoiceCode,
    required this.studentName,
    required this.studentCode,
    this.phone,
    required this.className,
    required this.balance,
    this.dueDate,
  });

  factory TopDebtorItem.fromJson(Map<String, dynamic> json) {
    return TopDebtorItem(
      invoiceId: json['invoiceId'] ?? '',
      invoiceCode: json['invoiceCode'] ?? '',
      studentName: json['studentName'] ?? '',
      studentCode: json['studentCode'] ?? '',
      phone: json['phone'],
      className: json['className'] ?? '',
      balance: (json['balance'] ?? 0).toDouble(),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
    );
  }

  @override
  List<Object?> get props => [invoiceId, invoiceCode, studentName, studentCode, phone, className, balance, dueDate];
}

class DashboardOverviewModel extends Equatable {
  final int totalStudents;
  final int newStudentsThisMonth;
  final int totalActiveClasses;
  final double monthlyRevenue;
  final double lastMonthRevenue;
  final double monthlyRevenueGrowth;
  final double totalDebts;
  final List<MonthlyTrendItem> revenueTrend;
  final List<CourseDistributionItem> courseDistribution;
  final List<UpcomingClassItem> upcomingClasses;
  final List<TopDebtorItem> topDebtors;

  const DashboardOverviewModel({
    required this.totalStudents,
    required this.newStudentsThisMonth,
    required this.totalActiveClasses,
    required this.monthlyRevenue,
    required this.lastMonthRevenue,
    required this.monthlyRevenueGrowth,
    required this.totalDebts,
    required this.revenueTrend,
    required this.courseDistribution,
    required this.upcomingClasses,
    required this.topDebtors,
  });

  factory DashboardOverviewModel.fromJson(Map<String, dynamic> json) {
    return DashboardOverviewModel(
      totalStudents: json['totalStudents'] ?? 0,
      newStudentsThisMonth: json['newStudentsThisMonth'] ?? 0,
      totalActiveClasses: json['totalActiveClasses'] ?? 0,
      monthlyRevenue: (json['monthlyRevenue'] ?? 0).toDouble(),
      lastMonthRevenue: (json['lastMonthRevenue'] ?? 0).toDouble(),
      monthlyRevenueGrowth: (json['monthlyRevenueGrowth'] ?? 0).toDouble(),
      totalDebts: (json['totalDebts'] ?? 0).toDouble(),
      revenueTrend: (json['revenueTrend'] as List<dynamic>? ?? [])
          .map((i) => MonthlyTrendItem.fromJson(i))
          .toList(),
      courseDistribution: (json['courseDistribution'] as List<dynamic>? ?? [])
          .map((i) => CourseDistributionItem.fromJson(i))
          .toList(),
      upcomingClasses: (json['upcomingClasses'] as List<dynamic>? ?? [])
          .map((i) => UpcomingClassItem.fromJson(i))
          .toList(),
      topDebtors: (json['topDebtors'] as List<dynamic>? ?? [])
          .map((i) => TopDebtorItem.fromJson(i))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        totalStudents,
        newStudentsThisMonth,
        totalActiveClasses,
        monthlyRevenue,
        lastMonthRevenue,
        monthlyRevenueGrowth,
        totalDebts,
        revenueTrend,
        courseDistribution,
        upcomingClasses,
        topDebtors,
      ];
}

// -----------------------------------------------------------------------------
// 2. REVENUE REPORT MODEL
// -----------------------------------------------------------------------------
class RevenueMonthItem extends Equatable {
  final int month;
  final String monthLabel;
  final double revenue;
  final int paymentsCount;

  const RevenueMonthItem({
    required this.month,
    required this.monthLabel,
    required this.revenue,
    required this.paymentsCount,
  });

  factory RevenueMonthItem.fromJson(Map<String, dynamic> json) {
    return RevenueMonthItem(
      month: json['month'] ?? 0,
      monthLabel: json['monthLabel'] ?? '',
      revenue: (json['revenue'] ?? 0).toDouble(),
      paymentsCount: json['paymentsCount'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [month, monthLabel, revenue, paymentsCount];
}

class PaymentMethodShareItem extends Equatable {
  final String method;
  final double revenue;
  final double percentage;

  const PaymentMethodShareItem({
    required this.method,
    required this.revenue,
    required this.percentage,
  });

  factory PaymentMethodShareItem.fromJson(Map<String, dynamic> json) {
    return PaymentMethodShareItem(
      method: json['method'] ?? '',
      revenue: (json['revenue'] ?? 0).toDouble(),
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [method, revenue, percentage];
}

class BranchRevenueItem extends Equatable {
  final String id;
  final String name;
  final double revenue;
  final double percentage;

  const BranchRevenueItem({
    required this.id,
    required this.name,
    required this.revenue,
    required this.percentage,
  });

  factory BranchRevenueItem.fromJson(Map<String, dynamic> json) {
    return BranchRevenueItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      revenue: (json['revenue'] ?? 0).toDouble(),
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [id, name, revenue, percentage];
}

class RevenueReportModel extends Equatable {
  final int year;
  final double totalRevenue;
  final double averageMonthlyRevenue;
  final Map<String, dynamic> highestMonth;
  final List<RevenueMonthItem> monthlyData;
  final List<PaymentMethodShareItem> byMethod;
  final List<BranchRevenueItem> byBranch;

  const RevenueReportModel({
    required this.year,
    required this.totalRevenue,
    required this.averageMonthlyRevenue,
    required this.highestMonth,
    required this.monthlyData,
    required this.byMethod,
    required this.byBranch,
  });

  factory RevenueReportModel.fromJson(Map<String, dynamic> json) {
    return RevenueReportModel(
      year: json['year'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      averageMonthlyRevenue: (json['averageMonthlyRevenue'] ?? 0).toDouble(),
      highestMonth: (json['highestMonth'] as Map<String, dynamic>?) ?? {},
      monthlyData: (json['monthlyData'] as List<dynamic>? ?? [])
          .map((i) => RevenueMonthItem.fromJson(i))
          .toList(),
      byMethod: (json['byMethod'] as List<dynamic>? ?? [])
          .map((i) => PaymentMethodShareItem.fromJson(i))
          .toList(),
      byBranch: (json['byBranch'] as List<dynamic>? ?? [])
          .map((i) => BranchRevenueItem.fromJson(i))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [year, totalRevenue, averageMonthlyRevenue, highestMonth, monthlyData, byMethod, byBranch];
}

// -----------------------------------------------------------------------------
// 3. ATTENDANCE REPORT MODEL
// -----------------------------------------------------------------------------
class ClassAttendanceStatItem extends Equatable {
  final String id;
  final String name;
  final int total;
  final int present;
  final double attendanceRate;

  const ClassAttendanceStatItem({
    required this.id,
    required this.name,
    required this.total,
    required this.present,
    required this.attendanceRate,
  });

  factory ClassAttendanceStatItem.fromJson(Map<String, dynamic> json) {
    return ClassAttendanceStatItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      total: json['total'] ?? 0,
      present: json['present'] ?? 0,
      attendanceRate: (json['attendanceRate'] ?? 0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [id, name, total, present, attendanceRate];
}

class AttendanceReportModel extends Equatable {
  final int totalRecords;
  final int presentCount;
  final int lateCount;
  final int absentCount;
  final int excusedCount;
  final int makeupCount;
  final double attendanceRate;
  final List<ClassAttendanceStatItem> byClass;

  const AttendanceReportModel({
    required this.totalRecords,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
    required this.excusedCount,
    required this.makeupCount,
    required this.attendanceRate,
    required this.byClass,
  });

  factory AttendanceReportModel.fromJson(Map<String, dynamic> json) {
    return AttendanceReportModel(
      totalRecords: json['totalRecords'] ?? 0,
      presentCount: json['presentCount'] ?? 0,
      lateCount: json['lateCount'] ?? 0,
      absentCount: json['absentCount'] ?? 0,
      excusedCount: json['excusedCount'] ?? 0,
      makeupCount: json['makeupCount'] ?? 0,
      attendanceRate: (json['attendanceRate'] ?? 0).toDouble(),
      byClass: (json['byClass'] as List<dynamic>? ?? [])
          .map((i) => ClassAttendanceStatItem.fromJson(i))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        totalRecords,
        presentCount,
        lateCount,
        absentCount,
        excusedCount,
        makeupCount,
        attendanceRate,
        byClass,
      ];
}

// -----------------------------------------------------------------------------
// 4. DEBTS REPORT MODEL
// -----------------------------------------------------------------------------
class DebtInvoiceItem extends Equatable {
  final String id;
  final String code;
  final String studentName;
  final String studentCode;
  final String? phone;
  final String? email;
  final String className;
  final double totalAmount;
  final double paidAmount;
  final double balance;
  final String status;
  final DateTime? dueDate;
  final bool isOverdue;

  const DebtInvoiceItem({
    required this.id,
    required this.code,
    required this.studentName,
    required this.studentCode,
    this.phone,
    this.email,
    required this.className,
    required this.totalAmount,
    required this.paidAmount,
    required this.balance,
    required this.status,
    this.dueDate,
    required this.isOverdue,
  });

  factory DebtInvoiceItem.fromJson(Map<String, dynamic> json) {
    return DebtInvoiceItem(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      studentName: json['studentName'] ?? '',
      studentCode: json['studentCode'] ?? '',
      phone: json['phone'],
      email: json['email'],
      className: json['className'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      balance: (json['balance'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      isOverdue: json['isOverdue'] ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        code,
        studentName,
        studentCode,
        phone,
        email,
        className,
        totalAmount,
        paidAmount,
        balance,
        status,
        dueDate,
        isOverdue,
      ];
}

class DebtsSummaryModel extends Equatable {
  final double totalOutstanding;
  final double totalInvoiced;
  final double totalPaid;
  final int overdueCount;

  const DebtsSummaryModel({
    required this.totalOutstanding,
    required this.totalInvoiced,
    required this.totalPaid,
    required this.overdueCount,
  });

  factory DebtsSummaryModel.fromJson(Map<String, dynamic> json) {
    return DebtsSummaryModel(
      totalOutstanding: (json['totalOutstanding'] ?? 0).toDouble(),
      totalInvoiced: (json['totalInvoiced'] ?? 0).toDouble(),
      totalPaid: (json['totalPaid'] ?? 0).toDouble(),
      overdueCount: json['overdueCount'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [totalOutstanding, totalInvoiced, totalPaid, overdueCount];
}

class DebtsReportModel extends Equatable {
  final List<DebtInvoiceItem> items;
  final int total;
  final int page;
  final int limit;
  final DebtsSummaryModel summary;

  const DebtsReportModel({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.summary,
  });

  factory DebtsReportModel.fromJson(Map<String, dynamic> json) {
    return DebtsReportModel(
      items: (json['items'] as List<dynamic>? ?? [])
          .map((i) => DebtInvoiceItem.fromJson(i))
          .toList(),
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      summary: DebtsSummaryModel.fromJson(json['summary'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [items, total, page, limit, summary];
}

// -----------------------------------------------------------------------------
// 5. TEACHER WORKLOAD MODEL
// -----------------------------------------------------------------------------
class TeacherWorkloadModel extends Equatable {
  final String teacherId;
  final String fullName;
  final String? userCode;
  final String? email;
  final String? phone;
  final int activeClassesCount;
  final int totalSessions;
  final int completedSessions;
  final double totalTeachingHours;

  const TeacherWorkloadModel({
    required this.teacherId,
    required this.fullName,
    this.userCode,
    this.email,
    this.phone,
    required this.activeClassesCount,
    required this.totalSessions,
    required this.completedSessions,
    required this.totalTeachingHours,
  });

  factory TeacherWorkloadModel.fromJson(Map<String, dynamic> json) {
    return TeacherWorkloadModel(
      teacherId: json['teacherId'] ?? '',
      fullName: json['fullName'] ?? '',
      userCode: json['userCode'],
      email: json['email'],
      phone: json['phone'],
      activeClassesCount: json['activeClassesCount'] ?? 0,
      totalSessions: json['totalSessions'] ?? 0,
      completedSessions: json['completedSessions'] ?? 0,
      totalTeachingHours: (json['totalTeachingHours'] ?? 0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        teacherId,
        fullName,
        userCode,
        email,
        phone,
        activeClassesCount,
        totalSessions,
        completedSessions,
        totalTeachingHours,
      ];
}

// =============================================================================
// 6. ACADEMIC REPORT MODEL (Báo cáo kết quả học tập & Đánh giá)
// =============================================================================

class AcademicClassificationStat extends Equatable {
  final int count;
  final double percentage;

  const AcademicClassificationStat({
    required this.count,
    required this.percentage,
  });

  factory AcademicClassificationStat.fromJson(Map<String, dynamic> json) {
    return AcademicClassificationStat(
      count: json['count'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [count, percentage];
}

class AcademicClassificationModel extends Equatable {
  final AcademicClassificationStat excellent;
  final AcademicClassificationStat good;
  final AcademicClassificationStat average;
  final AcademicClassificationStat poor;

  const AcademicClassificationModel({
    required this.excellent,
    required this.good,
    required this.average,
    required this.poor,
  });

  factory AcademicClassificationModel.fromJson(Map<String, dynamic> json) {
    return AcademicClassificationModel(
      excellent: AcademicClassificationStat.fromJson(
        (json['excellent'] as Map<String, dynamic>?) ?? {},
      ),
      good: AcademicClassificationStat.fromJson(
        (json['good'] as Map<String, dynamic>?) ?? {},
      ),
      average: AcademicClassificationStat.fromJson(
        (json['average'] as Map<String, dynamic>?) ?? {},
      ),
      poor: AcademicClassificationStat.fromJson(
        (json['poor'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }

  @override
  List<Object?> get props => [excellent, good, average, poor];
}

class TopStudentAcademicItem extends Equatable {
  final String attemptId;
  final String studentName;
  final String studentCode;
  final String examTitle;
  final double score;
  final double percentage;
  final bool? isPassed;

  const TopStudentAcademicItem({
    required this.attemptId,
    required this.studentName,
    required this.studentCode,
    required this.examTitle,
    required this.score,
    required this.percentage,
    this.isPassed,
  });

  factory TopStudentAcademicItem.fromJson(Map<String, dynamic> json) {
    return TopStudentAcademicItem(
      attemptId: json['attemptId'] as String? ?? '',
      studentName: json['studentName'] as String? ?? '',
      studentCode: json['studentCode'] as String? ?? '',
      examTitle: json['examTitle'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      isPassed: json['isPassed'] as bool?,
    );
  }

  @override
  List<Object?> get props => [
        attemptId,
        studentName,
        studentCode,
        examTitle,
        score,
        percentage,
        isPassed,
      ];
}

class AcademicReportModel extends Equatable {
  final int totalAttempts;
  final double averageScore;
  final double passRate;
  final AcademicClassificationModel classification;
  final List<TopStudentAcademicItem> topStudents;

  const AcademicReportModel({
    required this.totalAttempts,
    required this.averageScore,
    required this.passRate,
    required this.classification,
    required this.topStudents,
  });

  factory AcademicReportModel.fromJson(Map<String, dynamic> json) {
    final classJson = (json['classification'] as Map<String, dynamic>?) ?? {};
    final topList = (json['topStudents'] as List<dynamic>?) ?? [];

    return AcademicReportModel(
      totalAttempts: json['totalAttempts'] as int? ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
      passRate: (json['passRate'] as num?)?.toDouble() ?? 0.0,
      classification: AcademicClassificationModel.fromJson(classJson),
      topStudents: topList
          .map((i) => TopStudentAcademicItem.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        totalAttempts,
        averageScore,
        passRate,
        classification,
        topStudents,
      ];
}
