import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsString, IsOptional, IsInt, Min } from 'class-validator';

export class CreateModuleDto {
  @ApiProperty({
    example: 'Module 1: Ngữ âm & Giao tiếp nền tảng',
    description: 'Tên module/chương',
  })
  @IsNotEmpty({ message: 'Tên module không được để trống' })
  @IsString()
  title!: string;

  @ApiPropertyOptional({
    example: 1,
    description: 'Thứ tự module trong cấp độ',
    default: 1,
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  order?: number;

  @ApiPropertyOptional({
    example: 'Bảng phiên âm quốc tế IPA và phát âm chuẩn',
    description: 'Mô tả tóm tắt module',
  })
  @IsOptional()
  @IsString()
  description?: string;
}
