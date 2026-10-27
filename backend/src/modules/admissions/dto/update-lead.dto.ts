import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, IsEmail, IsEnum } from 'class-validator';
import { LeadSource, LeadStatus } from '@prisma/client';

export class UpdateLeadDto {
  @ApiPropertyOptional({ example: 'Nguyễn Văn An' })
  @IsOptional()
  @IsString()
  fullName?: string;

  @ApiPropertyOptional({ example: '0988776655' })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional({ example: 'nguyenvanan@gmail.com' })
  @IsOptional()
  @IsEmail({}, { message: 'Định dạng email không hợp lệ' })
  email?: string;

  @ApiPropertyOptional({ example: 'IELTS Intensive 6.5' })
  @IsOptional()
  @IsString()
  targetCourse?: string;

  @ApiPropertyOptional({ enum: LeadSource })
  @IsOptional()
  @IsEnum(LeadSource)
  source?: LeadSource;

  @ApiPropertyOptional({
    enum: LeadStatus,
    description: 'Trạng thái tư vấn: NEW, CONTACTED, TEST_SCHEDULED, ENROLLED, CANCELLED',
  })
  @IsOptional()
  @IsEnum(LeadStatus, { message: 'Trạng thái lead không hợp lệ' })
  status?: LeadStatus;

  @ApiPropertyOptional({ example: 'Đã gọi tư vấn, hẹn ngày 20/10 kiểm tra xếp lớp' })
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiPropertyOptional({ example: 'uuid-chi-nhanh' })
  @IsOptional()
  @IsString()
  branchId?: string;

  @ApiPropertyOptional({ example: 'uuid-nhan-vien-hoc-vu' })
  @IsOptional()
  @IsString()
  assignedStaffId?: string;
}
