import { IsNumber, Min, IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';
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

export class SubmitTransferPaymentDto {
  @IsNumber()
  @Min(1000, { message: 'Số tiền chuyển khoản tối thiểu là 1,000 VNĐ' })
  @Type(() => Number)
  amount!: number;

  @IsString()
  @IsOptional()
  @MaxLength(120)
  transactionId?: string;

  @IsString()
  @IsOptional()
  @MaxLength(500)
  notes?: string;
}

export class ReviewPaymentDto {
  @IsString()
  @IsOptional()
  @MaxLength(500)
  reason?: string;

  @IsString()
  @IsOptional()
  @MaxLength(500)
  notes?: string;
}
