import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsNotEmpty,
  IsString,
  IsOptional,
  Matches,
  IsBoolean,
  IsUUID,
} from 'class-validator';

export class CreateCourseDto {
  @ApiProperty({
    example: 'ENG-IELTS',
    description: 'Mã định danh khóa học (chữ hoa, số, gạch nối)',
  })
  @IsNotEmpty({ message: 'Mã khóa học không được để trống' })
  @IsString()
  @Matches(/^[A-Z0-9_-]+$/, {
    message: 'Mã khóa học chỉ gồm chữ hoa, chữ số, gạch dưới và gạch nối',
  })
  code!: string;

  @ApiProperty({
    example: 'Chương trình Luyện thi IELTS Chuyên sâu',
    description: 'Tên khóa học',
  })
  @IsNotEmpty({ message: 'Tên khóa học không được để trống' })
  @IsString()
  title!: string;

  @ApiPropertyOptional({
    example: 'Chương trình đào tạo toàn diện 4 kỹ năng theo chuẩn Cambridge',
    description: 'Mô tả chi tiết khóa học',
  })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({
    example: 'Học sinh THPT, Sinh viên, Người đi làm',
    description: 'Đối tượng học viên phù hợp',
  })
  @IsOptional()
  @IsString()
  targetAudience?: string;

  @ApiPropertyOptional({
    example: 'English',
    description: 'Ngôn ngữ giảng dạy',
    default: 'English',
  })
  @IsOptional()
  @IsString()
  language?: string;

  @ApiPropertyOptional({
    example: 'https://images.unsplash.com/photo-1546410531-bb4caa6b424d',
    description: 'URL ảnh đại diện khóa học',
  })
  @IsOptional()
  @IsString()
  thumbnailUrl?: string;

  @ApiPropertyOptional({
    example: true,
    description: 'Trạng thái hoạt động',
    default: true,
  })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @ApiPropertyOptional({ description: 'Chương trình đào tạo chứa khóa học' })
  @IsOptional()
  @IsUUID()
  programId?: string;

  @ApiPropertyOptional({ example: 'ielts-target-65' })
  @IsOptional()
  @IsString()
  @Matches(/^[a-z0-9]+(?:-[a-z0-9]+)*$/)
  slug?: string;

  @ApiPropertyOptional({
    description: 'Mô tả hiển thị trong catalog công khai',
  })
  @IsOptional()
  @IsString()
  publicDescription?: string;
}
