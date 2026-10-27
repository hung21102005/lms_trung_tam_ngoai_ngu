import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, MinLength, Matches } from 'class-validator';

export class ChangePasswordDto {
  @ApiProperty({
    example: 'MatKhauCu@123',
    description: 'Mật khẩu hiện tại của tài khoản',
  })
  @IsNotEmpty({ message: 'Mật khẩu cũ không được để trống' })
  @IsString()
  oldPassword!: string;

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
}
