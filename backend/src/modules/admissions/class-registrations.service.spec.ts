import { describe, expect, it, vi } from 'vitest';
import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
} from '@nestjs/common';
import { ClassRegistrationsService } from './class-registrations.service.js';
import { PrismaService } from '../../database/prisma.service.js';
import { ClassesService } from '../classes/classes.service.js';

const offering = {
  id: 'class-1',
  remainingSeats: 2,
  course: { title: 'English A1' },
  branch: { id: 'branch-1' },
};

function setup() {
  const tx = {
    admissionLead: { create: vi.fn().mockResolvedValue({ id: 'lead-1' }) },
    classRegistration: {
      create: vi.fn().mockResolvedValue({ id: 'request-1' }),
    },
  };
  const prisma = {
    classRegistration: {
      findUnique: vi.fn().mockResolvedValue(null),
      upsert: vi.fn().mockResolvedValue({ id: 'request-1', status: 'PENDING' }),
    },
    classStudent: { findUnique: vi.fn().mockResolvedValue(null) },
    user: {
      findUnique: vi.fn().mockResolvedValue({
        id: 'student-1',
        fullName: 'Nguyễn An',
        phone: '0988776655',
        email: null,
        status: 'ACTIVE',
        studentProfile: { id: 'profile-1' },
      }),
    },
    $transaction: vi.fn(
      async (callback: (value: typeof tx) => Promise<unknown>) => callback(tx),
    ),
  };
  const classes = { findPublicOffering: vi.fn().mockResolvedValue(offering) };
  const service = new ClassRegistrationsService(
    prisma as unknown as PrismaService,
    classes as unknown as ClassesService,
  );
  return { service, prisma, classes, tx };
}

describe('ClassRegistrationsService', () => {
  it('creates a CRM lead and pending guest request atomically', async () => {
    const { service, prisma, tx } = setup();
    const result = await service.createGuest({
      classId: 'class-1',
      fullName: ' Nguyễn An ',
      phone: '+84 988 776 655',
      email: 'AN@example.com',
    });
    expect(result.message).toContain('Đã tiếp nhận');
    expect(prisma.$transaction).toHaveBeenCalledOnce();
    expect(tx.admissionLead.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        fullName: 'Nguyễn An',
        phone: '0988776655',
        email: 'an@example.com',
        targetCourse: 'English A1',
        branchId: 'branch-1',
      }),
    });
    expect(tx.classRegistration.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        applicantKey: 'phone:0988776655',
        leadId: 'lead-1',
        classId: 'class-1',
      }),
    });
  });

  it('does not duplicate an existing guest request or lead', async () => {
    const { service, prisma } = setup();
    prisma.classRegistration.findUnique.mockResolvedValueOnce({ id: 'old' });
    await service.createGuest({
      classId: 'class-1',
      fullName: 'Nguyễn An',
      phone: '0988776655',
    });
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it('rejects full offerings and malformed phone numbers', async () => {
    const { service, classes } = setup();
    classes.findPublicOffering.mockResolvedValueOnce({
      ...offering,
      remainingSeats: 0,
    });
    await expect(
      service.createGuest({
        classId: 'class-1',
        fullName: 'An',
        phone: '0988776655',
      }),
    ).rejects.toBeInstanceOf(ConflictException);
    await expect(
      service.createGuest({ classId: 'class-1', fullName: 'An', phone: 'abc' }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('uses authenticated student identity without trusting input fields', async () => {
    const { service, prisma } = setup();
    await service.createStudent(
      { classId: 'class-1', notes: 'Lớp tối' },
      { id: 'student-1', roles: ['student'] },
    );
    expect(prisma.classRegistration.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        create: expect.objectContaining({
          applicantKey: 'user:student-1',
          studentId: 'student-1',
          fullName: 'Nguyễn An',
        }),
      }),
    );
  });

  it('rejects non-students and already enrolled students', async () => {
    const { service, prisma } = setup();
    await expect(
      service.createStudent(
        { classId: 'class-1' },
        { id: 'admin-1', roles: ['super_admin'] },
      ),
    ).rejects.toBeInstanceOf(ForbiddenException);
    prisma.classStudent.findUnique.mockResolvedValueOnce({
      status: 'ENROLLED',
    });
    await expect(
      service.createStudent(
        { classId: 'class-1' },
        { id: 'student-1', roles: ['student'] },
      ),
    ).rejects.toBeInstanceOf(ConflictException);
  });
});
