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
import { LeadStatus, UserStatus, Prisma } from '@prisma/client';
import {
  CreateLeadDto,
  UpdateLeadDto,
  QueryLeadsDto,
  ConvertLeadDto,
} from './dto/index.js';

@Injectable()
export class AdmissionsService {
  private readonly logger = new Logger(AdmissionsService.name);
  private readonly saltRounds = 12;

  constructor(
    private readonly prisma: PrismaService,
    private readonly mailService: MailService,
  ) {}

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
        },
      }),
      this.prisma.admissionLead.count({ where }),
    ]);

    return {
      items,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
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
      },
    });

    if (!lead) {
      throw new NotFoundException(
        'Không tìm thấy thông tin đăng ký tư vấn này.',
      );
    }

    return lead;
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
      },
    });

    return {
      message: 'Cập nhật tiến trình tư vấn thành công.',
      lead: updated,
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
