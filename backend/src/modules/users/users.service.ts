import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import * as XLSX from 'xlsx';
import { UserStatus, Gender, Prisma } from '@prisma/client';
import { PrismaService } from '../../database/index.js';
import { MailService } from '../mail/index.js';
import {
  QueryUsersDto,
  CreateStudentDto,
  CreateParentDto,
  CreateStaffDto,
  UpdateUserDto,
  UpdateUserStatusDto,
  AdminResetPasswordDto,
  AssignRolesDto,
} from './dto/index.js';

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);
  private readonly saltRounds = 12;

  constructor(
    private readonly prisma: PrismaService,
    private readonly mailService: MailService,
  ) {}

  async assertBranchAccess(
    actor: { roles: string[]; branchId?: string | null },
    targetId: string,
  ): Promise<void> {
    if (actor.roles.includes('super_admin')) return;
    const target = await this.prisma.user.findUnique({
      where: { id: targetId },
      select: {
        branchId: true,
        userRoles: { select: { role: { select: { code: true } } } },
      },
    });
    if (!target) throw new NotFoundException('Không tìm thấy người dùng này.');
    if (!actor.branchId || target.branchId !== actor.branchId) {
      throw new ForbiddenException(
        'Bạn không có quyền truy cập người dùng ở chi nhánh này.',
      );
    }
    if (target.userRoles.some((item) => item.role.code === 'super_admin')) {
      throw new ForbiddenException(
        'Chỉ Super Admin được quản lý tài khoản Super Admin.',
      );
    }
    if (target.userRoles.some((item) => item.role.code === 'branch_admin')) {
      throw new ForbiddenException(
        'Chỉ Super Admin được quản lý tài khoản quản trị chi nhánh.',
      );
    }
  }

  // --------------------------------------------------------------------------
  // HELPER: Tự động sinh mã định danh không trùng lặp (HV-2026-0001, GV-2026-0001...)
  // --------------------------------------------------------------------------
  private async generateUniqueUserCode(prefix: string): Promise<string> {
    const year = new Date().getFullYear();
    const pattern = `${prefix}-${year}-`;

    const count = await this.prisma.user.count({
      where: {
        userCode: {
          startsWith: pattern,
        },
      },
    });

    let index = count + 1;
    let code = `${pattern}${String(index).padStart(4, '0')}`;

    while (await this.prisma.user.findUnique({ where: { userCode: code } })) {
      index++;
      code = `${pattern}${String(index).padStart(4, '0')}`;
    }

    return code;
  }

  // --------------------------------------------------------------------------
  // 1. GET /users — Danh sách người dùng phân trang & tìm kiếm, lọc
  // --------------------------------------------------------------------------
  async findAll(query: QueryUsersDto) {
    const { page = 1, limit = 10, search, role, branchId, status } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.UserWhereInput = {};

    if (search && search.trim()) {
      const keyword = search.trim();
      where.OR = [
        { fullName: { contains: keyword, mode: 'insensitive' } },
        { userCode: { contains: keyword, mode: 'insensitive' } },
        { email: { contains: keyword, mode: 'insensitive' } },
        { phone: { contains: keyword, mode: 'insensitive' } },
      ];
    }

    if (role && role.trim()) {
      where.userRoles = {
        some: {
          role: {
            code: role.trim(),
          },
        },
      };
    }

    if (branchId && branchId.trim()) {
      where.branchId = branchId.trim();
    }

    if (status) {
      where.status = status;
    }

    const [users, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          userCode: true,
          fullName: true,
          email: true,
          phone: true,
          avatarUrl: true,
          gender: true,
          dateOfBirth: true,
          address: true,
          status: true,
          isFirstLogin: true,
          lastLoginAt: true,
          createdAt: true,
          updatedAt: true,
          branch: {
            select: { id: true, code: true, name: true },
          },
          userRoles: {
            select: {
              role: {
                select: { id: true, code: true, name: true },
              },
            },
          },
          studentProfile: true,
          teacherProfile: true,
        },
      }),
      this.prisma.user.count({ where }),
    ]);

    // Chuẩn hóa định dạng danh sách role cho frontend dễ hiển thị
    const items = users.map((user) => ({
      ...user,
      roles: user.userRoles.map((ur) => ur.role),
      userRoles: undefined,
    }));

    return {
      items,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async exportUsersExcel(branchId?: string): Promise<Buffer> {
    const users = await this.prisma.user.findMany({
      where: branchId ? { branchId } : undefined,
      orderBy: { createdAt: 'desc' },
      select: {
        userCode: true,
        fullName: true,
        email: true,
        phone: true,
        status: true,
        branch: { select: { name: true } },
        userRoles: { select: { role: { select: { name: true } } } },
        createdAt: true,
      },
    });
    const rows = users.map((user) => ({
      'Mã tài khoản': user.userCode,
      'Họ và tên': user.fullName,
      Email: user.email ?? '',
      'Điện thoại': user.phone ?? '',
      'Vai trò': user.userRoles.map((item) => item.role.name).join(', '),
      'Chi nhánh': user.branch?.name ?? '',
      'Trạng thái': user.status,
      'Ngày tạo': user.createdAt.toISOString().slice(0, 10),
    }));
    const sheet = XLSX.utils.json_to_sheet(rows);
    const book = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(book, sheet, 'Nguoi dung');
    return XLSX.write(book, { type: 'buffer', bookType: 'xlsx' }) as Buffer;
  }

  async findTeacherOptions(branchId: string) {
    return this.prisma.user.findMany({
      where: {
        branchId,
        status: UserStatus.ACTIVE,
        userRoles: { some: { role: { code: 'teacher' } } },
      },
      select: { id: true, userCode: true, fullName: true },
      orderBy: { fullName: 'asc' },
    });
  }

  // --------------------------------------------------------------------------
  // 2. GET /users/:id — Chi tiết người dùng kèm profile và quan hệ
  // --------------------------------------------------------------------------
  async findOne(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      include: {
        branch: {
          select: {
            id: true,
            code: true,
            name: true,
            address: true,
            phone: true,
          },
        },
        userRoles: {
          include: {
            role: {
              select: { id: true, code: true, name: true, description: true },
            },
          },
        },
        studentProfile: true,
        teacherProfile: true,
        children: {
          include: {
            student: {
              select: {
                id: true,
                userCode: true,
                fullName: true,
                email: true,
                phone: true,
                avatarUrl: true,
              },
            },
          },
        },
        parents: {
          include: {
            parent: {
              select: {
                id: true,
                userCode: true,
                fullName: true,
                email: true,
                phone: true,
                avatarUrl: true,
              },
            },
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException(
        'Không tìm thấy người dùng này trong hệ thống.',
      );
    }

    const { passwordHash, userRoles, ...safeUser } = user;
    return {
      ...safeUser,
      roles: userRoles.map((ur) => ur.role),
    };
  }

  // --------------------------------------------------------------------------
  // 3. POST /users/students — Cấp tài khoản học viên mới
  // --------------------------------------------------------------------------
  async createStudent(dto: CreateStudentDto) {
    if (dto.email) {
      const existingEmail = await this.prisma.user.findUnique({
        where: { email: dto.email.trim().toLowerCase() },
      });
      if (existingEmail) {
        throw new ConflictException(
          `Email ${dto.email} đã được sử dụng bởi tài khoản khác.`,
        );
      }
    }

    if (dto.phone) {
      const existingPhone = await this.prisma.user.findUnique({
        where: { phone: dto.phone.trim() },
      });
      if (existingPhone) {
        throw new ConflictException(
          `Số điện thoại ${dto.phone} đã được sử dụng.`,
        );
      }
    }

    if (dto.branchId) {
      const branch = await this.prisma.branch.findUnique({
        where: { id: dto.branchId },
      });
      if (!branch) {
        throw new NotFoundException('Chi nhánh được chỉ định không tồn tại.');
      }
    }

    const studentRole = await this.prisma.role.findUnique({
      where: { code: 'student' },
    });
    if (!studentRole) {
      throw new BadRequestException(
        'Vai trò học viên (student) chưa được cấu hình.',
      );
    }

    const tempPassword =
      dto.temporaryPassword?.trim() ||
      `Student@${Math.floor(100000 + Math.random() * 900000)}`;
    const passwordHash = bcrypt.hashSync(tempPassword, this.saltRounds);
    const userCode = await this.generateUniqueUserCode('HV');

    const newUser = await this.prisma.$transaction(async (tx) => {
      return tx.user.create({
        data: {
          userCode,
          fullName: dto.fullName.trim(),
          email: dto.email ? dto.email.trim().toLowerCase() : null,
          phone: dto.phone ? dto.phone.trim() : null,
          gender: dto.gender,
          dateOfBirth: dto.dateOfBirth ? new Date(dto.dateOfBirth) : null,
          address: dto.address?.trim(),
          passwordHash,
          status: UserStatus.ACTIVE,
          isFirstLogin: true,
          branchId: dto.branchId,
          userRoles: {
            create: {
              roleId: studentRole.id,
            },
          },
          studentProfile: {
            create: {
              entryLevel: dto.entryLevel?.trim(),
              targetLevel: dto.targetLevel?.trim(),
              schoolName: dto.schoolName?.trim(),
              notes: dto.notes?.trim(),
            },
          },
        },
        include: {
          branch: { select: { id: true, code: true, name: true } },
          studentProfile: true,
          userRoles: { include: { role: true } },
        },
      });
    });

    if (newUser.email) {
      this.mailService.sendWelcomeEmail(
        newUser.email,
        newUser.fullName,
        newUser.userCode,
        tempPassword,
      );
    }

    const { passwordHash: _, userRoles, ...safeUser } = newUser;
    return {
      message: 'Cấp tài khoản học viên thành công.',
      temporaryPassword: tempPassword,
      user: {
        ...safeUser,
        roles: userRoles.map((ur) => ur.role),
      },
    };
  }

  // --------------------------------------------------------------------------
  // 4. POST /users/parents — Cấp tài khoản phụ huynh & liên kết con
  // --------------------------------------------------------------------------
  async createParent(dto: CreateParentDto) {
    const existingPhone = await this.prisma.user.findUnique({
      where: { phone: dto.phone.trim() },
    });
    if (existingPhone) {
      throw new ConflictException(
        `Số điện thoại phụ huynh ${dto.phone} đã tồn tại.`,
      );
    }

    if (dto.email) {
      const existingEmail = await this.prisma.user.findUnique({
        where: { email: dto.email.trim().toLowerCase() },
      });
      if (existingEmail) {
        throw new ConflictException(`Email ${dto.email} đã tồn tại.`);
      }
    }

    if (dto.studentIds && dto.studentIds.length > 0) {
      const existingStudents = await this.prisma.user.findMany({
        where: { id: { in: dto.studentIds } },
        select: { id: true },
      });
      if (existingStudents.length !== dto.studentIds.length) {
        throw new BadRequestException(
          'Một hoặc nhiều ID học viên liên kết không tồn tại.',
        );
      }
    }

    const parentRole = await this.prisma.role.findUnique({
      where: { code: 'parent' },
    });
    if (!parentRole) {
      throw new BadRequestException(
        'Vai trò phụ huynh (parent) chưa được cấu hình.',
      );
    }

    const tempPassword =
      dto.temporaryPassword?.trim() ||
      `Parent@${Math.floor(100000 + Math.random() * 900000)}`;
    const passwordHash = bcrypt.hashSync(tempPassword, this.saltRounds);
    const userCode = await this.generateUniqueUserCode('PH');

    const newParent = await this.prisma.$transaction(async (tx) => {
      const parent = await tx.user.create({
        data: {
          userCode,
          fullName: dto.fullName.trim(),
          phone: dto.phone.trim(),
          email: dto.email ? dto.email.trim().toLowerCase() : null,
          gender: dto.gender,
          address: dto.address?.trim(),
          passwordHash,
          status: UserStatus.ACTIVE,
          isFirstLogin: true,
          branchId: dto.branchId,
          userRoles: {
            create: {
              roleId: parentRole.id,
            },
          },
        },
        include: {
          branch: { select: { id: true, code: true, name: true } },
          userRoles: { include: { role: true } },
        },
      });

      if (dto.studentIds && dto.studentIds.length > 0) {
        await tx.parentStudent.createMany({
          data: dto.studentIds.map((studentId) => ({
            parentId: parent.id,
            studentId,
            relationship: dto.relationship?.trim() || 'Phụ huynh',
            isPrimaryContact: true,
          })),
          skipDuplicates: true,
        });
      }

      return parent;
    });

    if (newParent.email) {
      this.mailService.sendWelcomeEmail(
        newParent.email,
        newParent.fullName,
        newParent.userCode,
        tempPassword,
      );
    }

    const { passwordHash: _, userRoles, ...safeUser } = newParent;
    return {
      message: 'Cấp tài khoản phụ huynh thành công.',
      temporaryPassword: tempPassword,
      user: {
        ...safeUser,
        roles: userRoles.map((ur) => ur.role),
      },
    };
  }

  // --------------------------------------------------------------------------
  // 5. POST /users/staff — Cấp tài khoản giáo viên, nhân viên học vụ, thu ngân
  // --------------------------------------------------------------------------
  async createStaff(dto: CreateStaffDto) {
    const existingEmail = await this.prisma.user.findUnique({
      where: { email: dto.email.trim().toLowerCase() },
    });
    if (existingEmail) {
      throw new ConflictException(`Email ${dto.email} đã được sử dụng.`);
    }

    if (dto.phone) {
      const existingPhone = await this.prisma.user.findUnique({
        where: { phone: dto.phone.trim() },
      });
      if (existingPhone) {
        throw new ConflictException(
          `Số điện thoại ${dto.phone} đã được sử dụng.`,
        );
      }
    }

    const targetRole = await this.prisma.role.findUnique({
      where: { code: dto.roleCode.trim() },
    });
    if (!targetRole) {
      throw new NotFoundException(
        `Không tìm thấy vai trò có mã ${dto.roleCode}.`,
      );
    }

    if (targetRole.code === 'student' || targetRole.code === 'parent') {
      throw new BadRequestException(
        'Vui lòng sử dụng API chuyên biệt để cấp tài khoản học viên hoặc phụ huynh.',
      );
    }

    let prefix = 'NV';
    if (
      targetRole.code === 'teacher' ||
      targetRole.code === 'teaching_assistant'
    ) {
      prefix = 'GV';
    } else if (targetRole.code === 'branch_admin') {
      prefix = 'QL';
    } else if (targetRole.code === 'academic_staff') {
      prefix = 'HVU';
    } else if (targetRole.code === 'cashier') {
      prefix = 'TN';
    }

    const userCode = await this.generateUniqueUserCode(prefix);
    const tempPassword =
      dto.temporaryPassword?.trim() ||
      `Staff@${Math.floor(100000 + Math.random() * 900000)}`;
    const passwordHash = bcrypt.hashSync(tempPassword, this.saltRounds);

    const isTeacher =
      targetRole.code === 'teacher' || targetRole.code === 'teaching_assistant';

    const newStaff = await this.prisma.$transaction(async (tx) => {
      return tx.user.create({
        data: {
          userCode,
          fullName: dto.fullName.trim(),
          email: dto.email.trim().toLowerCase(),
          phone: dto.phone ? dto.phone.trim() : null,
          gender: dto.gender,
          dateOfBirth: dto.dateOfBirth ? new Date(dto.dateOfBirth) : null,
          address: dto.address?.trim(),
          passwordHash,
          status: UserStatus.ACTIVE,
          isFirstLogin: true,
          branchId: dto.branchId,
          userRoles: {
            create: {
              roleId: targetRole.id,
            },
          },
          teacherProfile: isTeacher
            ? {
                create: {
                  degrees: dto.degrees?.trim(),
                  specialties: dto.specialties?.trim(),
                  bio: dto.bio?.trim(),
                  hourlyRate:
                    dto.hourlyRate !== undefined
                      ? new Prisma.Decimal(dto.hourlyRate)
                      : undefined,
                },
              }
            : undefined,
        },
        include: {
          branch: { select: { id: true, code: true, name: true } },
          teacherProfile: true,
          userRoles: { include: { role: true } },
        },
      });
    });

    if (newStaff.email) {
      this.mailService.sendWelcomeEmail(
        newStaff.email,
        newStaff.fullName,
        newStaff.userCode,
        tempPassword,
      );
    }

    const { passwordHash: _, userRoles, ...safeUser } = newStaff;
    return {
      message: 'Cấp tài khoản nhân sự thành công.',
      temporaryPassword: tempPassword,
      user: {
        ...safeUser,
        roles: userRoles.map((ur) => ur.role),
      },
    };
  }

  // --------------------------------------------------------------------------
  // 6. PATCH /users/:id — Cập nhật thông tin cá nhân hoặc hồ sơ chuyên biệt
  // --------------------------------------------------------------------------
  async updateUser(id: string, dto: UpdateUserDto) {
    const existing = await this.prisma.user.findUnique({
      where: { id },
      include: { studentProfile: true, teacherProfile: true },
    });

    if (!existing) {
      throw new NotFoundException('Không tìm thấy người dùng này.');
    }

    if (
      dto.email &&
      dto.email.trim().toLowerCase() !== existing.email?.toLowerCase()
    ) {
      const emailDup = await this.prisma.user.findUnique({
        where: { email: dto.email.trim().toLowerCase() },
      });
      if (emailDup) {
        throw new ConflictException(`Email ${dto.email} đã được sử dụng.`);
      }
    }

    if (dto.phone && dto.phone.trim() !== existing.phone) {
      const phoneDup = await this.prisma.user.findUnique({
        where: { phone: dto.phone.trim() },
      });
      if (phoneDup) {
        throw new ConflictException(
          `Số điện thoại ${dto.phone} đã được sử dụng.`,
        );
      }
    }

    const updatedUser = await this.prisma.$transaction(async (tx) => {
      // 1. Cập nhật User
      const user = await tx.user.update({
        where: { id },
        data: {
          fullName: dto.fullName?.trim(),
          email: dto.email ? dto.email.trim().toLowerCase() : undefined,
          phone: dto.phone ? dto.phone.trim() : undefined,
          avatarUrl: dto.avatarUrl,
          gender: dto.gender,
          dateOfBirth: dto.dateOfBirth ? new Date(dto.dateOfBirth) : undefined,
          address: dto.address?.trim(),
          branchId: dto.branchId,
        },
        include: {
          branch: { select: { id: true, code: true, name: true } },
          studentProfile: true,
          teacherProfile: true,
          userRoles: { include: { role: true } },
        },
      });

      // 2. Cập nhật StudentProfile nếu có
      if (
        user.studentProfile &&
        (dto.entryLevel !== undefined ||
          dto.targetLevel !== undefined ||
          dto.schoolName !== undefined ||
          dto.notes !== undefined)
      ) {
        await tx.studentProfile.update({
          where: { userId: id },
          data: {
            entryLevel: dto.entryLevel?.trim(),
            targetLevel: dto.targetLevel?.trim(),
            schoolName: dto.schoolName?.trim(),
            notes: dto.notes?.trim(),
          },
        });
      }

      // 3. Cập nhật TeacherProfile nếu có
      if (
        user.teacherProfile &&
        (dto.degrees !== undefined ||
          dto.specialties !== undefined ||
          dto.bio !== undefined ||
          dto.hourlyRate !== undefined)
      ) {
        await tx.teacherProfile.update({
          where: { userId: id },
          data: {
            degrees: dto.degrees?.trim(),
            specialties: dto.specialties?.trim(),
            bio: dto.bio?.trim(),
            hourlyRate:
              dto.hourlyRate !== undefined
                ? new Prisma.Decimal(dto.hourlyRate)
                : undefined,
          },
        });
      }

      return user;
    });

    const refreshed = await this.findOne(id);
    return {
      message: 'Cập nhật thông tin người dùng thành công.',
      user: refreshed,
    };
  }

  // --------------------------------------------------------------------------
  // 7. PATCH /users/:id/status — Khóa hoặc mở khóa tài khoản
  // --------------------------------------------------------------------------
  async updateUserStatus(id: string, dto: UpdateUserStatusDto) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      include: { userRoles: { include: { role: true } } },
    });

    if (!user) {
      throw new NotFoundException('Không tìm thấy người dùng.');
    }

    const isSuperAdmin = user.userRoles.some(
      (ur) => ur.role.code === 'super_admin',
    );
    if (
      isSuperAdmin &&
      (dto.status === UserStatus.LOCKED || dto.status === UserStatus.INACTIVE)
    ) {
      const activeSuperAdminCount = await this.prisma.user.count({
        where: {
          status: UserStatus.ACTIVE,
          userRoles: { some: { role: { code: 'super_admin' } } },
        },
      });

      if (activeSuperAdminCount <= 1) {
        throw new BadRequestException(
          'Không thể khóa hoặc vô hiệu hóa Super Admin duy nhất đang hoạt động.',
        );
      }
    }

    const updated = await this.prisma.user.update({
      where: { id },
      data: { status: dto.status },
      select: {
        id: true,
        userCode: true,
        fullName: true,
        status: true,
        updatedAt: true,
      },
    });

    return {
      message: `Đã cập nhật trạng thái tài khoản sang ${dto.status}.`,
      user: updated,
    };
  }

  // --------------------------------------------------------------------------
  // 8. POST /users/:id/reset-password — Admin cấp lại mật khẩu tạm thời
  // --------------------------------------------------------------------------
  async adminResetPassword(id: string, dto: AdminResetPasswordDto) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) {
      throw new NotFoundException('Không tìm thấy người dùng này.');
    }

    const tempPassword =
      dto.newPassword?.trim() ||
      `Lms@${Math.floor(100000 + Math.random() * 900000)}`;
    const passwordHash = bcrypt.hashSync(tempPassword, this.saltRounds);

    await this.prisma.user.update({
      where: { id },
      data: {
        passwordHash,
        isFirstLogin: true, // Bắt buộc đổi lại mật khẩu khi đăng nhập
      },
    });

    if (user.email) {
      this.mailService.sendResetPasswordEmail(
        user.email,
        user.fullName,
        tempPassword,
      );
    }

    return {
      message: 'Cấp lại mật khẩu tạm thời thành công.',
      temporaryPassword: tempPassword,
    };
  }

  // --------------------------------------------------------------------------
  // 9. GET /users/:id/roles — Lấy danh sách vai trò
  // --------------------------------------------------------------------------
  async getUserRoles(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      include: {
        userRoles: {
          include: {
            role: true,
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException('Không tìm thấy người dùng.');
    }

    return user.userRoles.map((ur) => ur.role);
  }

  // --------------------------------------------------------------------------
  // 10. POST /users/:id/roles — Gán vai trò cho người dùng
  // --------------------------------------------------------------------------
  async assignRoles(id: string, dto: AssignRolesDto) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) {
      throw new NotFoundException('Không tìm thấy người dùng.');
    }

    const roles = await this.prisma.role.findMany({
      where: {
        code: { in: dto.roleCodes },
      },
    });

    if (roles.length !== dto.roleCodes.length) {
      const foundCodes = roles.map((r) => r.code);
      const missing = dto.roleCodes.filter((c) => !foundCodes.includes(c));
      throw new NotFoundException(
        `Không tìm thấy các vai trò: ${missing.join(', ')}`,
      );
    }

    await this.prisma.$transaction(async (tx) => {
      // Xóa roles cũ
      await tx.userRole.deleteMany({ where: { userId: id } });

      // Gán roles mới
      await tx.userRole.createMany({
        data: roles.map((r) => ({
          userId: id,
          roleId: r.id,
        })),
      });
    });

    return {
      message: 'Gán vai trò thành công.',
      roles,
    };
  }

  // --------------------------------------------------------------------------
  // 11. POST /users/import — Nhập danh sách học viên từ file Excel
  // --------------------------------------------------------------------------
  async importStudentsFromExcel(fileBuffer: Buffer, branchId?: string) {
    if (!fileBuffer || fileBuffer.length === 0) {
      throw new BadRequestException(
        'File tải lên không có nội dung hoặc rỗng.',
      );
    }

    const workbook = XLSX.read(fileBuffer, { type: 'buffer' });
    const sheetName = workbook.SheetNames[0];
    if (!sheetName) {
      throw new BadRequestException(
        'File Excel không có trang tính (sheet) nào.',
      );
    }

    const sheet = workbook.Sheets[sheetName];
    const rawRows = XLSX.utils.sheet_to_json<Record<string, any>>(sheet);

    if (rawRows.length === 0) {
      throw new BadRequestException('Trang tính không chứa dữ liệu dòng nào.');
    }

    const studentRole = await this.prisma.role.findUnique({
      where: { code: 'student' },
    });
    if (!studentRole) {
      throw new BadRequestException(
        'Vai trò học viên (student) chưa được cấu hình trong hệ thống.',
      );
    }

    const errors: Array<{ row: number; error: string; data?: any }> = [];
    const createdList: any[] = [];

    for (let i = 0; i < rawRows.length; i++) {
      const row = rawRows[i];
      const rowNumber = i + 2; // Hàng tiêu đề là hàng 1

      // Hỗ trợ linh hoạt cả tiêu đề tiếng Việt lẫn tiếng Anh
      const fullName = (
        row['Họ và tên'] ||
        row['Họ tên'] ||
        row['Full Name'] ||
        row['Name'] ||
        ''
      )
        ?.toString()
        .trim();

      const phone = (row['Số điện thoại'] || row['SĐT'] || row['Phone'] || '')
        ?.toString()
        .trim();

      const email = (row['Email'] || '')?.toString().trim().toLowerCase();

      const genderRaw = (row['Giới tính'] || row['Gender'] || '')
        ?.toString()
        .trim()
        .toLowerCase();

      const targetLevel = (
        row['Mục tiêu'] ||
        row['Target Level'] ||
        row['Khóa học'] ||
        ''
      )
        ?.toString()
        .trim();

      const entryLevel = (row['Trình độ đầu vào'] || row['Entry Level'] || '')
        ?.toString()
        .trim();

      const schoolName = (row['Trường học'] || row['School'] || '')
        ?.toString()
        .trim();

      const notes = (row['Ghi chú'] || row['Notes'] || '')?.toString().trim();

      if (!fullName) {
        errors.push({
          row: rowNumber,
          error: 'Họ và tên học viên không được để trống.',
          data: row,
        });
        continue;
      }

      // Kiểm tra trùng lặp email nếu có
      if (email) {
        const existEmail = await this.prisma.user.findUnique({
          where: { email },
        });
        if (existEmail) {
          errors.push({
            row: rowNumber,
            error: `Email ${email} đã tồn tại trong hệ thống.`,
            data: row,
          });
          continue;
        }
      }

      // Kiểm tra trùng lặp số điện thoại nếu có
      if (phone) {
        const existPhone = await this.prisma.user.findUnique({
          where: { phone },
        });
        if (existPhone) {
          errors.push({
            row: rowNumber,
            error: `Số điện thoại ${phone} đã tồn tại trong hệ thống.`,
            data: row,
          });
          continue;
        }
      }

      let gender: Gender | null = null;
      if (genderRaw === 'nam' || genderRaw === 'male') {
        gender = Gender.MALE;
      } else if (
        genderRaw === 'nữ' ||
        genderRaw === 'nu' ||
        genderRaw === 'female'
      ) {
        gender = Gender.FEMALE;
      } else if (genderRaw) {
        gender = Gender.OTHER;
      }

      try {
        const userCode = await this.generateUniqueUserCode('HV');
        const defaultPassword = `Student@${Math.floor(100000 + Math.random() * 900000)}`;
        const passwordHash = bcrypt.hashSync(defaultPassword, this.saltRounds);

        const newStudent = await this.prisma.$transaction(async (tx) => {
          return tx.user.create({
            data: {
              userCode,
              fullName,
              email: email || null,
              phone: phone || null,
              gender,
              passwordHash,
              status: UserStatus.ACTIVE,
              isFirstLogin: true,
              branchId,
              userRoles: {
                create: {
                  roleId: studentRole.id,
                },
              },
              studentProfile: {
                create: {
                  entryLevel: entryLevel || null,
                  targetLevel: targetLevel || null,
                  schoolName: schoolName || null,
                  notes: notes || null,
                },
              },
            },
            select: {
              id: true,
              userCode: true,
              fullName: true,
              email: true,
              phone: true,
            },
          });
        });

        createdList.push({
          ...newStudent,
          temporaryPassword: defaultPassword,
        });
      } catch (err: any) {
        errors.push({
          row: rowNumber,
          error: err.message || 'Lỗi khi lưu dữ liệu học viên.',
          data: row,
        });
      }
    }

    return {
      totalRows: rawRows.length,
      successCount: createdList.length,
      failureCount: errors.length,
      errors,
      createdStudents: createdList,
    };
  }
}
