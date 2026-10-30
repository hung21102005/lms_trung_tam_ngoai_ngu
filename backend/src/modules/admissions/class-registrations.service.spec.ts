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
    admissionLead: {
      create: vi.fn().mockResolvedValue({ id: 'lead-1' }),
      update: vi.fn().mockResolvedValue({ id: 'lead-1' }),
      updateMany: vi.fn().mockResolvedValue({ count: 1 }),
    },
    classRegistration: {
      create: vi.fn().mockResolvedValue({ id: 'request-1' }),
      findUnique: vi.fn().mockResolvedValue(null),
      updateMany: vi.fn().mockResolvedValue({ count: 1 }),
    },
    classStudent: {
      findUnique: vi.fn().mockResolvedValue(null),
      count: vi.fn().mockResolvedValue(0),
      create: vi.fn().mockResolvedValue({ id: 'enroll-1' }),
      update: vi.fn().mockResolvedValue({ id: 'enroll-1' }),
    },
    invoice: {
      findFirst: vi.fn().mockResolvedValue(null),
      create: vi.fn().mockResolvedValue({ id: 'invoice-1' }),
    },
    user: {
      findUnique: vi.fn().mockResolvedValue({
        id: 'student-1',
        phone: '0988776655',
        status: 'ACTIVE',
        studentProfile: { id: 'profile-1' },
        userRoles: [{ role: { code: 'student' } }],
      }),
    },
  };
  const prisma = {
    classRegistration: {
      findUnique: vi.fn().mockResolvedValue(null),
      findFirst: vi.fn().mockResolvedValue(null),
      findMany: vi.fn().mockResolvedValue([]),
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

  it('shows a converted guest request in the new student account', async () => {
    const { service, prisma } = setup();
    await service.myRegistrations('student-1');
    expect(prisma.classRegistration.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          OR: [
            { studentId: 'student-1' },
            { lead: { is: { convertedUserId: 'student-1' } } },
          ],
        },
      }),
    );
  });

  it('reuses the guest request after its Lead becomes a student', async () => {
    const { service, prisma } = setup();
    prisma.classRegistration.findFirst.mockResolvedValueOnce({
      id: 'guest-request',
      classId: 'class-1',
      status: 'PENDING',
    });
    await expect(
      service.createStudent(
        { classId: 'class-1' },
        { id: 'student-1', roles: ['student'] },
      ),
    ).resolves.toMatchObject({ id: 'guest-request' });
    expect(prisma.classRegistration.upsert).not.toHaveBeenCalled();
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

  it('reviews a branch request and synchronizes its CRM lead', async () => {
    const { service, tx } = setup();
    tx.classRegistration.findUnique.mockResolvedValueOnce({
      id: 'request-1',
      status: 'PENDING',
      notes: null,
      leadId: 'lead-1',
      class: { branchId: 'branch-1' },
    });
    const result = await service.review(
      'request-1',
      { status: 'CONTACTED' as any },
      { roles: ['academic_staff'], branchId: 'branch-1' },
    );
    expect(result.status).toBe('CONTACTED');
    expect(tx.admissionLead.updateMany).toHaveBeenCalledWith({
      where: {
        id: 'lead-1',
        convertedUserId: null,
        status: { not: 'ENROLLED' },
      },
      data: { status: 'CONTACTED' },
    });
  });

  it('rejects staff review outside their branch', async () => {
    const { service, tx } = setup();
    tx.classRegistration.findUnique.mockResolvedValueOnce({
      id: 'request-1',
      status: 'PENDING',
      notes: null,
      leadId: null,
      class: { branchId: 'branch-2' },
    });
    await expect(
      service.review(
        'request-1',
        { status: 'REJECTED' as any },
        { roles: ['academic_staff'], branchId: 'branch-1' },
      ),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(tx.classRegistration.updateMany).not.toHaveBeenCalled();
  });

  it('approves enrollment and invoice in one serializable transaction', async () => {
    const { service, tx, prisma } = setup();
    tx.classRegistration.findUnique.mockResolvedValueOnce({
      id: 'request-1',
      classId: 'class-1',
      status: 'PENDING',
      studentId: 'student-1',
      phone: '0988776655',
      leadId: null,
      lead: null,
      class: {
        id: 'class-1',
        branchId: 'branch-1',
        status: 'OPEN_FOR_ENROLLMENT',
        maxCapacity: 20,
        tuitionFee: 100,
        name: 'English A1',
        startDate: new Date('2026-11-01'),
      },
    });
    const result = await service.approve(
      'request-1',
      {},
      { id: 'staff-1', roles: ['academic_staff'], branchId: 'branch-1' },
    );
    expect(result.status).toBe('APPROVED');
    expect(tx.classStudent.create).toHaveBeenCalledOnce();
    expect(tx.invoice.create).toHaveBeenCalledOnce();
    expect(tx.classRegistration.updateMany).toHaveBeenCalledOnce();
    expect(prisma.$transaction).toHaveBeenCalledWith(expect.any(Function), {
      isolationLevel: 'Serializable',
    });
  });

  it('never approves a full class or an unverified guest', async () => {
    const { service, tx } = setup();
    const request = {
      id: 'request-1',
      classId: 'class-1',
      status: 'PENDING',
      studentId: 'student-1',
      phone: '0988776655',
      leadId: null,
      lead: null,
      class: {
        id: 'class-1',
        branchId: 'branch-1',
        status: 'OPEN_FOR_ENROLLMENT',
        maxCapacity: 20,
        tuitionFee: 100,
        name: 'English A1',
        startDate: new Date('2026-11-01'),
      },
    };
    tx.classRegistration.findUnique.mockResolvedValue(request);
    tx.classStudent.count.mockResolvedValueOnce(20);
    await expect(
      service.approve(
        'request-1',
        {},
        { id: 'staff-1', roles: ['academic_staff'], branchId: 'branch-1' },
      ),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(tx.classStudent.create).not.toHaveBeenCalled();
    tx.classRegistration.findUnique.mockResolvedValueOnce({
      ...request,
      studentId: null,
      leadId: 'lead-1',
      lead: { convertedUserId: null },
    });
    await expect(
      service.approve(
        'request-1',
        {},
        { id: 'staff-1', roles: ['academic_staff'], branchId: 'branch-1' },
      ),
    ).rejects.toBeInstanceOf(BadRequestException);
  });
});
