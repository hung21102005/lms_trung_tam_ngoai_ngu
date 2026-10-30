import { describe, it, expect, beforeEach, vi } from 'vitest';
import { ReportsService } from './reports.service.js';
import { ExportReportType } from './dto/index.js';

describe('ReportsService', () => {
  let service: ReportsService;
  let mockPrisma: any;
  let mockRedis: any;

  beforeEach(() => {
    mockPrisma = {
      user: {
        count: vi.fn(),
        findMany: vi.fn(),
      },
      class: {
        count: vi.fn(),
        findMany: vi.fn(),
      },
      classSession: { findMany: vi.fn() },
      submission: { findMany: vi.fn(), count: vi.fn() },
      notification: { count: vi.fn() },
      payment: {
        aggregate: vi.fn(),
        findMany: vi.fn(),
      },
      invoice: {
        aggregate: vi.fn(),
        findMany: vi.fn(),
        count: vi.fn(),
      },
      attendance: {
        findMany: vi.fn(),
        groupBy: vi.fn(),
      },
      examAttempt: {
        findMany: vi.fn(),
        count: vi.fn(),
      },
      course: {
        findMany: vi.fn(),
      },
    };

    mockRedis = {
      get: vi.fn().mockResolvedValue(null),
      set: vi.fn().mockResolvedValue(true),
      del: vi.fn().mockResolvedValue(true),
    };

    service = new ReportsService(mockPrisma as any, mockRedis as any);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('scopes teacher dashboard data to the assigned teacher', async () => {
    mockPrisma.class.findMany.mockResolvedValue([{ id: 'class-1', code: 'C1', name: 'IELTS', status: 'IN_PROGRESS', students: [{ studentId: 'student-1' }] }]);
    mockPrisma.classSession.findMany.mockResolvedValue([]);
    mockPrisma.submission.findMany.mockResolvedValue([]);
    mockPrisma.submission.count.mockResolvedValue(2);
    mockPrisma.examAttempt.count.mockResolvedValue(1);
    mockPrisma.attendance.groupBy.mockResolvedValue([{ studentId: 'student-1', _count: { studentId: 3 } }]);
    mockPrisma.user.findMany.mockResolvedValue([{ id: 'student-1', fullName: 'Minh Anh', userCode: 'HV-01' }]);
    mockPrisma.notification.count.mockResolvedValue(1);

    const result = await service.getTeacherDashboard('teacher-1');

    expect(result.activeClasses).toBe(1);
    expect(result.totalStudents).toBe(1);
    expect(result.pendingAssignments).toBe(2);
    expect(result.pendingExams).toBe(1);
    expect(result.studentsNeedingAttention).toBe(1);
    expect(result.attendanceAlerts).toEqual([{ id: 'student-1', fullName: 'Minh Anh', userCode: 'HV-01', absencesLast30Days: 3 }]);
    expect(mockPrisma.class.findMany).toHaveBeenCalledWith(expect.objectContaining({
      where: { OR: [{ mainTeacherId: 'teacher-1' }, { assistantTeacherId: 'teacher-1' }] },
    }));
    expect(mockPrisma.submission.count).toHaveBeenCalledWith({ where: expect.objectContaining({
      assignment: { classId: { in: ['class-1'] } },
    }) });
  });

  it('limits attendance and academic reports to the teacher classes even with a class filter', async () => {
    mockPrisma.attendance.findMany.mockResolvedValue([]);
    mockPrisma.examAttempt.findMany.mockResolvedValue([]);

    await service.getAttendanceReport({ classId: 'class-1' }, 'teacher-1');
    await service.getAcademicReport({ classId: 'class-1' }, 'teacher-1');

    expect(mockPrisma.attendance.findMany).toHaveBeenCalledWith(expect.objectContaining({
      where: { session: { classId: 'class-1', class: { OR: [
        { mainTeacherId: 'teacher-1' }, { assistantTeacherId: 'teacher-1' },
      ] } } },
    }));
    expect(mockPrisma.examAttempt.findMany).toHaveBeenCalledWith(expect.objectContaining({
      where: { status: { in: ['SUBMITTED', 'GRADED'] }, exam: {
        classId: 'class-1', class: { OR: [
          { mainTeacherId: 'teacher-1' }, { assistantTeacherId: 'teacher-1' },
        ] },
      } },
    }));
  });

  it('calculates academic percentages from score and maxScore stored in ExamAttempt', async () => {
    mockPrisma.examAttempt.findMany.mockResolvedValue([
      {
        id: 'attempt-1', score: 8, maxScore: 10, isPassed: true,
        student: { fullName: 'Minh Anh', userCode: 'HV-01' },
        exam: { title: 'Kiểm tra giữa kỳ' },
      },
    ]);

    const result = await service.getAcademicReport({ classId: 'class-1' }, 'teacher-1');

    expect(mockPrisma.examAttempt.findMany).toHaveBeenCalledWith(expect.objectContaining({
      select: expect.objectContaining({ maxScore: true }),
    }));
    expect(result.averageScore).toBe(8);
    expect(result.passRate).toBe(100);
    expect(result.classification.good.count).toBe(1);
    expect(result.topStudents[0].percentage).toBe(80);
  });

  describe('getDashboardOverview', () => {
    it('should aggregate metrics and store in redis cache', async () => {
      mockPrisma.user.count.mockResolvedValueOnce(120).mockResolvedValueOnce(15);
      mockPrisma.class.count.mockResolvedValue(8);
      mockPrisma.payment.aggregate
        .mockResolvedValueOnce({ _sum: { amount: 50000000 } })
        .mockResolvedValueOnce({ _sum: { amount: 40000000 } })
        .mockResolvedValue({ _sum: { amount: 30000000 } });
      mockPrisma.invoice.aggregate.mockResolvedValue({ _sum: { balance: 12000000 } });
      mockPrisma.course.findMany.mockResolvedValue([
        { id: 'c-1', name: 'IELTS', classes: [{ _count: { students: 40 } }] },
      ]);
      mockPrisma.class.findMany.mockResolvedValue([]);
      mockPrisma.invoice.findMany.mockResolvedValue([]);

      const result = await service.getDashboardOverview();

      expect(result.totalStudents).toBe(120);
      expect(result.newStudentsThisMonth).toBe(15);
      expect(result.totalActiveClasses).toBe(8);
      expect(result.monthlyRevenue).toBe(50000000);
      expect(result.lastMonthRevenue).toBe(40000000);
      expect(result.monthlyRevenueGrowth).toBe(25.0);
      expect(result.totalDebts).toBe(12000000);
      expect(mockRedis.set).toHaveBeenCalled();
    });

    it('should return cached data if available in Redis', async () => {
      const cachedData = { totalStudents: 99, monthlyRevenue: 10000000 };
      mockRedis.get.mockResolvedValue(JSON.stringify(cachedData));

      const result = await service.getDashboardOverview();
      expect(result.totalStudents).toBe(99);
      expect(mockPrisma.user.count).not.toHaveBeenCalled();
    });
  });

  describe('getRevenueReport', () => {
    it('should calculate monthly revenue and payment method breakdown', async () => {
      mockPrisma.payment.findMany.mockResolvedValue([
        { amount: 5000000, payDate: new Date(2026, 0, 15), method: 'VNPAY', invoice: null },
        { amount: 3000000, payDate: new Date(2026, 0, 20), method: 'CASH', invoice: null },
        { amount: 7000000, payDate: new Date(2026, 1, 10), method: 'VNPAY', invoice: null },
      ]);

      const result = await service.getRevenueReport({ year: 2026 });

      expect(result.year).toBe(2026);
      expect(result.totalRevenue).toBe(15000000);
      expect(result.monthlyData[0].revenue).toBe(8000000);
      expect(result.monthlyData[1].revenue).toBe(7000000);
      expect(result.byMethod).toHaveLength(2);
    });
  });

  describe('getAttendanceReport', () => {
    it('should calculate attendance rate and breakdown by status', async () => {
      mockPrisma.attendance.findMany.mockResolvedValue([
        { status: 'PRESENT', session: { class: { id: 'c1', name: 'IELTS 1' } } },
        { status: 'PRESENT', session: { class: { id: 'c1', name: 'IELTS 1' } } },
        { status: 'LATE', session: { class: { id: 'c1', name: 'IELTS 1' } } },
        { status: 'ABSENT', session: { class: { id: 'c1', name: 'IELTS 1' } } },
      ]);

      const result = await service.getAttendanceReport({});

      expect(result.totalRecords).toBe(4);
      expect(result.presentCount).toBe(2);
      expect(result.lateCount).toBe(1);
      expect(result.absentCount).toBe(1);
      expect(result.attendanceRate).toBe(75.0);
      expect(result.byClass).toHaveLength(1);
    });
  });

  describe('getAcademicReport', () => {
    it('should compute score distributions and top students', async () => {
      mockPrisma.examAttempt.findMany.mockResolvedValue([
        {
          id: 'att-1',
          score: 9.0,
          maxScore: 10,
          isPassed: true,
          student: { id: 's1', fullName: 'Nguyễn A', userCode: 'HV01' },
          exam: { id: 'e1', title: 'Midterm', passPercentage: 50 },
        },
        {
          id: 'att-2',
          score: 7.5,
          maxScore: 10,
          isPassed: true,
          student: { id: 's2', fullName: 'Trần B', userCode: 'HV02' },
          exam: { id: 'e1', title: 'Midterm', passPercentage: 50 },
        },
        {
          id: 'att-3',
          score: 4.0,
          maxScore: 10,
          isPassed: false,
          student: { id: 's3', fullName: 'Lê C', userCode: 'HV03' },
          exam: { id: 'e1', title: 'Midterm', passPercentage: 50 },
        },
      ]);

      const result = await service.getAcademicReport({});

      expect(result.totalAttempts).toBe(3);
      expect(result.averageScore).toBe(6.8);
      expect(result.passRate).toBe(66.7);
      expect(result.classification.excellent.count).toBe(1);
      expect(result.classification.good.count).toBe(1);
      expect(result.classification.poor.count).toBe(1);
      expect(result.topStudents[0].studentName).toBe('Nguyễn A');
    });
  });

  describe('getDebtsReport', () => {
    it('should return list of overdue and outstanding invoices', async () => {
      const pastDate = new Date(2026, 8, 1);
      mockPrisma.invoice.findMany.mockResolvedValue([
        {
          id: 'inv-1',
          code: 'HD-001',
          totalAmount: 5000000,
          paidAmount: 2000000,
          balance: 3000000,
          status: 'PARTIALLY_PAID',
          dueDate: pastDate,
          student: { id: 's1', fullName: 'Học viên A', userCode: 'HV01', phone: '0901', email: 'a@lms.vn' },
          class: { id: 'c1', name: 'Lớp 1' },
        },
      ]);
      mockPrisma.invoice.count.mockResolvedValue(1);
      mockPrisma.invoice.aggregate.mockResolvedValue({
        _sum: { balance: 3000000, totalAmount: 5000000, paidAmount: 2000000 },
      });

      const result = await service.getDebtsReport({});

      expect(result.items).toHaveLength(1);
      expect(result.items[0].balance).toBe(3000000);
      expect(result.items[0].isOverdue).toBe(true);
      expect(result.summary.totalOutstanding).toBe(3000000);
    });
  });

  describe('getTeacherWorkloadReport', () => {
    it('should aggregate teaching hours per teacher', async () => {
      mockPrisma.user.findMany.mockResolvedValue([
        {
          id: 't-1',
          fullName: 'Thầy David',
          userCode: 'GV01',
          email: 'david@lms.vn',
          phone: '0912',
          taughtClasses: [{ id: 'c1', status: 'IN_PROGRESS' }],
          sessionTeachers: [{ id: 's1', status: 'COMPLETED' }, { id: 's2', status: 'SCHEDULED' }],
        },
      ]);

      const result = await service.getTeacherWorkloadReport();

      expect(result).toHaveLength(1);
      expect(result[0].fullName).toBe('Thầy David');
      expect(result[0].activeClassesCount).toBe(1);
      expect(result[0].completedSessions).toBe(1);
      expect(result[0].totalTeachingHours).toBe(1.5);
    });
  });

  describe('exportReportExcel', () => {
    it('should generate a valid XLSX buffer for revenue', async () => {
      mockPrisma.payment.findMany.mockResolvedValue([]);
      const buffer = await service.exportReportExcel(ExportReportType.REVENUE);

      expect(buffer).toBeDefined();
      expect(Buffer.isBuffer(buffer)).toBe(true);
      expect(buffer.length).toBeGreaterThan(0);
    });

    it('should generate a valid XLSX buffer for debts', async () => {
      mockPrisma.invoice.findMany.mockResolvedValue([]);
      mockPrisma.invoice.count.mockResolvedValue(0);
      mockPrisma.invoice.aggregate.mockResolvedValue({ _sum: { balance: 0, totalAmount: 0, paidAmount: 0 } });

      const buffer = await service.exportReportExcel(ExportReportType.DEBTS);

      expect(buffer).toBeDefined();
      expect(Buffer.isBuffer(buffer)).toBe(true);
    });
  });
});
