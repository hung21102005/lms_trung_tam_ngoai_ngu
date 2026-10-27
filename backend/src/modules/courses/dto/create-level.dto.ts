import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsString, IsOptional, IsInt, Min, IsNumber } from 'class-validator';

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
}
