import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsArray,
  IsBoolean,
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ExamStatus } from '@prisma/client';

export class ExamQuestionItemDto {
  @ApiProperty({ description: 'ID câu hỏi từ ngân hàng' })
  @IsNotEmpty()
  @IsString()
  questionId: string;

  @ApiPropertyOptional({ description: 'Thứ tự câu hỏi trong đề', example: 1 })
  @IsOptional()
  @IsInt()
  orderIndex?: number;

  @ApiPropertyOptional({ description: 'Điểm số của câu trong đề thi này', example: 1.0 })
  @IsOptional()
  @IsNumber()
  points?: number;
}

export class CreateExamDto {
  @ApiProperty({ description: 'Tiêu đề đề thi / bài kiểm tra', example: 'Kiểm tra giữa kỳ - IELTS Listening & Reading' })
  @IsNotEmpty({ message: 'Tiêu đề đề thi không được để trống' })
  @IsString()
  title: string;

  @ApiPropertyOptional({ description: 'Mô tả bài thi' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ description: 'ID lớp học áp dụng đề thi này (để trống nếu là bài thi tự do/mẫu)' })
  @IsOptional()
  @IsString()
  classId?: string;

  @ApiPropertyOptional({ description: 'Thời gian làm bài tính theo phút', example: 45 })
  @IsOptional()
  @IsInt()
  @Min(1)
  durationMinutes?: number;

  @ApiPropertyOptional({ description: 'Tỷ lệ % điểm để vượt qua (Pass)', example: 50.0 })
  @IsOptional()
  @IsNumber()
  passPercentage?: number;

  @ApiPropertyOptional({ description: 'Tổng thang điểm bài thi', example: 10.0 })
  @IsOptional()
  @IsNumber()
  totalPoints?: number;

  @ApiPropertyOptional({ description: 'Trộn ngẫu nhiên câu hỏi khi học viên làm bài', default: false })
  @IsOptional()
  @IsBoolean()
  shuffleQuestions?: boolean;

  @ApiPropertyOptional({ description: 'Số lần tối đa được làm bài', default: 1 })
  @IsOptional()
  @IsInt()
  @Min(1)
  maxAttempts?: number;

  @ApiPropertyOptional({ enum: ExamStatus, default: ExamStatus.DRAFT })
  @IsOptional()
  @IsEnum(ExamStatus)
  status?: ExamStatus;

  @ApiPropertyOptional({ description: 'Thời gian bắt đầu mở đề' })
  @IsOptional()
  @IsString()
  startTime?: string;

  @ApiPropertyOptional({ description: 'Thời gian đóng đề' })
  @IsOptional()
  @IsString()
  endTime?: string;

  @ApiPropertyOptional({ description: 'Danh sách câu hỏi chọn vào đề thi', type: [ExamQuestionItemDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ExamQuestionItemDto)
  questions?: ExamQuestionItemDto[];
}
