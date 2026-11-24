import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
} from 'class-validator';
import { PaymentMethod } from '@prisma/client';

export enum RegistrationReviewAction {
  CONTACTED = 'CONTACTED',
  REJECTED = 'REJECTED',
  CANCELLED = 'CANCELLED',
  REOPEN = 'REOPEN',
}

export class ReviewClassRegistrationDto {
  @ApiProperty({ enum: RegistrationReviewAction })
  @IsEnum(RegistrationReviewAction)
  status!: RegistrationReviewAction;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  notes?: string;
}

export class ApproveClassRegistrationDto {
  @ApiPropertyOptional({
    description:
      'Học viên đã xác minh; đơn khách mới cần chuyển Lead hoặc xác nhận tài khoản trước.',
  })
  @IsOptional()
  @IsUUID()
  studentId?: string;

  @ApiPropertyOptional({ description: 'Mã khuyến mãi áp dụng khi ghi danh' })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  promotionCode?: string;

  @ApiPropertyOptional({ description: 'Số tiền giảm trừ trực tiếp / học bổng (VNĐ)' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Type(() => Number)
  discountAmount?: number;

  @ApiPropertyOptional({ description: 'Hạn thanh toán học phí (ISO Date)' })
  @IsOptional()
  @IsString()
  dueDate?: string;

  @ApiPropertyOptional({ description: 'Số tiền học viên đóng ngay khi duyệt ghi danh (VNĐ)' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Type(() => Number)
  initialPaymentAmount?: number;

  @ApiPropertyOptional({ enum: PaymentMethod, description: 'Phương thức thanh toán đợt đầu' })
  @IsOptional()
  @IsEnum(PaymentMethod)
  paymentMethod?: PaymentMethod;

  @ApiPropertyOptional({ description: 'Mã giao dịch ngân hàng (nếu chuyển khoản)' })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  transactionId?: string;

  @ApiPropertyOptional({ description: 'Ghi chú hóa đơn / thu phí' })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  invoiceNotes?: string;
}
