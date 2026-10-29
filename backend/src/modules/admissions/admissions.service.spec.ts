import { Test, TestingModule } from '@nestjs/testing';
import { AdmissionsService } from './admissions.service.js';
import { PrismaService } from '../../database/index.js';
import { MailService } from '../mail/index.js';
import {
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  ConflictException,
} from '@nestjs/common';
import { LeadStatus, Prisma } from '@prisma/client';

describe('AdmissionsService', () => {
  let service: AdmissionsService;

  const mockLead = {
    id: 'lead-uuid-1',
    fullName: 'Nguyễn Văn An',
    phone: '0988776655',
    email: 'an.nguyen@gmail.com',
    targetCourse: 'IELTS 6.5',
    status: LeadStatus.NEW,
    branchId: 'br-1',
    notes: 'Muốn học tối',
    convertedUserId: null,
  };

  const mockPrismaService = {
    admissionLead: {
      create: vi.fn(),
      findMany: vi.fn(),
      count: vi.fn(),
      findUnique: vi.fn(),
      findUniqueOrThrow: vi.fn(),
      update: vi.fn(),
      updateMany: vi.fn(),
    },
    role: {
      findUnique: vi.fn(),
    },
    studentProfile: {
      count: vi.fn(),
    },
    user: { create: vi.fn() },
    $transaction: vi.fn(),
  };

  const mockMailService = {
    sendWelcomeEmail: vi.fn().mockResolvedValue(true),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AdmissionsService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: MailService, useValue: mockMailService },
      ],
    }).compile();

    service = module.get<AdmissionsService>(AdmissionsService);
    vi.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('createLead', () => {
    it('should create an admission lead with status NEW', async () => {
      mockPrismaService.admissionLead.create.mockResolvedValue(mockLead);

      const res = await service.createLead({
        fullName: 'Nguyễn Văn An',
        phone: '0988776655',
        email: 'an.nguyen@gmail.com',
        targetCourse: 'IELTS 6.5',
      });

      expect(res.lead.fullName).toBe('Nguyễn Văn An');
      expect(res.lead.status).toBe(LeadStatus.NEW);
    });
  });

  describe('findOne', () => {
    it('should throw NotFoundException if lead not found', async () => {
      mockPrismaService.admissionLead.findUnique.mockResolvedValue(null);

      await expect(service.findOne('invalid-id')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should return lead if found', async () => {
      mockPrismaService.admissionLead.findUnique.mockResolvedValue(mockLead);

      const res = await service.findOne('lead-uuid-1');
      expect(res.id).toBe('lead-uuid-1');
    });
  });

  it('rejects access to a lead belonging to a different branch', async () => {
    mockPrismaService.admissionLead.findUnique.mockResolvedValue({
      branchId: 'br-2',
    });
    await expect(
      service.assertBranchAccess('lead-uuid-1', 'br-1'),
    ).rejects.toThrow(ForbiddenException);
  });

  describe('convertLead', () => {
    const setupConversion = () => {
      mockPrismaService.admissionLead.findUnique.mockResolvedValue(mockLead);
      mockPrismaService.role.findUnique.mockResolvedValue({
        id: 'role-student',
      });
      mockPrismaService.studentProfile.count.mockResolvedValue(9);
      mockPrismaService.user.create.mockResolvedValue({
        id: 'student-1',
        userCode: 'HV-2026-0010',
        fullName: mockLead.fullName,
        phone: mockLead.phone,
        email: mockLead.email,
        branch: null,
        studentProfile: { id: 'profile-1' },
      });
      mockPrismaService.admissionLead.updateMany.mockResolvedValue({
        count: 1,
      });
      mockPrismaService.admissionLead.findUniqueOrThrow.mockResolvedValue({
        ...mockLead,
        convertedUserId: 'student-1',
      });
      mockPrismaService.$transaction.mockImplementation((callback) =>
        callback(mockPrismaService),
      );
    };

    it('converts one lead and guards the update in a serializable transaction', async () => {
      setupConversion();
      const result = await service.convertLead('lead-uuid-1', {});
      expect(result.student.id).toBe('student-1');
      expect(mockPrismaService.$transaction).toHaveBeenCalledWith(
        expect.any(Function),
        { isolationLevel: Prisma.TransactionIsolationLevel.Serializable },
      );
      expect(mockPrismaService.admissionLead.updateMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: {
            id: mockLead.id,
            convertedUserId: null,
            status: { not: LeadStatus.ENROLLED },
          },
        }),
      );
    });

    it('rejects a lead converted concurrently instead of reporting success', async () => {
      setupConversion();
      mockPrismaService.admissionLead.updateMany.mockResolvedValueOnce({
        count: 0,
      });
      await expect(service.convertLead('lead-uuid-1', {})).rejects.toThrow(
        ConflictException,
      );
    });

    it('does not mask account creation when welcome email fails', async () => {
      setupConversion();
      mockMailService.sendWelcomeEmail.mockRejectedValueOnce(
        new Error('SMTP offline'),
      );
      await expect(
        service.convertLead('lead-uuid-1', {}),
      ).resolves.toMatchObject({
        student: { id: 'student-1' },
      });
    });
    it('should throw BadRequestException if lead is already enrolled', async () => {
      mockPrismaService.admissionLead.findUnique.mockResolvedValue({
        ...mockLead,
        status: LeadStatus.ENROLLED,
        convertedUserId: 'user-123',
      });

      await expect(
        service.convertLead('lead-uuid-1', { entryLevel: 'A2' }),
      ).rejects.toThrow(BadRequestException);
    });
  });
});
