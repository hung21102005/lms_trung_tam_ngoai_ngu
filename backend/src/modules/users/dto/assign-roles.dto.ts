import { ApiProperty } from '@nestjs/swagger';
import { IsArray, IsNotEmpty, IsString } from 'class-validator';

export class AssignRolesDto {
  @ApiProperty({
    description: 'Danh sách các mã vai trò (role code) gán cho người dùng',
    example: ['teacher', 'academic_staff'],
    type: [String],
  })
  @IsNotEmpty({ message: 'Danh sách vai trò không được để trống' })
  @IsArray()
  @IsString({ each: true })
  roleCodes: string[];
}
