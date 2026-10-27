import { IsString, IsNotEmpty, IsNumber, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class ValidatePromotionDto {
  @IsString()
  @IsNotEmpty({ message: 'Mã khuyến mãi không được để trống' })
  code!: string;

  @IsNumber()
  @Min(0)
  @Type(() => Number)
  orderAmount!: number;
}
