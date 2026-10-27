import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsNotEmpty,
  IsOptional,
  IsNumber,
  Min,
  IsEnum,
  IsString,
  MaxLength,
} from 'class-validator';
import { EnrollmentStatus } from '@prisma/client';

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
  tuitionPaid?: number;

  @ApiPropertyOptional({
    example: 'Đăng ký nhận ưu đãi 10% học phí',
    description: 'Ghi chú ghi danh',
  })
  @IsOptional()
  @IsString()
  notes?: string;
}
