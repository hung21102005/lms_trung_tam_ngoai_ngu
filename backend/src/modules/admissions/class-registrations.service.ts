import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import {
  ClassStatus,
  EnrollmentStatus,
  InvoiceStatus,
  LeadSource,
  LeadStatus,
  Prisma,
  RegistrationStatus,
  UserStatus,
} from '@prisma/client';
import { PrismaService } from '../../database/prisma.service.js';
import { ClassesService } from '../classes/classes.service.js';
import {
  CreateGuestRegistrationDto,
  CreateStudentRegistrationDto,
} from './dto/create-class-registration.dto.js';
import {
  ApproveClassRegistrationDto,
  RegistrationReviewAction,
  ReviewClassRegistrationDto,
} from './dto/review-class-registration.dto.js';

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
    const phone = this.normalizePhone(dto.phone);
    if (!/^0\d{9,10}$/.test(phone)) {
      throw new BadRequestException('Số điện thoại không hợp lệ');
    }
    const applicantKey = `phone:${phone}`;
    const existing = await this.prisma.classRegistration.findUnique({
      where: { classId_applicantKey: { classId: dto.classId, applicantKey } },
    });
    if (existing) return accepted;
    const offering = await this.assertOffering(dto.classId);
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
    const guestRequest = await this.prisma.classRegistration.findFirst({
      where: {
        classId: dto.classId,
        lead: { is: { convertedUserId: actor.id } },
      },
      select: { id: true, classId: true, status: true, createdAt: true },
    });
    if (guestRequest) return guestRequest;
    const applicantKey = `user:${actor.id}`;
    const existingRequest = await this.prisma.classRegistration.findUnique({
      where: { classId_applicantKey: { classId: dto.classId, applicantKey } },
      select: { id: true, classId: true, status: true, createdAt: true },
    });
    if (existingRequest) return existingRequest;
    await this.assertOffering(dto.classId);
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
      where: {
        OR: [{ studentId }, { lead: { is: { convertedUserId: studentId } } }],
      },
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
        lead: { select: { convertedUserId: true } },
        createdAt: true,
        class: { select: { name: true, code: true, branchId: true } },
      },
    });
  }

  private assertStaffBranch(
    actor: { roles: string[]; branchId?: string | null },
    branchId: string,
  ) {
    if (
      !actor.roles.some((role) =>
        ['super_admin', 'branch_admin', 'academic_staff'].includes(role),
      )
    ) {
      throw new ForbiddenException('Không có quyền xử lý đơn đăng ký');
    }
    if (!actor.roles.includes('super_admin') && actor.branchId !== branchId) {
      throw new ForbiddenException('Đơn không thuộc chi nhánh của bạn');
    }
  }

  async review(
    id: string,
    dto: ReviewClassRegistrationDto,
    actor: { roles: string[]; branchId?: string | null },
  ) {
    return this.prisma.$transaction(async (tx) => {
      const request = await tx.classRegistration.findUnique({
        where: { id },
        include: { class: { select: { branchId: true } } },
      });
      if (!request) throw new NotFoundException('Không tìm thấy đơn đăng ký');
      this.assertStaffBranch(actor, request.class.branchId);
      if (
        request.status !== RegistrationStatus.PENDING &&
        request.status !== RegistrationStatus.CONTACTED
      ) {
        throw new ConflictException(
          'Đơn đã được xử lý và không thể đổi trạng thái',
        );
      }
      const next =
        dto.status === RegistrationReviewAction.CONTACTED
          ? RegistrationStatus.CONTACTED
          : RegistrationStatus.REJECTED;
      const updated = await tx.classRegistration.updateMany({
        where: {
          id,
          status: {
            in: [RegistrationStatus.PENDING, RegistrationStatus.CONTACTED],
          },
        },
        data: { status: next, notes: dto.notes?.trim() ?? request.notes },
      });
      if (updated.count !== 1)
        throw new ConflictException('Đơn đã được xử lý bởi người khác');
      if (request.leadId) {
        await tx.admissionLead.updateMany({
          where: {
            id: request.leadId,
            convertedUserId: null,
            status: { not: LeadStatus.ENROLLED },
          },
          data: {
            status:
              next === RegistrationStatus.CONTACTED
                ? LeadStatus.CONTACTED
                : LeadStatus.CANCELLED,
          },
        });
      }
      return { id, status: next };
    });
  }

  async approve(
    id: string,
    dto: ApproveClassRegistrationDto,
    actor: { id: string; roles: string[]; branchId?: string | null },
  ) {
    for (let attempt = 0; attempt < 3; attempt++) {
      try {
        return await this.prisma.$transaction(
          async (tx) => {
            const request = await tx.classRegistration.findUnique({
              where: { id },
              include: { class: true, lead: true },
            });
            if (!request)
              throw new NotFoundException('Không tìm thấy đơn đăng ký');
            this.assertStaffBranch(actor, request.class.branchId);
            if (request.status === RegistrationStatus.APPROVED) {
              return {
                id,
                status: RegistrationStatus.APPROVED,
                studentId: request.studentId,
              };
            }
            if (
              request.status !== RegistrationStatus.PENDING &&
              request.status !== RegistrationStatus.CONTACTED
            ) {
              throw new ConflictException('Đơn không còn chờ duyệt');
            }
            if (request.class.status !== ClassStatus.OPEN_FOR_ENROLLMENT) {
              throw new ConflictException('Lớp không còn mở đăng ký');
            }
            const studentId =
              request.studentId ??
              request.lead?.convertedUserId ??
              dto.studentId;
            if (!studentId) {
              throw new BadRequestException(
                'Cần chuyển Lead thành tài khoản học viên hoặc chọn học viên đã xác minh',
              );
            }
            if (
              request.studentId &&
              dto.studentId &&
              dto.studentId !== request.studentId
            ) {
              throw new BadRequestException(
                'Không thể thay học viên của đơn đã đăng nhập',
              );
            }
            if (
              request.lead?.convertedUserId &&
              dto.studentId &&
              dto.studentId !== request.lead.convertedUserId
            ) {
              throw new BadRequestException(
                'Học viên không khớp tài khoản đã chuyển từ Lead',
              );
            }
            const student = await tx.user.findUnique({
              where: { id: studentId },
              select: {
                id: true,
                phone: true,
                status: true,
                studentProfile: { select: { id: true } },
                userRoles: { select: { role: { select: { code: true } } } },
              },
            });
            if (
              !student ||
              student.status !== UserStatus.ACTIVE ||
              !student.studentProfile ||
              !student.userRoles.some((entry) => entry.role.code === 'student')
            ) {
              throw new BadRequestException(
                'Tài khoản được chọn không phải học viên đang hoạt động',
              );
            }
            if (
              request.leadId &&
              this.normalizePhone(student.phone ?? '') !==
                this.normalizePhone(request.phone)
            ) {
              throw new BadRequestException(
                'Số điện thoại học viên không khớp đơn khách mới',
              );
            }
            const existing = await tx.classStudent.findUnique({
              where: {
                classId_studentId: { classId: request.classId, studentId },
              },
            });
            if (existing?.status === EnrollmentStatus.ENROLLED) {
              throw new ConflictException(
                'Học viên đã được ghi danh vào lớp này',
              );
            }
            const enrolledCount = await tx.classStudent.count({
              where: {
                classId: request.classId,
                status: EnrollmentStatus.ENROLLED,
              },
            });
            if (enrolledCount >= request.class.maxCapacity) {
              throw new ConflictException(
                'Lớp đã đủ sĩ số tại thời điểm duyệt',
              );
            }
            const changed = await tx.classRegistration.updateMany({
              where: {
                id,
                status: {
                  in: [
                    RegistrationStatus.PENDING,
                    RegistrationStatus.CONTACTED,
                  ],
                },
              },
              data: { status: RegistrationStatus.APPROVED, studentId },
            });
            if (changed.count !== 1)
              throw new ConflictException('Đơn đã được xử lý bởi người khác');
            if (existing) {
              await tx.classStudent.update({
                where: { id: existing.id },
                data: {
                  status: EnrollmentStatus.ENROLLED,
                  joinedAt: new Date(),
                },
              });
            } else {
              await tx.classStudent.create({
                data: {
                  classId: request.classId,
                  studentId,
                  status: EnrollmentStatus.ENROLLED,
                  tuitionPaid: 0,
                },
              });
            }
            if (Number(request.class.tuitionFee) > 0) {
              const invoice = await tx.invoice.findFirst({
                where: {
                  classId: request.classId,
                  studentId,
                  status: { not: InvoiceStatus.CANCELLED },
                },
              });
              if (!invoice) {
                await tx.invoice.create({
                  data: {
                    code: `HD-${new Date().getFullYear()}-${randomUUID().slice(0, 8).toUpperCase()}`,
                    title: `Học phí lớp ${request.class.name}`,
                    classId: request.classId,
                    studentId,
                    subtotal: request.class.tuitionFee,
                    discount: 0,
                    totalAmount: request.class.tuitionFee,
                    paidAmount: 0,
                    balance: request.class.tuitionFee,
                    status: InvoiceStatus.PENDING,
                    dueDate: request.class.startDate,
                    createdById: actor.id,
                  },
                });
              }
            }
            if (request.leadId) {
              await tx.admissionLead.update({
                where: { id: request.leadId },
                data: {
                  status: LeadStatus.ENROLLED,
                  convertedUserId: studentId,
                  convertedAt: new Date(),
                },
              });
            }
            return { id, status: RegistrationStatus.APPROVED, studentId };
          },
          { isolationLevel: Prisma.TransactionIsolationLevel.Serializable },
        );
      } catch (error) {
        if (
          error instanceof Prisma.PrismaClientKnownRequestError &&
          error.code === 'P2034' &&
          attempt < 2
        ) {
          continue;
        }
        if (
          error instanceof Prisma.PrismaClientKnownRequestError &&
          error.code === 'P2002'
        ) {
          throw new ConflictException(
            'Học viên hoặc hóa đơn đã tồn tại, vui lòng tải lại đơn',
          );
        }
        throw error;
      }
    }
    throw new ConflictException('Không thể duyệt đơn, vui lòng thử lại');
  }
}
