import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MinLength } from 'class-validator';

export class AdminResetPasswordDto {
  @ApiPropertyOptional({
    description: 'Mật khẩu tạm thời mới (nếu bỏ trống, hệ thống sẽ tự sinh ngẫu nhiên)',
    example: 'NewPass@2026',
  })
  @IsOptional()
  @IsString()
  @MinLength(6, { message: 'Mật khẩu tối thiểu 6 ký tự' })
  newPassword?: string;
}
