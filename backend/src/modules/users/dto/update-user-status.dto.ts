import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsEnum } from 'class-validator';
import { UserStatus } from '@prisma/client';

export class UpdateUserStatusDto {
  @ApiProperty({
    description: 'Trạng thái tài khoản mới',
    enum: UserStatus,
    example: UserStatus.LOCKED,
  })
  @IsNotEmpty({ message: 'Trạng thái không được để trống' })
  @IsEnum(UserStatus, { message: 'Trạng thái tài khoản không hợp lệ' })
  status: UserStatus;
}
