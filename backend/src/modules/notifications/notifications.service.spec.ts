import { describe, it, expect, vi, beforeEach } from 'vitest';
import { NotificationsService } from './notifications.service.js';
import { PrismaService } from '../../database/prisma.service.js';
import { FirebaseService } from '../firebase/firebase.service.js';
import { MailService } from '../mail/mail.service.js';
import { NotificationType } from '@prisma/client';

describe('NotificationsService', () => {
  let service: NotificationsService;
  let prisma: any;
  let firebaseService: any;
  let mailService: any;

  beforeEach(() => {
    prisma = {
      notification: {
        create: vi.fn(),
        findMany: vi.fn(),
        findUnique: vi.fn(),
        update: vi.fn(),
        updateMany: vi.fn(),
        count: vi.fn(),
      },
      user: {
        findUnique: vi.fn(),
        findMany: vi.fn(),
        update: vi.fn(),
      },
    };

    firebaseService = {
      getMessaging: vi.fn().mockReturnValue({
        sendEachForMulticast: vi.fn().mockResolvedValue({
          successCount: 1,
          failureCount: 0,
        }),
      }),
    };

    mailService = {
      sendTuitionReminderEmail: vi.fn().mockResolvedValue(true),
    };

    service = new NotificationsService(
      prisma as unknown as PrismaService,
      firebaseService as unknown as FirebaseService,
      mailService as unknown as MailService,
    );
  });

  describe('createNotification', () => {
    it('should create notification in database and trigger FCM push if token exists', async () => {
      const mockNotification = {
        id: 'notif-1',
        userId: 'user-1',
        title: 'Thong bao hoc tap',
        body: 'Lop hoc sap bat dau',
        type: NotificationType.ACADEMIC,
        isRead: false,
      };

      prisma.notification.create.mockResolvedValue(mockNotification);
      prisma.user.findUnique.mockResolvedValue({
        id: 'user-1',
        fcmTokens: ['token-xyz'],
      });

      const result = await service.createNotification(
        'user-1',
        'Thong bao hoc tap',
        'Lop hoc sap bat dau',
        NotificationType.ACADEMIC,
      );

      expect(prisma.notification.create).toHaveBeenCalled();
      expect(result.id).toBe('notif-1');
    });
  });

  describe('getUserNotifications', () => {
    it('should return paginated notifications and unread count', async () => {
      prisma.notification.findMany.mockResolvedValue([
        { id: 'notif-1', title: 'T1' },
      ]);
      prisma.notification.count
        .mockResolvedValueOnce(1) // total
        .mockResolvedValueOnce(1); // unreadCount

      const result = await service.getUserNotifications('user-1', 1, 10);

      expect(result.items.length).toBe(1);
      expect(result.total).toBe(1);
      expect(result.unreadCount).toBe(1);
    });
  });

  describe('markAsRead', () => {
    it('should mark notification as read for user', async () => {
      prisma.notification.findUnique.mockResolvedValue({
        id: 'notif-1',
        userId: 'user-1',
        isRead: false,
      });
      prisma.notification.update.mockResolvedValue({
        id: 'notif-1',
        isRead: true,
      });

      const result = await service.markAsRead('user-1', 'notif-1');

      expect(prisma.notification.update).toHaveBeenCalledWith({
        where: { id: 'notif-1' },
        data: expect.objectContaining({ isRead: true }),
      });
      expect(result.isRead).toBe(true);
    });
  });

  describe('updateFcmToken', () => {
    it('should append new token if not present', async () => {
      prisma.user.findUnique.mockResolvedValue({
        id: 'user-1',
        fcmTokens: ['old-token'],
      });
      prisma.user.update.mockResolvedValue({});

      const result = await service.updateFcmToken('user-1', 'new-token');

      expect(prisma.user.update).toHaveBeenCalledWith({
        where: { id: 'user-1' },
        data: { fcmTokens: ['old-token', 'new-token'] },
      });
      expect(result.success).toBe(true);
    });
  });

  describe('Triggers', () => {
    it('should notify student and parents on absence', async () => {
      prisma.user.findUnique.mockResolvedValue({
        id: 'student-1',
        fullName: 'Nguyen Van A',
        fcmTokens: [],
        parents: [
          { parentId: 'parent-1', parent: { id: 'parent-1', fullName: 'Nguyen Van B' } },
        ],
      });
      prisma.notification.create.mockResolvedValue({ id: 'notif-x' });

      await service.notifyAbsence('student-1', 'Unit 1 Grammar', new Date('2026-10-20'));

      expect(prisma.notification.create).toHaveBeenCalledTimes(2);
    });

    it('should notify student on assignment deadline', async () => {
      prisma.notification.create.mockResolvedValue({ id: 'notif-x' });
      prisma.user.findUnique.mockResolvedValue({ id: 'student-1', fcmTokens: [] });

      await service.notifyAssignmentDeadline('student-1', 'Homework 01', new Date());

      expect(prisma.notification.create).toHaveBeenCalled();
    });

    it('should notify tuition overdue and send email to parents', async () => {
      prisma.user.findUnique.mockResolvedValue({
        id: 'student-1',
        fullName: 'Nguyen Van A',
        fcmTokens: [],
        parents: [
          {
            parentId: 'parent-1',
            parent: { id: 'parent-1', fullName: 'Nguyen Van B', email: 'parent@example.com' },
          },
        ],
      });
      prisma.notification.create.mockResolvedValue({ id: 'notif-x' });

      await service.notifyTuitionOverdue('student-1', 'HD-2026-0001', 3500000);

      expect(prisma.notification.create).toHaveBeenCalledTimes(2);
      expect(mailService.sendTuitionReminderEmail).toHaveBeenCalled();
    });
  });
});
