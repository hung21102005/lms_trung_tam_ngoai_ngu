import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { LeadSource, Prisma, UserStatus } from '@prisma/client';
import { PrismaService } from '../../database/prisma.service.js';
import { ClassesService } from '../classes/classes.service.js';
import {
  CreateGuestRegistrationDto,
  CreateStudentRegistrationDto,
} from './dto/create-class-registration.dto.js';

const accepted = {
  message: 'Đã tiếp nhận yêu cầu đăng ký lớp. Học vụ sẽ liên hệ để xác nhận.',
};

@Injectable()
export class ClassRegistrationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly classesService: ClassesService,
  ) {}

  private async assertOffering(classId: string) {
    const offering = await this.classesService.findPublicOffering(classId);
    if (offering.remainingSeats < 1) {
      throw new ConflictException('Lớp hiện đã đủ sĩ số');
    }
    return offering;
  }

  private normalizePhone(phone: string) {
    const digits = phone.replace(/\D/g, '');
    return digits.startsWith('84') ? `0${digits.slice(2)}` : digits;
  }

  async createGuest(dto: CreateGuestRegistrationDto) {
    const offering = await this.assertOffering(dto.classId);
    const phone = this.normalizePhone(dto.phone);
    if (!/^0\d{9,10}$/.test(phone)) {
      throw new BadRequestException('Số điện thoại không hợp lệ');
    }
    const applicantKey = `phone:${phone}`;
    const existing = await this.prisma.classRegistration.findUnique({
      where: { classId_applicantKey: { classId: dto.classId, applicantKey } },
    });
    if (existing) return accepted;
    try {
      await this.prisma.$transaction(async (tx) => {
        const lead = await tx.admissionLead.create({
          data: {
            fullName: dto.fullName.trim(),
            phone,
            email: dto.email?.trim().toLowerCase(),
            targetCourse: offering.course.title,
            source: LeadSource.WEBSITE,
            branchId: offering.branch.id,
            notes: dto.notes?.trim(),
          },
        });
        await tx.classRegistration.create({
          data: {
            classId: dto.classId,
            applicantKey,
            fullName: dto.fullName.trim(),
            phone,
            email: dto.email?.trim().toLowerCase(),
            notes: dto.notes?.trim(),
            leadId: lead.id,
          },
        });
      });
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        return accepted;
      }
      throw error;
    }
    return accepted;
  }

  async createStudent(
    dto: CreateStudentRegistrationDto,
    actor: { id: string; roles: string[] },
  ) {
    if (!actor.roles.includes('student')) {
      throw new ForbiddenException(
        'Chỉ học viên được đăng ký bằng tài khoản này',
      );
    }
    await this.assertOffering(dto.classId);
    const user = await this.prisma.user.findUnique({
      where: { id: actor.id },
      select: {
        id: true,
        fullName: true,
        phone: true,
        email: true,
        status: true,
        studentProfile: { select: { id: true } },
      },
    });
    if (!user || user.status !== UserStatus.ACTIVE || !user.studentProfile) {
      throw new ForbiddenException('Tài khoản học viên không hoạt động');
    }
    if (!user.phone)
      throw new BadRequestException(
        'Vui lòng cập nhật số điện thoại trước khi đăng ký',
      );
    const enrolled = await this.prisma.classStudent.findUnique({
      where: {
        classId_studentId: { classId: dto.classId, studentId: actor.id },
      },
    });
    if (enrolled?.status === 'ENROLLED') {
      throw new ConflictException('Bạn đã là học viên của lớp này');
    }
    const applicantKey = `user:${actor.id}`;
    try {
      return await this.prisma.classRegistration.upsert({
        where: { classId_applicantKey: { classId: dto.classId, applicantKey } },
        update: {},
        create: {
          classId: dto.classId,
          applicantKey,
          studentId: actor.id,
          fullName: user.fullName,
          phone: user.phone,
          email: user.email,
          notes: dto.notes?.trim(),
        },
        select: { id: true, classId: true, status: true, createdAt: true },
      });
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        return this.prisma.classRegistration.findUniqueOrThrow({
          where: {
            classId_applicantKey: { classId: dto.classId, applicantKey },
          },
          select: { id: true, classId: true, status: true, createdAt: true },
        });
      }
      throw error;
    }
  }

  myRegistrations(studentId: string) {
    return this.prisma.classRegistration.findMany({
      where: { studentId },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        status: true,
        createdAt: true,
        class: {
          select: {
            id: true,
            name: true,
            startDate: true,
            course: { select: { title: true } },
          },
        },
      },
    });
  }

  listForStaff(
    actor: { roles: string[]; branchId?: string | null },
    classId?: string,
  ) {
    const superAdmin = actor.roles.includes('super_admin');
    if (!superAdmin && !actor.branchId)
      throw new ForbiddenException('Tài khoản không có chi nhánh');
    return this.prisma.classRegistration.findMany({
      where: {
        ...(classId ? { classId } : {}),
        ...(!superAdmin ? { class: { branchId: actor.branchId! } } : {}),
      },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        classId: true,
        fullName: true,
        phone: true,
        email: true,
        status: true,
        studentId: true,
        leadId: true,
        createdAt: true,
        class: { select: { name: true, code: true, branchId: true } },
      },
    });
  }
}
