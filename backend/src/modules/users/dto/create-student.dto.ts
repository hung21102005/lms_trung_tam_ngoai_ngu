import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsNotEmpty,
  IsString,
  IsEmail,
  IsOptional,
  IsEnum,
  IsDateString,
  MinLength,
} from 'class-validator';
import { Gender } from '@prisma/client';

export class CreateStudentDto {
  @ApiProperty({ description: 'Họ và tên học viên', example: 'Trần Văn Nam' })
  @IsNotEmpty({ message: 'Họ và tên không được để trống' })
  @IsString()
  fullName: string;

  @ApiPropertyOptional({ description: 'Email của học viên', example: 'nam.tran@gmail.com' })
  @IsOptional()
  @IsEmail({}, { message: 'Định dạng email không hợp lệ' })
  email?: string;

  @ApiPropertyOptional({ description: 'Số điện thoại', example: '0901234567' })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional({ description: 'Giới tính', enum: Gender, example: Gender.MALE })
  @IsOptional()
  @IsEnum(Gender)
  gender?: Gender;

  @ApiPropertyOptional({ description: 'Ngày sinh (ISO-8601)', example: '2008-05-15' })
  @IsOptional()
  @IsDateString()
  dateOfBirth?: string;

  @ApiPropertyOptional({ description: 'Địa chỉ thường trú', example: '123 Nguyễn Thị Minh Khai, Q.1' })
  @IsOptional()
  @IsString()
  address?: string;

  @ApiPropertyOptional({ description: 'ID chi nhánh theo học' })
  @IsOptional()
  @IsString()
  branchId?: string;

  @ApiPropertyOptional({
    description: 'Mật khẩu tạm thời (nếu bỏ trống, hệ thống sẽ tự sinh ngẫu nhiên)',
    example: 'Student@123456',
  })
  @IsOptional()
  @IsString()
  @MinLength(6, { message: 'Mật khẩu tối thiểu 6 ký tự' })
  temporaryPassword?: string;

  @ApiPropertyOptional({ description: 'Trình độ đầu vào', example: 'A2 Key English' })
  @IsOptional()
  @IsString()
  entryLevel?: string;

  @ApiPropertyOptional({ description: 'Mục tiêu đào tạo', example: 'IELTS 6.5' })
  @IsOptional()
  @IsString()
  targetLevel?: string;

  @ApiPropertyOptional({ description: 'Trường học hiện tại', example: 'THPT Lê Hồng Phong' })
  @IsOptional()
  @IsString()
  schoolName?: string;

  @ApiPropertyOptional({ description: 'Ghi chú học vụ' })
  @IsOptional()
  @IsString()
  notes?: string;
}
