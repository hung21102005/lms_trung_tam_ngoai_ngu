import {
  Controller,
  Get,
  Param,
  Post,
  Query,
  Res,
  UseGuards,
} from '@nestjs/common';
import type { Response } from 'express';
import { ApiBearerAuth, ApiOperation, ApiParam, ApiQuery, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { RolesGuard } from '../auth/guards/roles.guard.js';
import { Roles } from '../auth/decorators/roles.decorator.js';
import { CurrentUser } from '../auth/decorators/current-user.decorator.js';
import { ReportsService } from './reports.service.js';
import {
  GetRevenueReportDto,
  GetAttendanceReportDto,
  GetAcademicReportDto,
  GetDebtsReportDto,
  ExportReportType,
} from './dto/index.js';

@ApiTags('Reports & Analytics (Báo cáo & Thống kê)')
@Controller('reports')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth()
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @Get('teacher/dashboard')
  @Roles('teacher', 'teaching_assistant')
  @ApiOperation({ summary: 'Dashboard của giảng viên đang đăng nhập' })
  getTeacherDashboard(@CurrentUser() user: { id: string }) {
    return this.reportsService.getTeacherDashboard(user.id);
  }

  @Get('dashboard')
  @Roles('super_admin', 'branch_admin', 'academic_staff', 'cashier')
  @ApiOperation({ summary: 'Lấy dữ liệu tổng quan cho Dashboard (KPIs, doanh thu, lớp học, công nợ)' })
  async getDashboardOverview() {
    return this.reportsService.getDashboardOverview();
  }

  @Post('dashboard/refresh-cache')
  @Roles('super_admin', 'branch_admin')
  @ApiOperation({ summary: 'Làm mới cache Redis của Dashboard' })
  async refreshDashboardCache() {
    await this.reportsService.clearDashboardCache();
    return { success: true, message: 'Đã xóa cache dashboard thành công' };
  }

  @Get('revenue')
  @Roles('super_admin', 'branch_admin', 'cashier')
  @ApiOperation({ summary: 'Báo cáo doanh thu theo tháng/năm, chi nhánh, phương thức' })
  async getRevenueReport(@Query() dto: GetRevenueReportDto) {
    return this.reportsService.getRevenueReport(dto);
  }

  @Get('attendance')
  @Roles('super_admin', 'branch_admin', 'academic_staff', 'teacher')
  @ApiOperation({ summary: 'Báo cáo tỷ lệ chuyên cần theo lớp hoặc thời gian' })
  async getAttendanceReport(@Query() dto: GetAttendanceReportDto,
    @CurrentUser() user: { id: string; roles: string[] }) {
    return this.reportsService.getAttendanceReport(dto,
      user.roles.includes('teacher') ? user.id : undefined);
  }

  @Get('academic')
  @Roles('super_admin', 'branch_admin', 'academic_staff', 'teacher')
  @ApiOperation({ summary: 'Báo cáo kết quả học tập và phân loại học lực' })
  async getAcademicReport(@Query() dto: GetAcademicReportDto,
    @CurrentUser() user: { id: string; roles: string[] }) {
    return this.reportsService.getAcademicReport(dto,
      user.roles.includes('teacher') ? user.id : undefined);
  }

  @Get('debts')
  @Roles('super_admin', 'branch_admin', 'cashier', 'academic_staff')
  @ApiOperation({ summary: 'Báo cáo danh sách công nợ học phí chưa thanh toán' })
  async getDebtsReport(@Query() dto: GetDebtsReportDto) {
    return this.reportsService.getDebtsReport(dto);
  }

  @Get('teacher-workload')
  @Roles('super_admin', 'branch_admin', 'academic_staff')
  @ApiOperation({ summary: 'Báo cáo thống kê tải giờ dạy của giáo viên' })
  async getTeacherWorkloadReport() {
    return this.reportsService.getTeacherWorkloadReport();
  }

  @Get('export/:type')
  @Roles('super_admin', 'branch_admin', 'cashier', 'academic_staff')
  @ApiOperation({ summary: 'Xuất file Excel báo cáo (.xlsx)' })
  @ApiParam({ name: 'type', enum: ExportReportType, description: 'Loại báo cáo cần xuất' })
  async exportReport(
    @Param('type') type: ExportReportType,
    @Res() res: Response,
  ) {
    const buffer = await this.reportsService.exportReportExcel(type);
    const dateStr = new Date().toISOString().slice(0, 10);
    const filename = `bao-cao-${type}-${dateStr}.xlsx`;

    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    res.setHeader(
      'Content-Disposition',
      `attachment; filename="${filename}"`,
    );

    res.end(buffer);
  }
}
