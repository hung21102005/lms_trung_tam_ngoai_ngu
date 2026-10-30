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
import { isRetryableTransactionConflict } from '../../common/prisma-transaction.js';
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
    if (existing) {
      if (existing.status === RegistrationStatus.REJECTED) {
        throw new ConflictException(
          'Yêu cầu đăng ký lớp này đã bị từ chối trước đó. Vui lòng liên hệ bộ phận Tuyển sinh để được hỗ trợ mở lại hồ sơ.',
        );
      }
      if (existing.status === RegistrationStatus.APPROVED) {
        throw new ConflictException(
          'Số điện thoại này đã được xác nhận nhập học vào lớp.',
        );
      }
      return accepted;
    }
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
    if (guestRequest) {
      if (guestRequest.status === RegistrationStatus.REJECTED) {
        throw new ConflictException(
          'Yêu cầu đăng ký lớp này đã bị từ chối trước đó. Vui lòng liên hệ Học vụ nếu bạn cần mở lại hồ sơ đăng ký.',
        );
      }
      return guestRequest;
    }
    const applicantKey = `user:${actor.id}`;
    const existingRequest = await this.prisma.classRegistration.findUnique({
      where: { classId_applicantKey: { classId: dto.classId, applicantKey } },
      select: { id: true, classId: true, status: true, createdAt: true },
    });
    if (existingRequest) {
      if (existingRequest.status === RegistrationStatus.REJECTED) {
        throw new ConflictException(
          'Yêu cầu đăng ký lớp này đã bị từ chối trước đó. Vui lòng liên hệ Học vụ nếu bạn cần mở lại hồ sơ đăng ký.',
        );
      }
      return existingRequest;
    }
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

  async listForStaff(
    actor: { roles: string[]; branchId?: string | null },
    classId?: string,
    status?: string,
  ) {
    const superAdmin = actor.roles.includes('super_admin');
    if (!superAdmin && !actor.branchId)
      throw new ForbiddenException('Tài khoản không có chi nhánh');
    const validStatuses = Object.values(RegistrationStatus) as string[];
    const statusFilter =
      status && validStatuses.includes(status)
        ? (status as RegistrationStatus)
        : undefined;

    const rows = await this.prisma.classRegistration.findMany({
      where: {
        ...(classId ? { classId } : {}),
        ...(statusFilter ? { status: statusFilter } : {}),
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
        notes: true,
        studentId: true,
        leadId: true,
        lead: { select: { id: true, status: true, convertedUserId: true } },
        createdAt: true,
        updatedAt: true,
        class: {
          select: {
            id: true,
            name: true,
            code: true,
            branchId: true,
            status: true,
            maxCapacity: true,
            startTime: true,
            endTime: true,
            scheduleDays: true,
            course: { select: { id: true, code: true, title: true } },
            branch: { select: { id: true, code: true, name: true } },
            room: { select: { id: true, code: true, name: true } },
            _count: {
              select: {
                students: { where: { status: EnrollmentStatus.ENROLLED } },
              },
            },
          },
        },
      },
    });

    return rows.map((row) => ({
      ...row,
      isActiveDependency:
        row.status === RegistrationStatus.PENDING ||
        row.status === RegistrationStatus.CONTACTED ||
        row.status === RegistrationStatus.APPROVED,
      isHistoricalRecord:
        row.status === RegistrationStatus.REJECTED ||
        row.status === RegistrationStatus.CANCELLED,
      canDelete:
        (row.status === RegistrationStatus.REJECTED ||
          row.status === RegistrationStatus.CANCELLED) &&
        !row.studentId &&
        !row.lead?.convertedUserId,
      class: row.class
        ? {
            ...row.class,
            enrolledCount: row.class._count.students,
            remainingSeats: Math.max(
              0,
              row.class.maxCapacity - row.class._count.students,
            ),
          }
        : null,
    }));
  }

  async summaryForStaff(
    actor: { roles: string[]; branchId?: string | null },
    classId?: string,
  ) {
    const superAdmin = actor.roles.includes('super_admin');
    if (!superAdmin && !actor.branchId)
      throw new ForbiddenException('Tài khoản không có chi nhánh');
    const baseWhere: Prisma.ClassRegistrationWhereInput = {
      ...(classId ? { classId } : {}),
      ...(!superAdmin ? { class: { branchId: actor.branchId! } } : {}),
    };
    const grouped = await this.prisma.classRegistration.groupBy({
      by: ['status'],
      where: baseWhere,
      _count: { _all: true },
    });
    const counts: Record<string, number> = {
      PENDING: 0,
      CONTACTED: 0,
      APPROVED: 0,
      REJECTED: 0,
      CANCELLED: 0,
    };
    for (const item of grouped) {
      counts[item.status] = item._count._all;
    }
    const total =
      counts.PENDING +
      counts.CONTACTED +
      counts.APPROVED +
      counts.REJECTED +
      counts.CANCELLED;
    return {
      total,
      pending: counts.PENDING,
      contacted: counts.CONTACTED,
      inProgress: counts.PENDING + counts.CONTACTED,
      approved: counts.APPROVED,
      rejected: counts.REJECTED,
      cancelled: counts.CANCELLED,
      activeCount: counts.PENDING + counts.CONTACTED + counts.APPROVED,
      historicalCount: counts.REJECTED + counts.CANCELLED,
    };
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
    actor: { id?: string; roles: string[]; branchId?: string | null },
  ) {
    return this.prisma.$transaction(async (tx) => {
      const request = await tx.classRegistration.findUnique({
        where: { id },
        include: {
          class: {
            select: {
              id: true,
              branchId: true,
              status: true,
              maxCapacity: true,
              _count: {
                select: {
                  students: { where: { status: EnrollmentStatus.ENROLLED } },
                },
              },
            },
          },
        },
      });
      if (!request) throw new NotFoundException('Không tìm thấy đơn đăng ký');
      this.assertStaffBranch(actor, request.class.branchId);

      const timestamp = new Date().toISOString().slice(0, 16).replace('T', ' ');
      const noteInput = dto.notes?.trim();

      if (dto.status === RegistrationReviewAction.REOPEN) {
        if (
          request.status !== RegistrationStatus.REJECTED &&
          request.status !== RegistrationStatus.CANCELLED
        ) {
          throw new ConflictException(
            'Chỉ đơn đã từ chối hoặc đã hủy mới có thể mở lại',
          );
        }
        if (request.class.status === ClassStatus.CANCELLED) {
          throw new ConflictException(
            'Lớp học đã hủy, không thể mở lại đơn đăng ký của lớp này',
          );
        }
        if (request.class._count.students >= request.class.maxCapacity) {
          throw new ConflictException(
            'Lớp học hiện đã đủ sĩ số, không thể mở lại đơn đăng ký',
          );
        }
        const reopenAudit = `[Mở lại đơn ${timestamp}]${noteInput ? `: ${noteInput}` : ''}`;
        const combinedNotes = [request.notes, reopenAudit]
          .filter((part) => part && part.trim().length > 0)
          .join('\n');
        const reopened = await tx.classRegistration.updateMany({
          where: {
            id,
            status: {
              in: [RegistrationStatus.REJECTED, RegistrationStatus.CANCELLED],
            },
          },
          data: {
            status: RegistrationStatus.PENDING,
            notes: combinedNotes,
          },
        });
        if (reopened.count !== 1) {
          throw new ConflictException('Đơn đã được thay đổi bởi người khác');
        }
        if (request.leadId) {
          await tx.admissionLead.updateMany({
            where: {
              id: request.leadId,
              convertedUserId: null,
              status: LeadStatus.CANCELLED,
            },
            data: { status: LeadStatus.CONTACTED },
          });
        }
        return {
          id,
          status: RegistrationStatus.PENDING,
          notes: combinedNotes,
        };
      }

      if (
        request.status !== RegistrationStatus.PENDING &&
        request.status !== RegistrationStatus.CONTACTED
      ) {
        throw new ConflictException(
          'Đơn đã ở trạng thái kết thúc và không thể đổi trạng thái trực tiếp',
        );
      }

      const next =
        dto.status === RegistrationReviewAction.CONTACTED
          ? RegistrationStatus.CONTACTED
          : dto.status === RegistrationReviewAction.CANCELLED
            ? RegistrationStatus.CANCELLED
            : RegistrationStatus.REJECTED;

      let updatedNotes = request.notes ?? null;
      if (
        next === RegistrationStatus.REJECTED ||
        next === RegistrationStatus.CANCELLED
      ) {
        const tag =
          next === RegistrationStatus.REJECTED ? 'Từ chối đơn' : 'Hủy đơn';
        const auditLine = `[${tag} ${timestamp}]${noteInput ? `: ${noteInput}` : ''}`;
        updatedNotes = [request.notes, auditLine]
          .filter((part) => part && part.trim().length > 0)
          .join('\n');
      } else if (noteInput) {
        updatedNotes = [request.notes, `[Liên hệ ${timestamp}]: ${noteInput}`]
          .filter((part) => part && part.trim().length > 0)
          .join('\n');
      }

      const updated = await tx.classRegistration.updateMany({
        where: {
          id,
          status: {
            in: [RegistrationStatus.PENDING, RegistrationStatus.CONTACTED],
          },
        },
        data: { status: next, notes: updatedNotes },
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
      return { id, status: next, notes: updatedNotes };
    });
  }

  async deleteRegistration(
    id: string,
    actor: { id?: string; roles: string[]; branchId?: string | null },
  ) {
    return this.prisma.$transaction(async (tx) => {
      const request = await tx.classRegistration.findUnique({
        where: { id },
        include: {
          class: { select: { id: true, branchId: true, code: true, name: true } },
          lead: { select: { id: true, convertedUserId: true } },
        },
      });
      if (!request) throw new NotFoundException('Không tìm thấy đơn đăng ký');
      this.assertStaffBranch(actor, request.class.branchId);

      if (request.status === RegistrationStatus.APPROVED) {
        throw new ConflictException(
          'Không thể xóa đơn đăng ký đã được duyệt nhập học. Lịch sử ghi danh phải được bảo toàn.',
        );
      }
      if (
        request.status === RegistrationStatus.PENDING ||
        request.status === RegistrationStatus.CONTACTED
      ) {
        throw new BadRequestException(
          'Đơn đăng ký đang trong quá trình xử lý. Vui lòng Từ chối hoặc Hủy đơn trước khi xóa bản ghi thử nghiệm.',
        );
      }

      const linkedStudentId =
        request.studentId ?? request.lead?.convertedUserId ?? null;
      if (linkedStudentId) {
        const [enrollment, invoice] = await Promise.all([
          tx.classStudent.findUnique({
            where: {
              classId_studentId: {
                classId: request.classId,
                studentId: linkedStudentId,
              },
            },
          }),
          tx.invoice.findFirst({
            where: {
              classId: request.classId,
              studentId: linkedStudentId,
              status: { not: InvoiceStatus.CANCELLED },
            },
          }),
        ]);
        if (enrollment) {
          throw new ConflictException(
            'Học viên của đơn này đã có dữ liệu ghi danh trong lớp, không thể xóa đơn lịch sử.',
          );
        }
        if (invoice) {
          throw new ConflictException(
            'Học viên của đơn này đã có hóa đơn học phí liên kết với lớp học, không thể xóa đơn lịch sử.',
          );
        }
      }

      await tx.classRegistration.delete({ where: { id } });

      const [activeRegistrationsCount, historicalRegistrationsCount] =
        await Promise.all([
          tx.classRegistration.count({
            where: {
              classId: request.classId,
              status: {
                in: [
                  RegistrationStatus.PENDING,
                  RegistrationStatus.CONTACTED,
                  RegistrationStatus.APPROVED,
                ],
              },
            },
          }),
          tx.classRegistration.count({
            where: {
              classId: request.classId,
              status: {
                in: [RegistrationStatus.REJECTED, RegistrationStatus.CANCELLED],
              },
            },
          }),
        ]);

      return {
        success: true,
        id,
        classId: request.classId,
        activeRegistrationsCount,
        historicalRegistrationsCount,
        message: 'Đã xóa bản ghi đơn đăng ký đã kết thúc khỏi lịch sử lớp học.',
      };
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
        if (isRetryableTransactionConflict(error)) {
          if (attempt < 2) continue;
          throw new ConflictException('Không thể duyệt đơn, vui lòng thử lại');
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
