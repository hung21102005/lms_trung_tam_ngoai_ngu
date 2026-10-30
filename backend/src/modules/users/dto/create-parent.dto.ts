import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsNotEmpty,
  IsString,
  IsEmail,
  IsOptional,
  IsEnum,
  IsArray,
  MinLength,
} from 'class-validator';
import { Gender } from '@prisma/client';

export class CreateParentDto {
  @ApiProperty({ description: 'Họ và tên phụ huynh', example: 'Trần Văn Hùng' })
  @IsNotEmpty({ message: 'Họ và tên không được để trống' })
  @IsString()
  fullName: string;

  @ApiProperty({ description: 'Số điện thoại phụ huynh (dùng để đăng nhập và liên hệ)', example: '0912345678' })
  @IsNotEmpty({ message: 'Số điện thoại không được để trống' })
  @IsString()
  phone: string;

  @ApiPropertyOptional({ description: 'Email phụ huynh', example: 'hung.tran@gmail.com' })
  @IsOptional()
  @IsEmail({}, { message: 'Định dạng email không hợp lệ' })
  email?: string;

  @ApiPropertyOptional({ description: 'Giới tính', enum: Gender, example: Gender.MALE })
  @IsOptional()
  @IsEnum(Gender)
  gender?: Gender;

  @ApiPropertyOptional({ description: 'Địa chỉ liên hệ', example: '123 Nguyễn Thị Minh Khai, Q.1' })
  @IsOptional()
  @IsString()
  address?: string;

  @ApiPropertyOptional({ description: 'ID chi nhánh' })
  @IsOptional()
  @IsString()
  branchId?: string;

  @ApiPropertyOptional({
    description: 'Mật khẩu tạm thời (mặc định ngẫu nhiên nếu không nhập)',
    example: 'Parent@123456',
  })
  @IsOptional()
  @IsString()
  @MinLength(6, { message: 'Mật khẩu tối thiểu 6 ký tự' })
  temporaryPassword?: string;

  @ApiPropertyOptional({
    description: 'Danh sách ID học viên là con em của phụ huynh này',
    example: ['uuid-student-1', 'uuid-student-2'],
    type: [String],
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  studentIds?: string[];

  @ApiPropertyOptional({ description: 'Mối quan hệ với học viên', example: 'Bố' })
  @IsOptional()
  @IsString()
  relationship?: string;
}
