import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class CreateQuestionBankDto {
  @ApiProperty({ description: 'Tiêu đề ngân hàng câu hỏi', example: 'Ngân hàng đề thi IELTS Listening & Reading Unit 1-5' })
  @IsNotEmpty({ message: 'Tiêu đề ngân hàng câu hỏi không được để trống' })
  @IsString()
  title: string;

  @ApiPropertyOptional({ description: 'Mô tả chi tiết', example: 'Tập hợp các câu hỏi trắc nghiệm và điền từ' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ description: 'Ngôn ngữ', example: 'EN' })
  @IsOptional()
  @IsString()
  language?: string;

  @ApiPropertyOptional({ description: 'Trình độ / Level', example: 'IELTS' })
  @IsOptional()
  @IsString()
  level?: string;
}
