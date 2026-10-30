import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsEnum, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export enum RevenueGroupBy {
  MONTH = 'month',
  DAY = 'day',
}

export enum ExportReportType {
  REVENUE = 'revenue',
  DEBTS = 'debts',
  ATTENDANCE = 'attendance',
  WORKLOAD = 'workload',
}

export class GetRevenueReportDto {
  @ApiPropertyOptional({ description: 'Năm cần xem thống kê (mặc định năm hiện tại)', default: new Date().getFullYear() })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(2020)
  @Max(2050)
  year?: number;

  @ApiPropertyOptional({ description: 'ID chi nhánh cần lọc' })
  @IsOptional()
  @IsString()
  branchId?: string;

  @ApiPropertyOptional({ description: 'Nhóm theo tháng hoặc theo ngày', enum: RevenueGroupBy, default: RevenueGroupBy.MONTH })
  @IsOptional()
  @IsEnum(RevenueGroupBy)
  groupBy?: RevenueGroupBy = RevenueGroupBy.MONTH;
}

export class GetAttendanceReportDto {
  @ApiPropertyOptional({ description: 'ID lớp học cần lọc' })
  @IsOptional()
  @IsString()
  classId?: string;

  @ApiPropertyOptional({ description: 'Từ ngày (YYYY-MM-DD)' })
  @IsOptional()
  @IsString()
  startDate?: string;

  @ApiPropertyOptional({ description: 'Đến ngày (YYYY-MM-DD)' })
  @IsOptional()
  @IsString()
  endDate?: string;
}

export class GetAcademicReportDto {
  @ApiPropertyOptional({ description: 'ID lớp học cần lọc' })
  @IsOptional()
  @IsString()
  classId?: string;

  @ApiPropertyOptional({ description: 'ID kỳ thi / bài kiểm tra cần lọc' })
  @IsOptional()
  @IsString()
  examId?: string;
}

export class GetDebtsReportDto {
  @ApiPropertyOptional({ description: 'ID chi nhánh' })
  @IsOptional()
  @IsString()
  branchId?: string;

  @ApiPropertyOptional({ description: 'Tìm theo tên hoặc mã học viên' })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({ description: 'Trang hiện tại', default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({ description: 'Số bản ghi mỗi trang', default: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 20;
}
