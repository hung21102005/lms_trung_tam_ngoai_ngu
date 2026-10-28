import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsNotEmpty,
  IsString,
  IsOptional,
  IsUUID,
  IsEnum,
  IsArray,
  IsInt,
  Min,
  Matches,
  IsDateString,
  IsNumber,
} from 'class-validator';
import { ClassStatus } from '@prisma/client';

export class CreateClassDto {
  @ApiProperty({
    example: 'IELTS-F-2026-02',
    description: 'Mã lớp học (duy nhất toàn hệ thống)',
  })
  @IsNotEmpty({ message: 'Mã lớp không được để trống' })
  @IsString()
  @Matches(/^[A-Z0-9_-]+$/, {
    message: 'Mã lớp chỉ chứa chữ hoa, số, gạch dưới và gạch nối',
  })
  code!: string;

  @ApiProperty({
    example: 'Lớp IELTS Foundation T2-T4-T6 (Tối)',
    description: 'Tên lớp học',
  })
  @IsNotEmpty({ message: 'Tên lớp học không được để trống' })
  @IsString()
  name!: string;

  @ApiProperty({
    example: 'uuid-course',
    description: 'ID khóa học',
  })
  @IsNotEmpty({ message: 'Khóa học không được để trống' })
  @IsUUID('4', { message: 'courseId phải là định dạng UUID' })
  courseId!: string;

  @ApiProperty({
    example: 'uuid-level',
    description: 'ID cấp độ trong khóa học',
  })
  @IsNotEmpty({ message: 'Cấp độ không được để trống' })
  @IsUUID('4', { message: 'levelId phải là định dạng UUID' })
  levelId!: string;

  @ApiProperty({
    example: 'uuid-branch',
    description: 'ID chi nhánh mở lớp',
  })
  @IsNotEmpty({ message: 'Chi nhánh không được để trống' })
  @IsUUID('4', { message: 'branchId phải là định dạng UUID' })
  branchId!: string;

  @ApiPropertyOptional({
    example: 'uuid-room',
    description: 'ID phòng học cố định',
  })
  @IsOptional()
  @IsUUID('4', { message: 'roomId phải là định dạng UUID' })
  roomId?: string;

  @ApiPropertyOptional({
    example: 'uuid-teacher',
    description: 'ID giáo viên đứng lớp chính',
  })
  @IsOptional()
  @IsUUID('4', { message: 'mainTeacherId phải là định dạng UUID' })
  mainTeacherId?: string;

  @ApiPropertyOptional({
    example: 'uuid-assistant',
    description: 'ID trợ giảng phụ trách',
  })
  @IsOptional()
  @IsUUID('4', { message: 'assistantTeacherId phải là định dạng UUID' })
  assistantTeacherId?: string;

  @ApiPropertyOptional({
    enum: ClassStatus,
    default: ClassStatus.PLANNING,
    description: 'Trạng thái lớp học',
  })
  @IsOptional()
  @IsEnum(ClassStatus, { message: 'Trạng thái lớp học không hợp lệ' })
  status?: ClassStatus;

  @ApiProperty({
    example: '2026-11-02',
    description: 'Ngày bắt đầu khóa học (YYYY-MM-DD)',
  })
  @IsNotEmpty({ message: 'Ngày bắt đầu không được để trống' })
  @IsDateString(
    {},
    { message: 'Định dạng ngày bắt đầu không hợp lệ (YYYY-MM-DD)' },
  )
  startDate!: string;

  @ApiProperty({
    example: ['MONDAY', 'WEDNESDAY', 'FRIDAY'],
    description: 'Các thứ học trong tuần',
  })
  @IsArray({ message: 'scheduleDays phải là mảng chuỗi các ngày trong tuần' })
  @IsNotEmpty({ message: 'Lịch học trong tuần không được để trống' })
  scheduleDays!: string[];

  @ApiProperty({
    example: '18:00',
    description: 'Giờ bắt đầu học (HH:mm)',
  })
  @IsNotEmpty({ message: 'Giờ bắt đầu không được để trống' })
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, {
    message: 'Định dạng giờ bắt đầu không hợp lệ (HH:mm)',
  })
  startTime!: string;

  @ApiProperty({
    example: '19:30',
    description: 'Giờ kết thúc học (HH:mm)',
  })
  @IsNotEmpty({ message: 'Giờ kết thúc không được để trống' })
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, {
    message: 'Định dạng giờ kết thúc không hợp lệ (HH:mm)',
  })
  endTime!: string;

  @ApiPropertyOptional({
    example: 24,
    description: 'Tổng số buổi học của khóa',
    default: 24,
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  totalSessions?: number;

  @ApiPropertyOptional({
    example: 20,
    description: 'Sĩ số tối đa của lớp',
    default: 20,
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  maxCapacity?: number;

  @ApiPropertyOptional({
    example: 6500000,
    description: 'Học phí thực tế áp dụng cho lớp này',
  })
  @IsOptional()
  @IsNumber()
  @Min(0)
  tuitionFee?: number;

  @ApiPropertyOptional({
    example: '2026-10-01',
    description: 'Ngày bắt đầu nhận đăng ký',
  })
  @IsOptional()
  @IsDateString({}, { message: 'Ngày bắt đầu đăng ký không hợp lệ' })
  registrationOpenAt?: string;

  @ApiPropertyOptional({
    example: '2026-10-31',
    description: 'Ngày kết thúc nhận đăng ký',
  })
  @IsOptional()
  @IsDateString({}, { message: 'Ngày kết thúc đăng ký không hợp lệ' })
  registrationCloseAt?: string;

  @ApiPropertyOptional({
    example: 'Lớp chuẩn bị thi IELTS đợt tháng 3/2027',
    description: 'Ghi chú lớp học',
  })
  @IsOptional()
  @IsString()
  notes?: string;
}
