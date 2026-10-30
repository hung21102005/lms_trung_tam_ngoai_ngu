import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsString, IsOptional, IsEmail, IsEnum } from 'class-validator';
import { LeadSource } from '@prisma/client';

export class CreateLeadDto {
  @ApiProperty({
    example: 'Nguyễn Văn An',
    description: 'Họ và tên người có nhu cầu học',
  })
  @IsNotEmpty({ message: 'Họ và tên không được để trống' })
  @IsString({ message: 'Họ và tên phải là chuỗi ký tự' })
  fullName!: string;

  @ApiProperty({
    example: '0988776655',
    description: 'Số điện thoại liên hệ',
  })
  @IsNotEmpty({ message: 'Số điện thoại không được để trống' })
  @IsString({ message: 'Số điện thoại phải là chuỗi ký tự' })
  phone!: string;

  @ApiPropertyOptional({
    example: 'nguyenvanan@gmail.com',
    description: 'Email liên hệ nhận tư vấn và thông tin khóa học',
  })
  @IsOptional()
  @IsEmail({}, { message: 'Định dạng email không hợp lệ' })
  email?: string;

  @ApiPropertyOptional({
    example: 'Luyện thi IELTS Cấp Tốc 6.5',
    description: 'Khóa học hoặc chương trình học viên quan tâm',
  })
  @IsOptional()
  @IsString()
  targetCourse?: string;

  @ApiPropertyOptional({
    enum: LeadSource,
    default: LeadSource.WEBSITE,
    description: 'Nguồn tiếp nhận lead: WEBSITE, FACEBOOK, ZALO, DIRECT_WALKIN, REFERRAL, OTHER',
  })
  @IsOptional()
  @IsEnum(LeadSource, { message: 'Nguồn lead không hợp lệ' })
  source?: LeadSource;

  @ApiPropertyOptional({
    example: 'uuid-chi-nhanh',
    description: 'ID chi nhánh thuận tiện học viên muốn đăng ký',
  })
  @IsOptional()
  @IsString()
  branchId?: string;

  @ApiPropertyOptional({
    example: 'Muốn học vào các buổi tối trong tuần',
    description: 'Ghi chú ban đầu của người đăng ký',
  })
  @IsOptional()
  @IsString()
  notes?: string;
}
