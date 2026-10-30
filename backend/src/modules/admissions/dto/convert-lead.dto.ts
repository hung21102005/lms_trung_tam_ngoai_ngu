import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MinLength } from 'class-validator';

export class ConvertLeadDto {
  @ApiPropertyOptional({
    example: 'IELTS 4.5',
    description: 'Trình độ đầu vào sau khi kiểm tra xếp lớp (Placement test)',
  })
  @IsOptional()
  @IsString()
  entryLevel?: string;

  @ApiPropertyOptional({
    example: 'IELTS 6.5',
    description: 'Mục tiêu điểm số đầu ra của học viên',
  })
  @IsOptional()
  @IsString()
  targetLevel?: string;

  @ApiPropertyOptional({
    example: 'THPT Gia Định',
    description: 'Trường học hoặc đơn vị công tác hiện tại',
  })
  @IsOptional()
  @IsString()
  schoolName?: string;

  @ApiPropertyOptional({
    example: 'Student@2026',
    description: 'Mật khẩu tạm thời ban đầu (nếu không cung cấp, hệ thống tự động sinh ngẫu nhiên)',
  })
  @IsOptional()
  @IsString()
  @MinLength(6, { message: 'Mật khẩu tạm tối thiểu 6 ký tự' })
  temporaryPassword?: string;

  @ApiPropertyOptional({
    example: 'uuid-chi-nhanh',
    description: 'Chi nhánh chính thức của học viên (nếu muốn ghi đè chi nhánh trên lead)',
  })
  @IsOptional()
  @IsString()
  branchId?: string;

  @ApiPropertyOptional({
    example: 'Đã hoàn tất kiểm tra đầu vào, xếp vào khóa IELTS Foundation',
    description: 'Ghi chú học vụ khi tiếp nhận',
  })
  @IsOptional()
  @IsString()
  notes?: string;
}
