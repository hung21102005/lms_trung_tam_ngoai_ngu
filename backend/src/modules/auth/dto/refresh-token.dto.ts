import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

export class RefreshTokenDto {
  @ApiProperty({
    example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
    description: 'Refresh token hợp lệ đã cấp khi đăng nhập',
  })
  @IsNotEmpty({ message: 'Refresh token không được để trống' })
  @IsString()
  refreshToken!: string;
}
