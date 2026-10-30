import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, IsInt, Min, Max, IsBoolean } from 'class-validator';
import { Type, Transform } from 'class-transformer';

export class QueryCoursesDto {
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

  @ApiPropertyOptional({ example: 'IELTS', description: 'Tìm theo mã hoặc tên khóa học' })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({ example: 'English', description: 'Lọc theo ngôn ngữ' })
  @IsOptional()
  @IsString()
  language?: string;

  @ApiPropertyOptional({ example: true, description: 'Lọc theo trạng thái hoạt động' })
  @IsOptional()
  @Transform(({ value }) => value === 'true' || value === true)
  @IsBoolean()
  isActive?: boolean;
}
