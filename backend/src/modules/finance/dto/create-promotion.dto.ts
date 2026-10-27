import { IsString, IsNotEmpty, IsOptional, IsEnum, IsNumber, Min } from 'class-validator';
import { Type } from 'class-transformer';
import { PromotionType } from '@prisma/client';

export class CreatePromotionDto {
  @IsString()
  @IsNotEmpty({ message: 'Mã khuyến mãi không được để trống' })
  code!: string;

  @IsString()
  @IsNotEmpty({ message: 'Tên chương trình ưu đãi không được để trống' })
  name!: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsEnum(PromotionType, { message: 'Loại khuyến mãi không hợp lệ' })
  @IsOptional()
  type?: PromotionType;

  @IsNumber()
  @Min(0, { message: 'Giá trị khuyến mãi phải >= 0' })
  @Type(() => Number)
  value!: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  @Type(() => Number)
  minOrderValue?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  @Type(() => Number)
  maxDiscount?: number;

  @IsString()
  @IsNotEmpty({ message: 'Ngày bắt đầu không được để trống' })
  startDate!: string;

  @IsString()
  @IsNotEmpty({ message: 'Ngày kết thúc không được để trống' })
  endDate!: string;

  @IsNumber()
  @Min(1)
  @IsOptional()
  @Type(() => Number)
  usageLimit?: number;
}
