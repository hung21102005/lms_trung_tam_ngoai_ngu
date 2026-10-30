import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsString, IsOptional, IsInt, Min } from 'class-validator';

export class CreateLessonDto {
  @ApiProperty({
    example: 'Unit 1: IPA Vowels & Self-Introduction',
    description: 'Tên bài học',
  })
  @IsNotEmpty({ message: 'Tên bài học không được để trống' })
  @IsString()
  title!: string;

  @ApiPropertyOptional({
    example: 1,
    description: 'Thứ tự bài học trong module',
    default: 1,
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  order?: number;

  @ApiPropertyOptional({
    example: 'Nội dung tóm tắt hoặc giáo án bài học',
    description: 'Nội dung chi tiết bài học',
  })
  @IsOptional()
  @IsString()
  content?: string;

  @ApiPropertyOptional({
    example: 90,
    description: 'Thời lượng bài học (phút)',
    default: 90,
  })
  @IsOptional()
  @IsInt()
  @Min(15)
  durationMinutes?: number;
}
