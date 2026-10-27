import { IsString, IsNotEmpty, IsOptional, IsEnum } from 'class-validator';
import { NotificationType } from '@prisma/client';

export class SendNotificationDto {
  @IsString()
  @IsOptional()
  userId?: string;

  @IsString()
  @IsOptional()
  role?: string;

  @IsString()
  @IsNotEmpty({ message: 'Tiêu đề thông báo không được để trống' })
  title!: string;

  @IsString()
  @IsNotEmpty({ message: 'Nội dung thông báo không được để trống' })
  body!: string;

  @IsEnum(NotificationType, { message: 'Loại thông báo không hợp lệ' })
  @IsOptional()
  type?: NotificationType;

  @IsOptional()
  data?: Record<string, any>;
}
