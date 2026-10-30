import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, IsUUID, IsEnum, Matches, IsDateString } from 'class-validator';
import { SessionStatus } from '@prisma/client';

export class UpdateClassSessionDto {
  @ApiPropertyOptional({
    example: 'Buổi 3: Luyện phát âm phụ âm kép & Mini test',
    description: 'Tiêu đề buổi học',
  })
  @IsOptional()
  @IsString()
  title?: string;

  @ApiPropertyOptional({
    example: '2026-11-10',
    description: 'Ngày diễn ra buổi học (YYYY-MM-DD)',
  })
  @IsOptional()
  @IsDateString({}, { message: 'Định dạng ngày không hợp lệ (YYYY-MM-DD)' })
  date?: string;

  @ApiPropertyOptional({
    example: '18:00',
    description: 'Giờ bắt đầu học (HH:mm)',
  })
  @IsOptional()
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, { message: 'Định dạng giờ bắt đầu không hợp lệ (HH:mm)' })
  startTime?: string;

  @ApiPropertyOptional({
    example: '19:30',
    description: 'Giờ kết thúc học (HH:mm)',
  })
  @IsOptional()
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, { message: 'Định dạng giờ kết thúc không hợp lệ (HH:mm)' })
  endTime?: string;

  @ApiPropertyOptional({
    example: 'uuid-room',
    description: 'ID phòng học thay đổi',
  })
  @IsOptional()
  @IsUUID('4', { message: 'roomId phải là định dạng UUID' })
  roomId?: string;

  @ApiPropertyOptional({
    example: 'uuid-teacher',
    description: 'ID giáo viên đứng lớp / giáo viên dạy thay',
  })
  @IsOptional()
  @IsUUID('4', { message: 'teacherId phải là định dạng UUID' })
  teacherId?: string;

  @ApiPropertyOptional({
    enum: SessionStatus,
    description: 'Trạng thái buổi học',
  })
  @IsOptional()
  @IsEnum(SessionStatus, { message: 'Trạng thái buổi học không hợp lệ' })
  status?: SessionStatus;

  @ApiPropertyOptional({
    example: 'uuid-lesson',
    description: 'ID bài học trong giáo trình',
  })
  @IsOptional()
  @IsUUID('4', { message: 'lessonId phải là định dạng UUID' })
  lessonId?: string;

  @ApiPropertyOptional({
    example: 'Đổi phòng do máy chiếu phòng cũ bảo trì',
    description: 'Ghi chú buổi học',
  })
  @IsOptional()
  @IsString()
  notes?: string;
}
