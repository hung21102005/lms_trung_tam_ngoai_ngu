import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, IsInt, Min, IsBoolean } from 'class-validator';

export class UpdateRoomDto {
  @ApiPropertyOptional({ example: 'Phòng Lab Chuyên Dụng 201' })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({ example: 35 })
  @IsOptional()
  @IsInt()
  @Min(1)
  capacity?: number;

  @ApiPropertyOptional({ example: 'Bổ sung thêm 5 bộ tai nghe thu âm' })
  @IsOptional()
  @IsString()
  equipment?: string;

  @ApiPropertyOptional({ example: true, description: 'Trạng thái hoạt động phòng học' })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
