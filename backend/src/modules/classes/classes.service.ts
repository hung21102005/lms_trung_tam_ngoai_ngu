import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service.js';
import {
  CreateClassDto,
  UpdateClassDto,
  EnrollStudentDto,
  UpdateClassSessionDto,
  QueryClassesDto,
} from './dto/index.js';
import {
  ClassStatus,
  EnrollmentStatus,
  InvoiceStatus,
  SessionStatus,
  UserStatus,
  PublicationStatus,
  RegistrationStatus,
  LeadStatus,
  Prisma,
} from '@prisma/client';
import { randomUUID } from 'node:crypto';
import { QueryPublicClassesDto } from './dto/query-public-classes.dto.js';
import { isRetryableTransactionConflict } from '../../common/prisma-transaction.js';

const publicOfferingSelect = {
  id: true,
  code: true,
  name: true,
  startDate: true,
  endDate: true,
  scheduleDays: true,
  startTime: true,
  endTime: true,
  totalSessions: true,
  maxCapacity: true,
  tuitionFee: true,
  registrationOpenAt: true,
  registrationCloseAt: true,
  course: { select: { id: true, slug: true, title: true, thumbnailUrl: true } },
  level: { select: { id: true, code: true, name: true } },
  branch: { select: { id: true, name: true, address: true } },
  mainTeacher: { select: { fullName: true } },
  _count: {
    select: { students: { where: { status: EnrollmentStatus.ENROLLED } } },
  },
} satisfies Prisma.ClassSelect;

// Class enrollment dates are PostgreSQL DATE values. Compare them with the
// center's calendar date, not the server's current UTC calendar date.
function vietnamCalendarDate(now: Date): Date {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone: 'Asia/Ho_Chi_Minh',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(now);
  const value = (part: string) =>
    Number(parts.find((item) => item.type === part)?.value);
  return new Date(Date.UTC(value('year'), value('month') - 1, value('day')));
}

export interface ClassActor {
  id: string;
  roles: string[];
  branchId?: string | null;
}

@Injectable()
export class ClassesService {
  constructor(private readonly prisma: PrismaService) {}

  private publicOfferingWhere(today: Date): Prisma.ClassWhereInput {
    return {
      status: ClassStatus.OPEN_FOR_ENROLLMENT,
      registrationOpenAt: { lte: today },
      registrationCloseAt: { gte: today },
      startDate: { gte: today },
      tuitionFee: { gt: 0 },
      room: { isActive: true },
      mainTeacher: { status: UserStatus.ACTIVE },
      branch: { isActive: true },
      course: {
        isActive: true,
        slug: { not: null },
        publicationStatus: PublicationStatus.PUBLISHED,
        program: { status: PublicationStatus.PUBLISHED, isPublic: true },
      },
    };
  }

  async findPublicOfferings(query: QueryPublicClassesDto) {
    const { page = 1, limit = 12, branchId, courseId } = query;
    const today = vietnamCalendarDate(new Date());
    const where: Prisma.ClassWhereInput = {
      ...this.publicOfferingWhere(today),
      ...(branchId ? { branchId } : {}),
      ...(courseId ? { courseId } : {}),
    };
    const [items, total] = await Promise.all([
      this.prisma.class.findMany({
        where,
        select: publicOfferingSelect,
        orderBy: [{ startDate: 'asc' }, { name: 'asc' }],
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.class.count({ where }),
    ]);
    return {
      items: items.map((item) => ({
        ...item,
        enrolledCount: item._count.students,
        remainingSeats: Math.max(0, item.maxCapacity - item._count.students),
        _count: undefined,
      })),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async findPublicOffering(id: string) {
    const today = vietnamCalendarDate(new Date());
    const item = await this.prisma.class.findFirst({
      where: { ...this.publicOfferingWhere(today), id },
      select: publicOfferingSelect,
    });
    if (!item)
      throw new NotFoundException('Không tìm thấy lớp đang mở đăng ký');
    return {
      ...item,
      enrolledCount: item._count.students,
      remainingSeats: Math.max(0, item.maxCapacity - item._count.students),
      _count: undefined,
    };
  }

  // --------------------------------------------------------------------------
  // CLASSES CRUD & LIST
  // --------------------------------------------------------------------------

  async findAll(query: QueryClassesDto, actor: ClassActor) {
    const { page, limit, search, status, branchId, courseId, teacherId } =
      query;
    const skip = (page - 1) * limit;

    const where: any = {};

    if (search) {
      where.OR = [
        { code: { contains: search, mode: 'insensitive' } },
        { name: { contains: search, mode: 'insensitive' } },
      ];
    }

    if (status) {
      where.status = status;
    }

    if (branchId) {
      where.branchId = branchId;
    }

    if (courseId) {
      where.courseId = courseId;
    }

    if (teacherId) {
      where.AND = [
        {
          OR: [{ mainTeacherId: teacherId }, { assistantTeacherId: teacherId }],
        },
      ];
    }

    if (!actor.roles.includes('super_admin')) {
      let access: any;
      if (
        actor.roles.some((role) =>
          ['branch_admin', 'academic_staff'].includes(role),
        )
      ) {
        if (!actor.branchId)
          throw new ForbiddenException('Tài khoản chưa được gán chi nhánh');
        access = { branchId: actor.branchId };
      } else if (
        actor.roles.some((role) =>
          ['teacher', 'teaching_assistant'].includes(role),
        )
      ) {
        access = {
          OR: [{ mainTeacherId: actor.id }, { assistantTeacherId: actor.id }],
        };
      } else if (actor.roles.includes('student')) {
        access = {
          students: {
            some: { studentId: actor.id, status: EnrollmentStatus.ENROLLED },
          },
        };
      } else if (actor.roles.includes('parent')) {
        const children = await this.prisma.parentStudent.findMany({
          where: { parentId: actor.id },
          select: { studentId: true },
        });
        access = {
          students: {
            some: {
              studentId: { in: children.map((child) => child.studentId) },
              status: EnrollmentStatus.ENROLLED,
            },
          },
        };
      } else {
        throw new ForbiddenException(
          'Bạn không có quyền xem danh sách lớp học',
        );
      }
      where.AND = [...(where.AND ?? []), access];
    }

    const [items, total] = await Promise.all([
      this.prisma.class.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          course: { select: { id: true, code: true, title: true } },
          level: { select: { id: true, code: true, name: true } },
          branch: { select: { id: true, code: true, name: true } },
          room: {
            select: { id: true, code: true, name: true, capacity: true },
          },
          mainTeacher: {
            select: {
              id: true,
              fullName: true,
              userCode: true,
              avatarUrl: true,
            },
          },
          assistantTeacher: {
            select: {
              id: true,
              fullName: true,
              userCode: true,
              avatarUrl: true,
            },
          },
          _count: {
            select: {
              students: true,
              sessions: true,
            },
          },
        },
      }),
      this.prisma.class.count({ where }),
    ]);

    return {
      items,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async findOne(id: string, actor?: ClassActor) {
    const classEntity = await this.prisma.class.findUnique({
      where: { id },
      include: {
        course: true,
        level: true,
        branch: true,
        room: true,
        mainTeacher: {
          select: {
            id: true,
            userCode: true,
            fullName: true,
            email: true,
            phone: true,
            avatarUrl: true,
            teacherProfile: true,
          },
        },
        assistantTeacher: {
          select: {
            id: true,
            userCode: true,
            fullName: true,
            email: true,
            phone: true,
            avatarUrl: true,
          },
        },
        students: {
          include: {
            student: {
              select: {
                id: true,
                userCode: true,
                fullName: true,
                email: true,
                phone: true,
                avatarUrl: true,
                status: true,
                studentProfile: true,
              },
            },
          },
          orderBy: { joinedAt: 'asc' },
        },
        sessions: {
          orderBy: { sessionNumber: 'asc' },
          include: {
            room: { select: { id: true, code: true, name: true } },
            teacher: { select: { id: true, fullName: true, userCode: true } },
            lesson: { select: { id: true, title: true, order: true } },
          },
        },
      },
    });

    if (!classEntity) {
      throw new NotFoundException(`Không tìm thấy lớp học với ID: ${id}`);
    }

    if (actor && !actor.roles.includes('super_admin')) {
      let allowed = false;
      let visibleStudentIds: string[] | null = null;
      if (
        actor.roles.some((role) =>
          ['branch_admin', 'academic_staff'].includes(role),
        )
      ) {
        allowed = !!actor.branchId && classEntity.branchId === actor.branchId;
      } else if (
        actor.roles.some((role) =>
          ['teacher', 'teaching_assistant'].includes(role),
        )
      ) {
        allowed =
          classEntity.mainTeacherId === actor.id ||
          classEntity.assistantTeacherId === actor.id;
      } else if (actor.roles.includes('student')) {
        allowed = classEntity.students.some(
          (item) =>
            item.studentId === actor.id &&
            item.status === EnrollmentStatus.ENROLLED,
        );
        visibleStudentIds = [actor.id];
      } else if (actor.roles.includes('parent')) {
        const childIds = classEntity.students
          .filter((item) => item.status === EnrollmentStatus.ENROLLED)
          .map((item) => item.studentId);
        const relations =
          childIds.length > 0
            ? await this.prisma.parentStudent.findMany({
                where: { parentId: actor.id, studentId: { in: childIds } },
                select: { studentId: true },
              })
            : [];
        visibleStudentIds = relations.map((item) => item.studentId);
        allowed = visibleStudentIds.length > 0;
      }
      if (!allowed)
        throw new ForbiddenException('Bạn không có quyền xem lớp học này');
      if (visibleStudentIds) {
        classEntity.students = classEntity.students.filter((item) =>
          visibleStudentIds.includes(item.studentId),
        );
      }
    }

    if (
      actor?.roles.some((role) =>
        ['teacher', 'teaching_assistant'].includes(role),
      ) &&
      !actor.roles.some((role) =>
        ['super_admin', 'branch_admin', 'academic_staff'].includes(role),
      )
    ) {
      return {
        ...classEntity,
        students: classEntity.students.map((item) => ({
          id: item.id,
          classId: item.classId,
          studentId: item.studentId,
          status: item.status,
          joinedAt: item.joinedAt,
          student: {
            id: item.student.id,
            userCode: item.student.userCode,
            fullName: item.student.fullName,
            avatarUrl: item.student.avatarUrl,
            status: item.student.status,
          },
        })),
      };
    }

    return classEntity;
  }

  // --------------------------------------------------------------------------
  // TẠO LỚP & AUTO-GENERATE SESSIONS CÓ CHECK TRÙNG LỊCH PHÒNG/GIÁO VIÊN
  // --------------------------------------------------------------------------

  private validateRegistrationWindow(
    openAt?: string | Date | null,
    closeAt?: string | Date | null,
    classStart?: string | Date | null,
  ) {
    if (!openAt && !closeAt) return;
    if (!openAt || !closeAt) {
      throw new BadRequestException('Cần nhập đủ ngày mở và đóng đăng ký');
    }
    const open = new Date(openAt);
    const close = new Date(closeAt);
    const start = classStart ? new Date(classStart) : null;
    if (
      Number.isNaN(open.getTime()) ||
      Number.isNaN(close.getTime()) ||
      (start && Number.isNaN(start.getTime()))
    ) {
      throw new BadRequestException(
        'Ngày đăng ký hoặc ngày khai giảng không hợp lệ',
      );
    }
    if (open > close) {
      throw new BadRequestException(
        'Ngày mở đăng ký phải trước hoặc bằng ngày đóng đăng ký',
      );
    }
    if (start && close > start) {
      throw new BadRequestException(
        'Ngày đóng đăng ký không được sau ngày khai giảng',
      );
    }
  }

  async create(dto: CreateClassDto, actor: ClassActor) {
    if (
      !actor.roles.includes('super_admin') &&
      (!actor.branchId || actor.branchId !== dto.branchId)
    ) {
      throw new ForbiddenException('Bạn không được tạo lớp ở chi nhánh này');
    }
    // 1. Kiểm tra mã lớp trùng lặp
    const existingCode = await this.prisma.class.findUnique({
      where: { code: dto.code },
    });
    if (existingCode) {
      throw new ConflictException(
        `Mã lớp '${dto.code}' đã tồn tại trên hệ thống`,
      );
    }

    // 2. Kiểm tra tồn tại Course, Level, Branch
    const [course, level, branch] = await Promise.all([
      this.prisma.course.findUnique({ where: { id: dto.courseId } }),
      this.prisma.courseLevel.findUnique({ where: { id: dto.levelId } }),
      this.prisma.branch.findUnique({ where: { id: dto.branchId } }),
    ]);

    if (!course)
      throw new NotFoundException(
        `Không tìm thấy khóa học với ID: ${dto.courseId}`,
      );
    if (!level)
      throw new NotFoundException(
        `Không tìm thấy cấp độ với ID: ${dto.levelId}`,
      );
    if (!branch)
      throw new NotFoundException(
        `Không tìm thấy chi nhánh với ID: ${dto.branchId}`,
      );
    if (level.courseId !== dto.courseId) {
      throw new BadRequestException('Cấp độ không thuộc khóa học đã chọn');
    }
    if (
      course.isActive === false ||
      (course.publicationStatus && course.publicationStatus !== 'PUBLISHED')
    ) {
      throw new BadRequestException(
        'Khóa học chưa được duyệt và kích hoạt để mở lớp',
      );
    }

    if (dto.roomId) {
      const room = await this.prisma.room.findUnique({
        where: { id: dto.roomId },
      });
      if (!room)
        throw new NotFoundException('Không tìm thấy phòng học đã chọn');
      if (room.branchId !== dto.branchId) {
        throw new BadRequestException('Phòng học không thuộc chi nhánh mở lớp');
      }
      if (!room.isActive) {
        throw new BadRequestException('Phòng học đã ngừng hoạt động');
      }
      if ((dto.maxCapacity ?? 20) > room.capacity) {
        throw new BadRequestException('Sĩ số lớp vượt quá sức chứa phòng học');
      }
    }
    if (dto.mainTeacherId && dto.mainTeacherId === dto.assistantTeacherId) {
      throw new BadRequestException(
        'Giáo viên chính và trợ giảng phải khác nhau',
      );
    }
    for (const teacherId of [dto.mainTeacherId, dto.assistantTeacherId]) {
      if (!teacherId) continue;
      const teacher = await this.prisma.user.findFirst({
        where: {
          id: teacherId,
          branchId: dto.branchId,
          status: UserStatus.ACTIVE,
          userRoles: { some: { role: { code: 'teacher' } } },
        },
        select: { id: true },
      });
      if (!teacher) {
        throw new BadRequestException(
          'Giáo viên được chọn không hoạt động, không thuộc chi nhánh hoặc không có quyền giảng dạy',
        );
      }
    }
    if (dto.startTime >= dto.endTime) {
      throw new BadRequestException('Giờ kết thúc phải sau giờ bắt đầu');
    }
    if (!dto.scheduleDays.length) {
      throw new BadRequestException(
        'Vui lòng chọn ít nhất một ngày học trong tuần',
      );
    }
    this.validateRegistrationWindow(
      dto.registrationOpenAt,
      dto.registrationCloseAt,
      dto.startDate,
    );
    if (
      dto.status === ClassStatus.OPEN_FOR_ENROLLMENT &&
      (!dto.registrationOpenAt ||
        !dto.registrationCloseAt ||
        !dto.roomId ||
        !dto.mainTeacherId ||
        !(Number(dto.tuitionFee ?? level.tuitionFee) > 0))
    ) {
      throw new BadRequestException(
        'Cần có thời gian đăng ký, phòng, giáo viên chính và học phí trước khi mở tuyển sinh',
      );
    }

    // 3. Phân tích các ngày trong tuần (scheduleDays)
    const dayMap: Record<string, number> = {
      SUNDAY: 0,
      MONDAY: 1,
      TUESDAY: 2,
      WEDNESDAY: 3,
      THURSDAY: 4,
      FRIDAY: 5,
      SATURDAY: 6,
    };

    const targetDays = dto.scheduleDays.map((d) => {
      const upper = d.toUpperCase();
      if (dayMap[upper] === undefined) {
        throw new BadRequestException(
          `Ngày trong tuần không hợp lệ: '${d}'. Giá trị hợp lệ: MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY`,
        );
      }
      return dayMap[upper];
    });
    if (new Set(targetDays).size !== targetDays.length) {
      throw new BadRequestException('Ngày học trong tuần không được trùng lặp');
    }

    const totalSessions = dto.totalSessions || level.estimatedSessions || 24;
    const sessionDates: Date[] = [];
    const curDate = new Date(dto.startDate);

    while (sessionDates.length < totalSessions) {
      if (targetDays.includes(curDate.getUTCDay())) {
        sessionDates.push(new Date(curDate));
      }
      curDate.setUTCDate(curDate.getUTCDate() + 1);
    }

    const calculatedEndDate = sessionDates[sessionDates.length - 1];

    // 4. KIỂM TRA TRÙNG LỊCH (PHÒNG HỌC & GIÁO VIÊN)
    for (const sDate of sessionDates) {
      const dateStart = new Date(sDate);
      dateStart.setUTCHours(0, 0, 0, 0);

      // 4.1 Kiểm tra trùng phòng học
      if (dto.roomId) {
        const roomConflict = await this.prisma.classSession.findFirst({
          where: {
            roomId: dto.roomId,
            date: dateStart,
            status: { not: SessionStatus.CANCELLED },
            AND: [
              { startTime: { lt: dto.endTime } },
              { endTime: { gt: dto.startTime } },
            ],
          },
          include: {
            class: { select: { code: true, name: true } },
            room: { select: { code: true, name: true } },
          },
        });

        if (roomConflict) {
          const dateStr = sDate.toISOString().split('T')[0];
          throw new ConflictException(
            `Xung đột lịch phòng: Phòng '${roomConflict.room?.name || roomConflict.room?.code}' đã được xếp cho lớp '${roomConflict.class.name} (${roomConflict.class.code})' vào ngày ${dateStr} từ ${roomConflict.startTime} đến ${roomConflict.endTime}`,
          );
        }
      }

      // 4.2 Kiểm tra trùng lịch giáo viên chính
      if (dto.mainTeacherId) {
        const teacherConflict = await this.prisma.classSession.findFirst({
          where: {
            teacherId: dto.mainTeacherId,
            date: dateStart,
            status: { not: SessionStatus.CANCELLED },
            AND: [
              { startTime: { lt: dto.endTime } },
              { endTime: { gt: dto.startTime } },
            ],
          },
          include: {
            class: { select: { code: true, name: true } },
            teacher: { select: { fullName: true } },
          },
        });

        if (teacherConflict) {
          const dateStr = sDate.toISOString().split('T')[0];
          throw new ConflictException(
            `Xung đột lịch giáo viên: Giáo viên '${teacherConflict.teacher?.fullName}' đã có lịch dạy lớp '${teacherConflict.class.name} (${teacherConflict.class.code})' vào ngày ${dateStr} từ ${teacherConflict.startTime} đến ${teacherConflict.endTime}`,
          );
        }
      }
    }

    // 5. Lấy danh sách bài học thuộc cấp độ để gán tương ứng cho từng buổi (nếu có)
    const lessons = await this.prisma.lesson.findMany({
      where: {
        module: {
          levelId: dto.levelId,
        },
      },
      orderBy: [{ module: { order: 'asc' } }, { order: 'asc' }],
    });

    // 6. Thực hiện tạo Lớp và Sinh toàn bộ Buổi học trong 1 Transaction
    return this.prisma.$transaction(async (tx) => {
      const createdClass = await tx.class.create({
        data: {
          code: dto.code,
          name: dto.name,
          courseId: dto.courseId,
          levelId: dto.levelId,
          branchId: dto.branchId,
          roomId: dto.roomId,
          mainTeacherId: dto.mainTeacherId,
          assistantTeacherId: dto.assistantTeacherId,
          status: dto.status || ClassStatus.PLANNING,
          startDate: new Date(dto.startDate),
          endDate: calculatedEndDate,
          scheduleDays: dto.scheduleDays.map((d) => d.toUpperCase()),
          startTime: dto.startTime,
          endTime: dto.endTime,
          totalSessions,
          maxCapacity: dto.maxCapacity || 20,
          tuitionFee: dto.tuitionFee ?? level.tuitionFee ?? 0,
          registrationOpenAt: dto.registrationOpenAt
            ? new Date(dto.registrationOpenAt)
            : null,
          registrationCloseAt: dto.registrationCloseAt
            ? new Date(dto.registrationCloseAt)
            : null,
          notes: dto.notes,
        },
      });

      // Tạo các ClassSession
      for (let i = 0; i < sessionDates.length; i++) {
        const sDate = sessionDates[i];
        const sNumber = i + 1;
        const assignedLesson = lessons[i] || null;
        const sTitle = assignedLesson
          ? `Buổi ${sNumber}: ${assignedLesson.title}`
          : `Buổi học số ${sNumber}`;

        await tx.classSession.create({
          data: {
            classId: createdClass.id,
            sessionNumber: sNumber,
            title: sTitle,
            date: sDate,
            startTime: dto.startTime,
            endTime: dto.endTime,
            roomId: dto.roomId,
            teacherId: dto.mainTeacherId,
            status: SessionStatus.SCHEDULED,
            lessonId: assignedLesson ? assignedLesson.id : null,
          },
        });
      }

      return tx.class.findUnique({
        where: { id: createdClass.id },
        include: {
          course: { select: { id: true, code: true, title: true } },
          level: { select: { id: true, code: true, name: true } },
          branch: { select: { id: true, code: true, name: true } },
          room: { select: { id: true, code: true, name: true } },
          mainTeacher: { select: { id: true, fullName: true, userCode: true } },
          sessions: {
            orderBy: { sessionNumber: 'asc' },
          },
        },
      });
    });
  }

  async update(id: string, dto: UpdateClassDto, actor: ClassActor) {
    const current = await this.findOne(id, actor);
    const scheduleFields: (keyof UpdateClassDto)[] = [
      'courseId',
      'levelId',
      'branchId',
      'roomId',
      'mainTeacherId',
      'assistantTeacherId',
      'startDate',
      'scheduleDays',
      'startTime',
      'endTime',
      'totalSessions',
    ];
    if (scheduleFields.some((field) => dto[field] !== undefined)) {
      throw new BadRequestException(
        'Không thể đổi khóa, chi nhánh hoặc lịch phân công qua thông tin lớp; hãy điều chỉnh từng buổi học',
      );
    }

    if (dto.code) {
      const existing = await this.prisma.class.findUnique({
        where: { code: dto.code },
      });
      if (existing && existing.id !== id) {
        throw new ConflictException(`Mã lớp '${dto.code}' đã được sử dụng`);
      }
    }

    const capacity = dto.maxCapacity ?? current.maxCapacity;
    const enrolled = current.students.filter(
      (item) => item.status === EnrollmentStatus.ENROLLED,
    ).length;
    if (capacity < enrolled) {
      throw new BadRequestException(
        'Sĩ số tối đa không được thấp hơn số học viên đang học',
      );
    }
    if (current.room && capacity > current.room.capacity) {
      throw new BadRequestException('Sĩ số lớp vượt quá sức chứa phòng học');
    }

    const openAt = dto.registrationOpenAt ?? current.registrationOpenAt;
    const closeAt = dto.registrationCloseAt ?? current.registrationCloseAt;
    if (
      dto.registrationOpenAt !== undefined ||
      dto.registrationCloseAt !== undefined ||
      dto.status === ClassStatus.OPEN_FOR_ENROLLMENT
    ) {
      this.validateRegistrationWindow(openAt, closeAt, current.startDate);
    }
    if (dto.status === ClassStatus.OPEN_FOR_ENROLLMENT) {
      if (
        !openAt ||
        !closeAt ||
        !current.roomId ||
        !current.mainTeacherId ||
        !(Number(dto.tuitionFee ?? current.tuitionFee) > 0)
      ) {
        throw new BadRequestException(
          'Cần có thời gian đăng ký, phòng, giáo viên chính và học phí trước khi mở tuyển sinh',
        );
      }
      if (
        !current.course.isActive ||
        current.course.publicationStatus !== 'PUBLISHED'
      ) {
        throw new BadRequestException(
          'Khóa học chưa được công bố để mở tuyển sinh',
        );
      }
    }

    const updateData: any = { ...dto };
    if (dto.registrationOpenAt)
      updateData.registrationOpenAt = new Date(dto.registrationOpenAt);
    if (dto.registrationCloseAt)
      updateData.registrationCloseAt = new Date(dto.registrationCloseAt);

    return this.prisma.class.update({
      where: { id },
      data: updateData,
    });
  }

  async deleteClass(id: string, actor: ClassActor) {
    const current = await this.findOne(id, actor);

    if (current.status !== ClassStatus.PLANNING) {
      throw new BadRequestException(
        `Chỉ lớp đang lập kế hoạch mới có thể xóa vĩnh viễn. Lớp hiện ở trạng thái '${current.status}'.`,
      );
    }

    const studentCount = await this.prisma.classStudent.count({
      where: { classId: id },
    });
    if (studentCount > 0) {
      throw new BadRequestException(
        `Lớp học đã có ${studentCount} học viên được ghi danh. Để đảm bảo toàn vẹn dữ liệu, không thể xóa vĩnh viễn. Vui lòng chọn HỦY LỚP (CANCELLED).`,
      );
    }

    const registrationCount = await this.prisma.classRegistration.count({
      where: { classId: id },
    });
    if (registrationCount > 0) {
      throw new BadRequestException(
        `Lớp học đã có ${registrationCount} đơn đăng ký trực tuyến. Vui lòng chuyển trạng thái sang HỦY LỚP (CANCELLED) thay vì xóa vĩnh viễn.`,
      );
    }

    const invoiceCount = await this.prisma.invoice.count({
      where: { classId: id },
    });
    if (invoiceCount > 0) {
      throw new BadRequestException(
        `Lớp học đã phát sinh ${invoiceCount} chứng từ/hóa đơn tài chính. Không thể xóa vĩnh viễn dữ liệu tài chính.`,
      );
    }

    const attendanceCount = await this.prisma.attendance.count({
      where: { session: { classId: id } },
    });
    if (attendanceCount > 0) {
      throw new BadRequestException(
        `Lớp học đã có ${attendanceCount} bản ghi điểm danh học viên. Không thể xóa vĩnh viễn.`,
      );
    }

    const [assignmentCount, examCount] = await Promise.all([
      this.prisma.assignment.count({ where: { classId: id } }),
      this.prisma.exam.count({ where: { classId: id } }),
    ]);
    if (assignmentCount > 0 || examCount > 0) {
      throw new BadRequestException(
        'Lớp học đã được giao bài tập hoặc đề thi. Không thể xóa vĩnh viễn.',
      );
    }

    return this.prisma.$transaction(async (tx) => {
      await tx.classSession.deleteMany({
        where: { classId: id },
      });
      const deleted = await tx.class.deleteMany({
        where: { id, status: ClassStatus.PLANNING },
      });
      if (deleted.count !== 1) {
        throw new ConflictException(
          'Trạng thái lớp đã thay đổi. Vui lòng tải lại trước khi xóa.',
        );
      }
      return {
        success: true,
        message: `Đã xóa vĩnh viễn lớp học '${current.code}' thành công.`,
      };
    });
  }

  // --------------------------------------------------------------------------
  // QUẢN LÝ HỌC VIÊN TRONG LỚP (ENROLLMENT)
  // --------------------------------------------------------------------------

  async enrollStudent(
    classId: string,
    dto: EnrollStudentDto,
    actor: ClassActor,
  ) {
    for (let attempt = 0; attempt < 3; attempt++) {
      try {
        return await this.prisma.$transaction(
          async (tx) => {
            const classEntity = await tx.class.findUnique({
              where: { id: classId },
              include: {
                _count: {
                  select: {
                    students: {
                      where: { status: EnrollmentStatus.ENROLLED },
                    },
                  },
                },
              },
            });

            if (!classEntity) {
              throw new NotFoundException(
                `Không tìm thấy lớp học với ID: ${classId}`,
              );
            }
            if (
              !actor.roles.includes('super_admin') &&
              (!actor.branchId || actor.branchId !== classEntity.branchId)
            ) {
              throw new ForbiddenException(
                'Lớp học không thuộc chi nhánh của bạn',
              );
            }

            // Kiểm tra học viên tồn tại
            const identifier = dto.studentId.trim();
            if (!identifier)
              throw new BadRequestException('Vui lòng nhập mã học viên');
            const studentUser = await tx.user.findFirst({
              where: { OR: [{ id: identifier }, { userCode: identifier }] },
              include: { userRoles: { include: { role: true } } },
            });

            if (!studentUser) {
              throw new NotFoundException(
                `Không tìm thấy người dùng với ID: ${dto.studentId}`,
              );
            }
            if (
              !studentUser.userRoles.some(
                (item) => item.role.code === 'student',
              )
            ) {
              throw new BadRequestException(
                'Người dùng không có vai trò học viên',
              );
            }
            if (
              studentUser.status === UserStatus.LOCKED ||
              studentUser.status === UserStatus.INACTIVE
            ) {
              throw new BadRequestException(
                'Không thể ghi danh tài khoản học viên đang bị khóa hoặc ngừng hoạt động',
              );
            }
            const studentId = studentUser.id;

            // Kiểm tra đã có trong lớp chưa
            const existingEnrollment = await tx.classStudent.findUnique({
              where: {
                classId_studentId: {
                  classId,
                  studentId,
                },
              },
            });

            if (existingEnrollment) {
              if (existingEnrollment.status === EnrollmentStatus.ENROLLED) {
                throw new ConflictException(
                  'Học viên đã được ghi danh vào lớp học này rồi',
                );
              }
            }

            const targetStatus = dto.status || EnrollmentStatus.ENROLLED;
            if (
              targetStatus === EnrollmentStatus.ENROLLED &&
              classEntity._count.students >= classEntity.maxCapacity
            ) {
              throw new ConflictException(
                `Lớp học đã đạt sĩ số tối đa (${classEntity._count.students}/${classEntity.maxCapacity} học viên)`,
              );
            }

            const studentEnrollment = existingEnrollment
              ? await tx.classStudent.update({
                  where: { id: existingEnrollment.id },
                  data: {
                    status: targetStatus,
                    tuitionPaid:
                      dto.tuitionPaid ?? existingEnrollment.tuitionPaid,
                    notes: dto.notes,
                  },
                })
              : await tx.classStudent.create({
                  data: {
                    classId,
                    studentId,
                    status: targetStatus,
                    tuitionPaid: dto.tuitionPaid || 0,
                    notes: dto.notes,
                  },
                  include: {
                    student: {
                      select: {
                        id: true,
                        userCode: true,
                        fullName: true,
                        email: true,
                        phone: true,
                      },
                    },
                  },
                });

            // Tự động tạo hóa đơn học phí cho học viên nếu lớp có học phí
            const tuitionFee = Number(classEntity.tuitionFee) || 0;
            if (targetStatus === EnrollmentStatus.ENROLLED && tuitionFee > 0) {
              const year = new Date().getFullYear();
              const code = `HD-${year}-${randomUUID().slice(0, 8).toUpperCase()}`;
              const paid = dto.tuitionPaid ? Number(dto.tuitionPaid) : 0;
              const balance = Math.max(0, tuitionFee - paid);
              const invoiceStatus =
                balance === 0
                  ? InvoiceStatus.PAID
                  : paid > 0
                    ? InvoiceStatus.PARTIALLY_PAID
                    : InvoiceStatus.PENDING;

              const existingInvoice = await tx.invoice.findFirst({
                where: {
                  classId,
                  studentId,
                  status: { not: InvoiceStatus.CANCELLED },
                },
              });
              if (!existingInvoice)
                await tx.invoice.create({
                  data: {
                    code,
                    title: `Học phí lớp ${classEntity.name}`,
                    studentId,
                    classId: classEntity.id,
                    subtotal: tuitionFee,
                    discount: 0,
                    totalAmount: tuitionFee,
                    paidAmount: paid,
                    balance,
                    status: invoiceStatus,
                    dueDate: classEntity.startDate,
                  },
                });
            }

            if (targetStatus === EnrollmentStatus.ENROLLED) {
              const pendingRequests = await tx.classRegistration.findMany({
                where: {
                  classId,
                  status: {
                    in: [
                      RegistrationStatus.PENDING,
                      RegistrationStatus.CONTACTED,
                    ],
                  },
                  OR: [
                    { studentId },
                    { lead: { is: { convertedUserId: studentId } } },
                  ],
                },
                select: { id: true, leadId: true },
              });
              if (pendingRequests.length) {
                await tx.classRegistration.updateMany({
                  where: { id: { in: pendingRequests.map((item) => item.id) } },
                  data: { status: RegistrationStatus.APPROVED, studentId },
                });
                const leadIds = pendingRequests
                  .map((item) => item.leadId)
                  .filter((id): id is string => id !== null);
                if (leadIds.length) {
                  await tx.admissionLead.updateMany({
                    where: { id: { in: leadIds } },
                    data: { status: LeadStatus.ENROLLED },
                  });
                }
              }
            }

            return studentEnrollment;
          },
          { isolationLevel: Prisma.TransactionIsolationLevel.Serializable },
        );
      } catch (error) {
        if (isRetryableTransactionConflict(error)) {
          if (attempt < 2) continue;
          throw new ConflictException('Không thể ghi danh, vui lòng thử lại');
        }
        if (
          error instanceof Prisma.PrismaClientKnownRequestError &&
          error.code === 'P2002'
        )
          throw new ConflictException(
            'Học viên đã được ghi danh hoặc mã hóa đơn bị trùng',
          );
        throw error;
      }
    }
    throw new ConflictException('Không thể ghi danh, vui lòng thử lại');
  }

  async removeStudent(classId: string, studentId: string, actor: ClassActor) {
    const enrollment = await this.prisma.classStudent.findUnique({
      where: {
        classId_studentId: {
          classId,
          studentId,
        },
      },
      include: { class: { select: { branchId: true } } },
    });

    if (!enrollment) {
      throw new NotFoundException('Học viên không có trong danh sách lớp này');
    }
    if (
      !actor.roles.includes('super_admin') &&
      (!actor.branchId || actor.branchId !== enrollment.class.branchId)
    ) {
      throw new ForbiddenException('Lớp học không thuộc chi nhánh của bạn');
    }

    await this.prisma.classStudent.delete({
      where: { id: enrollment.id },
    });

    return { message: 'Đã xóa học viên khỏi lớp học thành công' };
  }

  // --------------------------------------------------------------------------
  // BUỔI HỌC (SESSIONS)
  // --------------------------------------------------------------------------

  async findSessionsByClass(classId: string, actor: ClassActor) {
    await this.findOne(classId, actor);

    return this.prisma.classSession.findMany({
      where: { classId },
      orderBy: { sessionNumber: 'asc' },
      include: {
        room: { select: { id: true, code: true, name: true } },
        teacher: {
          select: { id: true, fullName: true, userCode: true, avatarUrl: true },
        },
        lesson: {
          select: { id: true, title: true, order: true, durationMinutes: true },
        },
      },
    });
  }

  async updateSession(
    sessionId: string,
    dto: UpdateClassSessionDto,
    actor: ClassActor,
  ) {
    const session = await this.prisma.classSession.findUnique({
      where: { id: sessionId },
      include: { class: true },
    });

    if (!session) {
      throw new NotFoundException(
        `Không tìm thấy buổi học với ID: ${sessionId}`,
      );
    }
    if (!actor.roles.includes('super_admin')) {
      const isBranchStaff =
        actor.roles.some((role) =>
          ['branch_admin', 'academic_staff'].includes(role),
        ) &&
        !!actor.branchId &&
        actor.branchId === session.class.branchId;
      const isAssignedTeacher =
        actor.roles.includes('teacher') &&
        (session.teacherId === actor.id ||
          session.class.mainTeacherId === actor.id);
      if (!isBranchStaff && !isAssignedTeacher) {
        throw new ForbiddenException('Bạn không được điều chỉnh buổi học này');
      }
      if (
        isAssignedTeacher &&
        !isBranchStaff &&
        (dto.date !== undefined ||
          dto.startTime !== undefined ||
          dto.endTime !== undefined ||
          dto.roomId !== undefined ||
          dto.teacherId !== undefined ||
          dto.lessonId !== undefined ||
          (dto.status !== undefined && dto.status !== SessionStatus.COMPLETED))
      ) {
        throw new ForbiddenException(
          'Giảng viên chỉ được cập nhật nội dung, ghi chú và hoàn thành buổi học; thay đổi lịch cần học vụ xử lý',
        );
      }
    }

    const targetDate = dto.date ? new Date(dto.date) : session.date;
    const targetStartTime = dto.startTime || session.startTime;
    const targetEndTime = dto.endTime || session.endTime;
    const targetRoomId = dto.roomId !== undefined ? dto.roomId : session.roomId;
    const targetTeacherId =
      dto.teacherId !== undefined ? dto.teacherId : session.teacherId;

    // Kiểm tra xung đột phòng học nếu có thay đổi
    if (targetRoomId) {
      const roomConflict = await this.prisma.classSession.findFirst({
        where: {
          id: { not: sessionId },
          roomId: targetRoomId,
          date: targetDate,
          status: { not: SessionStatus.CANCELLED },
          AND: [
            { startTime: { lt: targetEndTime } },
            { endTime: { gt: targetStartTime } },
          ],
        },
        include: { class: { select: { code: true, name: true } } },
      });

      if (roomConflict) {
        throw new ConflictException(
          `Phòng học đã có lớp '${roomConflict.class.name} (${roomConflict.class.code})' học vào thời gian này`,
        );
      }
    }

    // Kiểm tra xung đột giáo viên nếu có thay đổi
    if (targetTeacherId) {
      const teacherConflict = await this.prisma.classSession.findFirst({
        where: {
          id: { not: sessionId },
          teacherId: targetTeacherId,
          date: targetDate,
          status: { not: SessionStatus.CANCELLED },
          AND: [
            { startTime: { lt: targetEndTime } },
            { endTime: { gt: targetStartTime } },
          ],
        },
        include: { class: { select: { code: true, name: true } } },
      });

      if (teacherConflict) {
        throw new ConflictException(
          `Giáo viên đã có lịch dạy lớp '${teacherConflict.class.name}' vào thời gian này`,
        );
      }
    }

    const updateData: any = { ...dto };
    if (dto.date) updateData.date = new Date(dto.date);

    return this.prisma.classSession.update({
      where: { id: sessionId },
      data: updateData,
      include: {
        room: true,
        teacher: { select: { id: true, fullName: true, userCode: true } },
        lesson: true,
      },
    });
  }

  // --------------------------------------------------------------------------
  // MY CLASSES & MY SCHEDULE
  // --------------------------------------------------------------------------

  async getMyClasses(
    userId: string,
    roles: string[],
    branchId?: string | null,
  ) {
    const isTeacher =
      roles.includes('teacher') || roles.includes('teaching_assistant');
    const isStudent = roles.includes('student');
    const isParent = roles.includes('parent');
    const isAdmin =
      roles.includes('super_admin') ||
      roles.includes('branch_admin') ||
      roles.includes('academic_staff');

    if (isAdmin) {
      if (!roles.includes('super_admin') && !branchId) {
        throw new ForbiddenException('Tài khoản chưa được gán chi nhánh');
      }
      return this.prisma.class.findMany({
        where: {
          status: {
            in: [ClassStatus.IN_PROGRESS, ClassStatus.OPEN_FOR_ENROLLMENT],
          },
          ...(!roles.includes('super_admin') ? { branchId: branchId! } : {}),
        },
        include: {
          course: { select: { id: true, code: true, title: true } },
          level: { select: { id: true, name: true } },
          branch: { select: { id: true, name: true } },
          room: { select: { id: true, name: true } },
          mainTeacher: { select: { id: true, fullName: true } },
          _count: { select: { students: true } },
        },
        orderBy: { startDate: 'desc' },
      });
    }

    if (isTeacher) {
      return this.prisma.class.findMany({
        where: {
          OR: [{ mainTeacherId: userId }, { assistantTeacherId: userId }],
          status: {
            in: [ClassStatus.IN_PROGRESS, ClassStatus.OPEN_FOR_ENROLLMENT],
          },
        },
        include: {
          course: { select: { id: true, code: true, title: true } },
          level: { select: { id: true, name: true } },
          branch: { select: { id: true, name: true } },
          room: { select: { id: true, name: true } },
          _count: { select: { students: true, sessions: true } },
        },
        orderBy: { startDate: 'desc' },
      });
    }

    if (isStudent) {
      return this.prisma.class.findMany({
        where: {
          students: {
            some: {
              studentId: userId,
              status: EnrollmentStatus.ENROLLED,
            },
          },
        },
        include: {
          course: { select: { id: true, code: true, title: true } },
          level: { select: { id: true, name: true } },
          branch: { select: { id: true, name: true } },
          room: { select: { id: true, name: true } },
          mainTeacher: {
            select: { id: true, fullName: true, avatarUrl: true },
          },
          _count: { select: { sessions: true } },
        },
        orderBy: { startDate: 'desc' },
      });
    }

    if (isParent) {
      // Tìm học viên là con
      const children = await this.prisma.parentStudent.findMany({
        where: { parentId: userId },
        select: { studentId: true },
      });
      const childIds = children.map((c) => c.studentId);

      return this.prisma.class.findMany({
        where: {
          students: {
            some: {
              studentId: { in: childIds },
              status: EnrollmentStatus.ENROLLED,
            },
          },
        },
        include: {
          course: { select: { id: true, code: true, title: true } },
          level: { select: { id: true, name: true } },
          branch: { select: { id: true, name: true } },
          room: { select: { id: true, name: true } },
          mainTeacher: { select: { id: true, fullName: true } },
          students: {
            where: {
              studentId: { in: childIds },
              status: EnrollmentStatus.ENROLLED,
            },
            include: { student: { select: { id: true, fullName: true } } },
          },
        },
        orderBy: { startDate: 'desc' },
      });
    }

    return [];
  }

  async getMySchedule(
    userId: string,
    roles: string[],
    fromDate?: string,
    toDate?: string,
    branchId?: string,
  ) {
    const isTeacher =
      roles.includes('teacher') || roles.includes('teaching_assistant');
    const isStudent = roles.includes('student');
    const isParent = roles.includes('parent');
    const isSuperAdmin = roles.includes('super_admin');
    const isBranchStaff =
      roles.includes('branch_admin') || roles.includes('academic_staff');

    const dateFilter: any = {};
    if (fromDate) dateFilter.gte = new Date(fromDate);
    if (toDate) dateFilter.lte = new Date(toDate);

    const where: any = {};
    if (fromDate || toDate) where.date = dateFilter;

    if (isSuperAdmin) {
      // Super admin may view the complete center timetable.
    } else if (isBranchStaff) {
      if (!branchId)
        throw new ForbiddenException('Tài khoản chưa được gán chi nhánh');
      where.class = { branchId };
    } else if (isTeacher) {
      where.OR = [
        { teacherId: userId },
        { class: { mainTeacherId: userId } },
        { class: { assistantTeacherId: userId } },
      ];
    } else if (isStudent) {
      where.class = {
        students: {
          some: {
            studentId: userId,
            status: EnrollmentStatus.ENROLLED,
          },
        },
      };
    } else if (isParent) {
      const children = await this.prisma.parentStudent.findMany({
        where: { parentId: userId },
        select: { studentId: true },
      });
      const childIds = children.map((c) => c.studentId);

      where.class = {
        students: {
          some: {
            studentId: { in: childIds },
            status: EnrollmentStatus.ENROLLED,
          },
        },
      };
    } else {
      throw new ForbiddenException('Bạn không có quyền xem thời khóa biểu');
    }

    return this.prisma.classSession.findMany({
      where,
      orderBy: [{ date: 'asc' }, { startTime: 'asc' }],
      include: {
        class: {
          select: {
            id: true,
            code: true,
            name: true,
            course: { select: { code: true, title: true } },
            branch: { select: { name: true } },
          },
        },
        room: { select: { id: true, code: true, name: true } },
        teacher: { select: { id: true, fullName: true, userCode: true } },
        lesson: { select: { id: true, title: true } },
      },
    });
  }
}
