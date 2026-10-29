import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsNotEmpty,
  IsString,
  IsOptional,
  IsInt,
  Min,
  Max,
  IsNumber,
  IsObject,
} from 'class-validator';

export class CreateCourseLevelDto {
  @ApiProperty({
    example: 'FOUNDATION',
    description: 'Mã cấp độ (duy nhất trong khóa học)',
  })
  @IsNotEmpty({ message: 'Mã cấp độ không được để trống' })
  @IsString()
  code!: string;

  @ApiProperty({
    example: 'IELTS Foundation (Nền tảng 4.0 - 5.0)',
    description: 'Tên cấp độ',
  })
  @IsNotEmpty({ message: 'Tên cấp độ không được để trống' })
  @IsString()
  name!: string;

  @ApiPropertyOptional({
    example: 'Xây dựng nền tảng từ vựng, ngữ pháp và phát âm',
    description: 'Mô tả mục tiêu chuẩn đầu ra',
  })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({
    example: 1,
    description: 'Thứ tự hiển thị',
    default: 1,
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  order?: number;

  @ApiPropertyOptional({
    example: 24,
    description: 'Số buổi học dự kiến',
    default: 24,
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  estimatedSessions?: number;

  @ApiPropertyOptional({
    example: 6500000,
    description: 'Học phí đề xuất cho cấp độ (VNĐ)',
    default: 0,
  })
  @IsOptional()
  @IsNumber()
  @Min(0)
  tuitionFee?: number;

  @ApiPropertyOptional({ description: 'Mức CEFR, ví dụ A2 hoặc B1' })
  @IsOptional()
  @IsString()
  cefrLevel?: string;

  @ApiPropertyOptional({ minimum: 0, maximum: 9 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(9)
  ieltsTargetBand?: number;

  @ApiPropertyOptional({ minimum: 10, maximum: 990 })
  @IsOptional()
  @IsInt()
  @Min(10)
  @Max(990)
  toeicTargetScore?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  cambridgeQualification?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  entryRequirements?: string;

  @ApiPropertyOptional({ description: 'Mục tiêu đầu ra có cấu trúc' })
  @IsOptional()
  @IsObject()
  expectedOutcomes?: Record<string, string>;

  @ApiPropertyOptional({ description: 'Cấu phần và tiêu chí đánh giá' })
  @IsOptional()
  @IsObject()
  assessmentScheme?: Record<string, string>;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  completionCriteria?: string;

  @ApiPropertyOptional({ minimum: 1 })
  @IsOptional()
  @IsInt()
  @Min(1)
  recommendedHours?: number;
}
