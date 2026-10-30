import { IsNumber, Min, IsEnum, IsOptional, IsString } from 'class-validator';
import { Type } from 'class-transformer';
import { PaymentMethod } from '@prisma/client';

export class RecordPaymentDto {
  @IsNumber()
  @Min(1000, { message: 'Số tiền thanh toán tối thiểu là 1,000 VNĐ' })
  @Type(() => Number)
  amount!: number;

  @IsEnum(PaymentMethod, { message: 'Phương thức thanh toán không hợp lệ' })
  method!: PaymentMethod;

  @IsString()
  @IsOptional()
  transactionId?: string;

  @IsString()
  @IsOptional()
  notes?: string;
}
