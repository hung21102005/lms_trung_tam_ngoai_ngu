import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service.js';
import { RedisService } from '../redis/redis.service.js';
import {
  GetRevenueReportDto,
  GetAttendanceReportDto,
  GetAcademicReportDto,
  GetDebtsReportDto,
  ExportReportType,
} from './dto/index.js';
import { AttendanceStatus, ClassStatus, UserStatus, SessionStatus, EnrollmentStatus, SubmissionStatus, AttemptStatus } from '@prisma/client';
import * as XLSX from 'xlsx';

@Injectable()
export class ReportsService {
  private readonly logger = new Logger(ReportsService.name);
  private readonly DASHBOARD_CACHE_KEY = 'reports:dashboard:overview';
  private readonly CACHE_TTL_SECONDS = 300; // 5 phút

  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  async getTeacherDashboard(teacherId: string) {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const weekEnd = new Date(today);
    weekEnd.setDate(weekEnd.getDate() + 7);
    const assignedClass = {
      OR: [{ mainTeacherId: teacherId }, { assistantTeacherId: teacherId }],
    };
    const [classes, sessions, pendingSubmissions, unreadNotifications] = await Promise.all([
      this.prisma.class.findMany({
        where: assignedClass,
        select: {
          id: true, code: true, name: true, status: true,
          students: { where: { status: EnrollmentStatus.ENROLLED }, select: { studentId: true } },
        },
      }),
      this.prisma.classSession.findMany({
        where: {
          OR: [{ teacherId }, { class: assignedClass }],
          date: { gte: today, lt: weekEnd },
          status: { not: SessionStatus.CANCELLED },
        },
        orderBy: [{ date: 'asc' }, { startTime: 'asc' }],
        select: {
          id: true, date: true, startTime: true, endTime: true, status: true, title: true,
          class: { select: { id: true, code: true, name: true } },
          room: { select: { name: true } },
        },
      }),
      this.prisma.submission.findMany({
        where: {
          status: { in: [SubmissionStatus.SUBMITTED, SubmissionStatus.LATE] },
          assignment: { class: assignedClass },
        },
        orderBy: { submittedAt: 'desc' },
        take: 10,
        select: {
          id: true, assignmentId: true, submittedAt: true,
          student: { select: { id: true, fullName: true, userCode: true } },
          assignment: { select: { title: true, class: { select: { code: true } } } },
        },
      }),
      this.prisma.notification.count({ where: { userId: teacherId, isRead: false } }),
    ]);
    const classIds = classes.map((item) => item.id);
    const monthAgo = new Date(today);
    monthAgo.setDate(monthAgo.getDate() - 30);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    const [pendingCount, pendingExams, absences] = classIds.length
      ? await Promise.all([
          this.prisma.submission.count({
            where: {
              status: { in: [SubmissionStatus.SUBMITTED, SubmissionStatus.LATE] },
              assignment: { classId: { in: classIds } },
            },
          }),
          this.prisma.examAttempt.count({
            where: {
              status: AttemptStatus.SUBMITTED,
              exam: { classId: { in: classIds } },
              answers: { some: { score: null } },
            },
          }),
          this.prisma.attendance.groupBy({
            by: ['studentId'],
            where: {
              status: AttendanceStatus.ABSENT,
              session: { classId: { in: classIds }, date: { gte: monthAgo, lt: tomorrow } },
            },
            _count: { studentId: true },
          }),
        ])
      : [0, 0, []];
    const frequentlyAbsent = absences.filter((item) => item._count.studentId >= 3);
    const studentIds = new Set(classes.flatMap((item) => item.students.map((student) => student.studentId)));
    const atRiskIds = frequentlyAbsent
      .filter((item) => studentIds.has(item.studentId))
      .map((item) => item.studentId);
    const atRiskUsers = atRiskIds.length
      ? await this.prisma.user.findMany({
          where: { id: { in: atRiskIds } },
          select: { id: true, fullName: true, userCode: true },
        })
      : [];
    const absentCount = new Map(frequentlyAbsent.map((item) => [item.studentId, item._count.studentId]));
    return {
      activeClasses: classes.filter((item) =>
        item.status === ClassStatus.OPEN_FOR_ENROLLMENT ||
        item.status === ClassStatus.IN_PROGRESS,
      ).length,
      totalStudents: new Set(classes.flatMap((item) => item.students.map((student) => student.studentId))).size,
      sessionsThisWeek: sessions.length,
      sessionsToday: sessions.filter((session) => session.date.getTime() === today.getTime()).length,
      pendingAssignments: pendingCount,
      pendingExams,
      studentsNeedingAttention: atRiskIds.length,
      attendanceAlerts: atRiskUsers.map((user) => ({
        ...user, absencesLast30Days: absentCount.get(user.id) ?? 0,
      })),
      unreadNotifications,
      classes: classes.map(({ students, ...item }) => ({ ...item, studentsCount: students.length })),
      sessions,
      pendingSubmissions,
    };
  }

  // --------------------------------------------------------------------------
  // 1. DASHBOARD OVERVIEW
  // --------------------------------------------------------------------------
  async getDashboardOverview() {
    // 1. Kiểm tra cache Redis
    try {
      const cached = await this.redis.get(this.DASHBOARD_CACHE_KEY);
      if (cached) {
        return JSON.parse(cached);
      }
    } catch (e) {
      this.logger.warn(`Lỗi khi đọc cache Redis: ${e}`);
    }

    const now = new Date();
    const startOfCurrentMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const startOfLastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const endOfLastMonth = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59);

    // 2. Tổng số học viên active
    const totalStudents = await this.prisma.user.count({
      where: {
        userRoles: {
          some: {
            role: { code: 'student' },
          },
        },
        status: UserStatus.ACTIVE,
      },
    });

    // 3. Số học viên mới trong tháng này
    const newStudentsThisMonth = await this.prisma.user.count({
      where: {
        userRoles: {
          some: {
            role: { code: 'student' },
          },
        },
        createdAt: { gte: startOfCurrentMonth },
      },
    });

    // 4. Tổng số lớp học đang hoạt động
    const totalActiveClasses = await this.prisma.class.count({
      where: {
        status: { in: [ClassStatus.OPEN_FOR_ENROLLMENT, ClassStatus.IN_PROGRESS] },
      },
    });

    // 5. Doanh thu tháng hiện tại
    const currentMonthPayments = await this.prisma.payment.aggregate({
      _sum: { amount: true },
      where: {
        status: 'SUCCESS',
        payDate: { gte: startOfCurrentMonth },
      },
    });
    const monthlyRevenue = Number(currentMonthPayments._sum.amount || 0);

    // 6. Doanh thu tháng trước & Tỷ lệ tăng trưởng
    const lastMonthPayments = await this.prisma.payment.aggregate({
      _sum: { amount: true },
      where: {
        status: 'SUCCESS',
        payDate: { gte: startOfLastMonth, lte: endOfLastMonth },
      },
    });
    const lastMonthRevenue = Number(lastMonthPayments._sum.amount || 0);

    let monthlyRevenueGrowth = 0;
    if (lastMonthRevenue > 0) {
      monthlyRevenueGrowth = Number((((monthlyRevenue - lastMonthRevenue) / lastMonthRevenue) * 100).toFixed(1));
    } else if (monthlyRevenue > 0) {
      monthlyRevenueGrowth = 100;
    }

    // 7. Tổng công nợ tồn đọng (hóa đơn chưa hoàn tất thanh toán)
    const pendingInvoices = await this.prisma.invoice.aggregate({
      _sum: { balance: true },
      where: {
        status: { in: ['PENDING', 'PARTIALLY_PAID', 'OVERDUE'] },
      },
    });
    const totalDebts = Number(pendingInvoices._sum.balance || 0);

    // 8. Xu hướng doanh thu 6 tháng gần nhất
    const revenueTrend = await this.getSixMonthsRevenueTrend();

    // 9. Phân bổ học viên theo khóa học
    const courseDistribution = await this.getStudentCourseDistribution();

    // 10. Top 5 lớp sắp khai giảng
    const upcomingClasses = await this.prisma.class.findMany({
      where: {
        status: { in: [ClassStatus.PLANNING, ClassStatus.OPEN_FOR_ENROLLMENT] },
        startDate: { gte: now },
      },
      orderBy: { startDate: 'asc' },
      take: 5,
      select: {
        id: true,
        name: true,
        startDate: true,
        maxCapacity: true,
        course: { select: { title: true } },
        mainTeacher: { select: { fullName: true } },
        _count: { select: { students: true } },
      },
    });

    // 11. Top 5 học viên công nợ lớn nhất
    const topDebtors = await this.prisma.invoice.findMany({
      where: {
        status: { in: ['PENDING', 'PARTIALLY_PAID', 'OVERDUE'] },
        balance: { gt: 0 },
      },
      orderBy: { balance: 'desc' },
      take: 5,
      select: {
        id: true,
        code: true,
        totalAmount: true,
        paidAmount: true,
        balance: true,
        dueDate: true,
        student: {
          select: {
            id: true,
            fullName: true,
            userCode: true,
            phone: true,
          },
        },
        class: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });

    const result = {
      totalStudents,
      newStudentsThisMonth,
      totalActiveClasses,
      monthlyRevenue,
      lastMonthRevenue,
      monthlyRevenueGrowth,
      totalDebts,
      revenueTrend,
      courseDistribution,
      upcomingClasses: upcomingClasses.map((c) => ({
        id: c.id,
        name: c.name,
        courseName: c.course?.title || 'Chưa gán',
        teacherName: c.mainTeacher?.fullName || 'Chưa gán',
        startDate: c.startDate,
        enrolledCount: c._count.students,
        maxStudents: c.maxCapacity,
      })),
      topDebtors: topDebtors.map((d) => ({
        invoiceId: d.id,
        invoiceCode: d.code,
        studentName: d.student.fullName,
        studentCode: d.student.userCode,
        phone: d.student.phone,
        className: d.class?.name || 'N/A',
        balance: Number(d.balance),
        dueDate: d.dueDate,
      })),
    };

    // Lưu vào Redis cache
    try {
      await this.redis.set(this.DASHBOARD_CACHE_KEY, JSON.stringify(result), this.CACHE_TTL_SECONDS);
    } catch (e) {
      this.logger.warn(`Lỗi khi ghi cache Redis: ${e}`);
    }

    return result;
  }

  // --------------------------------------------------------------------------
  // 2. BÁO CÁO DOANH THU
  // --------------------------------------------------------------------------
  async getRevenueReport(dto: GetRevenueReportDto) {
    const year = dto.year || new Date().getFullYear();
    const startOfYear = new Date(year, 0, 1);
    const endOfYear = new Date(year, 11, 31, 23, 59, 59);

    const wherePayment: any = {
      status: 'SUCCESS',
      payDate: { gte: startOfYear, lte: endOfYear },
    };

    if (dto.branchId) {
      wherePayment.invoice = {
        class: { branchId: dto.branchId },
      };
    }

    const payments = await this.prisma.payment.findMany({
      where: wherePayment,
      select: {
        amount: true,
        payDate: true,
        method: true,
        invoice: {
          select: {
            class: {
              select: {
                branch: {
                  select: { id: true, name: true },
                },
              },
            },
          },
        },
      },
    });

    // 12 tháng
    const monthlyData = Array.from({ length: 12 }, (_, i) => ({
      month: i + 1,
      monthLabel: `T${i + 1}`,
      revenue: 0,
      paymentsCount: 0,
    }));

    const methodMap = new Map<string, number>();
    const branchMap = new Map<string, { id: string; name: string; revenue: number }>();

    for (const p of payments) {
      const pMonth = new Date(p.payDate).getMonth();
      const amount = Number(p.amount);

      monthlyData[pMonth].revenue += amount;
      monthlyData[pMonth].paymentsCount += 1;

      // Method breakdown
      const method = p.method || 'OTHER';
      methodMap.set(method, (methodMap.get(method) || 0) + amount);

      // Branch breakdown
      const branch = p.invoice?.class?.branch;
      if (branch) {
        const existing = branchMap.get(branch.id) || { id: branch.id, name: branch.name, revenue: 0 };
        existing.revenue += amount;
        branchMap.set(branch.id, existing);
      }
    }

    const totalRevenue = monthlyData.reduce((sum, m) => sum + m.revenue, 0);
    const averageMonthlyRevenue = Math.round(totalRevenue / 12);
    let highestMonth = { month: 1, revenue: 0 };
    for (const m of monthlyData) {
      if (m.revenue > highestMonth.revenue) {
        highestMonth = { month: m.month, revenue: m.revenue };
      }
    }

    return {
      year,
      totalRevenue,
      averageMonthlyRevenue,
      highestMonth,
      monthlyData,
      byMethod: Array.from(methodMap.entries()).map(([method, revenue]) => ({
        method,
        revenue,
        percentage: totalRevenue > 0 ? Number(((revenue / totalRevenue) * 100).toFixed(1)) : 0,
      })),
      byBranch: Array.from(branchMap.values()).map((b) => ({
        ...b,
        percentage: totalRevenue > 0 ? Number(((b.revenue / totalRevenue) * 100).toFixed(1)) : 0,
      })),
    };
  }

  // --------------------------------------------------------------------------
  // 3. BÁO CÁO CHUYÊN CẦN
  // --------------------------------------------------------------------------
  async getAttendanceReport(dto: GetAttendanceReportDto, teacherId?: string) {
    const where: any = {};

    if (teacherId) {
      where.session = { class: { OR: [
        { mainTeacherId: teacherId }, { assistantTeacherId: teacherId },
      ] } };
    }

    if (dto.classId) {
      where.session = { ...where.session, classId: dto.classId };
    }

    if (dto.startDate || dto.endDate) {
      where.session = where.session || {};
      where.session.date = {};
      if (dto.startDate) where.session.date.gte = new Date(dto.startDate);
      if (dto.endDate) where.session.date.lte = new Date(dto.endDate);
    }

    const attendances = await this.prisma.attendance.findMany({
      where,
      select: {
        status: true,
        session: {
          select: {
            class: {
              select: { id: true, name: true },
            },
          },
        },
      },
    });

    const totalRecords = attendances.length;
    let presentCount = 0;
    let lateCount = 0;
    let absentCount = 0;
    let excusedCount = 0;
    let makeupCount = 0;

    const classMap = new Map<string, { id: string; name: string; total: number; present: number }>();

    for (const att of attendances) {
      const st = att.status?.toUpperCase();
      if (st === 'PRESENT') presentCount++;
      else if (st === 'LATE') lateCount++;
      else if (st === 'ABSENT') absentCount++;
      else if (st === 'EXCUSED') excusedCount++;
      else if (st === 'MAKEUP') makeupCount++;

      const cls = att.session?.class;
      if (cls) {
        const item = classMap.get(cls.id) || { id: cls.id, name: cls.name, total: 0, present: 0 };
        item.total++;
        if (st === 'PRESENT' || st === 'LATE' || st === 'MAKEUP') {
          item.present++;
        }
        classMap.set(cls.id, item);
      }
    }

    const attendanceRate =
      totalRecords > 0
        ? Number((((presentCount + lateCount + makeupCount) / totalRecords) * 100).toFixed(1))
        : 100;

    return {
      totalRecords,
      presentCount,
      lateCount,
      absentCount,
      excusedCount,
      makeupCount,
      attendanceRate,
      byClass: Array.from(classMap.values()).map((c) => ({
        ...c,
        attendanceRate: c.total > 0 ? Number(((c.present / c.total) * 100).toFixed(1)) : 100,
      })),
    };
  }

  // --------------------------------------------------------------------------
  // 4. BÁO CÁO KẾT QUẢ HỌC TẬP
  // --------------------------------------------------------------------------
  async getAcademicReport(dto: GetAcademicReportDto, teacherId?: string) {
    const where: any = {
      status: { in: ['SUBMITTED', 'GRADED'] },
    };

    if (dto.examId) {
      where.examId = dto.examId;
    }
    if (teacherId) {
      where.exam = { class: { OR: [
        { mainTeacherId: teacherId }, { assistantTeacherId: teacherId },
      ] } };
    }
    if (dto.classId) {
      where.exam = { ...where.exam, classId: dto.classId };
    }

    const attempts = await this.prisma.examAttempt.findMany({
      where,
      select: {
        id: true,
        score: true,
        maxScore: true,
        isPassed: true,
        student: {
          select: { id: true, fullName: true, userCode: true },
        },
        exam: {
          select: { id: true, title: true, passPercentage: true },
        },
      },
    });

    const totalAttempts = attempts.length;
    let excellentCount = 0; // >= 85%
    let goodCount = 0;      // 70% - 84%
    let averageCount = 0;   // 50% - 69%
    let poorCount = 0;      // < 50%
    let passedCount = 0;
    let totalScore = 0;

    for (const a of attempts) {
      const score = Number(a.score || 0);
      const maxScore = Number(a.maxScore || 0);
      const pct = maxScore > 0 ? (score / maxScore) * 100 : 0;
      totalScore += score;

      if (a.isPassed) passedCount++;

      if (pct >= 85) excellentCount++;
      else if (pct >= 70) goodCount++;
      else if (pct >= 50) averageCount++;
      else poorCount++;
    }

    const averageScore = totalAttempts > 0 ? Number((totalScore / totalAttempts).toFixed(1)) : 0;
    const passRate = totalAttempts > 0 ? Number(((passedCount / totalAttempts) * 100).toFixed(1)) : 0;

    // Top 5 học viên điểm cao
    const sortedAttempts = [...attempts].sort((a, b) => Number(b.score || 0) - Number(a.score || 0));
    const topStudents = sortedAttempts.slice(0, 5).map((a) => ({
      attemptId: a.id,
      studentName: a.student.fullName,
      studentCode: a.student.userCode,
      examTitle: a.exam.title,
      score: Number(a.score || 0),
      percentage: Number(a.maxScore || 0) > 0
        ? Number(((Number(a.score || 0) / Number(a.maxScore)) * 100).toFixed(1))
        : 0,
      isPassed: a.isPassed,
    }));

    return {
      totalAttempts,
      averageScore,
      passRate,
      classification: {
        excellent: { count: excellentCount, percentage: totalAttempts ? Number(((excellentCount / totalAttempts) * 100).toFixed(1)) : 0 },
        good: { count: goodCount, percentage: totalAttempts ? Number(((goodCount / totalAttempts) * 100).toFixed(1)) : 0 },
        average: { count: averageCount, percentage: totalAttempts ? Number(((averageCount / totalAttempts) * 100).toFixed(1)) : 0 },
        poor: { count: poorCount, percentage: totalAttempts ? Number(((poorCount / totalAttempts) * 100).toFixed(1)) : 0 },
      },
      topStudents,
    };
  }

  // --------------------------------------------------------------------------
  // 5. BÁO CÁO CÔNG NỢ
  // --------------------------------------------------------------------------
  async getDebtsReport(dto: GetDebtsReportDto) {
    const page = dto.page || 1;
    const limit = dto.limit || 20;
    const skip = (page - 1) * limit;

    const where: any = {
      status: { in: ['PENDING', 'PARTIALLY_PAID', 'OVERDUE'] },
      balance: { gt: 0 },
    };

    if (dto.branchId) {
      where.class = { branchId: dto.branchId };
    }

    if (dto.search) {
      where.OR = [
        { code: { contains: dto.search, mode: 'insensitive' } },
        { student: { fullName: { contains: dto.search, mode: 'insensitive' } } },
        { student: { userCode: { contains: dto.search, mode: 'insensitive' } } },
      ];
    }

    const [invoices, total, aggregate] = await Promise.all([
      this.prisma.invoice.findMany({
        where,
        skip,
        take: limit,
        orderBy: { dueDate: 'asc' },
        include: {
          student: {
            select: { id: true, fullName: true, userCode: true, phone: true, email: true },
          },
          class: {
            select: { id: true, name: true },
          },
        },
      }),
      this.prisma.invoice.count({ where }),
      this.prisma.invoice.aggregate({
        where,
        _sum: { balance: true, totalAmount: true, paidAmount: true },
      }),
    ]);

    const now = new Date();
    const overdueCount = invoices.filter((inv) => inv.dueDate && new Date(inv.dueDate) < now).length;

    return {
      items: invoices.map((inv) => ({
        id: inv.id,
        code: inv.code,
        studentName: inv.student.fullName,
        studentCode: inv.student.userCode,
        phone: inv.student.phone,
        email: inv.student.email,
        className: inv.class?.name || 'Học phí chung',
        totalAmount: Number(inv.totalAmount),
        paidAmount: Number(inv.paidAmount),
        balance: Number(inv.balance),
        status: inv.status,
        dueDate: inv.dueDate,
        isOverdue: inv.dueDate ? new Date(inv.dueDate) < now : false,
      })),
      total,
      page,
      limit,
      summary: {
        totalOutstanding: Number(aggregate._sum.balance || 0),
        totalInvoiced: Number(aggregate._sum.totalAmount || 0),
        totalPaid: Number(aggregate._sum.paidAmount || 0),
        overdueCount,
      },
    };
  }

  // --------------------------------------------------------------------------
  // 6. BÁO CÁO TẢI GIỜ DẠY GIÁO VIÊN (WORKLOAD)
  // --------------------------------------------------------------------------
  async getTeacherWorkloadReport() {
    const teachers = await this.prisma.user.findMany({
      where: {
        userRoles: {
          some: {
            role: { code: 'teacher' },
          },
        },
        status: UserStatus.ACTIVE,
      },
      select: {
        id: true,
        fullName: true,
        userCode: true,
        email: true,
        phone: true,
        taughtClasses: {
          select: {
            id: true,
            status: true,
          },
        },
        sessionTeachers: {
          select: {
            id: true,
            status: true,
          },
        },
      },
    });

    return teachers.map((t) => {
      const activeClassesCount = t.taughtClasses.filter(
        (c) => c.status === ClassStatus.OPEN_FOR_ENROLLMENT || c.status === ClassStatus.IN_PROGRESS,
      ).length;
      const totalSessions = t.sessionTeachers.length;
      const completedSessions = t.sessionTeachers.filter((s) => s.status === SessionStatus.COMPLETED).length;
      // Mỗi buổi học tiêu chuẩn là 1.5 giờ dạy
      const totalTeachingHours = Number((completedSessions * 1.5).toFixed(1));

      return {
        teacherId: t.id,
        fullName: t.fullName,
        userCode: t.userCode,
        email: t.email,
        phone: t.phone,
        activeClassesCount,
        totalSessions,
        completedSessions,
        totalTeachingHours,
      };
    });
  }

  // --------------------------------------------------------------------------
  // 7. XUẤT EXCEL (.xlsx)
  // --------------------------------------------------------------------------
  async exportReportExcel(type: ExportReportType): Promise<Buffer> {
    const wb = XLSX.utils.book_new();

    if (type === ExportReportType.REVENUE) {
      const data = await this.getRevenueReport({});
      const rows = data.monthlyData.map((m) => ({
        'Tháng': `Tháng ${m.month}`,
        'Doanh thu (VNĐ)': m.revenue,
        'Số lượt thanh toán': m.paymentsCount,
      }));
      rows.push({
        'Tháng': 'TỔNG CỘNG NĂM',
        'Doanh thu (VNĐ)': data.totalRevenue,
        'Số lượt thanh toán': data.monthlyData.reduce((acc, cur) => acc + cur.paymentsCount, 0),
      });

      const ws = XLSX.utils.json_to_sheet(rows);
      XLSX.utils.book_append_sheet(wb, ws, 'DoanhThu');
    } else if (type === ExportReportType.DEBTS) {
      const data = await this.getDebtsReport({ limit: 1000 });
      const rows = data.items.map((i) => ({
        'Mã HĐ': i.code,
        'Tên học viên': i.studentName,
        'Mã học viên': i.studentCode,
        'Số điện thoại': i.phone || '',
        'Lớp học': i.className,
        'Tổng học phí': i.totalAmount,
        'Đã nộp': i.paidAmount,
        'Còn nợ (VNĐ)': i.balance,
        'Hạn nộp': i.dueDate ? new Date(i.dueDate).toLocaleDateString('vi-VN') : '',
        'Trạng thái': i.isOverdue ? 'Quá hạn' : 'Đúng hạn',
      }));

      const ws = XLSX.utils.json_to_sheet(rows);
      XLSX.utils.book_append_sheet(wb, ws, 'CongNo');
    } else if (type === ExportReportType.ATTENDANCE) {
      const data = await this.getAttendanceReport({});
      const rows = data.byClass.map((c) => ({
        'Mã / Tên Lớp': c.name,
        'Tổng lượt điểm danh': c.total,
        'Có mặt': c.present,
        'Tỷ lệ chuyên cần (%)': `${c.attendanceRate}%`,
      }));

      const ws = XLSX.utils.json_to_sheet(rows);
      XLSX.utils.book_append_sheet(wb, ws, 'ChuyenCan');
    } else if (type === ExportReportType.WORKLOAD) {
      const data = await this.getTeacherWorkloadReport();
      const rows = data.map((t) => ({
        'Mã GV': t.userCode || '',
        'Họ tên giáo viên': t.fullName,
        'Email': t.email,
        'Số lớp đang dạy': t.activeClassesCount,
        'Tổng số buổi': t.totalSessions,
        'Buổi đã dạy': t.completedSessions,
        'Giờ dạy quy đổi (giờ)': t.totalTeachingHours,
      }));

      const ws = XLSX.utils.json_to_sheet(rows);
      XLSX.utils.book_append_sheet(wb, ws, 'TaiGioDay');
    }

    const buffer = XLSX.write(wb, { type: 'buffer', bookType: 'xlsx' });
    return buffer as Buffer;
  }

  // --------------------------------------------------------------------------
  // HELPER METHODS
  // --------------------------------------------------------------------------
  private async getSixMonthsRevenueTrend() {
    const now = new Date();
    const months = [];
    for (let i = 5; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const start = new Date(d.getFullYear(), d.getMonth(), 1);
      const end = new Date(d.getFullYear(), d.getMonth() + 1, 0, 23, 59, 59);

      const payments = await this.prisma.payment.aggregate({
        _sum: { amount: true },
        where: {
          status: 'SUCCESS',
          payDate: { gte: start, lte: end },
        },
      });

      months.push({
        month: `T${d.getMonth() + 1}/${d.getFullYear()}`,
        revenue: Number(payments._sum.amount || 0),
      });
    }
    return months;
  }

  private async getStudentCourseDistribution() {
    const courses = await this.prisma.course.findMany({
      select: {
        id: true,
        title: true,
        classes: {
          select: {
            _count: {
              select: { students: true },
            },
          },
        },
      },
    });

    return courses.map((c) => {
      const totalStudents = c.classes.reduce((sum, cls) => sum + cls._count.students, 0);
      return {
        courseId: c.id,
        courseName: c.title,
        studentCount: totalStudents,
      };
    });
  }

  async clearDashboardCache() {
    try {
      await this.redis.del(this.DASHBOARD_CACHE_KEY);
    } catch (e) {
      this.logger.warn(`Lỗi xóa cache: ${e}`);
    }
  }
}
