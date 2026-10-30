import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';

export enum RegistrationReviewAction {
  CONTACTED = 'CONTACTED',
  REJECTED = 'REJECTED',
  CANCELLED = 'CANCELLED',
  REOPEN = 'REOPEN',
}

export class ReviewClassRegistrationDto {
  @ApiProperty({ enum: RegistrationReviewAction })
  @IsEnum(RegistrationReviewAction)
  status!: RegistrationReviewAction;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  notes?: string;
}

export class ApproveClassRegistrationDto {
  @ApiPropertyOptional({
    description:
      'Học viên đã xác minh; đơn khách mới cần chuyển Lead hoặc xác nhận tài khoản trước.',
  })
  @IsOptional()
  @IsUUID()
  studentId?: string;
}
