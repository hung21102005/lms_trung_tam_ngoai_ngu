import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsNotEmpty, IsString, Length, MinLength, Matches } from 'class-validator';

export class ResetPasswordDto {
  @ApiProperty({
    example: 'student@lms-edu.vn',
    description: 'Email đã yêu cầu đặt lại mật khẩu',
  })
  @IsNotEmpty({ message: 'Email không được để trống' })
  @IsEmail({}, { message: 'Định dạng email không hợp lệ' })
  email!: string;

  @ApiProperty({
    example: '123456',
    description: 'Mã xác thực OTP gồm 6 chữ số nhận qua email',
  })
  @IsNotEmpty({ message: 'Mã OTP không được để trống' })
  @IsString()
  @Length(6, 6, { message: 'Mã OTP phải có đúng 6 chữ số' })
  otpCode!: string;

  @ApiProperty({
    example: 'MatKhauMoi@2026',
    description: 'Mật khẩu mới (tối thiểu 8 ký tự, gồm chữ hoa, chữ thường, chữ số)',
  })
  @IsNotEmpty({ message: 'Mật khẩu mới không được để trống' })
  @IsString()
  @MinLength(8, { message: 'Mật khẩu mới phải có tối thiểu 8 ký tự' })
  @Matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/, {
    message: 'Mật khẩu phải chứa ít nhất một chữ hoa, một chữ thường và một chữ số',
  })
  newPassword!: string;

  @ApiProperty({
    example: 'MatKhauMoi@2026',
    description: 'Xác nhận lại mật khẩu mới',
  })
  @IsNotEmpty({ message: 'Xác nhận mật khẩu không được để trống' })
  @IsString()
  confirmPassword!: string;
}
