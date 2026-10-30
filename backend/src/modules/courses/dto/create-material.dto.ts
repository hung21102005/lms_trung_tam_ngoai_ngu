import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsString, IsOptional, IsInt, IsEnum, Min } from 'class-validator';
import { MaterialFileType } from '@prisma/client';

export class CreateLessonMaterialDto {
  @ApiProperty({
    example: 'Slide bài giảng Unit 1',
    description: 'Tên hiển thị của tài liệu',
  })
  @IsNotEmpty({ message: 'Tên tài liệu không được để trống' })
  @IsString()
  title!: string;

  @ApiProperty({
    example: 'https://storage.googleapis.com/lms-edu/materials/unit-1-slide.pdf',
    description: 'URL tải hoặc xem tài liệu',
  })
  @IsNotEmpty({ message: 'Đường dẫn file không được để trống' })
  @IsString()
  fileUrl!: string;

  @ApiPropertyOptional({
    enum: MaterialFileType,
    default: MaterialFileType.DOCUMENT,
    description: 'Phân loại tài liệu',
  })
  @IsOptional()
  @IsEnum(MaterialFileType, { message: 'Loại tài liệu không hợp lệ' })
  fileType?: MaterialFileType;

  @ApiPropertyOptional({
    example: 1048576,
    description: 'Kích thước file (bytes)',
  })
  @IsOptional()
  @IsInt()
  @Min(0)
  fileSizeBytes?: number;

  @ApiPropertyOptional({
    example: 1,
    description: 'Thứ tự hiển thị',
    default: 1,
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  order?: number;
}
