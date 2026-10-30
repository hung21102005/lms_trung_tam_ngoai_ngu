import { describe, it, expect, vi, beforeEach } from 'vitest';
import { FinanceService } from './finance.service.js';
import { PrismaService } from '../../database/prisma.service.js';
import { ConfigService } from '@nestjs/config';
import { NotificationsService } from '../notifications/notifications.service.js';
import {
  InvoiceStatus,
  PaymentMethod,
  PaymentStatus,
  PromotionType,
} from '@prisma/client';
import * as crypto from 'crypto';

describe('FinanceService', () => {
  let service: FinanceService;
  let prisma: any;
  let configService: any;
  let notificationsService: any;

  beforeEach(() => {
    prisma = {
      invoice: {
        create: vi.fn(),
        findMany: vi.fn(),
        findUnique: vi.fn(),
        findFirst: vi.fn(),
        update: vi.fn(),
        count: vi.fn().mockResolvedValue(0),
        aggregate: vi.fn().mockResolvedValue({
          _sum: { totalAmount: 5000000, paidAmount: 2000000, balance: 3000000 },
        }),
      },
      payment: {
        create: vi.fn(),
        findMany: vi.fn(),
        findFirst: vi.fn(),
        count: vi.fn().mockResolvedValue(0),
      },
      promotion: {
        create: vi.fn(),
        findMany: vi.fn(),
        findUnique: vi.fn(),
        update: vi.fn(),
      },
      user: {
        findUnique: vi.fn(),
      },
      class: {
        findUnique: vi.fn(),
      },
      classStudent: {
        updateMany: vi.fn(),
      },
    };

    configService = {
      get: vi.fn((key: string) => {
        if (key === 'vnpay.tmnCode') return 'TESTTMN';
        if (key === 'vnpay.hashSecret') return 'TESTSECRETKEY123';
        if (key === 'vnpay.url') return 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
        if (key === 'vnpay.returnUrl') return 'http://localhost:3000/api/v1/finance/payments/vnpay-return';
        return null;
      }),
    };

    notificationsService = {
      createNotification: vi.fn().mockResolvedValue({}),
      notifyTuitionOverdue: vi.fn().mockResolvedValue({}),
    };

    service = new FinanceService(
      prisma as unknown as PrismaService,
      configService as unknown as ConfigService,
      notificationsService as unknown as NotificationsService,
    );
  });

  describe('createInvoice', () => {
    it('should create an invoice with calculated balance and status PENDING', async () => {
      prisma.user.findUnique.mockResolvedValue({ id: 'student-1' });
      prisma.invoice.create.mockImplementation((args: any) => ({
        id: 'inv-1',
        ...args.data,
      }));

      const result = await service.createInvoice({
        studentId: 'student-1',
        title: 'Hoc phi IELTS Foundation',
        subtotal: 5000000,
        discount: 500000,
      });

      expect(prisma.invoice.create).toHaveBeenCalled();
      expect(result.subtotal).toBe(5000000);
      expect(result.discount).toBe(500000);
      expect(result.totalAmount).toBe(4500000);
      expect(result.balance).toBe(4500000);
      expect(result.status).toBe(InvoiceStatus.PENDING);
      expect(notificationsService.createNotification).toHaveBeenCalled();
    });

    it('should apply valid promotion code with percentage discount', async () => {
      prisma.user.findUnique.mockResolvedValue({ id: 'student-1' });
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - 2);
      const endDate = new Date();
      endDate.setDate(endDate.getDate() + 5);

      prisma.promotion.findUnique.mockResolvedValue({
        id: 'promo-1',
        code: 'PROMO10',
        name: 'Giam 10%',
        isActive: true,
        type: PromotionType.PERCENTAGE,
        value: 10,
        startDate,
        endDate,
        usedCount: 0,
        usageLimit: 100,
        maxDiscount: 1000000,
      });

      prisma.invoice.create.mockImplementation((args: any) => ({
        id: 'inv-1',
        ...args.data,
      }));

      const result = await service.createInvoice({
        studentId: 'student-1',
        title: 'Hoc phi IELTS Foundation',
        subtotal: 5000000,
        promotionCode: 'PROMO10',
      });

      expect(result.discount).toBe(500000); // 10% of 5,000,000
      expect(result.totalAmount).toBe(4500000);
      expect(prisma.promotion.update).toHaveBeenCalled();
    });
  });

  describe('recordPayment', () => {
    it('should transition invoice to PARTIALLY_PAID on partial payment', async () => {
      prisma.invoice.findUnique.mockResolvedValue({
        id: 'inv-1',
        code: 'HD-2026-0001',
        studentId: 'student-1',
        classId: 'class-1',
        totalAmount: 5000000,
        paidAmount: 0,
        balance: 5000000,
        status: InvoiceStatus.PENDING,
      });

      prisma.payment.create.mockResolvedValue({
        id: 'pay-1',
        code: 'PT-2026-0001',
        amount: 2000000,
        method: PaymentMethod.CASH,
      });

      prisma.invoice.update.mockResolvedValue({
        id: 'inv-1',
        paidAmount: 2000000,
        balance: 3000000,
        status: InvoiceStatus.PARTIALLY_PAID,
      });

      const result = await service.recordPayment('inv-1', {
        amount: 2000000,
        method: PaymentMethod.CASH,
      });

      expect(prisma.payment.create).toHaveBeenCalled();
      expect(prisma.invoice.update).toHaveBeenCalledWith({
        where: { id: 'inv-1' },
        data: {
          paidAmount: 2000000,
          balance: 3000000,
          status: InvoiceStatus.PARTIALLY_PAID,
        },
      });
      expect(prisma.classStudent.updateMany).toHaveBeenCalled();
      expect(result.invoice.status).toBe(InvoiceStatus.PARTIALLY_PAID);
    });

    it('should transition invoice to PAID when fully settled', async () => {
      prisma.invoice.findUnique.mockResolvedValue({
        id: 'inv-1',
        code: 'HD-2026-0001',
        studentId: 'student-1',
        totalAmount: 5000000,
        paidAmount: 2000000,
        balance: 3000000,
        status: InvoiceStatus.PARTIALLY_PAID,
      });

      prisma.payment.create.mockResolvedValue({
        id: 'pay-2',
        code: 'PT-2026-0002',
        amount: 3000000,
        method: PaymentMethod.BANK_TRANSFER,
      });

      prisma.invoice.update.mockResolvedValue({
        id: 'inv-1',
        paidAmount: 5000000,
        balance: 0,
        status: InvoiceStatus.PAID,
      });

      const result = await service.recordPayment('inv-1', {
        amount: 3000000,
        method: PaymentMethod.BANK_TRANSFER,
      });

      expect(prisma.invoice.update).toHaveBeenCalledWith({
        where: { id: 'inv-1' },
        data: {
          paidAmount: 5000000,
          balance: 0,
          status: InvoiceStatus.PAID,
        },
      });
      expect(result.invoice.status).toBe(InvoiceStatus.PAID);
    });

    it('should reject payment exceeding remaining balance', async () => {
      prisma.invoice.findUnique.mockResolvedValue({
        id: 'inv-1',
        totalAmount: 5000000,
        paidAmount: 4000000,
        balance: 1000000,
        status: InvoiceStatus.PARTIALLY_PAID,
      });

      await expect(
        service.recordPayment('inv-1', {
          amount: 2000000,
          method: PaymentMethod.CASH,
        }),
      ).rejects.toThrow('lớn hơn số dư còn lại');
    });
  });

  describe('VNPay Integration', () => {
    it('should generate signed VNPay payment URL with HMAC-SHA512 checksum', () => {
      const mockInvoice = {
        id: 'inv-1',
        code: 'HD-2026-0001',
        balance: 3000000,
        status: InvoiceStatus.PENDING,
      };

      const url = service.createVNPayPaymentUrl(mockInvoice, '127.0.0.1');

      expect(url).toContain('https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?');
      expect(url).toContain('vnp_TmnCode=TESTTMN');
      expect(url).toContain('vnp_Amount=300000000');
      expect(url).toContain('vnp_SecureHash=');
    });

    it('should verify valid VNPay callback signature and record payment', async () => {
      const secretKey = 'TESTSECRETKEY123';
      const params: Record<string, string> = {
        vnp_Amount: '300000000',
        vnp_BankCode: 'NCB',
        vnp_Command: 'pay',
        vnp_CreateDate: '20261019120000',
        vnp_CurrCode: 'VND',
        vnp_OrderInfo: 'Thanh toan hoc phi',
        vnp_ResponseCode: '00',
        vnp_TmnCode: 'TESTTMN',
        vnp_TransactionNo: '14567890',
        vnp_TxnRef: 'HD-2026-0001_1729304958',
        vnp_Version: '2.1.0',
      };

      const sortedKeys = Object.keys(params).sort();
      const signData = sortedKeys
        .map((k) => `${encodeURIComponent(k)}=${encodeURIComponent(params[k])}`)
        .join('&');
      const hash = crypto
        .createHmac('sha512', secretKey)
        .update(Buffer.from(signData, 'utf-8'))
        .digest('hex');

      params.vnp_SecureHash = hash;

      prisma.invoice.findUnique.mockResolvedValue({
        id: 'inv-1',
        code: 'HD-2026-0001',
        studentId: 'student-1',
        totalAmount: 3000000,
        paidAmount: 0,
        balance: 3000000,
        status: InvoiceStatus.PENDING,
      });

      prisma.payment.findFirst.mockResolvedValue(null);
      prisma.payment.create.mockResolvedValue({
        id: 'pay-vnpay',
        amount: 3000000,
        method: PaymentMethod.VNPAY,
      });
      prisma.invoice.update.mockResolvedValue({
        id: 'inv-1',
        status: InvoiceStatus.PAID,
      });

      const callbackResult = await service.handleVNPayCallback(params);

      expect(callbackResult.success).toBe(true);
      expect(callbackResult.invoiceCode).toBe('HD-2026-0001');
      expect(prisma.payment.create).toHaveBeenCalled();
    });

    it('should reject tampered checksum in VNPay callback', async () => {
      const params = {
        vnp_Amount: '300000000',
        vnp_ResponseCode: '00',
        vnp_TxnRef: 'HD-2026-0001_1729304958',
        vnp_SecureHash: 'invalid_tampered_hash_12345',
      };

      await expect(service.handleVNPayCallback(params)).rejects.toThrow(
        'Chữ ký xác thực VNPay không hợp lệ',
      );
    });
  });

  describe('checkOverdueInvoices', () => {
    it('should mark past due invoices as OVERDUE and notify', async () => {
      prisma.invoice.findMany.mockResolvedValue([
        {
          id: 'inv-overdue',
          code: 'HD-2026-0009',
          studentId: 'student-1',
          balance: 2500000,
          status: InvoiceStatus.PENDING,
        },
      ]);
      prisma.invoice.update.mockResolvedValue({});

      const result = await service.checkOverdueInvoices();

      expect(result.processedCount).toBe(1);
      expect(prisma.invoice.update).toHaveBeenCalledWith({
        where: { id: 'inv-overdue' },
        data: { status: InvoiceStatus.OVERDUE },
      });
      expect(notificationsService.notifyTuitionOverdue).toHaveBeenCalled();
    });
  });
});
