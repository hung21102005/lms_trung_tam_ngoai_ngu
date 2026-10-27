import { describe, it, expect, vi, beforeEach } from 'vitest';
import { AttendanceService } from './attendance.service.js';
import { AttendanceStatus, MakeupStatus, SessionStatus } from '@prisma/client';
import {
  BadRequestException,
  ForbiddenException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';

describe('AttendanceService', () => {
  let service: AttendanceService;
  let prismaMock: any;
  let notificationsMock: any;

  beforeEach(() => {
    prismaMock = {
      classSession: {
        findUnique: vi.fn(),
        update: vi.fn(),
        updateMany: vi.fn().mockResolvedValue({ count: 1 }),
      },
      attendance: {
        upsert: vi.fn(),
        findUnique: vi.fn(),
        update: vi.fn(),
        findMany: vi.fn(),
      },
      classStudent: { findMany: vi.fn(), findFirst: vi.fn() },
      user: {
        findUnique: vi.fn(),
      },
      class: {
        findUnique: vi.fn(),
      },
      parentStudent: {
        findMany: vi.fn(),
        findFirst: vi.fn(),
      },
      makeupRequest: {
        create: vi.fn(),
        findUnique: vi.fn(),
        findMany: vi.fn(),
        update: vi.fn(),
      },
      $transaction: vi.fn((callback) => callback(prismaMock)),
    };

    notificationsMock = { notifyAbsence: vi.fn().mockResolvedValue(undefined) };
    service = new AttendanceService(prismaMock, notificationsMock);
  });

  describe('getSessionAttendance', () => {
    it('should return session details, summary, and students with attendance status', async () => {
      const mockSession = {
        id: 'session-1',
        classId: 'class-1',
        sessionNumber: 1,
        title: 'Buổi 1: Unit 1 Greetings',
        date: new Date('2026-10-18'),
        startTime: '18:00',
        endTime: '19:30',
        status: SessionStatus.SCHEDULED,
        room: { id: 'room-1', name: 'Phòng 101' },
        teacher: { id: 'teacher-1', fullName: 'Thầy David' },
        class: {
          code: 'IELTS-F-01',
          name: 'IELTS Foundation',
          mainTeacherId: 'teacher-1',
          students: [
            {
              student: {
                id: 'student-1',
                userCode: 'HV001',
                fullName: 'Nguyễn Văn A',
                avatarUrl: null,
                phone: '0901234567',
                email: 'a@example.com',
              },
            },
            {
              student: {
                id: 'student-2',
                userCode: 'HV002',
                fullName: 'Trần Thị B',
                avatarUrl: null,
                phone: '0907654321',
                email: 'b@example.com',
              },
            },
          ],
        },
        attendances: [
          {
            id: 'att-1',
            studentId: 'student-1',
            status: AttendanceStatus.PRESENT,
            checkInTime: new Date('2026-10-18T18:00:00Z'),
            notes: null,
            markedBy: {
              id: 'teacher-1',
              fullName: 'Thầy David',
              userCode: 'GV001',
            },
            markedAt: new Date(),
          },
        ],
      };

      prismaMock.classSession.findUnique.mockResolvedValue(mockSession);

      const result = await service.getSessionAttendance('session-1', {
        id: 'teacher-1',
        roles: ['teacher'],
      });

      expect(result.session.id).toBe('session-1');
      expect(result.summary.totalEnrolled).toBe(2);
      expect(result.summary.present).toBe(1);
      expect(result.summary.markedCount).toBe(1);
      expect(result.students.length).toBe(2);
      expect(result.students[0].status).toBe(AttendanceStatus.PRESENT);
      expect(result.students[1].status).toBeNull();
    });

    it('should throw NotFoundException if session not found', async () => {
      prismaMock.classSession.findUnique.mockResolvedValue(null);
      await expect(
        service.getSessionAttendance('invalid-id', {
          id: 'teacher-1',
          roles: ['teacher'],
        }),
      ).rejects.toThrow(NotFoundException);
    });

    it('prevents an unrelated teacher from opening the class roster', async () => {
      prismaMock.classSession.findUnique.mockResolvedValue({
        id: 'session-1',
        teacherId: 'teacher-1',
        class: { mainTeacherId: 'teacher-1' },
      });
      await expect(
        service.getSessionAttendance('session-1', {
          id: 'teacher-2',
          roles: ['teacher'],
        }),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  describe('batchMarkAttendance', () => {
    it('should upsert attendance records, alert for absent students, and keep the session in progress until explicitly locked', async () => {
      const mockSession = {
        id: 'session-1',
        classId: 'class-1',
        title: 'Buổi 1: Unit 1 Greetings',
        status: SessionStatus.SCHEDULED,
        class: { name: 'IELTS Foundation', mainTeacherId: 'teacher-1' },
        date: new Date('2026-10-18'),
      };

      prismaMock.classSession.findUnique.mockResolvedValue(mockSession);
      prismaMock.attendance.upsert.mockResolvedValue({ id: 'att-1' });
      prismaMock.classStudent.findMany.mockResolvedValue([
        { studentId: 'student-1' },
        { studentId: 'student-2' },
      ]);
      prismaMock.attendance.findMany.mockResolvedValue([]);
      prismaMock.classSession.update.mockResolvedValue({});

      // Mock getSessionAttendance call at the end
      vi.spyOn(service, 'getSessionAttendance').mockResolvedValue({
        session: mockSession,
        summary: {
          totalEnrolled: 2,
          markedCount: 2,
          present: 1,
          absent: 1,
          late: 0,
          excused: 0,
          makeup: 0,
        },
        students: [],
      } as any);

      const dto = {
        students: [
          { studentId: 'student-1', status: AttendanceStatus.PRESENT },
          {
            studentId: 'student-2',
            status: AttendanceStatus.ABSENT,
            notes: 'Không phép',
          },
        ],
      };

      const result = await service.batchMarkAttendance('session-1', dto, {
        id: 'teacher-1',
        roles: ['teacher'],
      });

      expect(prismaMock.attendance.upsert).toHaveBeenCalledTimes(2);
      expect(notificationsMock.notifyAbsence).toHaveBeenCalledWith(
        'student-2',
        mockSession.title,
        mockSession.date,
      );
      expect(prismaMock.classSession.updateMany).toHaveBeenCalledWith({
        where: { id: 'session-1', status: SessionStatus.SCHEDULED },
        data: { status: SessionStatus.IN_PROGRESS },
      });
      expect(result.summary.present).toBe(1);
      expect(result.summary.absent).toBe(1);
    });

    it('rejects a student outside the enrolled class before writing', async () => {
      prismaMock.classSession.findUnique.mockResolvedValue({
        id: 'session-1',
        classId: 'class-1',
        status: SessionStatus.SCHEDULED,
        class: { mainTeacherId: 'teacher-1' },
      });
      prismaMock.classStudent.findMany.mockResolvedValue([
        { studentId: 'student-1' },
      ]);

      await expect(
        service.batchMarkAttendance(
          'session-1',
          {
            students: [
              { studentId: 'other-student', status: AttendanceStatus.PRESENT },
            ],
          },
          { id: 'teacher-1', roles: ['teacher'] },
        ),
      ).rejects.toThrow(ForbiddenException);
      expect(prismaMock.attendance.upsert).not.toHaveBeenCalled();
    });

    it('rejects duplicate student IDs before writing', async () => {
      prismaMock.classSession.findUnique.mockResolvedValue({
        id: 'session-1',
        classId: 'class-1',
        status: SessionStatus.SCHEDULED,
        class: { mainTeacherId: 'teacher-1' },
      });
      await expect(
        service.batchMarkAttendance(
          'session-1',
          {
            students: [
              { studentId: 'student-1', status: AttendanceStatus.PRESENT },
              { studentId: 'student-1', status: AttendanceStatus.ABSENT },
            ],
          },
          { id: 'teacher-1', roles: ['teacher'] },
        ),
      ).rejects.toThrow(BadRequestException);
      expect(prismaMock.attendance.upsert).not.toHaveBeenCalled();
    });

    it('keeps the session in progress until every enrolled student is marked', async () => {
      prismaMock.classSession.findUnique.mockResolvedValue({
        id: 'session-1',
        classId: 'class-1',
        status: SessionStatus.SCHEDULED,
        class: { mainTeacherId: 'teacher-1' },
      });
      prismaMock.classStudent.findMany.mockResolvedValue([
        { studentId: 'student-1' },
        { studentId: 'student-2' },
      ]);
      prismaMock.attendance.findMany.mockResolvedValue([]);
      vi.spyOn(service, 'getSessionAttendance').mockResolvedValue({} as any);

      await service.batchMarkAttendance(
        'session-1',
        {
          students: [
            { studentId: 'student-1', status: AttendanceStatus.PRESENT },
          ],
        },
        { id: 'teacher-1', roles: ['teacher'] },
      );

      expect(prismaMock.classSession.updateMany).toHaveBeenCalledWith({
        where: { id: 'session-1', status: SessionStatus.SCHEDULED },
        data: { status: SessionStatus.IN_PROGRESS },
      });
    });

    it('locks attendance and session together after the complete class is marked', async () => {
      prismaMock.classSession.findUnique.mockResolvedValue({
        id: 'session-1', classId: 'class-1', title: 'Buổi học',
        date: new Date('2026-10-27'), status: SessionStatus.SCHEDULED,
        class: { mainTeacherId: 'teacher-1' },
      });
      prismaMock.classStudent.findMany.mockResolvedValue([{ studentId: 'student-1' }]);
      prismaMock.attendance.findMany.mockResolvedValue([]);
      vi.spyOn(service, 'getSessionAttendance').mockResolvedValue({} as any);

      await service.batchMarkAttendance('session-1', {
        lock: true,
        students: [{ studentId: 'student-1', status: AttendanceStatus.PRESENT }],
      }, { id: 'teacher-1', roles: ['teacher'] });

      expect(prismaMock.$transaction).toHaveBeenCalledTimes(1);
      expect(prismaMock.attendance.upsert).toHaveBeenCalledTimes(1);
      expect(prismaMock.classSession.updateMany).toHaveBeenCalledWith({
        where: { id: 'session-1', status: { not: SessionStatus.COMPLETED } },
        data: { status: SessionStatus.COMPLETED },
      });
    });

    it('does not lock a partially marked class', async () => {
      prismaMock.classSession.findUnique.mockResolvedValue({
        id: 'session-1', classId: 'class-1', status: SessionStatus.SCHEDULED,
        class: { mainTeacherId: 'teacher-1' },
      });
      prismaMock.classStudent.findMany.mockResolvedValue([
        { studentId: 'student-1' }, { studentId: 'student-2' },
      ]);
      await expect(service.batchMarkAttendance('session-1', {
        lock: true,
        students: [{ studentId: 'student-1', status: AttendanceStatus.PRESENT }],
      }, { id: 'teacher-1', roles: ['teacher'] })).rejects.toBeInstanceOf(BadRequestException);
      expect(prismaMock.$transaction).not.toHaveBeenCalled();
    });

    it('rejects a second lock when another request completed the session', async () => {
      prismaMock.classSession.findUnique.mockResolvedValue({
        id: 'session-1', classId: 'class-1', title: 'Buổi học',
        date: new Date('2026-10-27'), status: SessionStatus.SCHEDULED,
        class: { mainTeacherId: 'teacher-1' },
      });
      prismaMock.classStudent.findMany.mockResolvedValue([{ studentId: 'student-1' }]);
      prismaMock.attendance.findMany.mockResolvedValue([]);
      prismaMock.classSession.updateMany.mockResolvedValue({ count: 0 });

      await expect(service.batchMarkAttendance('session-1', {
        lock: true,
        students: [{ studentId: 'student-1', status: AttendanceStatus.PRESENT }],
      }, { id: 'teacher-1', roles: ['teacher'] })).rejects.toBeInstanceOf(ConflictException);
    });

    it('rejects changes after attendance has been locked', async () => {
      prismaMock.classSession.findUnique.mockResolvedValue({
        id: 'session-1',
        classId: 'class-1',
        title: 'Buổi 1',
        date: new Date(),
        status: SessionStatus.COMPLETED,
        class: { mainTeacherId: 'teacher-1' },
      });
      prismaMock.classStudent.findMany.mockResolvedValue([
        { studentId: 'student-1' },
      ]);
      prismaMock.attendance.findMany.mockResolvedValue([
        { studentId: 'student-1', status: AttendanceStatus.ABSENT },
      ]);
      vi.spyOn(service, 'getSessionAttendance').mockResolvedValue({} as any);

      await expect(
        service.batchMarkAttendance(
          'session-1',
          {
            students: [
              { studentId: 'student-1', status: AttendanceStatus.ABSENT },
            ],
          },
          { id: 'teacher-1', roles: ['teacher'] },
        ),
      ).rejects.toThrow(BadRequestException);
      expect(prismaMock.attendance.upsert).not.toHaveBeenCalled();
    });
  });

  describe('getStudentAttendanceHistory', () => {
    it('allows a linked parent and rejects an unrelated parent', async () => {
      prismaMock.user.findUnique.mockResolvedValue({
        id: 'student-1',
        branchId: 'branch-1',
      });
      prismaMock.parentStudent.findFirst
        .mockResolvedValueOnce({ parentId: 'parent-1' })
        .mockResolvedValueOnce(null);
      prismaMock.attendance.findMany.mockResolvedValue([]);

      await expect(
        service.getStudentAttendanceHistory('student-1', {
          id: 'parent-1',
          roles: ['parent'],
        }),
      ).resolves.toMatchObject({ summary: { totalSessions: 0 } });
      await expect(
        service.getStudentAttendanceHistory('student-1', {
          id: 'parent-2',
          roles: ['parent'],
        }),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should correctly calculate attendance rate percentage', async () => {
      prismaMock.user.findUnique.mockResolvedValue({
        id: 'student-1',
        userCode: 'HV001',
        fullName: 'Nguyễn Văn A',
      });

      prismaMock.attendance.findMany.mockResolvedValue([
        {
          id: 'att-1',
          status: AttendanceStatus.PRESENT,
          checkInTime: new Date(),
          notes: null,
          markedAt: new Date(),
          session: {
            id: 's-1',
            sessionNumber: 1,
            title: 'Buổi 1',
            date: new Date(),
            startTime: '18:00',
            endTime: '19:30',
            class: { id: 'c-1', code: 'C01', name: 'Lớp 1' },
            room: null,
            teacher: null,
          },
        },
        {
          id: 'att-2',
          status: AttendanceStatus.LATE,
          checkInTime: new Date(),
          notes: 'Muộn 10p',
          markedAt: new Date(),
          session: {
            id: 's-2',
            sessionNumber: 2,
            title: 'Buổi 2',
            date: new Date(),
            startTime: '18:00',
            endTime: '19:30',
            class: { id: 'c-1', code: 'C01', name: 'Lớp 1' },
            room: null,
            teacher: null,
          },
        },
        {
          id: 'att-3',
          status: AttendanceStatus.ABSENT,
          checkInTime: null,
          notes: 'Vắng',
          markedAt: new Date(),
          session: {
            id: 's-3',
            sessionNumber: 3,
            title: 'Buổi 3',
            date: new Date(),
            startTime: '18:00',
            endTime: '19:30',
            class: { id: 'c-1', code: 'C01', name: 'Lớp 1' },
            room: null,
            teacher: null,
          },
        },
        {
          id: 'att-4',
          status: AttendanceStatus.MAKEUP,
          checkInTime: new Date(),
          notes: 'Học bù',
          markedAt: new Date(),
          session: {
            id: 's-4',
            sessionNumber: 4,
            title: 'Buổi 4',
            date: new Date(),
            startTime: '18:00',
            endTime: '19:30',
            class: { id: 'c-1', code: 'C01', name: 'Lớp 1' },
            room: null,
            teacher: null,
          },
        },
      ]);

      const result = await service.getStudentAttendanceHistory('student-1', {
        id: 'student-1',
        roles: ['student'],
      });

      expect(result.summary.totalSessions).toBe(4);
      expect(result.summary.present).toBe(1);
      expect(result.summary.late).toBe(1);
      expect(result.summary.absent).toBe(1);
      expect(result.summary.makeup).toBe(1);
      // (1 + 1 + 0.8) / 4 * 100 = 2.8 / 4 * 100 = 70.0%
      expect(result.summary.attendanceRate).toBe(70.0);
    });
  });

  describe('makeupRequests', () => {
    it('should create and update makeup request with attendance creation upon approval', async () => {
      prismaMock.classSession.findUnique
        .mockResolvedValueOnce({ id: 'orig-session' })
        .mockResolvedValueOnce({ id: 'target-session' });

      prismaMock.makeupRequest.create.mockResolvedValue({
        id: 'mr-1',
        status: MakeupStatus.PENDING,
      });

      const created = await service.createMakeupRequest('student-1', {
        originalSessionId: 'orig-session',
        targetSessionId: 'target-session',
        reason: 'Trùng lịch',
      });

      expect(created.status).toBe(MakeupStatus.PENDING);

      // Approve makeup request
      prismaMock.makeupRequest.findUnique.mockResolvedValue({
        id: 'mr-1',
        studentId: 'student-1',
        originalSessionId: 'orig-session',
        targetSessionId: 'target-session',
        status: MakeupStatus.PENDING,
      });

      prismaMock.makeupRequest.update.mockResolvedValue({
        id: 'mr-1',
        status: MakeupStatus.APPROVED,
      });

      prismaMock.attendance.upsert.mockResolvedValue({});

      const updated = await service.updateMakeupRequest(
        'mr-1',
        {
          status: MakeupStatus.APPROVED,
          reason: 'Đã duyệt',
        },
        'staff-1',
      );

      expect(updated.status).toBe(MakeupStatus.APPROVED);
      expect(prismaMock.attendance.upsert).toHaveBeenCalledWith({
        where: {
          sessionId_studentId: {
            sessionId: 'target-session',
            studentId: 'student-1',
          },
        },
        create: expect.objectContaining({
          status: AttendanceStatus.MAKEUP,
        }),
        update: expect.objectContaining({
          status: AttendanceStatus.MAKEUP,
        }),
      });
    });
  });
});
