import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsString, IsOptional, IsEmail, Matches } from 'class-validator';

export class CreateBranchDto {
  @ApiProperty({
    example: 'BR-BT',
    description: 'Mã định danh chi nhánh (chữ hoa và gạch nối)',
  })
  @IsNotEmpty({ message: 'Mã chi nhánh không được để trống' })
  @IsString()
  @Matches(/^[A-Z0-9_-]+$/, { message: 'Mã chi nhánh chỉ bao gồm chữ hoa, chữ số và gạch nối' })
  code!: string;

  @ApiProperty({
    example: 'Chi nhánh Bình Thạnh - Hồ Chí Minh',
    description: 'Tên chi nhánh trung tâm ngoại ngữ',
  })
  @IsNotEmpty({ message: 'Tên chi nhánh không được để trống' })
  @IsString()
  name!: string;

  @ApiProperty({
    example: '456 Điện Biên Phủ, Phường 25, Bình Thạnh, TP.HCM',
    description: 'Địa chỉ cơ sở chi nhánh',
  })
  @IsNotEmpty({ message: 'Địa chỉ chi nhánh không được để trống' })
  @IsString()
  address!: string;

  @ApiPropertyOptional({
    example: '0283998877',
    description: 'Số điện thoại bàn hoặc hotline cơ sở',
  })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional({
    example: 'binhthanh@lms-edu.vn',
    description: 'Email tiếp nhận liên hệ của chi nhánh',
  })
  @IsOptional()
  @IsEmail({}, { message: 'Định dạng email không hợp lệ' })
  email?: string;
}
