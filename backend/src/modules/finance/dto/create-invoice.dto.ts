import { IsString, IsNotEmpty, IsOptional, IsNumber, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class CreateInvoiceDto {
  @IsString()
  @IsNotEmpty({ message: 'studentId không được để trống' })
  studentId!: string;

  @IsString()
  @IsOptional()
  classId?: string;

  @IsString()
  @IsNotEmpty({ message: 'Tiêu đề hóa đơn không được để trống' })
  title!: string;

  @IsNumber()
  @Min(0, { message: 'Học phí gốc phải >= 0' })
  @Type(() => Number)
  subtotal!: number;

  @IsNumber()
  @Min(0, { message: 'Giảm giá phải >= 0' })
  @IsOptional()
  @Type(() => Number)
  discount?: number;

  @IsString()
  @IsOptional()
  promotionCode?: string;

  @IsString()
  @IsOptional()
  dueDate?: string;

  @IsString()
  @IsOptional()
  notes?: string;
}
