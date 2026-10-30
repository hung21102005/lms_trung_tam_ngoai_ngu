import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class GradeExamAnswerDto {
  @ApiProperty({ description: 'Điểm số chấm cho câu này', example: 1.5 })
  @IsNotEmpty({ message: 'Điểm số không được để trống' })
  @IsNumber()
  @Min(0)
  score: number;

  @ApiPropertyOptional({ description: 'Nhận xét chi tiết của giáo viên' })
  @IsOptional()
  @IsString()
  feedback?: string;
}
