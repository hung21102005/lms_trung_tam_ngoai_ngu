import { Test, TestingModule } from '@nestjs/testing';
import { UsersService } from './users.service.js';
import { PrismaService } from '../../database/index.js';
import { MailService } from '../mail/index.js';
import {
  ConflictException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { UserStatus } from '@prisma/client';

describe('UsersService', () => {
  let service: UsersService;

  const mockRoleStudent = {
    id: 'role-student-id',
    code: 'student',
    name: 'Học viên',
  };
  const mockRoleSuperAdmin = {
    id: 'role-sa-id',
    code: 'super_admin',
    name: 'Super Admin',
  };

  const mockPrismaService = {
    user: {
      findUnique: vi.fn(),
      findMany: vi.fn(),
      count: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
    },
    branch: {
      findUnique: vi.fn(),
    },
    role: {
      findUnique: vi.fn(),
      findMany: vi.fn(),
    },
    userRole: {
      deleteMany: vi.fn(),
      createMany: vi.fn(),
    },
    parentStudent: {
      createMany: vi.fn(),
    },
    studentProfile: {
      update: vi.fn(),
    },
    teacherProfile: {
      update: vi.fn(),
    },
    $transaction: vi.fn((callback) => callback(mockPrismaService)),
  };

  const mockMailService = {
    sendWelcomeEmail: vi.fn(),
    sendResetPasswordEmail: vi.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UsersService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: MailService, useValue: mockMailService },
      ],
    }).compile();

    service = module.get<UsersService>(UsersService);
    vi.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('assertBranchAccess', () => {
    it('denies a branch admin access to another branch', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue({
        branchId: 'branch-b',
        userRoles: [{ role: { code: 'student' } }],
      });
      await expect(
        service.assertBranchAccess(
          { roles: ['branch_admin'], branchId: 'branch-a' },
          'user-b',
        ),
      ).rejects.toThrow(ForbiddenException);
    });

    it('denies a branch admin access to a super admin in the same branch', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue({
        branchId: 'branch-a',
        userRoles: [{ role: { code: 'super_admin' } }],
      });
      await expect(
        service.assertBranchAccess(
          { roles: ['branch_admin'], branchId: 'branch-a' },
          'super-admin',
        ),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  it('returns only minimal active teacher lookup fields for a branch', async () => {
    mockPrismaService.user.findMany.mockResolvedValue([
      { id: 'teacher-1', userCode: 'GV-0001', fullName: 'Nguyễn Văn Dũng' },
    ]);
    const teachers = await service.findTeacherOptions('branch-a');
    expect(teachers).toHaveLength(1);
    expect(mockPrismaService.user.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          branchId: 'branch-a',
          status: UserStatus.ACTIVE,
        }),
        select: { id: true, userCode: true, fullName: true },
      }),
    );
  });

  describe('createStudent', () => {
    it('should throw ConflictException if email is already taken', async () => {
      mockPrismaService.user.findUnique.mockResolvedValueOnce({
        id: 'existing-id',
        email: 'test@gmail.com',
      });

      await expect(
        service.createStudent({
          fullName: 'Nguyễn Văn A',
          email: 'test@gmail.com',
        }),
      ).rejects.toThrow(ConflictException);
    });

    it('should create student and return temporary password', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue(null);
      mockPrismaService.user.count.mockResolvedValue(0);
      mockPrismaService.role.findUnique.mockResolvedValue(mockRoleStudent);

      const createdUser = {
        id: 'new-user-id',
        userCode: 'HV-2026-0001',
        fullName: 'Nguyễn Văn A',
        email: 'test@gmail.com',
        phone: null,
        passwordHash: 'hashed',
        status: UserStatus.ACTIVE,
        isFirstLogin: true,
        branch: null,
        studentProfile: { entryLevel: 'A1', targetLevel: 'B2' },
        userRoles: [{ role: mockRoleStudent }],
      };

      mockPrismaService.user.create.mockResolvedValue(createdUser);

      const result = await service.createStudent({
        fullName: 'Nguyễn Văn A',
        email: 'test@gmail.com',
        entryLevel: 'A1',
        targetLevel: 'B2',
      });

      expect(result.message).toContain('Cấp tài khoản học viên thành công');
      expect(result.temporaryPassword).toBeDefined();
      expect(result.user.fullName).toBe('Nguyễn Văn A');
      expect(mockMailService.sendWelcomeEmail).toHaveBeenCalled();
    });
  });

  describe('updateUserStatus', () => {
    it('should throw BadRequestException if locking the only active super admin', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue({
        id: 'sa-id',
        userRoles: [{ role: mockRoleSuperAdmin }],
      });
      mockPrismaService.user.count.mockResolvedValue(1);

      await expect(
        service.updateUserStatus('sa-id', { status: UserStatus.LOCKED }),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('adminResetPassword', () => {
    it('should reset password, mark isFirstLogin as true, and send email', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue({
        id: 'user-id',
        email: 'student@edu.vn',
        fullName: 'Lê Văn B',
      });
      mockPrismaService.user.update.mockResolvedValue({ id: 'user-id' });

      const result = await service.adminResetPassword('user-id', {
        newPassword: 'NewPassword@123',
      });

      expect(result.temporaryPassword).toBe('NewPassword@123');
      expect(mockPrismaService.user.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ isFirstLogin: true }),
        }),
      );
      expect(mockMailService.sendResetPasswordEmail).toHaveBeenCalledWith(
        'student@edu.vn',
        'Lê Văn B',
        'NewPassword@123',
      );
    });
  });
});
