import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
  ConflictException,
  ForbiddenException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import { PrismaService } from '../../database/prisma.service.js';
import { NotificationsService } from '../notifications/notifications.service.js';
import {
  InvoiceStatus,
  PaymentMethod,
  PaymentStatus,
  PromotionType,
} from '@prisma/client';
import {
  CreateInvoiceDto,
  RecordPaymentDto,
  SubmitTransferPaymentDto,
  CreatePromotionDto,
  ValidatePromotionDto,
  PayOnlineDto,
} from './dto/index.js';

@Injectable()
export class FinanceService {
  private readonly logger = new Logger(FinanceService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
    private readonly notificationsService: NotificationsService,
  ) {}

  // --------------------------------------------------------------------------
  // 1. QUẢN LÝ HÓA ĐƠN (INVOICES)
  // --------------------------------------------------------------------------

  async generateInvoiceCode(): Promise<string> {
    const year = new Date().getFullYear();
    const count = await this.prisma.invoice.count();
    for (let offset = 1; offset <= 50; offset++) {
      const candidate = `HD-${year}-${String(count + offset).padStart(4, '0')}`;
      const exists = await this.prisma.invoice.findUnique({
        where: { code: candidate },
        select: { id: true },
      });
      if (!exists) return candidate;
    }
    return `HD-${year}-${crypto.randomUUID().slice(0, 8).toUpperCase()}`;
  }

  async generatePaymentCode(): Promise<string> {
    const year = new Date().getFullYear();
    const count = await this.prisma.payment.count();
    for (let offset = 1; offset <= 50; offset++) {
      const candidate = `PT-${year}-${String(count + offset).padStart(4, '0')}`;
      const exists = await this.prisma.payment.findUnique({
        where: { code: candidate },
        select: { id: true },
      });
      if (!exists) return candidate;
    }
    return `PT-${year}-${crypto.randomUUID().slice(0, 8).toUpperCase()}`;
  }

  async createInvoice(dto: CreateInvoiceDto, createdById?: string) {
    const studentKey = dto.studentId.trim();
    const student = await this.prisma.user.findFirst({
      where: {
        OR: [{ id: studentKey }, { userCode: studentKey }],
      },
    });

    if (!student) {
      throw new NotFoundException(`Không tìm thấy học viên với mã/ID: ${dto.studentId}`);
    }

    if (dto.classId) {
      const cls = await this.prisma.class.findUnique({
        where: { id: dto.classId },
      });
      if (!cls) {
        throw new NotFoundException(`Không tìm thấy lớp học với ID: ${dto.classId}`);
      }
    }

    let calculatedDiscount = dto.discount || 0;
    let appliedPromotionId: string | undefined = undefined;

    if (dto.promotionCode && dto.promotionCode.trim().length > 0) {
      const promoResult = await this.validatePromotionInternal(
        dto.promotionCode.trim(),
        dto.subtotal,
      );
      calculatedDiscount = promoResult.discountAmount;
      appliedPromotionId = promoResult.promotion.id;

      // Tăng số lượt dùng của mã KM
      await this.prisma.promotion.update({
        where: { id: promoResult.promotion.id },
        data: { usedCount: { increment: 1 } },
      });
    }

    const totalAmount = Math.max(0, dto.subtotal - calculatedDiscount);
    const initialPaid =
      dto.initialPaymentAmount && dto.initialPaymentAmount > 0
        ? Math.min(totalAmount, Number(dto.initialPaymentAmount))
        : 0;
    const balance = Math.max(0, totalAmount - initialPaid);
    const status =
      balance <= 0
        ? InvoiceStatus.PAID
        : initialPaid > 0
          ? InvoiceStatus.PARTIALLY_PAID
          : InvoiceStatus.PENDING;
    const code = await this.generateInvoiceCode();

    const invoice = await this.prisma.invoice.create({
      data: {
        code,
        title: dto.title,
        studentId: student.id,
        classId: dto.classId,
        subtotal: dto.subtotal,
        discount: calculatedDiscount,
        totalAmount,
        paidAmount: initialPaid,
        balance,
        status,
        dueDate: dto.dueDate ? new Date(dto.dueDate) : undefined,
        notes: dto.notes,
        promotionId: appliedPromotionId,
        createdById,
      },
      include: {
        student: {
          select: {
            id: true,
            userCode: true,
            fullName: true,
            email: true,
            phone: true,
          },
        },
        class: {
          select: {
            id: true,
            code: true,
            name: true,
          },
        },
        promotion: true,
      },
    });

    if (initialPaid > 0) {
      const paymentCode = await this.generatePaymentCode();
      await this.prisma.payment.create({
        data: {
          code: paymentCode,
          invoiceId: invoice.id,
          studentId: student.id,
          amount: initialPaid,
          method: dto.paymentMethod || PaymentMethod.CASH,
          status: PaymentStatus.SUCCESS,
          transactionId: dto.transactionId,
          notes: dto.notes || `Thu học phí ngay khi phát hành hóa đơn ${code}`,
          receivedById: createdById,
        },
      });
      if (dto.classId) {
        await this.prisma.classStudent.updateMany({
          where: { classId: dto.classId, studentId: student.id },
          data: { tuitionPaid: { increment: initialPaid } },
        });
      }
    }

    // Thông báo cho học viên về hóa đơn mới
    const formattedTotal = Number(totalAmount).toLocaleString('vi-VN') + ' VNĐ';
    await this.notificationsService.createNotification(
      student.id,
      'Thông báo học phí mới',
      `Hóa đơn "${dto.title}" (${code}) với số tiền ${formattedTotal} đã được phát hành.`,
      'TUITION' as any,
      { invoiceId: invoice.id, invoiceCode: code, amount: totalAmount },
    );

    return this.getInvoiceById(invoice.id);
  }

  async getInvoices(query: {
    status?: InvoiceStatus;
    studentId?: string;
    classId?: string;
    branchId?: string;
    pendingTransferOnly?: boolean;
    search?: string;
    startDate?: string;
    endDate?: string;
    page?: number;
    limit?: number;
  }) {
    const page = query.page || 1;
    const limit = query.limit || 20;
    const where: any = {};

    if (query.status) {
      where.status = query.status;
    }

    if (query.studentId) {
      where.studentId = query.studentId;
    }

    if (query.classId) {
      where.classId = query.classId;
    }

    if (query.branchId) {
      where.OR = [
        { class: { branchId: query.branchId } },
        { student: { branchId: query.branchId } },
      ];
    }

    if (query.pendingTransferOnly) {
      where.payments = {
        some: { status: PaymentStatus.PENDING },
      };
    }

    if (query.startDate || query.endDate) {
      where.issuedDate = {};
      if (query.startDate) {
        where.issuedDate.gte = new Date(query.startDate);
      }
      if (query.endDate) {
        where.issuedDate.lte = new Date(query.endDate);
      }
    }

    if (query.search) {
      const searchCond = [
        { code: { contains: query.search, mode: 'insensitive' } },
        { title: { contains: query.search, mode: 'insensitive' } },
        { student: { fullName: { contains: query.search, mode: 'insensitive' } } },
        { student: { phone: { contains: query.search, mode: 'insensitive' } } },
        { student: { userCode: { contains: query.search, mode: 'insensitive' } } },
      ];
      if (where.OR) {
        where.AND = [{ OR: where.OR }, { OR: searchCond }];
        delete where.OR;
      } else {
        where.OR = searchCond;
      }
    }

    const [items, total, summary, pendingTransferCount, overdueCount] =
      await Promise.all([
        this.prisma.invoice.findMany({
          where,
          include: {
            student: {
              select: {
                id: true,
                userCode: true,
                fullName: true,
                phone: true,
                email: true,
              },
            },
            class: {
              select: {
                id: true,
                code: true,
                name: true,
              },
            },
            payments: {
              select: {
                id: true,
                code: true,
                amount: true,
                method: true,
                payDate: true,
                status: true,
                transactionId: true,
                notes: true,
              },
              orderBy: { payDate: 'desc' },
            },
          },
          orderBy: { createdAt: 'desc' },
          skip: (page - 1) * limit,
          take: limit,
        }),
        this.prisma.invoice.count({ where }),
        this.prisma.invoice.aggregate({
          where: {
            ...where,
            status: { not: InvoiceStatus.CANCELLED },
          },
          _sum: {
            totalAmount: true,
            paidAmount: true,
            balance: true,
          },
        }),
        this.prisma.invoice.count({
          where: {
            payments: { some: { status: PaymentStatus.PENDING } },
          },
        }),
        this.prisma.invoice.count({
          where: { status: InvoiceStatus.OVERDUE },
        }),
      ]);

    return {
      items,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit) || 1,
      summary: {
        totalRevenue: summary._sum.totalAmount || 0,
        paidRevenue: summary._sum.paidAmount || 0,
        outstandingRevenue: summary._sum.balance || 0,
        pendingTransferCount,
        overdueCount,
      },
    };
  }

  async getInvoiceById(id: string) {
    const invoice = await this.prisma.invoice.findUnique({
      where: { id },
      include: {
        student: {
          select: {
            id: true,
            userCode: true,
            fullName: true,
            email: true,
            phone: true,
            parents: {
              include: {
                parent: {
                  select: {
                    id: true,
                    fullName: true,
                    phone: true,
                    email: true,
                  },
                },
              },
            },
          },
        },
        class: {
          include: {
            course: true,
            level: true,
            branch: true,
          },
        },
        promotion: true,
        payments: {
          include: {
            receivedBy: {
              select: {
                id: true,
                fullName: true,
                userCode: true,
              },
            },
          },
          orderBy: { payDate: 'desc' },
        },
        createdBy: {
          select: {
            id: true,
            fullName: true,
            userCode: true,
          },
        },
      },
    });

    if (!invoice) {
      throw new NotFoundException(`Không tìm thấy hóa đơn với ID: ${id}`);
    }

    return invoice;
  }

  async getMyInvoices(userId: string) {
    // Tìm các hóa đơn của chính mình hoặc của con em (nếu là phụ huynh)
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        children: { select: { studentId: true } },
      },
    });

    const studentIds = [userId];
    if (user && user.children.length > 0) {
      studentIds.push(...user.children.map((c) => c.studentId));
    }

    return this.prisma.invoice.findMany({
      where: {
        studentId: { in: studentIds },
      },
      include: {
        class: {
          select: {
            id: true,
            code: true,
            name: true,
          },
        },
        student: {
          select: {
            id: true,
            fullName: true,
            userCode: true,
          },
        },
        payments: {
          orderBy: { payDate: 'desc' },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async cancelInvoice(id: string, reason?: string) {
    const invoice = await this.getInvoiceById(id);

    if (invoice.status === InvoiceStatus.PAID) {
      throw new BadRequestException('Không thể hủy hóa đơn đã thanh toán đầy đủ');
    }

    if (Number(invoice.paidAmount) > 0) {
      throw new BadRequestException(
        'Hóa đơn đã có khoản thanh toán. Hãy hoàn tiền trước khi hủy hóa đơn.',
      );
    }

    return this.prisma.invoice.update({
      where: { id },
      data: {
        status: InvoiceStatus.CANCELLED,
        notes: reason
          ? `${invoice.notes || ''}\n[Lý do hủy: ${reason}]`.trim()
          : invoice.notes,
      },
    });
  }

  async refundInvoice(id: string, amount: number, reason?: string, receivedById?: string) {
    const invoice = await this.getInvoiceById(id);

    if (Number(invoice.paidAmount) <= 0) {
      throw new BadRequestException('Hóa đơn chưa có khoản thanh toán nào để hoàn tiền');
    }

    if (amount > Number(invoice.paidAmount)) {
      throw new BadRequestException(
        `Số tiền hoàn (${amount}) không được vượt quá số tiền đã nộp (${invoice.paidAmount})`,
      );
    }

    const paymentCode = await this.generatePaymentCode();
    await this.prisma.payment.create({
      data: {
        code: paymentCode,
        invoiceId: id,
        studentId: invoice.studentId,
        amount: -amount, // Âm để thể hiện hoàn tiền
        method: PaymentMethod.CASH,
        status: PaymentStatus.REFUNDED,
        notes: `Hoàn tiền: ${reason || 'Yêu cầu hoàn trả học phí'}`,
        receivedById,
      },
    });

    const newPaidAmount = Math.max(0, Number(invoice.paidAmount) - amount);
    const newBalance = Number(invoice.totalAmount) - newPaidAmount;

    return this.prisma.invoice.update({
      where: { id },
      data: {
        paidAmount: newPaidAmount,
        balance: newBalance,
        status: InvoiceStatus.REFUNDED,
        notes: `${invoice.notes || ''}\n[Hoàn tiền: ${amount} VNĐ - Lý do: ${reason || 'N/A'}]`.trim(),
      },
      include: { payments: true },
    });
  }

  async autoCreateInvoiceForEnrollment(classId: string, studentId: string, createdById?: string) {
    const existing = await this.prisma.invoice.findFirst({
      where: { classId, studentId },
    });

    if (existing) {
      return existing;
    }

    const cls = await this.prisma.class.findUnique({
      where: { id: classId },
    });

    if (!cls) return null;

    const tuitionFee = Number(cls.tuitionFee) || 0;
    const code = await this.generateInvoiceCode();

    return this.prisma.invoice.create({
      data: {
        code,
        title: `Học phí lớp ${cls.name}`,
        studentId,
        classId,
        subtotal: tuitionFee,
        discount: 0,
        totalAmount: tuitionFee,
        paidAmount: 0,
        balance: tuitionFee,
        status: tuitionFee === 0 ? InvoiceStatus.PAID : InvoiceStatus.PENDING,
        dueDate: cls.startDate,
        createdById,
      },
    });
  }

  // --------------------------------------------------------------------------
  // 2. GHI NHẬN THANH TOÁN (PAYMENTS)
  // --------------------------------------------------------------------------

  async recordPayment(invoiceId: string, dto: RecordPaymentDto, receivedById?: string) {
    const invoice = await this.getInvoiceById(invoiceId);

    if (
      invoice.status === InvoiceStatus.CANCELLED ||
      invoice.status === InvoiceStatus.REFUNDED
    ) {
      throw new BadRequestException(
        `Không thể ghi nhận thanh toán cho hóa đơn ở trạng thái ${invoice.status}`,
      );
    }

    if (Number(invoice.balance) <= 0) {
      throw new BadRequestException('Hóa đơn này đã được thanh toán đầy đủ');
    }

    if (dto.amount > Number(invoice.balance)) {
      throw new BadRequestException(
        `Số tiền thanh toán (${dto.amount.toLocaleString()} VNĐ) lớn hơn số dư còn lại (${Number(invoice.balance).toLocaleString()} VNĐ)`,
      );
    }

    const code = await this.generatePaymentCode();
    const payment = await this.prisma.payment.create({
      data: {
        code,
        invoiceId,
        studentId: invoice.studentId,
        amount: dto.amount,
        method: dto.method,
        status: PaymentStatus.SUCCESS,
        transactionId: dto.transactionId,
        notes: dto.notes,
        receivedById,
      },
    });

    const newPaidAmount = Number(invoice.paidAmount) + dto.amount;
    const newBalance = Math.max(0, Number(invoice.totalAmount) - newPaidAmount);
    const newStatus =
      newBalance <= 0 ? InvoiceStatus.PAID : InvoiceStatus.PARTIALLY_PAID;

    const updatedInvoice = await this.prisma.invoice.update({
      where: { id: invoiceId },
      data: {
        paidAmount: newPaidAmount,
        balance: newBalance,
        status: newStatus,
      },
    });

    // Cập nhật tuitionPaid trong class_students nếu có gắn classId
    if (invoice.classId) {
      await this.prisma.classStudent.updateMany({
        where: {
          classId: invoice.classId,
          studentId: invoice.studentId,
        },
        data: {
          tuitionPaid: {
            increment: dto.amount,
          },
        },
      });
    }

    // Thông báo cho học viên
    const formattedAmount = Number(dto.amount).toLocaleString('vi-VN') + ' VNĐ';
    await this.notificationsService.createNotification(
      invoice.studentId,
      'Xác nhận thanh toán học phí thành công',
      `Thanh toán ${formattedAmount} cho hóa đơn ${invoice.code} đã được ghi nhận thành công qua ${dto.method}.`,
      'TUITION' as any,
      { invoiceId: invoice.id, paymentId: payment.id, amount: dto.amount },
    );

    return {
      payment,
      invoice: await this.getInvoiceById(invoiceId),
    };
  }

  async submitTransferPayment(
    invoiceId: string,
    dto: SubmitTransferPaymentDto,
    actor: { id: string; roles?: string[] },
  ) {
    const invoice = await this.getInvoiceById(invoiceId);
    const roles = actor.roles || [];
    const isStaff = roles.some((r) =>
      ['super_admin', 'branch_admin', 'cashier', 'academic_staff'].includes(r),
    );

    if (!isStaff && invoice.studentId !== actor.id) {
      const parentRel = await this.prisma.parentStudent.findUnique({
        where: {
          parentId_studentId: {
            parentId: actor.id,
            studentId: invoice.studentId,
          },
        },
      });
      if (!parentRel) {
        throw new ForbiddenException(
          'Bạn chỉ được gửi xác nhận chuyển khoản cho hóa đơn của mình hoặc con em mình.',
        );
      }
    }

    if (
      invoice.status === InvoiceStatus.CANCELLED ||
      invoice.status === InvoiceStatus.REFUNDED
    ) {
      throw new BadRequestException(
        'Hóa đơn này đã hủy hoặc hoàn tiền, không thể gửi xác nhận chuyển khoản.',
      );
    }

    const balance = Number(invoice.balance);
    if (balance <= 0) {
      throw new BadRequestException('Hóa đơn này đã được thanh toán đầy đủ.');
    }

    if (dto.amount > balance) {
      throw new BadRequestException(
        `Số tiền khai báo (${dto.amount.toLocaleString('vi-VN')} VNĐ) vượt quá số dư còn nợ (${balance.toLocaleString('vi-VN')} VNĐ).`,
      );
    }

    const existingPending = await this.prisma.payment.findFirst({
      where: {
        invoiceId,
        status: PaymentStatus.PENDING,
      },
    });
    if (existingPending) {
      throw new ConflictException(
        `Hóa đơn đang có phiếu chuyển khoản ${existingPending.code} chờ Thu ngân xác nhận. Vui lòng đợi đối soát trước khi gửi yêu cầu mới.`,
      );
    }

    const code = await this.generatePaymentCode();
    const payment = await this.prisma.payment.create({
      data: {
        code,
        invoiceId,
        studentId: invoice.studentId,
        amount: dto.amount,
        method: PaymentMethod.BANK_TRANSFER,
        status: PaymentStatus.PENDING,
        transactionId: dto.transactionId?.trim() || null,
        notes:
          dto.notes?.trim() ||
          `Xác nhận chuyển khoản VietQR cho hóa đơn ${invoice.code} (chờ đối soát)`,
      },
    });

    return {
      message:
        'Đã gửi thông tin chuyển khoản thành công. Thu ngân sẽ đối soát và xác nhận phiếu thu.',
      payment,
      invoice: await this.getInvoiceById(invoiceId),
    };
  }

  async approvePendingPayment(
    paymentId: string,
    actorId: string,
    notes?: string,
  ) {
    const payment = await this.prisma.payment.findUnique({
      where: { id: paymentId },
      include: { invoice: true },
    });
    if (!payment) {
      throw new NotFoundException(`Không tìm thấy giao dịch với ID: ${paymentId}`);
    }
    if (payment.status !== PaymentStatus.PENDING) {
      throw new ConflictException('Giao dịch này đã được xử lý trước đó.');
    }

    const invoice = payment.invoice;
    const payAmount = Number(payment.amount);
    if (payAmount > Number(invoice.balance)) {
      throw new BadRequestException(
        `Số tiền duyệt (${payAmount.toLocaleString('vi-VN')} VNĐ) vượt quá số dư còn lại của hóa đơn (${Number(invoice.balance).toLocaleString('vi-VN')} VNĐ).`,
      );
    }

    const newPaidAmount = Number(invoice.paidAmount) + payAmount;
    const newBalance = Math.max(0, Number(invoice.totalAmount) - newPaidAmount);
    const newStatus =
      newBalance <= 0 ? InvoiceStatus.PAID : InvoiceStatus.PARTIALLY_PAID;

    const updatedPayment = await this.prisma.$transaction(async (tx) => {
      const p = await tx.payment.update({
        where: { id: paymentId },
        data: {
          status: PaymentStatus.SUCCESS,
          receivedById: actorId,
          payDate: new Date(),
          notes: notes
            ? `${payment.notes || ''}\n[Thu ngân duyệt: ${notes}]`.trim()
            : payment.notes,
        },
      });

      await tx.invoice.update({
        where: { id: invoice.id },
        data: {
          paidAmount: newPaidAmount,
          balance: newBalance,
          status: newStatus,
        },
      });

      if (invoice.classId) {
        await tx.classStudent.updateMany({
          where: {
            classId: invoice.classId,
            studentId: invoice.studentId,
          },
          data: {
            tuitionPaid: { increment: payAmount },
          },
        });
      }
      return p;
    });

    const formattedAmount = payAmount.toLocaleString('vi-VN') + ' VNĐ';
    await this.notificationsService.createNotification(
      invoice.studentId,
      'Đã đối soát & xác nhận học phí chuyển khoản',
      `Khoản chuyển khoản ${formattedAmount} (Phiếu thu ${payment.code}) cho hóa đơn ${invoice.code} đã được xác nhận thành công.`,
      'TUITION' as any,
      { invoiceId: invoice.id, paymentId: payment.id, amount: payAmount },
    );

    return {
      message: 'Đã xác nhận khoản chuyển khoản và cập nhật công nợ học phí.',
      payment: updatedPayment,
      invoice: await this.getInvoiceById(invoice.id),
    };
  }

  async rejectPendingPayment(
    paymentId: string,
    actorId: string,
    reason?: string,
  ) {
    const payment = await this.prisma.payment.findUnique({
      where: { id: paymentId },
      include: { invoice: true },
    });
    if (!payment) {
      throw new NotFoundException(`Không tìm thấy giao dịch với ID: ${paymentId}`);
    }
    if (payment.status !== PaymentStatus.PENDING) {
      throw new ConflictException('Giao dịch này đã được xử lý trước đó.');
    }

    const updatedPayment = await this.prisma.payment.update({
      where: { id: paymentId },
      data: {
        status: PaymentStatus.FAILED,
        receivedById: actorId,
        notes: `${payment.notes || ''}\n[Từ chối đối soát: ${reason || 'Chưa nhận được khoản chuyển khoản tương ứng'}]`.trim(),
      },
    });

    await this.notificationsService.createNotification(
      payment.studentId,
      'Yêu cầu xác nhận chuyển khoản chưa khớp',
      `Phiếu báo chuyển khoản ${payment.code} của hóa đơn ${payment.invoice.code} chưa thể xác nhận. Lý do: ${reason || 'Chưa ghi nhận giao dịch trên sao kê'}.`,
      'TUITION' as any,
      { invoiceId: payment.invoiceId, paymentId: payment.id },
    );

    return {
      message: 'Đã từ chối yêu cầu xác nhận chuyển khoản.',
      payment: updatedPayment,
      invoice: await this.getInvoiceById(payment.invoiceId),
    };
  }

  // --------------------------------------------------------------------------
  // 3. MÃ KHUYẾN MÃI (PROMOTIONS)
  // --------------------------------------------------------------------------

  async togglePromotion(id: string) {
    const existing = await this.prisma.promotion.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundException(`Không tìm thấy mã khuyến mãi với ID: ${id}`);
    }
    return this.prisma.promotion.update({
      where: { id },
      data: { isActive: !existing.isActive },
    });
  }

  async createPromotion(dto: CreatePromotionDto) {
    const existing = await this.prisma.promotion.findUnique({
      where: { code: dto.code.toUpperCase() },
    });

    if (existing) {
      throw new ConflictException(`Mã khuyến mãi '${dto.code}' đã tồn tại`);
    }

    return this.prisma.promotion.create({
      data: {
        code: dto.code.toUpperCase(),
        name: dto.name,
        description: dto.description,
        type: dto.type || PromotionType.PERCENTAGE,
        value: dto.value,
        minOrderValue: dto.minOrderValue,
        maxDiscount: dto.maxDiscount,
        startDate: new Date(dto.startDate),
        endDate: new Date(dto.endDate),
        usageLimit: dto.usageLimit,
      },
    });
  }

  async getPromotions(isActive?: boolean) {
    const where: any = {};
    if (isActive !== undefined) {
      where.isActive = isActive;
    }
    return this.prisma.promotion.findMany({
      where,
      orderBy: { createdAt: 'desc' },
    });
  }

  async validatePromotion(dto: ValidatePromotionDto) {
    const result = await this.validatePromotionInternal(dto.code, dto.orderAmount);
    return {
      isValid: true,
      code: result.promotion.code,
      name: result.promotion.name,
      type: result.promotion.type,
      discountAmount: result.discountAmount,
      finalAmount: Math.max(0, dto.orderAmount - result.discountAmount),
    };
  }

  private async validatePromotionInternal(code: string, orderAmount: number) {
    const promotion = await this.prisma.promotion.findUnique({
      where: { code: code.toUpperCase() },
    });

    if (!promotion) {
      throw new NotFoundException(`Mã khuyến mãi '${code}' không tồn tại`);
    }

    if (!promotion.isActive) {
      throw new BadRequestException(`Mã khuyến mãi '${code}' hiện đang bị khóa`);
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const start = new Date(promotion.startDate);
    start.setHours(0, 0, 0, 0);

    const end = new Date(promotion.endDate);
    end.setHours(23, 59, 59, 999);

    if (today < start || today > end) {
      throw new BadRequestException(`Mã khuyến mãi '${code}' đã hết hạn hoặc chưa bắt đầu`);
    }

    if (promotion.usageLimit && promotion.usedCount >= promotion.usageLimit) {
      throw new BadRequestException(`Mã khuyến mãi '${code}' đã hết lượt sử dụng`);
    }

    if (promotion.minOrderValue && orderAmount < Number(promotion.minOrderValue)) {
      throw new BadRequestException(
        `Đơn hàng chưa đạt giá trị tối thiểu ${Number(promotion.minOrderValue).toLocaleString()} VNĐ để áp dụng mã`,
      );
    }

    let discountAmount = 0;
    if (promotion.type === PromotionType.PERCENTAGE) {
      discountAmount = (orderAmount * Number(promotion.value)) / 100;
      if (promotion.maxDiscount && discountAmount > Number(promotion.maxDiscount)) {
        discountAmount = Number(promotion.maxDiscount);
      }
    } else {
      discountAmount = Math.min(orderAmount, Number(promotion.value));
    }

    return {
      promotion,
      discountAmount,
    };
  }

  // --------------------------------------------------------------------------
  // 4. TÍCH HỢP CỔNG THANH TOÁN VNPAY (VNPAY INTEGRATION)
  // --------------------------------------------------------------------------

  createVNPayPaymentUrl(
    invoice: { id: string; code: string; balance: any; status: InvoiceStatus },
    ipAddr = '127.0.0.1',
    dto?: PayOnlineDto,
  ): string {
    const tmnCode = this.configService.get<string>('vnpay.tmnCode');
    const secretKey = this.configService.get<string>('vnpay.hashSecret');
    const vnpUrl =
      this.configService.get<string>('vnpay.url') ||
      'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
    const returnUrl =
      this.configService.get<string>('vnpay.returnUrl') ||
      'http://localhost:3000/api/v1/finance/payments/vnpay-return';

    if (!tmnCode || !secretKey) {
      throw new BadRequestException('Chưa cấu hình tài khoản VNPay trên hệ thống');
    }

    const amountInVND = Math.round(Number(invoice.balance));
    if (amountInVND <= 0) {
      throw new BadRequestException('Hóa đơn không còn dư nợ để thanh toán');
    }

    const now = new Date();
    const createDate = this.formatDateToYMDHMS(now);

    const vnpParams: Record<string, string> = {
      vnp_Version: '2.1.0',
      vnp_Command: 'pay',
      vnp_TmnCode: tmnCode,
      vnp_Locale: dto?.language || 'vn',
      vnp_CurrCode: 'VND',
      vnp_TxnRef: `${invoice.code}_${Date.now()}`,
      vnp_OrderInfo: `Thanh toan hoc phi hoa don ${invoice.code}`,
      vnp_OrderType: 'other',
      vnp_Amount: String(amountInVND * 100),
      vnp_ReturnUrl: returnUrl,
      vnp_IpAddr: ipAddr || '127.0.0.1',
      vnp_CreateDate: createDate,
    };

    if (dto?.bankCode) {
      vnpParams.vnp_BankCode = dto.bankCode;
    }

    // Sắp xếp các tham số theo bảng chữ cái A-Z
    const sortedKeys = Object.keys(vnpParams).sort();
    const signDataParts: string[] = [];

    for (const key of sortedKeys) {
      signDataParts.push(
        `${encodeURIComponent(key)}=${encodeURIComponent(vnpParams[key])}`,
      );
    }

    const signData = signDataParts.join('&');
    const hmac = crypto.createHmac('sha512', secretKey);
    const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest('hex');

    vnpParams.vnp_SecureHash = signed;

    const fullUrl = `${vnpUrl}?${signData}&vnp_SecureHash=${signed}`;
    return fullUrl;
  }

  async handleVNPayCallback(query: Record<string, any>) {
    const secretKey = this.configService.get<string>('vnpay.hashSecret');
    const secureHash = query.vnp_SecureHash;

    const cleanParams: Record<string, string> = {};
    for (const [k, v] of Object.entries(query)) {
      if (k !== 'vnp_SecureHash' && k !== 'vnp_SecureHashType') {
        cleanParams[k] = String(v);
      }
    }

    const sortedKeys = Object.keys(cleanParams).sort();
    const signDataParts: string[] = [];

    for (const key of sortedKeys) {
      signDataParts.push(
        `${encodeURIComponent(key)}=${encodeURIComponent(cleanParams[key])}`,
      );
    }

    const signData = signDataParts.join('&');
    const hmac = crypto.createHmac('sha512', secretKey || '');
    const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest('hex');

    if (secureHash !== signed) {
      this.logger.error('VNPay callback verification failed: checksum mismatch');
      throw new BadRequestException('Chữ ký xác thực VNPay không hợp lệ (Checksum Failed)');
    }

    const responseCode = query.vnp_ResponseCode;
    const txnRef = query.vnp_TxnRef; // Format: HD-2026-0001_1729304958
    const invoiceCode = txnRef ? txnRef.split('_')[0] : '';

    const invoice = await this.prisma.invoice.findUnique({
      where: { code: invoiceCode },
    });

    if (!invoice) {
      throw new NotFoundException(`Không tìm thấy hóa đơn ${invoiceCode}`);
    }

    if (responseCode === '00') {
      const amount = Number(query.vnp_Amount) / 100;
      const transactionId = query.vnp_TransactionNo;

      // Kiểm tra xem transactionId này đã được ghi nhận thanh toán chưa
      const existingPayment = await this.prisma.payment.findFirst({
        where: { transactionId: String(transactionId) },
      });

      if (!existingPayment) {
        await this.recordPayment(invoice.id, {
          amount,
          method: PaymentMethod.VNPAY,
          transactionId: String(transactionId),
          notes: `Thanh toán trực tuyến VNPay. Mã GD: ${transactionId}`,
        });
      }

      return {
        success: true,
        message: 'Giao dịch thanh toán qua VNPay thành công',
        invoiceCode,
        amount,
        transactionId,
      };
    } else {
      return {
        success: false,
        message: `Giao dịch thanh toán không thành công. Mã lỗi VNPay: ${responseCode}`,
        invoiceCode,
        responseCode,
      };
    }
  }

  // --------------------------------------------------------------------------
  // 5. CRON & AUTO-CHECKS (OVERDUE INVOICES)
  // --------------------------------------------------------------------------

  async checkOverdueInvoices() {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const pendingInvoices = await this.prisma.invoice.findMany({
      where: {
        status: { in: [InvoiceStatus.PENDING, InvoiceStatus.PARTIALLY_PAID] },
        dueDate: { lt: today },
      },
    });

    this.logger.log(`Phát hiện ${pendingInvoices.length} hóa đơn quá hạn cần cập nhật`);

    for (const inv of pendingInvoices) {
      await this.prisma.invoice.update({
        where: { id: inv.id },
        data: { status: InvoiceStatus.OVERDUE },
      });

      await this.notificationsService.notifyTuitionOverdue(
        inv.studentId,
        inv.code,
        Number(inv.balance),
      );
    }

    return { processedCount: pendingInvoices.length };
  }

  private formatDateToYMDHMS(date: Date): string {
    const yyyy = date.getFullYear();
    const mm = String(date.getMonth() + 1).padStart(2, '0');
    const dd = String(date.getDate()).padStart(2, '0');
    const hh = String(date.getHours()).padStart(2, '0');
    const min = String(date.getMinutes()).padStart(2, '0');
    const ss = String(date.getSeconds()).padStart(2, '0');
    return `${yyyy}${mm}${dd}${hh}${min}${ss}`;
  }
}
