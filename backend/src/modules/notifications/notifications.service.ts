import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service.js';
import { FirebaseService } from '../firebase/firebase.service.js';
import { MailService } from '../mail/mail.service.js';
import { NotificationType } from '@prisma/client';
import { SendNotificationDto } from './dto/index.js';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly firebaseService: FirebaseService,
    private readonly mailService: MailService,
  ) {}

  async createNotification(
    userId: string,
    title: string,
    body: string,
    type: NotificationType = NotificationType.SYSTEM,
    data?: Record<string, any>,
  ) {
    const notification = await this.prisma.notification.create({
      data: {
        userId,
        title,
        body,
        type,
        data: data || undefined,
      },
    });

    // Bắn push notification qua Firebase Cloud Messaging nếu user có FCM Token
    try {
      await this.pushToUser(userId, title, body, data);
    } catch (err) {
      this.logger.warn(`Không thể gửi FCM push notification cho user ${userId}:`, err);
    }

    return notification;
  }

  private async pushToUser(
    userId: string,
    title: string,
    body: string,
    data?: Record<string, any>,
  ) {
    const messaging = this.firebaseService.getMessaging();
    if (!messaging) return;

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { fcmTokens: true },
    });

    if (!user || !user.fcmTokens || user.fcmTokens.length === 0) return;

    const stringData: Record<string, string> = {};
    if (data) {
      for (const [k, v] of Object.entries(data)) {
        stringData[k] = typeof v === 'string' ? v : JSON.stringify(v);
      }
    }

    const response = await messaging.sendEachForMulticast({
      tokens: user.fcmTokens,
      notification: {
        title,
        body,
      },
      data: stringData,
    });

    this.logger.log(
      `Đã gửi push notification cho user ${userId}: ${response.successCount} thành công, ${response.failureCount} thất bại`,
    );
  }

  async getUserNotifications(userId: string, page = 1, limit = 20, isRead?: boolean) {
    const where: any = { userId };
    if (isRead !== undefined) {
      where.isRead = isRead;
    }

    const [items, total, unreadCount] = await Promise.all([
      this.prisma.notification.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.notification.count({ where }),
      this.prisma.notification.count({
        where: { userId, isRead: false },
      }),
    ]);

    return {
      items,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit) || 1,
      unreadCount,
    };
  }

  async markAsRead(userId: string, notificationId: string) {
    const notification = await this.prisma.notification.findUnique({
      where: { id: notificationId },
    });

    if (!notification || notification.userId !== userId) {
      throw new NotFoundException('Không tìm thấy thông báo hoặc bạn không có quyền');
    }

    return this.prisma.notification.update({
      where: { id: notificationId },
      data: {
        isRead: true,
        readAt: new Date(),
      },
    });
  }

  async markAllAsRead(userId: string) {
    return this.prisma.notification.updateMany({
      where: {
        userId,
        isRead: false,
      },
      data: {
        isRead: true,
        readAt: new Date(),
      },
    });
  }

  async getUnreadCount(userId: string): Promise<number> {
    return this.prisma.notification.count({
      where: {
        userId,
        isRead: false,
      },
    });
  }

  async updateFcmToken(userId: string, token: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { fcmTokens: true },
    });

    if (!user) {
      throw new NotFoundException(`Không tìm thấy người dùng với ID: ${userId}`);
    }

    const currentTokens = user.fcmTokens || [];
    if (!currentTokens.includes(token)) {
      await this.prisma.user.update({
        where: { id: userId },
        data: {
          fcmTokens: [...currentTokens, token],
        },
      });
    }

    return { success: true, message: 'Cập nhật FCM Token thành công' };
  }

  async sendBroadcast(dto: SendNotificationDto) {
    let targetUserIds: string[] = [];

    if (dto.userId) {
      targetUserIds = [dto.userId];
    } else if (dto.role) {
      const users = await this.prisma.user.findMany({
        where: {
          userRoles: {
            some: {
              role: {
                code: dto.role,
              },
            },
          },
        },
        select: { id: true },
      });
      targetUserIds = users.map((u) => u.id);
    } else {
      const users = await this.prisma.user.findMany({
        where: { status: 'ACTIVE' },
        select: { id: true },
      });
      targetUserIds = users.map((u) => u.id);
    }

    const notifications = await Promise.all(
      targetUserIds.map((userId) =>
        this.createNotification(
          userId,
          dto.title,
          dto.body,
          dto.type || NotificationType.SYSTEM,
          dto.data,
        ),
      ),
    );

    return {
      success: true,
      sentCount: notifications.length,
    };
  }

  // ============================================================================
  // TRIGGERS TỰ ĐỘNG (Absence, Deadline, Tuition, Exam)
  // ============================================================================

  async notifyAbsence(studentId: string, sessionTitle: string, sessionDate: Date) {
    const dateStr = sessionDate.toISOString().split('T')[0];
    const student = await this.prisma.user.findUnique({
      where: { id: studentId },
      include: {
        parents: {
          include: { parent: true },
        },
      },
    });

    if (!student) return;

    // 1. Thông báo cho học viên
    await this.createNotification(
      studentId,
      'Thông báo vắng học',
      `Bạn đã được ghi nhận vắng mặt trong buổi học "${sessionTitle}" ngày ${dateStr}. Vui lòng liên hệ trung tâm nếu bạn cần đăng ký học bù.`,
      NotificationType.ATTENDANCE,
      { sessionTitle, date: dateStr, studentId },
    );

    // 2. Thông báo cho phụ huynh của học viên (nếu có)
    for (const rel of student.parents) {
      if (rel.parent) {
        await this.createNotification(
          rel.parentId,
          'Thông báo vắng học của con',
          `Học viên ${student.fullName} đã vắng mặt trong buổi học "${sessionTitle}" ngày ${dateStr}.`,
          NotificationType.ATTENDANCE,
          { sessionTitle, date: dateStr, studentId, studentName: student.fullName },
        );
      }
    }
  }

  async notifyAssignmentDeadline(studentId: string, assignmentTitle: string, deadline: Date) {
    const dateStr = deadline.toLocaleString('vi-VN');
    await this.createNotification(
      studentId,
      'Nhắc nhở sắp đến hạn nộp bài tập',
      `Bài tập "${assignmentTitle}" sẽ hết hạn vào ${dateStr}. Hãy hoàn thành và nộp bài đúng hạn nhé!`,
      NotificationType.ACADEMIC,
      { assignmentTitle, deadline: deadline.toISOString() },
    );
  }

  async notifyTuitionOverdue(studentId: string, invoiceCode: string, amount: number) {
    const formattedAmount = Number(amount).toLocaleString('vi-VN') + ' VNĐ';
    const student = await this.prisma.user.findUnique({
      where: { id: studentId },
      include: {
        parents: {
          include: { parent: true },
        },
      },
    });

    if (!student) return;

    const message = `Hóa đơn học phí ${invoiceCode} với số tiền ${formattedAmount} đã quá hạn thanh toán. Vui lòng hoàn tất thanh toán để đảm bảo tiến độ học tập.`;

    await this.createNotification(
      studentId,
      'Nhắc nhở học phí quá hạn',
      message,
      NotificationType.TUITION,
      { invoiceCode, amount },
    );

    // Bắn thông báo và email cho phụ huynh
    for (const rel of student.parents) {
      if (rel.parent) {
        await this.createNotification(
          rel.parentId,
          `Học phí của con (${student.fullName}) quá hạn`,
          `Hóa đơn học phí ${invoiceCode} của học viên ${student.fullName} với số tiền ${formattedAmount} đã quá hạn.`,
          NotificationType.TUITION,
          { invoiceCode, amount, studentId },
        );

        if (rel.parent.email) {
          try {
            await this.mailService.sendTuitionReminderEmail?.(
              rel.parent.email,
              rel.parent.fullName,
              invoiceCode,
              formattedAmount,
            );
          } catch (e) {
            this.logger.warn(`Không thể gửi email nhắc học phí cho phụ huynh: ${e}`);
          }
        }
      }
    }
  }

  async notifyExamResult(studentId: string, examTitle: string, score: number, isPassed: boolean) {
    const statusText = isPassed ? 'ĐẠT' : 'CHƯA ĐẠT';
    await this.createNotification(
      studentId,
      'Kết quả bài thi đã có',
      `Kết quả bài thi "${examTitle}": ${score} điểm (${statusText}). Hãy vào ứng dụng để xem chi tiết!`,
      NotificationType.EXAM,
      { examTitle, score, isPassed },
    );
  }
}
