import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, MinLength } from 'class-validator';

export class LoginDto {
  @ApiProperty({
    example: 'admin@lms-edu.vn',
    description: 'Email, Số điện thoại hoặc Mã định danh tài khoản (VD: AD-000001, HV-2026-0001)',
  })
  @IsNotEmpty({ message: 'Tên đăng nhập / Email / Số điện thoại không được để trống' })
  @IsString({ message: 'Tên đăng nhập phải là chuỗi ký tự' })
  identifier!: string;

  @ApiProperty({
    example: 'Admin@123456',
    description: 'Mật khẩu đăng nhập',
  })
  @IsNotEmpty({ message: 'Mật khẩu không được để trống' })
  @IsString({ message: 'Mật khẩu phải là chuỗi ký tự' })
  @MinLength(6, { message: 'Mật khẩu phải chứa ít nhất 6 ký tự' })
  password!: string;
}
