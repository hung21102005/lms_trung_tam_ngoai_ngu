import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsNotEmpty,
  IsString,
  IsEmail,
  IsOptional,
  IsEnum,
  IsDateString,
  IsNumber,
  MinLength,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';
import { Gender } from '@prisma/client';

export class CreateStaffDto {
  @ApiProperty({ description: 'Họ và tên nhân sự / giáo viên', example: 'Nguyễn Thị Mai' })
  @IsNotEmpty({ message: 'Họ và tên không được để trống' })
  @IsString()
  fullName: string;

  @ApiProperty({ description: 'Email nhân sự (dùng để đăng nhập)', example: 'mai.nguyen@lms-edu.vn' })
  @IsNotEmpty({ message: 'Email không được để trống' })
  @IsEmail({}, { message: 'Định dạng email không hợp lệ' })
  email: string;

  @ApiPropertyOptional({ description: 'Số điện thoại', example: '0987654321' })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional({ description: 'Giới tính', enum: Gender, example: Gender.FEMALE })
  @IsOptional()
  @IsEnum(Gender)
  gender?: Gender;

  @ApiPropertyOptional({ description: 'Ngày sinh (ISO-8601)', example: '1995-10-20' })
  @IsOptional()
  @IsDateString()
  dateOfBirth?: string;

  @ApiPropertyOptional({ description: 'Địa chỉ', example: '456 Hai Bà Trưng, Q.1' })
  @IsOptional()
  @IsString()
  address?: string;

  @ApiPropertyOptional({ description: 'ID chi nhánh trực thuộc' })
  @IsOptional()
  @IsString()
  branchId?: string;

  @ApiProperty({
    description: 'Mã vai trò của nhân sự (teacher, teaching_assistant, academic_staff, cashier, branch_admin)',
    example: 'teacher',
  })
  @IsNotEmpty({ message: 'Vai trò nhân sự không được để trống' })
  @IsString()
  roleCode: string;

  @ApiPropertyOptional({
    description: 'Mật khẩu tạm thời (mặc định ngẫu nhiên nếu không nhập)',
    example: 'Staff@123456',
  })
  @IsOptional()
  @IsString()
  @MinLength(6, { message: 'Mật khẩu tối thiểu 6 ký tự' })
  temporaryPassword?: string;

  // Profile dành cho giáo viên / trợ giảng
  @ApiPropertyOptional({ description: 'Bằng cấp / Chứng chỉ (nếu là giáo viên)', example: 'Thạc sĩ Ngôn ngữ Anh, IELTS 8.5' })
  @IsOptional()
  @IsString()
  degrees?: string;

  @ApiPropertyOptional({ description: 'Chuyên môn giảng dạy', example: 'IELTS Writing & Speaking, SAT' })
  @IsOptional()
  @IsString()
  specialties?: string;

  @ApiPropertyOptional({ description: 'Tiểu sử / Giới thiệu bản thân', example: '5 năm kinh nghiệm luyện thi IELTS' })
  @IsOptional()
  @IsString()
  bio?: string;

  @ApiPropertyOptional({ description: 'Mức thù lao mỗi giờ dạy (VNĐ)', example: 350000 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  hourlyRate?: number;
}
