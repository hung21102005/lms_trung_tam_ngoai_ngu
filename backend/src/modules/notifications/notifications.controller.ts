import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Put,
  Query,
  Request,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { RolesGuard } from '../auth/guards/roles.guard.js';
import { Roles } from '../auth/decorators/roles.decorator.js';
import { NotificationsService } from './notifications.service.js';
import { SendNotificationDto, UpdateFcmTokenDto } from './dto/index.js';

@ApiTags('Notifications (Thông báo)')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller()
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get(['notifications', 'my/notifications'])
  @ApiOperation({ summary: 'Lấy danh sách thông báo của người dùng hiện tại' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'isRead', required: false, type: Boolean })
  async getMyNotifications(
    @Request() req: any,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @Query('isRead') isRead?: string,
  ) {
    const pageNum = page ? parseInt(page, 10) : 1;
    const limitNum = limit ? parseInt(limit, 10) : 20;
    const isReadBool = isRead !== undefined ? isRead === 'true' : undefined;

    return this.notificationsService.getUserNotifications(
      req.user.id,
      pageNum,
      limitNum,
      isReadBool,
    );
  }

  @Get(['notifications/unread-count', 'my/notifications/unread-count'])
  @ApiOperation({ summary: 'Lấy số lượng thông báo chưa đọc (badge count)' })
  async getUnreadCount(@Request() req: any) {
    const count = await this.notificationsService.getUnreadCount(req.user.id);
    return { count };
  }

  @Patch('notifications/:id/read')
  @ApiOperation({ summary: 'Đánh dấu một thông báo là đã đọc' })
  async markAsRead(@Request() req: any, @Param('id') id: string) {
    return this.notificationsService.markAsRead(req.user.id, id);
  }

  @Post('notifications/read-all')
  @ApiOperation({ summary: 'Đánh dấu tất cả thông báo là đã đọc' })
  async markAllAsRead(@Request() req: any) {
    return this.notificationsService.markAllAsRead(req.user.id);
  }

  @Put(['notifications/fcm-token', 'my/fcm-token'])
  @ApiOperation({ summary: 'Đăng ký hoặc cập nhật thiết bị FCM token để nhận push' })
  async updateFcmToken(@Request() req: any, @Body() dto: UpdateFcmTokenDto) {
    return this.notificationsService.updateFcmToken(req.user.id, dto.token);
  }

  @Post('notifications/send')
  @Roles('super_admin', 'branch_admin', 'academic_staff')
  @ApiOperation({ summary: 'Gửi thông báo (broadcast hoặc theo user/vai trò)' })
  async sendNotification(@Body() dto: SendNotificationDto) {
    return this.notificationsService.sendBroadcast(dto);
  }
}
