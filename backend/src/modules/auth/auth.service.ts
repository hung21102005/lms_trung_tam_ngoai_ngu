import {
  Injectable,
  UnauthorizedException,
  BadRequestException,
  NotFoundException,
  Logger,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../../database/index.js';
import {
  UserStatus,
  ClassStatus,
  EnrollmentStatus,
  RegistrationStatus,
} from '@prisma/client';
import {
  LoginDto,
  FirstLoginSetupDto,
  ChangePasswordDto,
  RefreshTokenDto,
  ForgotPasswordDto,
  ResetPasswordDto,
} from './dto/index.js';
import { RedisService } from '../redis/index.js';
import { MailService } from '../mail/index.js';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  private readonly saltRounds = 12;

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly redisService: RedisService,
    private readonly mailService: MailService,
  ) {}

  async login(dto: LoginDto) {
    const identifier = dto.identifier.trim();

    // Tìm người dùng theo email, phone hoặc userCode
    const user = await this.prisma.user.findFirst({
      where: {
        OR: [
          { email: identifier },
          { phone: identifier },
          { userCode: identifier },
        ],
      },
      include: {
        userRoles: {
          include: {
            role: {
              include: {
                rolePermissions: {
                  include: {
                    permission: true,
                  },
                },
              },
            },
          },
        },
        branch: true,
      },
    });

    if (!user) {
      throw new UnauthorizedException('Thông tin đăng nhập không chính xác.');
    }

    // Kiểm tra mật khẩu
    const isPasswordValid = bcrypt.compareSync(dto.password, user.passwordHash);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Thông tin đăng nhập không chính xác.');
    }

    // Kiểm tra trạng thái tài khoản
    if (user.status === UserStatus.LOCKED) {
      throw new UnauthorizedException('Tài khoản của bạn đã bị khóa. Vui lòng liên hệ quản trị viên.');
    }

    if (user.status === UserStatus.INACTIVE) {
      throw new UnauthorizedException('Tài khoản đang tạm ngưng hoạt động.');
    }

    // Cập nhật thời điểm đăng nhập gần nhất
    await this.prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() },
    });

    // Gom danh sách roles và permissions
    const roles = user.userRoles.map((ur) => ur.role.code);
    const permissionSet = new Set<string>();
    for (const ur of user.userRoles) {
      for (const rp of ur.role.rolePermissions) {
        permissionSet.add(rp.permission.code);
      }
    }

    const tokens = await this.generateTokens(user.id, user.userCode, user.email ?? undefined);

    const requiresPasswordChange = user.isFirstLogin || user.status === UserStatus.PENDING_ACTIVATION;

    return {
      requiresPasswordChange,
      message: requiresPasswordChange
        ? 'Đăng nhập lần đầu thành công. Bạn bắt buộc phải đổi mật khẩu để kích hoạt tài khoản.'
        : 'Đăng nhập thành công.',
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      user: {
        id: user.id,
        userCode: user.userCode,
        fullName: user.fullName,
        email: user.email,
        phone: user.phone,
        avatarUrl: user.avatarUrl,
        status: user.status,
        isFirstLogin: user.isFirstLogin,
        branch: user.branch ? { id: user.branch.id, code: user.branch.code, name: user.branch.name } : null,
        roles,
        permissions: Array.from(permissionSet),
      },
    };
  }

  async firstLoginSetup(userId: string, dto: FirstLoginSetupDto) {
    if (dto.newPassword !== dto.confirmPassword) {
      throw new BadRequestException('Mật khẩu mới và mật khẩu xác nhận không khớp.');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('Không tìm thấy tài khoản người dùng.');
    }

    if (!user.isFirstLogin && user.status === UserStatus.ACTIVE) {
      throw new BadRequestException('Tài khoản này đã được kích hoạt trước đó.');
    }

    // Băm mật khẩu mới với salt rounds = 12
    const newPasswordHash = bcrypt.hashSync(dto.newPassword, this.saltRounds);

    const updatedUser = await this.prisma.user.update({
      where: { id: userId },
      data: {
        passwordHash: newPasswordHash,
        isFirstLogin: false,
        status: UserStatus.ACTIVE,
      },
      include: {
        branch: true,
        studentProfile: true,
        teacherProfile: true,
        userRoles: {
          include: {
            role: {
              include: {
                rolePermissions: {
                  include: {
                    permission: true,
                  },
                },
              },
            },
          },
        },
      },
    });

    const roles = updatedUser.userRoles.map((ur) => ur.role.code);
    const permissionSet = new Set<string>();
    for (const ur of updatedUser.userRoles) {
      for (const rp of ur.role.rolePermissions) {
        permissionSet.add(rp.permission.code);
      }
    }
    const permissions = Array.from(permissionSet);

    const tokens = await this.generateTokens(
      updatedUser.id,
      updatedUser.userCode,
      updatedUser.email ?? undefined,
    );

    return {
      message: 'Kích hoạt tài khoản và thiết lập mật khẩu thành công.',
      requiresPasswordChange: false,
      ...tokens,
      user: {
        id: updatedUser.id,
        userCode: updatedUser.userCode,
        fullName: updatedUser.fullName,
        email: updatedUser.email,
        phone: updatedUser.phone,
        avatarUrl: updatedUser.avatarUrl,
        gender: updatedUser.gender,
        dateOfBirth: updatedUser.dateOfBirth,
        address: updatedUser.address,
        status: updatedUser.status,
        isFirstLogin: updatedUser.isFirstLogin,
        branch: updatedUser.branch
          ? { id: updatedUser.branch.id, code: updatedUser.branch.code, name: updatedUser.branch.name }
          : null,
        studentProfile: updatedUser.studentProfile,
        teacherProfile: updatedUser.teacherProfile,
        roles,
        permissions,
      },
    };
  }

  async changePassword(userId: string, dto: ChangePasswordDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('Không tìm thấy tài khoản.');
    }

    const isMatch = bcrypt.compareSync(dto.oldPassword, user.passwordHash);
    if (!isMatch) {
      throw new BadRequestException('Mật khẩu hiện tại không chính xác.');
    }

    const newPasswordHash = bcrypt.hashSync(dto.newPassword, this.saltRounds);

    await this.prisma.user.update({
      where: { id: userId },
      data: {
        passwordHash: newPasswordHash,
        isFirstLogin: false,
      },
    });

    return {
      message: 'Đổi mật khẩu thành công.',
    };
  }

  async refreshTokens(dto: RefreshTokenDto) {
    const refreshSecret = this.configService.get<string>('jwt.refreshSecret') || 'lms_super_secret_refresh_key_change_in_production_2026';

    try {
      const payload = this.jwtService.verify(dto.refreshToken, {
        secret: refreshSecret,
      });

      const user = await this.prisma.user.findUnique({
        where: { id: payload.sub },
      });

      if (!user || user.status === UserStatus.LOCKED || user.status === UserStatus.INACTIVE) {
        throw new UnauthorizedException('Phiên đăng nhập không hợp lệ hoặc đã bị khóa.');
      }

      return await this.generateTokens(user.id, user.userCode, user.email ?? undefined);
    } catch {
      throw new UnauthorizedException('Refresh token không hợp lệ hoặc đã hết hạn.');
    }
  }

  async getMe(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        branch: true,
        studentProfile: true,
        teacherProfile: true,
        userRoles: {
          include: {
            role: {
              include: {
                rolePermissions: {
                  include: {
                    permission: true,
                  },
                },
              },
            },
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException('Không tìm thấy thông tin người dùng.');
    }

    const roles = user.userRoles.map((ur) => ur.role.code);
    const permissionSet = new Set<string>();
    for (const ur of user.userRoles) {
      for (const rp of ur.role.rolePermissions) {
        permissionSet.add(rp.permission.code);
      }
    }

    const isSuperAdmin = roles.includes('super_admin');
    const isAdminOrStaff =
      isSuperAdmin ||
      roles.includes('branch_admin') ||
      roles.includes('academic_staff') ||
      roles.includes('cashier');
    const isTeacher =
      roles.includes('teacher') || roles.includes('teaching_assistant');
    const isParent = roles.includes('parent');
    const isStudent = roles.includes('student');

    let currentClass: string | null = null;
    const linkedStats: Record<string, any> = {};

    if (isTeacher) {
      const assignedClasses = await this.prisma.class.findMany({
        where: {
          OR: [{ mainTeacherId: user.id }, { assistantTeacherId: user.id }],
          status: { not: ClassStatus.CANCELLED },
        },
        select: {
          id: true,
          code: true,
          name: true,
          status: true,
          students: {
            where: { status: EnrollmentStatus.ENROLLED },
            select: { studentId: true },
          },
        },
      });

      const activeClasses = assignedClasses.filter(
        (c) =>
          c.status === ClassStatus.PLANNING ||
          c.status === ClassStatus.OPEN_FOR_ENROLLMENT ||
          c.status === ClassStatus.IN_PROGRESS,
      );
      const uniqueStudentIds = new Set<string>();
      for (const c of assignedClasses) {
        for (const s of c.students) {
          uniqueStudentIds.add(s.studentId);
        }
      }

      linkedStats.activeClassesCount = activeClasses.length;
      linkedStats.totalClassesCount = assignedClasses.length;
      linkedStats.totalStudentsCount = uniqueStudentIds.size;
      if (activeClasses.length > 0) {
        currentClass = activeClasses[0].name;
      }
    }

    if (isStudent) {
      const [enrollments, pendingRegsCount] = await Promise.all([
        this.prisma.classStudent.findMany({
          where: { studentId: user.id },
          include: {
            class: {
              select: { id: true, code: true, name: true, status: true },
            },
          },
          orderBy: { joinedAt: 'desc' },
        }),
        this.prisma.classRegistration.count({
          where: {
            studentId: user.id,
            status: {
              in: [RegistrationStatus.PENDING, RegistrationStatus.CONTACTED],
            },
          },
        }),
      ]);

      const activeEnrollments = enrollments.filter(
        (e) =>
          e.status === EnrollmentStatus.ENROLLED &&
          e.class.status !== ClassStatus.CANCELLED &&
          e.class.status !== ClassStatus.COMPLETED,
      );
      const completedEnrollments = enrollments.filter(
        (e) =>
          e.status === EnrollmentStatus.ENROLLED &&
          e.class.status === ClassStatus.COMPLETED,
      );

      linkedStats.activeClassesCount = activeEnrollments.length;
      linkedStats.completedClassesCount = completedEnrollments.length;
      linkedStats.pendingRegistrationsCount = pendingRegsCount;
      if (activeEnrollments.length > 0) {
        currentClass = activeEnrollments[0].class.name;
      }
    }

    if (isParent) {
      const parentRelations = await this.prisma.parentStudent.findMany({
        where: { parentId: user.id },
        include: {
          student: {
            select: {
              id: true,
              userCode: true,
              fullName: true,
              classEnrollments: {
                where: { status: EnrollmentStatus.ENROLLED },
                select: { id: true },
              },
            },
          },
        },
      });
      const childrenActiveEnrollments = parentRelations.reduce(
        (sum, rel) => sum + rel.student.classEnrollments.length,
        0,
      );
      linkedStats.linkedChildrenCount = parentRelations.length;
      linkedStats.childrenActiveClassesCount = childrenActiveEnrollments;
      linkedStats.linkedChildren = parentRelations.map((rel) => ({
        id: rel.student.id,
        userCode: rel.student.userCode,
        fullName: rel.student.fullName,
        relationship: rel.relationship,
      }));
    }

    if (isAdminOrStaff) {
      const branchScopeWhere =
        !isSuperAdmin && user.branchId ? { branchId: user.branchId } : {};
      const [usersCount, branchesCount, classesCount, coursesCount] =
        await Promise.all([
          this.prisma.user.count({ where: branchScopeWhere }),
          this.prisma.branch.count({
            where:
              !isSuperAdmin && user.branchId
                ? { id: user.branchId, isActive: true }
                : { isActive: true },
          }),
          this.prisma.class.count({
            where: {
              ...branchScopeWhere,
              status: { not: ClassStatus.CANCELLED },
            },
          }),
          this.prisma.course.count({ where: { isActive: true } }),
        ]);

      linkedStats.scopedUsersCount = usersCount;
      linkedStats.scopedBranchesCount = branchesCount;
      linkedStats.scopedClassesCount = classesCount;
      linkedStats.scopedCoursesCount = coursesCount;
    }

    return {
      id: user.id,
      userCode: user.userCode,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      avatarUrl: user.avatarUrl,
      gender: user.gender,
      dateOfBirth: user.dateOfBirth,
      address: user.address,
      status: user.status,
      isFirstLogin: user.isFirstLogin,
      branch: user.branch ? { id: user.branch.id, code: user.branch.code, name: user.branch.name } : null,
      studentProfile: user.studentProfile,
      teacherProfile: user.teacherProfile,
      currentClass,
      linkedStats,
      roles,
      permissions: Array.from(permissionSet),
    };
  }

  async forgotPassword(dto: ForgotPasswordDto) {
    const email = dto.email.trim().toLowerCase();
    const user = await this.prisma.user.findFirst({
      where: { email },
    });

    if (!user || user.status === UserStatus.LOCKED || user.status === UserStatus.INACTIVE) {
      return {
        message: 'Nếu địa chỉ email tồn tại trên hệ thống, mã xác thực OTP đã được gửi thành công.',
      };
    }

    const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
    const redisKey = `otp:pwd_reset:${email}`;
    await this.redisService.set(redisKey, otpCode, 300);

    await this.mailService.sendOtpEmail(user.email ?? email, user.fullName, otpCode);

    return {
      message: 'Mã xác thực OTP đã được gửi đến email của bạn. Vui lòng kiểm tra hòm thư.',
    };
  }

  async resetPassword(dto: ResetPasswordDto) {
    if (dto.newPassword !== dto.confirmPassword) {
      throw new BadRequestException('Mật khẩu mới và mật khẩu xác nhận không khớp.');
    }

    const email = dto.email.trim().toLowerCase();
    const redisKey = `otp:pwd_reset:${email}`;
    const storedOtp = await this.redisService.get(redisKey);

    if (!storedOtp || storedOtp !== dto.otpCode.trim()) {
      throw new BadRequestException('Mã xác thực OTP không chính xác hoặc đã hết hạn.');
    }

    const user = await this.prisma.user.findFirst({
      where: { email },
    });

    if (!user) {
      throw new NotFoundException('Không tìm thấy tài khoản người dùng.');
    }

    const newPasswordHash = bcrypt.hashSync(dto.newPassword, this.saltRounds);

    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        passwordHash: newPasswordHash,
        isFirstLogin: false,
        status: UserStatus.ACTIVE,
      },
    });

    await this.redisService.del(redisKey);

    return {
      message: 'Đặt lại mật khẩu thành công. Bạn có thể đăng nhập bằng mật khẩu mới.',
    };
  }

  private async generateTokens(userId: string, userCode: string, email?: string) {
    const payload = { sub: userId, userCode, email };

    const accessSecret = this.configService.get<string>('jwt.secret') || 'lms_super_secret_access_key_change_in_production_2026';
    const refreshSecret = this.configService.get<string>('jwt.refreshSecret') || 'lms_super_secret_refresh_key_change_in_production_2026';
    const accessExp = this.configService.get<string>('jwt.accessExpiration') || '15m';
    const refreshExp = this.configService.get<string>('jwt.refreshExpiration') || '7d';

    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(payload, {
        secret: accessSecret,
        expiresIn: accessExp,
      } as any),
      this.jwtService.signAsync(payload, {
        secret: refreshSecret,
        expiresIn: refreshExp,
      } as any),
    ]);

    return {
      accessToken,
      refreshToken,
      tokenType: 'Bearer',
      expiresIn: accessExp,
    };
  }
}
