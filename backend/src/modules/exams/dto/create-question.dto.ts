import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsNumber, IsOptional, IsString } from 'class-validator';
import { QuestionType } from '@prisma/client';

export class CreateQuestionDto {
  @ApiPropertyOptional({ enum: QuestionType, default: QuestionType.MULTIPLE_CHOICE })
  @IsOptional()
  @IsEnum(QuestionType, { message: 'Loại câu hỏi không hợp lệ' })
  type?: QuestionType;

  @ApiProperty({ description: 'Nội dung đề bài / câu hỏi', example: 'What is the synonym of "essential"?' })
  @IsNotEmpty({ message: 'Nội dung câu hỏi không được để trống' })
  @IsString()
  prompt: string;

  @ApiPropertyOptional({ description: 'URL file âm thanh (cho kỹ năng Nghe)' })
  @IsOptional()
  @IsString()
  audioUrl?: string;

  @ApiPropertyOptional({ description: 'URL hình ảnh minh họa' })
  @IsOptional()
  @IsString()
  imageUrl?: string;

  @ApiPropertyOptional({
    description: 'Danh sách lựa chọn (cho trắc nghiệm/matching/ordering)',
    example: [
      { id: 'A', text: 'Important' },
      { id: 'B', text: 'Minor' },
      { id: 'C', text: 'Trivial' },
      { id: 'D', text: 'Optional' },
    ],
  })
  @IsOptional()
  options?: any;

  @ApiPropertyOptional({
    description: 'Đáp án chính xác',
    example: ['A'],
  })
  @IsOptional()
  correctAnswers?: any;

  @ApiPropertyOptional({ description: 'Giải thích chi tiết đáp án' })
  @IsOptional()
  @IsString()
  explanation?: string;

  @ApiPropertyOptional({ description: 'Điểm số của câu hỏi', example: 1.0 })
  @IsOptional()
  @IsNumber()
  points?: number;
}
