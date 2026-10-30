import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { randomInt } from 'node:crypto';
import * as XLSX from 'xlsx';
import { PrismaService } from '../../database/index.js';
import { isRetryableTransactionConflict } from '../../common/prisma-transaction.js';
import { MailService } from '../mail/index.js';
import {
  LeadStatus,
  RegistrationStatus,
  UserStatus,
  Prisma,
} from '@prisma/client';
import {
  CreateLeadDto,
  UpdateLeadDto,
  CloseLeadDto,
  ArchiveLeadDto,
  QueryLeadsDto,
  ConvertLeadDto,
} from './dto/index.js';

const ARCHIVE_TAG_REGEX = /\[ARCHIVED(?::([A-Z_]+))?(?::([^\]]+))?\]/g;
const CLOSE_TAG_REGEX = /\[ĐÓNG LEAD - ([^\]]+)\]/;

@Injectable()
export class AdmissionsService {
  private readonly logger = new Logger(AdmissionsService.name);
  private readonly saltRounds = 12;

  constructor(
    private readonly prisma: PrismaService,
    private readonly mailService: MailService,
  ) {}

  private enrichLead<
    T extends {
      id: string;
      status: LeadStatus;
      notes?: string | null;
      convertedUserId?: string | null;
      classRegistrations?: { id: string; status: RegistrationStatus }[];
    },
  >(lead: T) {
    const rawNotes = lead.notes ?? '';
    const archiveMatch = /\[ARCHIVED(?::([A-Z_]+))?(?::([^\]]+))?\]/.exec(
      rawNotes,
    );
    const isArchived = Boolean(archiveMatch);
    const archivedPreviousStatus = archiveMatch?.[1] ?? null;
    const closeMatch = CLOSE_TAG_REGEX.exec(rawNotes);
    const closeReason = closeMatch?.[1] ?? null;

    const regs = lead.classRegistrations ?? [];
    const activeRegistrationsCount = regs.filter(
      (r) =>
        r.status === RegistrationStatus.PENDING ||
        r.status === RegistrationStatus.CONTACTED ||
        r.status === RegistrationStatus.APPROVED,
    ).length;
    const historicalRegistrationsCount = regs.filter(
      (r) =>
        r.status === RegistrationStatus.REJECTED ||
        r.status === RegistrationStatus.CANCELLED,
    ).length;

    let canDelete = true;
    let deleteBlockReason: string | null = null;
    if (lead.convertedUserId || lead.status === LeadStatus.ENROLLED) {
      canDelete = false;
      deleteBlockReason =
        'Hồ sơ Lead đã chuyển đổi thành học viên chính thức. Không thể xóa vĩnh viễn; vui lòng chọn Lưu trữ Lead.';
    } else if (activeRegistrationsCount > 0) {
      canDelete = false;
      deleteBlockReason = `Lead đang có ${activeRegistrationsCount} đơn đăng ký lớp học đang xử lý hoặc đã duyệt. Không thể xóa vĩnh viễn.`;
    } else if (historicalRegistrationsCount > 0) {
      canDelete = false;
      deleteBlockReason = `Lead có ${historicalRegistrationsCount} đơn đăng ký lớp học lưu trong lịch sử. Vui lòng xóa đơn đăng ký thử nghiệm trước hoặc chọn Lưu trữ Lead.`;
    }

    return {
      ...lead,
      isArchived,
      archivedPreviousStatus,
      closeReason,
      activeRegistrationsCount,
      historicalRegistrationsCount,
      canDelete,
      deleteBlockReason,
    };
  }

  async createLead(dto: CreateLeadDto) {
    const lead = await this.prisma.admissionLead.create({
      data: {
        fullName: dto.fullName.trim(),
        phone: dto.phone.trim(),
        email: dto.email ? dto.email.trim().toLowerCase() : undefined,
        targetCourse: dto.targetCourse?.trim(),
        source: dto.source,
        branchId: dto.branchId,
        notes: dto.notes?.trim(),
        status: LeadStatus.NEW,
      },
      include: {
        branch: {
          select: { id: true, code: true, name: true },
        },
      },
    });

    this.logger.log(
      `Tiếp nhận lead tư vấn mới: ${lead.fullName} (${lead.phone})`,
    );

    return {
      message:
        'Đăng ký nhận tư vấn thành công. Đội ngũ học vụ sẽ sớm liên hệ với bạn.',
      lead,
    };
  }

  async findAll(query: QueryLeadsDto) {
    const page = Math.max(1, Number(query.page) || 1);
    const limit = Math.max(1, Number(query.limit) || 10);
    const skip = (page - 1) * limit;

    const where: any = {};

    if (query.status) {
      where.status = query.status;
    }

    if (query.source) {
      where.source = query.source;
    }

    if (query.branchId) {
      where.branchId = query.branchId;
    }

    if (query.assignedStaffId) {
      where.assignedStaffId = query.assignedStaffId;
    }

    if (query.search && query.search.trim()) {
      const keyword = query.search.trim();
      where.OR = [
        { fullName: { contains: keyword, mode: 'insensitive' } },
        { phone: { contains: keyword, mode: 'insensitive' } },
        { email: { contains: keyword, mode: 'insensitive' } },
        { targetCourse: { contains: keyword, mode: 'insensitive' } },
      ];
    }

    const [items, total] = await Promise.all([
      this.prisma.admissionLead.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          branch: {
            select: { id: true, code: true, name: true },
          },
          assignedStaff: {
            select: { id: true, fullName: true, userCode: true, email: true },
          },
          classRegistrations: {
            select: { id: true, status: true, classId: true },
          },
        },
      }),
      this.prisma.admissionLead.count({ where }),
    ]);

    return {
      items: items.map((item) => this.enrichLead(item)),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async getSummary(branchId?: string) {
    const leads = await this.prisma.admissionLead.findMany({
      where: branchId ? { branchId } : undefined,
      select: {
        id: true,
        status: true,
        notes: true,
        convertedUserId: true,
      },
    });

    let total = 0;
    let activePipeline = 0;
    let newCount = 0;
    let contactedCount = 0;
    let testScheduledCount = 0;
    let enrolledCount = 0;
    let closedCount = 0;
    let archivedCount = 0;

    for (const lead of leads) {
      total++;
      const isArchived = Boolean(lead.notes && lead.notes.includes('[ARCHIVED'));
      const isConverted =
        lead.status === LeadStatus.ENROLLED || Boolean(lead.convertedUserId);

      if (isConverted) {
        enrolledCount++;
      }
      if (isArchived) {
        archivedCount++;
        continue;
      }
      if (lead.status === LeadStatus.NEW) {
        newCount++;
        activePipeline++;
      } else if (lead.status === LeadStatus.CONTACTED) {
        contactedCount++;
        activePipeline++;
      } else if (lead.status === LeadStatus.TEST_SCHEDULED) {
        testScheduledCount++;
        activePipeline++;
      } else if (lead.status === LeadStatus.CANCELLED) {
        closedCount++;
      }
    }

    return {
      total,
      activePipeline,
      newCount,
      contactedCount,
      testScheduledCount,
      enrolledCount,
      closedCount,
      archivedCount,
    };
  }

  async exportLeadsExcel(branchId?: string): Promise<Buffer> {
    const leads = await this.prisma.admissionLead.findMany({
      where: branchId ? { branchId } : undefined,
      orderBy: { createdAt: 'desc' },
      include: {
        branch: { select: { name: true } },
        assignedStaff: { select: { fullName: true } },
      },
    });
    const rows = leads.map((lead) => ({
      'Họ và tên': lead.fullName,
      'Số điện thoại': lead.phone,
      Email: lead.email ?? '',
      'Khóa học quan tâm': lead.targetCourse ?? '',
      Nguồn: lead.source,
      'Trạng thái': lead.status,
      'Chi nhánh': lead.branch?.name ?? '',
      'Nhân viên phụ trách': lead.assignedStaff?.fullName ?? '',
      'Ngày tạo': lead.createdAt.toISOString().slice(0, 10),
    }));
    const sheet = XLSX.utils.json_to_sheet(rows);
    const book = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(book, sheet, 'Leads');
    return XLSX.write(book, { type: 'buffer', bookType: 'xlsx' }) as Buffer;
  }

  async findOne(id: string) {
    const lead = await this.prisma.admissionLead.findUnique({
      where: { id },
      include: {
        branch: true,
        assignedStaff: {
          select: {
            id: true,
            fullName: true,
            userCode: true,
            email: true,
            phone: true,
          },
        },
        classRegistrations: {
          select: { id: true, status: true, classId: true },
        },
      },
    });

    if (!lead) {
      throw new NotFoundException(
        'Không tìm thấy thông tin đăng ký tư vấn này.',
      );
    }

    return this.enrichLead(lead);
  }

  async assertBranchAccess(id: string, branchId: string): Promise<void> {
    const lead = await this.prisma.admissionLead.findUnique({
      where: { id },
      select: { branchId: true },
    });
    if (!lead)
      throw new NotFoundException(
        'Không tìm thấy thông tin đăng ký tư vấn này.',
      );
    if (lead.branchId !== branchId) {
      throw new ForbiddenException(
        'Bạn không có quyền truy cập hồ sơ tư vấn ở chi nhánh này.',
      );
    }
  }

  async updateLead(id: string, dto: UpdateLeadDto) {
    await this.findOne(id);

    const updated = await this.prisma.admissionLead.update({
      where: { id },
      data: {
        fullName: dto.fullName?.trim(),
        phone: dto.phone?.trim(),
        email: dto.email ? dto.email.trim().toLowerCase() : undefined,
        targetCourse: dto.targetCourse?.trim(),
        source: dto.source,
        status: dto.status,
        notes: dto.notes?.trim(),
        branchId: dto.branchId,
        assignedStaffId: dto.assignedStaffId,
      },
      include: {
        branch: { select: { id: true, code: true, name: true } },
        assignedStaff: { select: { id: true, fullName: true, userCode: true } },
        classRegistrations: {
          select: { id: true, status: true, classId: true },
        },
      },
    });

    return {
      message: 'Cập nhật tiến trình tư vấn thành công.',
      lead: this.enrichLead(updated),
    };
  }

  async closeLead(id: string, body: CloseLeadDto, actorId?: string) {
    const lead = await this.findOne(id);
    if (lead.status === LeadStatus.ENROLLED || lead.convertedUserId) {
      throw new ConflictException(
        'Không thể đóng Lead vì hồ sơ đã chuyển đổi thành học viên chính thức. Bạn có thể lưu trữ hồ sơ.',
      );
    }
    const reason = body.reason?.trim() || 'Không còn nhu cầu';
    const extraNote = (body.notes ?? body.note)?.trim();
    const cleanedExisting = (lead.notes ?? '')
      .replace(ARCHIVE_TAG_REGEX, '')
      .replace(/\[ĐÓNG LEAD - [^\]]+\](?:: [^\n]*)?/g, '')
      .trim();
    const closeLine = `[ĐÓNG LEAD - ${reason}]${extraNote ? `: ${extraNote}` : ''}`;
    const nextNotes = [cleanedExisting, closeLine]
      .filter((part) => part.length > 0)
      .join('\n');

    const updated = await this.prisma.admissionLead.update({
      where: { id },
      data: {
        status: LeadStatus.CANCELLED,
        notes: nextNotes,
        ...(actorId && !lead.assignedStaffId
          ? { assignedStaffId: actorId }
          : {}),
      },
      include: {
        branch: { select: { id: true, code: true, name: true } },
        assignedStaff: { select: { id: true, fullName: true, userCode: true } },
        classRegistrations: {
          select: { id: true, status: true, classId: true },
        },
      },
    });

    return {
      message: `Đã đóng hồ sơ tư vấn (${reason}).`,
      lead: this.enrichLead(updated),
    };
  }

  async archiveLead(id: string, body?: ArchiveLeadDto, actorId?: string) {
    const lead = await this.findOne(id);
    const existingArchiveMatch = /\[ARCHIVED(?::([A-Z_]+))?(?::([^\]]+))?\]/.exec(
      lead.notes ?? '',
    );
    const preservedStatus = existingArchiveMatch?.[1] || lead.status;
    const cleanedNotes = (lead.notes ?? '')
      .replace(ARCHIVE_TAG_REGEX, '')
      .replace(/\[Lý do lưu trữ\]: [^\n]*/g, '')
      .trim();
    const dateStr = new Date().toISOString().slice(0, 10);
    const archiveTag = `[ARCHIVED:${preservedStatus}:${dateStr}]`;
    const extraReason = (body?.reason ?? body?.notes)?.trim();
    const nextNotes = [
      cleanedNotes,
      archiveTag,
      extraReason ? `[Lý do lưu trữ]: ${extraReason}` : '',
    ]
      .filter((part) => part.length > 0)
      .join('\n');

    const updated = await this.prisma.admissionLead.update({
      where: { id },
      data: {
        notes: nextNotes,
        ...(actorId && !lead.assignedStaffId
          ? { assignedStaffId: actorId }
          : {}),
      },
      include: {
        branch: { select: { id: true, code: true, name: true } },
        assignedStaff: { select: { id: true, fullName: true, userCode: true } },
        classRegistrations: {
          select: { id: true, status: true, classId: true },
        },
      },
    });

    return {
      message: 'Đã lưu trữ hồ sơ Lead thành công.',
      lead: this.enrichLead(updated),
    };
  }

  async restoreLead(id: string, _actorId?: string) {
    const lead = await this.findOne(id);
    const archiveMatch = /\[ARCHIVED(?::([A-Z_]+))?(?::([^\]]+))?\]/.exec(
      lead.notes ?? '',
    );
    const prevStatusRaw = archiveMatch?.[1];
    const validStatuses = Object.values(LeadStatus) as string[];
    const restoredStatus =
      lead.convertedUserId || lead.status === LeadStatus.ENROLLED
        ? LeadStatus.ENROLLED
        : prevStatusRaw &&
            validStatuses.includes(prevStatusRaw) &&
            prevStatusRaw !== LeadStatus.CANCELLED
          ? (prevStatusRaw as LeadStatus)
          : lead.status === LeadStatus.CANCELLED
            ? LeadStatus.CONTACTED
            : lead.status;

    const cleanedNotes = (lead.notes ?? '')
      .replace(ARCHIVE_TAG_REGEX, '')
      .replace(/\[Lý do lưu trữ\]: [^\n]*/g, '')
      .replace(/\[ĐÓNG LEAD - [^\]]+\](?:: [^\n]*)?/g, '')
      .trim();

    const updated = await this.prisma.admissionLead.update({
      where: { id },
      data: {
        status: restoredStatus,
        notes: cleanedNotes || null,
      },
      include: {
        branch: { select: { id: true, code: true, name: true } },
        assignedStaff: { select: { id: true, fullName: true, userCode: true } },
        classRegistrations: {
          select: { id: true, status: true, classId: true },
        },
      },
    });

    return {
      message: 'Đã khôi phục hồ sơ Lead về danh sách hoạt động.',
      lead: this.enrichLead(updated),
    };
  }

  async deleteLead(id: string) {
    const lead = await this.findOne(id);

    if (lead.convertedUserId || lead.status === LeadStatus.ENROLLED) {
      throw new ConflictException(
        'Không thể xóa Lead vì hồ sơ đã liên kết với một học viên. Bạn có thể lưu trữ hồ sơ.',
      );
    }

    const [activeRegCount, historicalRegCount] = await Promise.all([
      this.prisma.classRegistration.count({
        where: {
          leadId: id,
          status: {
            in: [
              RegistrationStatus.PENDING,
              RegistrationStatus.CONTACTED,
              RegistrationStatus.APPROVED,
            ],
          },
        },
      }),
      this.prisma.classRegistration.count({
        where: {
          leadId: id,
          status: {
            in: [RegistrationStatus.REJECTED, RegistrationStatus.CANCELLED],
          },
        },
      }),
    ]);

    if (activeRegCount > 0) {
      throw new ConflictException(
        `Không thể xóa Lead vì hồ sơ đang liên kết với ${activeRegCount} đơn đăng ký lớp học đang hoạt động. Bạn có thể đóng hoặc lưu trữ hồ sơ.`,
      );
    }

    if (historicalRegCount > 0) {
      throw new ConflictException(
        `Không thể xóa Lead vì hồ sơ có ${historicalRegCount} đơn đăng ký lớp học lưu trong lịch sử. Vui lòng xóa đơn đăng ký thử nghiệm liên quan trước hoặc chọn Lưu trữ Lead.`,
      );
    }

    await this.prisma.$transaction(async (tx) => {
      const fresh = await tx.admissionLead.findUnique({
        where: { id },
        select: {
          id: true,
          status: true,
          convertedUserId: true,
          _count: { select: { classRegistrations: true } },
        },
      });
      if (!fresh) {
        throw new NotFoundException('Không tìm thấy thông tin đăng ký tư vấn này.');
      }
      if (fresh.convertedUserId || fresh.status === LeadStatus.ENROLLED) {
        throw new ConflictException(
          'Không thể xóa Lead vì hồ sơ đã liên kết với một học viên. Bạn có thể lưu trữ hồ sơ.',
        );
      }
      if (fresh._count.classRegistrations > 0) {
        throw new ConflictException(
          'Không thể xóa Lead vì hồ sơ vẫn còn đơn đăng ký lớp học liên kết. Bạn có thể lưu trữ hồ sơ.',
        );
      }
      await tx.admissionLead.delete({ where: { id } });
    });

    return {
      success: true,
      id,
      message: `Đã xóa vĩnh viễn hồ sơ Lead "${lead.fullName}" thành công.`,
    };
  }

  async convertLead(id: string, dto: ConvertLeadDto) {
    const lead = await this.findOne(id);

    if (lead.status === LeadStatus.ENROLLED || lead.convertedUserId) {
      throw new BadRequestException(
        'Hồ sơ tư vấn này đã được chuyển đổi thành học viên chính thức trước đó.',
      );
    }

    // 1. Tìm role 'student'
    const studentRole = await this.prisma.role.findUnique({
      where: { code: 'student' },
    });

    if (!studentRole) {
      throw new BadRequestException(
        'Không tìm thấy cấu hình vai trò học viên (student) trong hệ thống.',
      );
    }

    // 2. Mật khẩu tạm thời
    const tempPassword =
      dto.temporaryPassword?.trim() || `Student@${randomInt(100000, 1000000)}`;
    const passwordHash = bcrypt.hashSync(tempPassword, this.saltRounds);

    // 3. Thực hiện chuyển đổi trong Transaction
    let result:
      Awaited<ReturnType<typeof this.convertLeadTransaction>> | undefined;
    for (let attempt = 0; attempt < 3; attempt++) {
      try {
        result = await this.convertLeadTransaction(
          lead,
          dto,
          studentRole.id,
          passwordHash,
          tempPassword,
          attempt,
        );
        break;
      } catch (error) {
        if (
          isRetryableTransactionConflict(error) ||
          (error instanceof Prisma.PrismaClientKnownRequestError &&
            error.code === 'P2002')
        ) {
          if (attempt < 2) continue;
          throw new ConflictException(
            'Không thể cấp mã học viên, vui lòng thử lại',
          );
        }
        throw error;
      }
    }
    if (!result)
      throw new ConflictException('Không thể chuyển Lead, vui lòng thử lại');

    // 4. Gửi email chào mừng và cấp tài khoản (nếu học viên có email)
    if (result.user.email) {
      try {
        await this.mailService.sendWelcomeEmail(
          result.user.email,
          result.user.fullName,
          result.user.userCode,
          result.tempPassword,
        );
      } catch (error) {
        this.logger.warn(
          `Đã tạo học viên nhưng gửi email chào mừng thất bại: ${error}`,
        );
      }
    }

    return {
      message:
        'Chuyển đổi thành công học viên chính thức và đã cấp phát tài khoản.',
      student: {
        id: result.user.id,
        userCode: result.user.userCode,
        fullName: result.user.fullName,
        email: result.user.email,
        phone: result.user.phone,
        temporaryPassword: result.tempPassword,
        branch: result.user.branch,
        studentProfile: result.user.studentProfile,
      },
      lead: result.lead,
    };
  }

  private convertLeadTransaction(
    lead: Awaited<ReturnType<typeof this.findOne>>,
    dto: ConvertLeadDto,
    roleId: string,
    passwordHash: string,
    tempPassword: string,
    attempt: number,
  ) {
    return this.prisma.$transaction(
      async (tx) => {
        // Đếm số lượng học viên hiện tại để sinh mã học viên tự tăng: HV-2026-0001
        const year = new Date().getFullYear();
        const countStudents = await tx.studentProfile.count();
        const studentCode = `HV-${year}-${String(countStudents + attempt + 1).padStart(4, '0')}`;

        // Tạo User
        const newUser = await tx.user.create({
          data: {
            userCode: studentCode,
            fullName: lead.fullName,
            phone: lead.phone,
            email: lead.email,
            passwordHash,
            status: UserStatus.ACTIVE,
            isFirstLogin: true, // Bắt buộc đổi mật khẩu khi đăng nhập lần đầu
            branchId: dto.branchId || lead.branchId,
            userRoles: {
              create: {
                roleId,
              },
            },
            studentProfile: {
              create: {
                entryLevel: dto.entryLevel?.trim(),
                targetLevel: dto.targetLevel?.trim() || lead.targetCourse,
                schoolName: dto.schoolName?.trim(),
                notes: dto.notes?.trim() || lead.notes,
              },
            },
          },
          include: {
            studentProfile: true,
            branch: { select: { id: true, code: true, name: true } },
            userRoles: { include: { role: true } },
          },
        });

        // Cập nhật trạng thái AdmissionLead
        const changed = await tx.admissionLead.updateMany({
          where: {
            id: lead.id,
            convertedUserId: null,
            status: { not: LeadStatus.ENROLLED },
          },
          data: {
            status: LeadStatus.ENROLLED,
            convertedUserId: newUser.id,
            convertedAt: new Date(),
            notes: dto.notes
              ? `${lead.notes || ''}\n[Chuyển đổi HV]: ${dto.notes}`.trim()
              : lead.notes,
          },
        });
        if (changed.count !== 1) {
          throw new ConflictException(
            'Hồ sơ đã được nhân viên khác chuyển thành học viên',
          );
        }
        const updatedLead = await tx.admissionLead.findUniqueOrThrow({
          where: { id: lead.id },
        });

        return { user: newUser, lead: updatedLead, tempPassword };
      },
      { isolationLevel: Prisma.TransactionIsolationLevel.Serializable },
    );
  }
}
