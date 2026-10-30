import { Test, TestingModule } from '@nestjs/testing';
import { AuthService } from './auth.service.js';
import { PrismaService } from '../../database/index.js';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { UnauthorizedException, BadRequestException } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { UserStatus } from '@prisma/client';
import { RedisService } from '../redis/index.js';
import { MailService } from '../mail/index.js';

describe('AuthService', () => {
  let authService: AuthService;

  const mockUser = {
    id: 'user-uuid-1',
    userCode: 'AD-000001',
    email: 'admin@lms-edu.vn',
    fullName: 'Admin User',
    passwordHash: bcrypt.hashSync('Admin@123456', 12),
    status: UserStatus.ACTIVE,
    isFirstLogin: false,
    userRoles: [
      {
        role: {
          code: 'super_admin',
          rolePermissions: [
            { permission: { code: 'system.manage' } },
          ],
        },
      },
    ],
    branch: { id: 'br-1', code: 'BR-Q1', name: 'Chi nhánh Quận 1' },
  };

  const mockPrismaService = {
    user: {
      findFirst: vi.fn(),
      findUnique: vi.fn(),
      update: vi.fn(),
    },
  };

  const mockJwtService = {
    signAsync: vi.fn().mockResolvedValue('mocked.jwt.token'),
    verify: vi.fn(),
  };

  const mockConfigService = {
    get: vi.fn((key: string) => {
      if (key === 'jwt.secret') return 'test-secret';
      if (key === 'jwt.refreshSecret') return 'test-refresh-secret';
      if (key === 'jwt.accessExpiration') return '15m';
      if (key === 'jwt.refreshExpiration') return '7d';
      return null;
    }),
  };

  const mockRedisService = {
    get: vi.fn(),
    set: vi.fn(),
    del: vi.fn(),
  };

  const mockMailService = {
    sendOtpEmail: vi.fn().mockResolvedValue(true),
    sendWelcomeEmail: vi.fn().mockResolvedValue(true),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: JwtService, useValue: mockJwtService },
        { provide: ConfigService, useValue: mockConfigService },
        { provide: RedisService, useValue: mockRedisService },
        { provide: MailService, useValue: mockMailService },
      ],
    }).compile();

    authService = module.get<AuthService>(AuthService);
  });

  it('should be defined', () => {
    expect(authService).toBeDefined();
  });

  describe('login', () => {
    it('should successfully log in with correct credentials', async () => {
      mockPrismaService.user.findFirst.mockResolvedValue(mockUser);
      mockPrismaService.user.update.mockResolvedValue(mockUser);

      const result = await authService.login({
        identifier: 'admin@lms-edu.vn',
        password: 'Admin@123456',
      });

      expect(result.accessToken).toBe('mocked.jwt.token');
      expect(result.user.email).toBe('admin@lms-edu.vn');
      expect(result.user.roles).toContain('super_admin');
      expect(result.requiresPasswordChange).toBe(false);
    });

    it('should throw UnauthorizedException if password does not match', async () => {
      mockPrismaService.user.findFirst.mockResolvedValue(mockUser);

      await expect(
        authService.login({
          identifier: 'admin@lms-edu.vn',
          password: 'WrongPassword@123',
        }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should flag requiresPasswordChange if user is on first login', async () => {
      const firstLoginUser = {
        ...mockUser,
        isFirstLogin: true,
        status: UserStatus.PENDING_ACTIVATION,
      };
      mockPrismaService.user.findFirst.mockResolvedValue(firstLoginUser);
      mockPrismaService.user.update.mockResolvedValue(firstLoginUser);

      const result = await authService.login({
        identifier: 'admin@lms-edu.vn',
        password: 'Admin@123456',
      });

      expect(result.requiresPasswordChange).toBe(true);
    });
  });

  describe('firstLoginSetup', () => {
    it('should throw BadRequestException if passwords do not match', async () => {
      await expect(
        authService.firstLoginSetup('user-uuid-1', {
          newPassword: 'Password@123',
          confirmPassword: 'DifferentPassword@123',
        }),
      ).rejects.toThrow(BadRequestException);
    });
  });
});
