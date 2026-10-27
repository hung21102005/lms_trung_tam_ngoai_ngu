import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsEmail,
  IsOptional,
  IsEnum,
  IsDateString,
  IsNumber,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';
import { Gender } from '@prisma/client';

export class UpdateUserDto {
  @ApiPropertyOptional({ description: 'Họ và tên', example: 'Trần Văn Nam' })
  @IsOptional()
  @IsString()
  fullName?: string;

  @ApiPropertyOptional({ description: 'Email', example: 'nam.tran@gmail.com' })
  @IsOptional()
  @IsEmail({}, { message: 'Định dạng email không hợp lệ' })
  email?: string;

  @ApiPropertyOptional({ description: 'Số điện thoại', example: '0901234567' })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional({ description: 'URL ảnh đại diện' })
  @IsOptional()
  @IsString()
  avatarUrl?: string;

  @ApiPropertyOptional({ description: 'Giới tính', enum: Gender })
  @IsOptional()
  @IsEnum(Gender)
  gender?: Gender;

  @ApiPropertyOptional({ description: 'Ngày sinh (ISO-8601)' })
  @IsOptional()
  @IsDateString()
  dateOfBirth?: string;

  @ApiPropertyOptional({ description: 'Địa chỉ thường trú' })
  @IsOptional()
  @IsString()
  address?: string;

  @ApiPropertyOptional({ description: 'ID chi nhánh' })
  @IsOptional()
  @IsString()
  branchId?: string;

  // Student profile fields
  @ApiPropertyOptional({ description: 'Trình độ đầu vào' })
  @IsOptional()
  @IsString()
  entryLevel?: string;

  @ApiPropertyOptional({ description: 'Mục tiêu học tập' })
  @IsOptional()
  @IsString()
  targetLevel?: string;

  @ApiPropertyOptional({ description: 'Trường học' })
  @IsOptional()
  @IsString()
  schoolName?: string;

  @ApiPropertyOptional({ description: 'Ghi chú học vụ' })
  @IsOptional()
  @IsString()
  notes?: string;

  // Teacher profile fields
  @ApiPropertyOptional({ description: 'Bằng cấp / Chứng chỉ' })
  @IsOptional()
  @IsString()
  degrees?: string;

  @ApiPropertyOptional({ description: 'Chuyên môn giảng dạy' })
  @IsOptional()
  @IsString()
  specialties?: string;

  @ApiPropertyOptional({ description: 'Tiểu sử' })
  @IsOptional()
  @IsString()
  bio?: string;

  @ApiPropertyOptional({ description: 'Thù lao theo giờ' })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  hourlyRate?: number;
}
