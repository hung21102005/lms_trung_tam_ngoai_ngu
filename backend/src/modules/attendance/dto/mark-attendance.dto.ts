import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsEnum,
  IsArray,
  IsBoolean,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import { AttendanceStatus, MakeupStatus } from '@prisma/client';

export class StudentAttendanceItemDto {
  @ApiProperty({ description: 'ID của học viên', example: 'uuid-student-1' })
  @IsString()
  @IsNotEmpty()
  studentId: string;

  @ApiProperty({
    enum: AttendanceStatus,
    description: 'Trạng thái điểm danh',
    example: AttendanceStatus.PRESENT,
  })
  @IsEnum(AttendanceStatus)
  status: AttendanceStatus;

  @ApiPropertyOptional({
    description: 'Thời điểm điểm danh / vào lớp',
    example: '2026-10-18T18:05:00.000Z',
  })
  @IsOptional()
  checkInTime?: string;

  @ApiPropertyOptional({
    description: 'Ghi chú (lý do muộn/vắng)',
    example: 'Xin phép vắng vì bị cảm',
  })
  @IsOptional()
  @IsString()
  notes?: string;
}

export class BatchMarkAttendanceDto {
  @ApiProperty({
    type: [StudentAttendanceItemDto],
    description: 'Danh sách học viên và trạng thái điểm danh',
  })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => StudentAttendanceItemDto)
  students: StudentAttendanceItemDto[];

  @ApiPropertyOptional({ description: 'Lưu điểm danh và khóa buổi học trong cùng giao dịch' })
  @IsOptional()
  @IsBoolean()
  lock?: boolean;
}

export class UpdateAttendanceDto {
  @ApiPropertyOptional({
    enum: AttendanceStatus,
    description: 'Trạng thái điểm danh',
    example: AttendanceStatus.PRESENT,
  })
  @IsOptional()
  @IsEnum(AttendanceStatus)
  status?: AttendanceStatus;

  @ApiPropertyOptional({
    description: 'Thời gian check-in',
    example: '2026-10-18T18:00:00.000Z',
  })
  @IsOptional()
  checkInTime?: string;

  @ApiPropertyOptional({
    description: 'Ghi chú',
    example: 'Đã bổ sung giấy xin phép',
  })
  @IsOptional()
  @IsString()
  notes?: string;
}

export class CreateMakeupRequestDto {
  @ApiProperty({
    description: 'ID buổi học gốc đã vắng',
    example: 'uuid-original-session',
  })
  @IsString()
  @IsNotEmpty()
  originalSessionId: string;

  @ApiPropertyOptional({
    description: 'ID buổi học mục tiêu muốn học bù (nếu đã chọn)',
    example: 'uuid-target-session',
  })
  @IsOptional()
  @IsString()
  targetSessionId?: string;

  @ApiPropertyOptional({
    description: 'Lý do đăng ký học bù',
    example: 'Trùng lịch thi học kỳ ở trường',
  })
  @IsOptional()
  @IsString()
  reason?: string;
}

export class UpdateMakeupRequestDto {
  @ApiProperty({
    enum: MakeupStatus,
    description: 'Trạng thái phê duyệt (APPROVED hoặc REJECTED)',
    example: MakeupStatus.APPROVED,
  })
  @IsEnum(MakeupStatus)
  status: MakeupStatus;

  @ApiPropertyOptional({
    description: 'Ghi chú duyệt hoặc lý do từ chối',
    example: 'Đồng ý chuyển sang lớp IELTS-F-02 ca T3-T5',
  })
  @IsOptional()
  @IsString()
  reason?: string;
}

export class QueryMakeupRequestsDto {
  @ApiPropertyOptional({
    enum: MakeupStatus,
    description: 'Lọc theo trạng thái yêu cầu',
  })
  @IsOptional()
  @IsEnum(MakeupStatus)
  status?: MakeupStatus;

  @ApiPropertyOptional({
    description: 'Lọc theo ID học viên',
  })
  @IsOptional()
  @IsString()
  studentId?: string;
}
