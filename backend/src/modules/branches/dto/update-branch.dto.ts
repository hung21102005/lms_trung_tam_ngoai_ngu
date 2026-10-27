import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, IsEmail, IsBoolean } from 'class-validator';

export class UpdateBranchDto {
  @ApiPropertyOptional({ example: 'Chi nhánh Bình Thạnh (Cơ sở 2)' })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({ example: '456 Điện Biên Phủ, Phường 25, Bình Thạnh, TP.HCM' })
  @IsOptional()
  @IsString()
  address?: string;

  @ApiPropertyOptional({ example: '0283998877' })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional({ example: 'binhthanh@lms-edu.vn' })
  @IsOptional()
  @IsEmail({}, { message: 'Định dạng email không hợp lệ' })
  email?: string;

  @ApiPropertyOptional({ example: true, description: 'Trạng thái hoạt động của cơ sở' })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
