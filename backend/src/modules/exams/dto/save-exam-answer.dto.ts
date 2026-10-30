import { ApiProperty } from '@nestjs/swagger';
import { IsArray, IsNotEmpty, IsString, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

export class AnswerItemDto {
  @ApiProperty({ description: 'ID câu hỏi đề thi (examQuestionId)' })
  @IsNotEmpty()
  @IsString()
  examQuestionId: string;

  @ApiProperty({ description: 'Câu trả lời của học viên' })
  studentAnswer: any;
}

export class SaveExamAnswersDto {
  @ApiProperty({ description: 'Danh sách các câu trả lời cần lưu', type: [AnswerItemDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => AnswerItemDto)
  answers: AnswerItemDto[];
}
