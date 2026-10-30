import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, IsEnum, IsInt, Min } from 'class-validator';
import { Type } from 'class-transformer';
import { LeadSource, LeadStatus } from '@prisma/client';

export class QueryLeadsDto {
  @ApiPropertyOptional({ default: 1, description: 'Số trang hiện tại (bắt đầu từ 1)' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page: number = 1;

  @ApiPropertyOptional({ default: 10, description: 'Số bản ghi trên mỗi trang' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  limit: number = 10;

  @ApiPropertyOptional({ description: 'Từ khóa tìm kiếm theo tên, số điện thoại hoặc email' })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({ enum: LeadStatus, description: 'Lọc theo trạng thái tư vấn' })
  @IsOptional()
  @IsEnum(LeadStatus)
  status?: LeadStatus;

  @ApiPropertyOptional({ enum: LeadSource, description: 'Lọc theo nguồn tiếp nhận' })
  @IsOptional()
  @IsEnum(LeadSource)
  source?: LeadSource;

  @ApiPropertyOptional({ description: 'Lọc theo ID chi nhánh' })
  @IsOptional()
  @IsString()
  branchId?: string;

  @ApiPropertyOptional({ description: 'Lọc theo nhân viên học vụ phụ trách' })
  @IsOptional()
  @IsString()
  assignedStaffId?: string;
}
