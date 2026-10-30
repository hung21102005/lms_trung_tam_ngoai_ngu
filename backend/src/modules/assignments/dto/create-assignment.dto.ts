import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsEnum,
  IsNumber,
  IsArray,
  IsObject,
  Min,
  Max,
} from 'class-validator';
import { Type } from 'class-transformer';
import { AssignmentStatus, AssignmentType } from '@prisma/client';

export class CreateAssignmentDto {
  @ApiPropertyOptional({
    enum: AssignmentStatus,
    default: AssignmentStatus.PUBLISHED,
  })
  @IsOptional()
  @IsEnum(AssignmentStatus)
  status?: AssignmentStatus;
  @ApiProperty({
    description: 'Tiêu đề bài tập',
    example: 'Speaking Task 1: Self Introduction',
  })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiPropertyOptional({
    description: 'Mô tả chi tiết / đề bài',
    example: 'Ghi âm bài nói giới thiệu bản thân trong thời lượng 2 phút.',
  })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({
    enum: AssignmentType,
    description: 'Loại bài tập',
    default: AssignmentType.HOMEWORK,
  })
  @IsOptional()
  @IsEnum(AssignmentType)
  type?: AssignmentType;

  @ApiPropertyOptional({
    description: 'Hạn nộp bài (ISO string)',
    example: '2026-10-25T23:59:59.000Z',
  })
  @IsOptional()
  @IsString()
  deadline?: string;

  @ApiPropertyOptional({
    description: 'Thang điểm tối đa',
    default: 10,
    example: 10,
  })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  @Min(1)
  @Max(100)
  maxScore?: number;

  @ApiPropertyOptional({
    description: 'Tài liệu hướng dẫn đính kèm từ giáo viên',
    example: [{ name: 'rubric.pdf', url: 'https://...', fileType: 'PDF' }],
  })
  @IsOptional()
  @IsArray()
  @IsObject({ each: true })
  @Type(() => Object)
  attachments?: any[];
}

export class UpdateAssignmentDto {
  @ApiPropertyOptional({ enum: AssignmentStatus })
  @IsOptional()
  @IsEnum(AssignmentStatus)
  status?: AssignmentStatus;
  @ApiPropertyOptional({ description: 'Tiêu đề bài tập' })
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  title?: string;

  @ApiPropertyOptional({ description: 'Mô tả' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ enum: AssignmentType })
  @IsOptional()
  @IsEnum(AssignmentType)
  type?: AssignmentType;

  @ApiPropertyOptional({ description: 'Hạn nộp bài (ISO string)' })
  @IsOptional()
  @IsString()
  deadline?: string;

  @ApiPropertyOptional({ description: 'Thang điểm tối đa' })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  @Min(1)
  @Max(100)
  maxScore?: number;

  @ApiPropertyOptional({ description: 'Tài liệu đính kèm' })
  @IsOptional()
  @IsArray()
  @IsObject({ each: true })
  @Type(() => Object)
  attachments?: any[];
}

export class SubmitAssignmentDto {
  @ApiPropertyOptional({
    description: 'Nội dung bài viết / câu trả lời dạng văn bản',
    example: 'My name is Alex. I am 20 years old...',
  })
  @IsOptional()
  @IsString()
  content?: string;

  @ApiPropertyOptional({
    description: 'Danh sách file nộp (audio, pdf, doc, hình ảnh)',
    example: [
      {
        type: 'audio',
        name: 'speaking_intro.m4a',
        url: 'https://storage.../audio.m4a',
        size: 1048576,
      },
    ],
  })
  @IsOptional()
  @IsArray()
  @IsObject({ each: true })
  @Type(() => Object)
  fileUrls?: any[];
}

export class GradeSubmissionDto {
  @ApiProperty({
    description: 'Điểm số bài tập',
    example: 8.5,
  })
  @IsNumber()
  @Type(() => Number)
  @Min(0)
  score: number;

  @ApiPropertyOptional({
    description: 'Nhận xét và góp ý của giáo viên',
    example: 'Phát âm rõ ràng, tuy nhiên chú ý nối âm đuôi ed.',
  })
  @IsOptional()
  @IsString()
  feedback?: string;

  @ApiPropertyOptional({
    description: 'Chi tiết điểm từng tiêu chí rubric (Speaking/Writing)',
    example: { pronunciation: 7.5, fluency: 7.0, grammar: 6.5, lexical: 7.0 },
  })
  @IsOptional()
  @IsObject()
  rubricScores?: Record<string, any>;
}

export class ReturnSubmissionDto {
  @ApiProperty({ description: 'Hướng dẫn học viên làm lại bài' })
  @IsString()
  @IsNotEmpty()
  feedback: string;
}
