import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, MinLength, Matches } from 'class-validator';

export class FirstLoginSetupDto {
  @ApiProperty({
    example: 'MatKhauMoi@2026',
    description: 'Mật khẩu mới (tối thiểu 8 ký tự, bao gồm chữ hoa, chữ thường và chữ số)',
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
