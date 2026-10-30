import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, IsEnum, IsInt, Min, Max } from 'class-validator';
import { Type } from 'class-transformer';
import { UserStatus } from '@prisma/client';

export class QueryUsersDto {
  @ApiPropertyOptional({ description: 'Số trang (bắt đầu từ 1)', default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page: number = 1;

  @ApiPropertyOptional({ description: 'Số lượng mục trên mỗi trang', default: 10 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit: number = 10;

  @ApiPropertyOptional({ description: 'Từ khóa tìm kiếm (họ tên, mã người dùng, email, SĐT)' })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({
    description: 'Lọc theo mã vai trò (super_admin, branch_admin, academic_staff, teacher, student, parent...)',
  })
  @IsOptional()
  @IsString()
  role?: string;

  @ApiPropertyOptional({ description: 'Lọc theo ID chi nhánh' })
  @IsOptional()
  @IsString()
  branchId?: string;

  @ApiPropertyOptional({
    description: 'Lọc theo trạng thái tài khoản',
    enum: UserStatus,
  })
  @IsOptional()
  @IsEnum(UserStatus)
  status?: UserStatus;
}
