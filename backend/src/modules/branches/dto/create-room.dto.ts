import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsString, IsOptional, IsInt, Min } from 'class-validator';

export class CreateRoomDto {
  @ApiProperty({
    example: 'uuid-chi-nhanh',
    description: 'ID của chi nhánh sở hữu phòng học này',
  })
  @IsNotEmpty({ message: 'Chi nhánh (branchId) không được để trống' })
  @IsString()
  branchId!: string;

  @ApiProperty({
    example: 'P201',
    description: 'Mã phòng học trong chi nhánh (duy nhất trong chi nhánh)',
  })
  @IsNotEmpty({ message: 'Mã phòng học không được để trống' })
  @IsString()
  code!: string;

  @ApiProperty({
    example: 'Phòng Học Thông Minh 201',
    description: 'Tên hiển thị phòng học',
  })
  @IsNotEmpty({ message: 'Tên phòng học không được để trống' })
  @IsString()
  name!: string;

  @ApiPropertyOptional({
    example: 30,
    default: 25,
    description: 'Sức chứa tối đa của phòng học',
  })
  @IsOptional()
  @IsInt()
  @Min(1, { message: 'Sức chứa phòng học tối thiểu là 1' })
  capacity?: number;

  @ApiPropertyOptional({
    example: 'Máy chiếu 4K, Loa trợ giảng, Bảng từ, Điều hòa hai chiều',
    description: 'Danh mục trang thiết bị trong phòng',
  })
  @IsOptional()
  @IsString()
  equipment?: string;
}
