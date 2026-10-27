import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Logger,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service.js';
import {
  BatchMarkAttendanceDto,
  UpdateAttendanceDto,
  CreateMakeupRequestDto,
  UpdateMakeupRequestDto,
  QueryMakeupRequestsDto,
} from './dto/index.js';
import { AttendanceStatus, MakeupStatus, SessionStatus } from '@prisma/client';
import { NotificationsService } from '../notifications/notifications.service.js';

export interface AttendanceActor {
  id: string;
  roles: string[];
  branchId?: string | null;
}

@Injectable()
export class AttendanceService {
  private readonly logger = new Logger(AttendanceService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
  ) {}

  private assertClassAccess(
    classItem: any,
    actor: AttendanceActor,
    teacherId?: string | null,
  ) {
    if (actor.roles.includes('super_admin')) return;
    if (
      actor.roles.some((role) =>
        ['branch_admin', 'academic_staff'].includes(role),
      ) &&
      actor.branchId &&
      actor.branchId === classItem.branchId
    )
      return;
    if (
      actor.roles.some((role) =>
        ['teacher', 'teaching_assistant'].includes(role),
      ) &&
      (teacherId === actor.id ||
        classItem.mainTeacherId === actor.id ||
        classItem.assistantTeacherId === actor.id)
    )
      return;
    throw new ForbiddenException('Bạn không phụ trách lớp học này');
  }

  // --------------------------------------------------------------------------
  // 1. GET ATTENDANCE FOR A CLASS SESSION
  // --------------------------------------------------------------------------

  async getSessionAttendance(sessionId: string, actor: AttendanceActor) {
    const session = await this.prisma.classSession.findUnique({
      where: { id: sessionId },
      include: {
        class: {
          include: {
            students: {
              where: { status: 'ENROLLED' },
              include: {
                student: {
                  select: {
                    id: true,
                    userCode: true,
                    fullName: true,
                    avatarUrl: true,
                    phone: true,
                    email: true,
                  },
                },
              },
            },
          },
        },
        attendances: {
          include: {
            markedBy: {
              select: {
                id: true,
                fullName: true,
                userCode: true,
              },
            },
          },
        },
        room: true,
        teacher: {
          select: {
            id: true,
            fullName: true,
            userCode: true,
            avatarUrl: true,
          },
        },
      },
    });

    if (!session) {
      throw new NotFoundException(
        `Không tìm thấy buổi học với ID: ${sessionId}`,
      );
    }
    this.assertClassAccess(session.class, actor, session.teacherId);

    const attendanceMap = new Map<string, any>();
    for (const att of session.attendances) {
      attendanceMap.set(att.studentId, att);
    }

    const students = session.class.students.map((cs) => {
      const student = cs.student;
      const att = attendanceMap.get(student.id);

      return {
        studentId: student.id,
        userCode: student.userCode,
        fullName: student.fullName,
        avatarUrl: student.avatarUrl,
        phone: student.phone,
        email: student.email,
        attendanceId: att ? att.id : null,
        status: att ? att.status : null,
        checkInTime: att?.checkInTime ? att.checkInTime.toISOString() : null,
        notes: att?.notes || null,
        markedBy: att?.markedBy || null,
        markedAt: att?.markedAt ? att.markedAt.toISOString() : null,
      };
    });

    const enrolledAttendance = session.attendances.filter((a) =>
      students.some((student) => student.studentId === a.studentId),
    );
    const summary = {
      totalEnrolled: students.length,
      markedCount: enrolledAttendance.length,
      present: enrolledAttendance.filter(
        (a) => a.status === AttendanceStatus.PRESENT,
      ).length,
      absent: enrolledAttendance.filter(
        (a) => a.status === AttendanceStatus.ABSENT,
      ).length,
      late: enrolledAttendance.filter((a) => a.status === AttendanceStatus.LATE)
        .length,
      excused: enrolledAttendance.filter(
        (a) => a.status === AttendanceStatus.EXCUSED,
      ).length,
      makeup: enrolledAttendance.filter(
        (a) => a.status === AttendanceStatus.MAKEUP,
      ).length,
    };

    return {
      session: {
        id: session.id,
        classId: session.classId,
        className: session.class.name,
        classCode: session.class.code,
        sessionNumber: session.sessionNumber,
        title: session.title,
        date: session.date,
        startTime: session.startTime,
        endTime: session.endTime,
        status: session.status,
        room: session.room,
        teacher: session.teacher,
      },
      summary,
      students,
    };
  }

  // --------------------------------------------------------------------------
  // 2. BATCH MARK ATTENDANCE
  // --------------------------------------------------------------------------

  async batchMarkAttendance(
    sessionId: string,
    dto: BatchMarkAttendanceDto,
    actor: AttendanceActor,
  ) {
    const session = await this.prisma.classSession.findUnique({
      where: { id: sessionId },
      include: {
        class: true,
      },
    });

    if (!session) {
      throw new NotFoundException(
        `Không tìm thấy buổi học với ID: ${sessionId}`,
      );
    }

    this.assertClassAccess(session.class, actor, session.teacherId);
    if (session.status === SessionStatus.CANCELLED) {
      throw new BadRequestException('Không thể điểm danh buổi học đã hủy');
    }
    if (session.status === SessionStatus.COMPLETED) {
      throw new BadRequestException(
        'Điểm danh của buổi học đã được khóa và không thể chỉnh sửa',
      );
    }
    if (!dto.students?.length)
      throw new BadRequestException('Danh sách điểm danh đang trống');
    const submittedIds = dto.students.map((item) => item.studentId);
    if (new Set(submittedIds).size !== submittedIds.length) {
      throw new BadRequestException(
        'Danh sách điểm danh có học viên trùng lặp',
      );
    }
    const enrollments = await this.prisma.classStudent.findMany({
      where: { classId: session.classId, status: 'ENROLLED' },
      select: { studentId: true },
    });
    const enrolledIds = new Set(enrollments.map((item) => item.studentId));
    if (submittedIds.some((id) => !enrolledIds.has(id))) {
      throw new ForbiddenException(
        'Danh sách điểm danh có học viên không thuộc lớp',
      );
    }
    if (dto.lock && (submittedIds.length !== enrolledIds.size ||
      enrolledIds.size === 0)) {
      throw new BadRequestException('Phải điểm danh toàn bộ học viên trong lớp trước khi khóa buổi học');
    }
    const previousRecords = await this.prisma.attendance.findMany({
      where: { sessionId },
      select: { studentId: true, status: true },
    });
    const previousStatus = new Map(
      previousRecords.map((item) => [item.studentId, item.status]),
    );

    const absentStudentIds: string[] = [];

    await this.prisma.$transaction(async (tx) => {
    for (const item of dto.students) {
      await tx.attendance.upsert({
        where: {
          sessionId_studentId: {
            sessionId,
            studentId: item.studentId,
          },
        },
        create: {
          sessionId,
          studentId: item.studentId,
          status: item.status,
          checkInTime:
            item.status === AttendanceStatus.ABSENT ||
            item.status === AttendanceStatus.EXCUSED
              ? null
              : item.checkInTime
                ? new Date(item.checkInTime)
                : new Date(),
          notes: item.notes,
          markedById: actor.id,
        },
        update: {
          status: item.status,
          checkInTime:
            item.status === AttendanceStatus.ABSENT ||
            item.status === AttendanceStatus.EXCUSED
              ? null
              : item.checkInTime
                ? new Date(item.checkInTime)
                : new Date(),
          notes: item.notes,
          markedById: actor.id,
          markedAt: new Date(),
        },
      });

      if (
        item.status === AttendanceStatus.ABSENT &&
        previousStatus.get(item.studentId) !== AttendanceStatus.ABSENT
      ) {
        absentStudentIds.push(item.studentId);
      }
    }

    if (dto.lock) {
      const result = await tx.classSession.updateMany({
        where: { id: sessionId, status: { not: SessionStatus.COMPLETED } },
        data: { status: SessionStatus.COMPLETED },
      });
      if (result.count !== 1) {
        throw new ConflictException('Buổi học đã được khóa bởi thao tác khác');
      }
    } else if (session.status === SessionStatus.SCHEDULED) {
      await tx.classSession.updateMany({
        where: { id: sessionId, status: SessionStatus.SCHEDULED },
        data: { status: SessionStatus.IN_PROGRESS },
      });
    }
    });

    for (const studentId of absentStudentIds) {
      try {
        await this.notifications.notifyAbsence(
          studentId,
          session.title,
          session.date,
        );
      } catch (error) {
        this.logger.warn(
          `Không gửi được thông báo vắng học cho ${studentId}: ${error}`,
        );
      }
    }

    return this.getSessionAttendance(sessionId, actor);
  }

  // --------------------------------------------------------------------------
  // 3. UPDATE SINGLE ATTENDANCE RECORD
  // --------------------------------------------------------------------------

  async updateAttendance(
    id: string,
    dto: UpdateAttendanceDto,
    actor: AttendanceActor,
  ) {
    const existing = await this.prisma.attendance.findUnique({
      where: { id },
      include: { session: { include: { class: true } } },
    });

    if (!existing) {
      throw new NotFoundException(`Không tìm thấy bản ghi điểm danh ID: ${id}`);
    }

    this.assertClassAccess(
      existing.session.class,
      actor,
      existing.session.teacherId,
    );
    if (existing.session.status === SessionStatus.COMPLETED) {
      throw new BadRequestException(
        'Điểm danh của buổi học đã được khóa và không thể chỉnh sửa',
      );
    }

    const updated = await this.prisma.attendance.update({
      where: { id },
      data: {
        status: dto.status,
        checkInTime:
          dto.status === AttendanceStatus.ABSENT ||
          dto.status === AttendanceStatus.EXCUSED
            ? null
            : dto.checkInTime
              ? new Date(dto.checkInTime)
              : undefined,
        notes: dto.notes,
        markedById: actor.id,
        markedAt: new Date(),
      },
    });
    if (
      dto.status === AttendanceStatus.ABSENT &&
      existing.status !== AttendanceStatus.ABSENT
    ) {
      try {
        await this.notifications.notifyAbsence(
          existing.studentId,
          existing.session.title,
          existing.session.date,
        );
      } catch (error) {
        this.logger.warn(
          `Không gửi được thông báo vắng học cho ${existing.studentId}: ${error}`,
        );
      }
    }
    return updated;
  }

  // --------------------------------------------------------------------------
  // 4. GET STUDENT ATTENDANCE HISTORY & RATE
  // --------------------------------------------------------------------------

  async getStudentAttendanceHistory(studentId: string, actor: AttendanceActor) {
    const student = await this.prisma.user.findUnique({
      where: { id: studentId },
      select: {
        id: true,
        userCode: true,
        fullName: true,
        avatarUrl: true,
        phone: true,
        email: true,
        branchId: true,
      },
    });

    if (!student) {
      throw new NotFoundException(`Không tìm thấy học viên ID: ${studentId}`);
    }

    if (actor.id !== studentId && !actor.roles.includes('super_admin')) {
      let allowed = false;
      if (
        actor.roles.some((role) =>
          ['branch_admin', 'academic_staff'].includes(role),
        )
      ) {
        allowed = !!actor.branchId && actor.branchId === student.branchId;
      } else if (actor.roles.includes('parent')) {
        allowed = !!(await this.prisma.parentStudent.findFirst({
          where: { parentId: actor.id, studentId },
        }));
      } else if (
        actor.roles.some((role) =>
          ['teacher', 'teaching_assistant'].includes(role),
        )
      ) {
        allowed = !!(await this.prisma.classStudent.findFirst({
          where: {
            studentId,
            status: 'ENROLLED',
            class: {
              OR: [
                { mainTeacherId: actor.id },
                { assistantTeacherId: actor.id },
              ],
            },
          },
        }));
      }
      if (!allowed)
        throw new ForbiddenException(
          'Bạn không có quyền xem chuyên cần của học viên này',
        );
    }

    const records = await this.prisma.attendance.findMany({
      where: { studentId },
      include: {
        session: {
          include: {
            class: {
              select: {
                id: true,
                code: true,
                name: true,
              },
            },
            room: true,
            teacher: {
              select: {
                id: true,
                fullName: true,
              },
            },
          },
        },
      },
      orderBy: {
        session: {
          date: 'desc',
        },
      },
    });

    const total = records.length;
    const presentCount = records.filter(
      (r) => r.status === AttendanceStatus.PRESENT,
    ).length;
    const lateCount = records.filter(
      (r) => r.status === AttendanceStatus.LATE,
    ).length;
    const absentCount = records.filter(
      (r) => r.status === AttendanceStatus.ABSENT,
    ).length;
    const excusedCount = records.filter(
      (r) => r.status === AttendanceStatus.EXCUSED,
    ).length;
    const makeupCount = records.filter(
      (r) => r.status === AttendanceStatus.MAKEUP,
    ).length;

    // Tỷ lệ chuyên cần: (Có mặt + Học bù + 0.8 * Đi muộn) / Tổng số buổi * 100
    const attendanceRate =
      total > 0
        ? Number(
            (
              ((presentCount + makeupCount + lateCount * 0.8) / total) *
              100
            ).toFixed(1),
          )
        : 100.0;

    return {
      student,
      summary: {
        totalSessions: total,
        present: presentCount,
        late: lateCount,
        absent: absentCount,
        excused: excusedCount,
        makeup: makeupCount,
        attendanceRate,
      },
      records: records.map((r) => ({
        id: r.id,
        status: r.status,
        checkInTime: r.checkInTime,
        notes: r.notes,
        markedAt: r.markedAt,
        session: {
          id: r.session.id,
          sessionNumber: r.session.sessionNumber,
          title: r.session.title,
          date: r.session.date,
          startTime: r.session.startTime,
          endTime: r.session.endTime,
          class: r.session.class,
          room: r.session.room,
          teacher: r.session.teacher,
        },
      })),
    };
  }

  // --------------------------------------------------------------------------
  // 5. GET CLASS ATTENDANCE SUMMARY
  // --------------------------------------------------------------------------

  async getClassAttendanceSummary(classId: string, actor: AttendanceActor) {
    const classItem = await this.prisma.class.findUnique({
      where: { id: classId },
      include: {
        sessions: {
          include: {
            attendances: true,
          },
          orderBy: { sessionNumber: 'asc' },
        },
        students: {
          where: { status: 'ENROLLED' },
          include: {
            student: {
              select: {
                id: true,
                userCode: true,
                fullName: true,
                avatarUrl: true,
                phone: true,
              },
            },
          },
        },
      },
    });

    if (!classItem) {
      throw new NotFoundException(`Không tìm thấy lớp học ID: ${classId}`);
    }
    this.assertClassAccess(classItem, actor);

    const completedSessions = classItem.sessions.filter(
      (s) => s.status === SessionStatus.COMPLETED || s.attendances.length > 0,
    );

    const studentSummaries = classItem.students.map((cs) => {
      const student = cs.student;
      let present = 0;
      let late = 0;
      let absent = 0;
      let excused = 0;
      let makeup = 0;

      for (const s of completedSessions) {
        const att = s.attendances.find((a) => a.studentId === student.id);
        if (att) {
          if (att.status === AttendanceStatus.PRESENT) present++;
          else if (att.status === AttendanceStatus.LATE) late++;
          else if (att.status === AttendanceStatus.ABSENT) absent++;
          else if (att.status === AttendanceStatus.EXCUSED) excused++;
          else if (att.status === AttendanceStatus.MAKEUP) makeup++;
        }
      }

      const totalRecorded = present + late + absent + excused + makeup;
      const rate =
        totalRecorded > 0
          ? Number(
              (((present + makeup + late * 0.8) / totalRecorded) * 100).toFixed(
                1,
              ),
            )
          : 100.0;

      return {
        student,
        stats: {
          totalCompleted: completedSessions.length,
          present,
          late,
          absent,
          excused,
          makeup,
          attendanceRate: rate,
        },
      };
    });

    const averageRate =
      studentSummaries.length > 0
        ? Number(
            (
              studentSummaries.reduce(
                (sum, s) => sum + s.stats.attendanceRate,
                0,
              ) / studentSummaries.length
            ).toFixed(1),
          )
        : 100.0;

    return {
      class: {
        id: classItem.id,
        code: classItem.code,
        name: classItem.name,
        totalSessions: classItem.totalSessions,
        completedSessions: completedSessions.length,
      },
      averageAttendanceRate: averageRate,
      studentSummaries,
    };
  }

  // --------------------------------------------------------------------------
  // 6. MAKEUP REQUESTS (HỌC BÙ)
  // --------------------------------------------------------------------------

  async createMakeupRequest(studentId: string, dto: CreateMakeupRequestDto) {
    const originalSession = await this.prisma.classSession.findUnique({
      where: { id: dto.originalSessionId },
    });

    if (!originalSession) {
      throw new NotFoundException(
        `Không tìm thấy buổi học gốc ID: ${dto.originalSessionId}`,
      );
    }

    if (dto.targetSessionId) {
      const targetSession = await this.prisma.classSession.findUnique({
        where: { id: dto.targetSessionId },
      });
      if (!targetSession) {
        throw new NotFoundException(
          `Không tìm thấy buổi học mục tiêu ID: ${dto.targetSessionId}`,
        );
      }
    }

    return this.prisma.makeupRequest.create({
      data: {
        studentId,
        originalSessionId: dto.originalSessionId,
        targetSessionId: dto.targetSessionId,
        reason: dto.reason,
        status: MakeupStatus.PENDING,
      },
      include: {
        originalSession: true,
        targetSession: true,
      },
    });
  }

  async getMakeupRequests(query: QueryMakeupRequestsDto) {
    const where: any = {};
    if (query.status) {
      where.status = query.status;
    }
    if (query.studentId) {
      where.studentId = query.studentId;
    }

    return this.prisma.makeupRequest.findMany({
      where,
      include: {
        student: {
          select: {
            id: true,
            userCode: true,
            fullName: true,
            avatarUrl: true,
            phone: true,
          },
        },
        originalSession: {
          include: {
            class: { select: { id: true, code: true, name: true } },
          },
        },
        targetSession: {
          include: {
            class: { select: { id: true, code: true, name: true } },
          },
        },
        approvedBy: {
          select: {
            id: true,
            fullName: true,
            userCode: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async updateMakeupRequest(
    id: string,
    dto: UpdateMakeupRequestDto,
    approvedById: string,
  ) {
    const req = await this.prisma.makeupRequest.findUnique({
      where: { id },
    });

    if (!req) {
      throw new NotFoundException(`Không tìm thấy yêu cầu học bù ID: ${id}`);
    }

    const updated = await this.prisma.makeupRequest.update({
      where: { id },
      data: {
        status: dto.status,
        reason: dto.reason ?? req.reason,
        approvedById,
      },
      include: {
        student: true,
        originalSession: true,
        targetSession: true,
      },
    });

    // Nếu duyệt thành công và đã có targetSessionId, tạo bản ghi Attendance với trạng thái MAKEUP
    if (dto.status === MakeupStatus.APPROVED && req.targetSessionId) {
      await this.prisma.attendance.upsert({
        where: {
          sessionId_studentId: {
            sessionId: req.targetSessionId,
            studentId: req.studentId,
          },
        },
        create: {
          sessionId: req.targetSessionId,
          studentId: req.studentId,
          status: AttendanceStatus.MAKEUP,
          notes: `Học bù từ buổi ${req.originalSessionId}`,
          markedById: approvedById,
        },
        update: {
          status: AttendanceStatus.MAKEUP,
          notes: `Học bù từ buổi ${req.originalSessionId}`,
          markedById: approvedById,
        },
      });
    }

    return updated;
  }
}
