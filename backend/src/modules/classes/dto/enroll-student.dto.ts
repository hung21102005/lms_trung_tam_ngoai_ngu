import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsNotEmpty,
  IsOptional,
  IsNumber,
  Min,
  IsEnum,
  IsString,
  MaxLength,
} from 'class-validator';
import { EnrollmentStatus, PaymentMethod } from '@prisma/client';

export class EnrollStudentDto {
  @ApiProperty({
    example: 'DEMO-HV-05',
    description: 'UUID hoặc mã học viên có role student',
  })
  @IsNotEmpty({ message: 'studentId không được để trống' })
  @IsString()
  @MaxLength(100)
  studentId!: string;

  @ApiPropertyOptional({
    enum: EnrollmentStatus,
    default: EnrollmentStatus.ENROLLED,
    description: 'Trạng thái ghi danh',
  })
  @IsOptional()
  @IsEnum(EnrollmentStatus, { message: 'Trạng thái ghi danh không hợp lệ' })
  status?: EnrollmentStatus;

  @ApiPropertyOptional({
    example: 6500000,
    description: 'Số tiền học phí đã đóng (nếu có)',
    default: 0,
  })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Type(() => Number)
  tuitionPaid?: number;

  @ApiPropertyOptional({ description: 'Mã khuyến mãi áp dụng khi ghi danh' })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  promotionCode?: string;

  @ApiPropertyOptional({ description: 'Số tiền giảm trừ trực tiếp / học bổng' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Type(() => Number)
  discountAmount?: number;

  @ApiPropertyOptional({ description: 'Hạn thanh toán học phí (ISO Date)' })
  @IsOptional()
  @IsString()
  dueDate?: string;

  @ApiPropertyOptional({
    enum: PaymentMethod,
    description: 'Phương thức thanh toán đợt đầu',
  })
  @IsOptional()
  @IsEnum(PaymentMethod)
  paymentMethod?: PaymentMethod;

  @ApiPropertyOptional({ description: 'Mã giao dịch ngân hàng (nếu có)' })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  transactionId?: string;

  @ApiPropertyOptional({
    example: 'Đăng ký nhận ưu đãi 10% học phí',
    description: 'Ghi chú ghi danh',
  })
  @IsOptional()
  @IsString()
  notes?: string;
}
