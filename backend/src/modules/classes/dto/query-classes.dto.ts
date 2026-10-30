import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, IsInt, Min, Max, IsEnum, IsUUID } from 'class-validator';
import { Type } from 'class-transformer';
import { ClassStatus } from '@prisma/client';

export class QueryClassesDto {
  @ApiPropertyOptional({ example: 1, default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page: number = 1;

  @ApiPropertyOptional({ example: 10, default: 10 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit: number = 10;

  @ApiPropertyOptional({ example: 'IELTS', description: 'Tìm theo mã hoặc tên lớp' })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({ enum: ClassStatus, description: 'Lọc theo trạng thái lớp' })
  @IsOptional()
  @IsEnum(ClassStatus)
  status?: ClassStatus;

  @ApiPropertyOptional({ example: 'uuid-branch', description: 'Lọc theo chi nhánh' })
  @IsOptional()
  @IsUUID('4')
  branchId?: string;

  @ApiPropertyOptional({ example: 'uuid-course', description: 'Lọc theo khóa học' })
  @IsOptional()
  @IsUUID('4')
  courseId?: string;

  @ApiPropertyOptional({ example: 'uuid-teacher', description: 'Lọc theo giáo viên chính' })
  @IsOptional()
  @IsUUID('4')
  teacherId?: string;
}
