import {
  Controller,
  Post,
  Get,
  Patch,
  Delete,
  Param,
  Body,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
  Res,
  ForbiddenException,
} from '@nestjs/common';
import type { Response } from 'express';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { AdmissionsService } from './admissions.service.js';
import {
  CreateLeadDto,
  UpdateLeadDto,
  CloseLeadDto,
  ArchiveLeadDto,
  QueryLeadsDto,
  ConvertLeadDto,
} from './dto/index.js';
import {
  JwtAuthGuard,
  RolesGuard,
  Roles,
  Public,
  CurrentUser,
} from '../auth/index.js';

@ApiTags('Admissions & Leads')
@Controller('admissions/leads')
export class AdmissionsController {
  constructor(private readonly admissionsService: AdmissionsService) {}

  private scopedBranch(
    actor: { roles: string[]; branchId?: string | null },
    branchId?: string,
  ) {
    if (actor.roles.includes('super_admin')) return branchId;
    if (!actor.branchId || (branchId && branchId !== actor.branchId)) {
      throw new ForbiddenException(
        'Bạn chỉ được quản lý hồ sơ tư vấn ở chi nhánh của mình.',
      );
    }
    return actor.branchId;
  }

  private async assertLeadAccess(
    actor: { roles: string[]; branchId?: string | null },
    id: string,
  ) {
    const branchId = this.scopedBranch(actor);
    if (branchId) await this.admissionsService.assertBranchAccess(id, branchId);
  }

  @Public()
  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Đăng ký tư vấn học tập trực tuyến (Công khai cho Website/App)',
    description:
      'Học viên hoặc phụ huynh để lại thông tin nhu cầu học tập từ trang web hoặc ứng dụng di động.',
  })
  @ApiResponse({
    status: 201,
    description: 'Tiếp nhận thông tin tư vấn thành công',
  })
  @ApiResponse({ status: 400, description: 'Dữ liệu đầu vào không hợp lệ' })
  createLead(@Body() dto: CreateLeadDto) {
    return this.admissionsService.createLead(dto);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'branch_admin', 'academic_staff')
  @ApiBearerAuth('JWT-auth')
  @Get()
  @ApiOperation({
    summary: 'Danh sách hồ sơ tư vấn tuyển sinh (Phân trang, Lọc & Tìm kiếm)',
    description:
      'Dành cho Quản trị viên và Nhân viên học vụ theo dõi các leads đăng ký học.',
  })
  @ApiResponse({ status: 200, description: 'Lấy danh sách thành công' })
  findAll(
    @Query() query: QueryLeadsDto,
    @CurrentUser() actor: { roles: string[]; branchId?: string | null },
  ) {
    query.branchId = this.scopedBranch(actor, query.branchId);
    return this.admissionsService.findAll(query);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'branch_admin', 'academic_staff')
  @ApiBearerAuth('JWT-auth')
  @Get('summary')
  @ApiOperation({
    summary: 'Thống kê tổng hợp số lượng Lead theo trạng thái & lưu trữ',
  })
  getSummary(
    @Query('branchId') branchId: string | undefined,
    @CurrentUser() actor: { roles: string[]; branchId?: string | null },
  ) {
    return this.admissionsService.getSummary(
      this.scopedBranch(actor, branchId),
    );
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'branch_admin', 'academic_staff')
  @ApiBearerAuth('JWT-auth')
  @Get('export/xlsx')
  async exportLeads(
    @Res() res: Response,
    @CurrentUser() actor: { roles: string[]; branchId?: string | null },
  ) {
    const buffer = await this.admissionsService.exportLeadsExcel(
      this.scopedBranch(actor),
    );
    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    res.setHeader('Content-Disposition', 'attachment; filename="leads.xlsx"');
    res.end(buffer);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'branch_admin', 'academic_staff')
  @ApiBearerAuth('JWT-auth')
  @Get(':id')
  @ApiOperation({
    summary: 'Chi tiết một hồ sơ tư vấn tuyển sinh',
  })
  @ApiResponse({
    status: 200,
    description: 'Lấy thông tin chi tiết thành công',
  })
  @ApiResponse({ status: 404, description: 'Không tìm thấy hồ sơ' })
  async findOne(
    @Param('id') id: string,
    @CurrentUser() actor: { roles: string[]; branchId?: string | null },
  ) {
    await this.assertLeadAccess(actor, id);
    return this.admissionsService.findOne(id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'branch_admin', 'academic_staff')
  @ApiBearerAuth('JWT-auth')
  @Patch(':id')
  @ApiOperation({
    summary:
      'Cập nhật tiến trình tư vấn (Trạng thái, Ghi chú, Phân công nhân viên)',
  })
  @ApiResponse({
    status: 200,
    description: 'Cập nhật tiến trình tư vấn thành công',
  })
  @ApiResponse({ status: 404, description: 'Không tìm thấy hồ sơ' })
  async updateLead(
    @Param('id') id: string,
    @Body() dto: UpdateLeadDto,
    @CurrentUser() actor: { roles: string[]; branchId?: string | null },
  ) {
    await this.assertLeadAccess(actor, id);
    if (dto.branchId) dto.branchId = this.scopedBranch(actor, dto.branchId);
    return this.admissionsService.updateLead(id, dto);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'branch_admin', 'academic_staff')
  @ApiBearerAuth('JWT-auth')
  @Post(':id/close')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Đóng hồ sơ tư vấn (Không còn nhu cầu / Không liên hệ được / ...)',
  })
  async closeLead(
    @Param('id') id: string,
    @Body() body: CloseLeadDto,
    @CurrentUser()
    actor: { id?: string; roles: string[]; branchId?: string | null },
  ) {
    await this.assertLeadAccess(actor, id);
    return this.admissionsService.closeLead(id, body, actor.id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'branch_admin', 'academic_staff')
  @ApiBearerAuth('JWT-auth')
  @Post(':id/archive')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Lưu trữ hồ sơ Lead (ẩn khỏi Kanban đang hoạt động, giữ lịch sử)',
  })
  async archiveLead(
    @Param('id') id: string,
    @Body() body: ArchiveLeadDto,
    @CurrentUser()
    actor: { id?: string; roles: string[]; branchId?: string | null },
  ) {
    await this.assertLeadAccess(actor, id);
    return this.admissionsService.archiveLead(id, body, actor.id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'branch_admin', 'academic_staff')
  @ApiBearerAuth('JWT-auth')
  @Post(':id/restore')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Khôi phục hồ sơ Lead từ mục Lưu trữ hoặc Đã đóng',
  })
  async restoreLead(
    @Param('id') id: string,
    @CurrentUser()
    actor: { id?: string; roles: string[]; branchId?: string | null },
  ) {
    await this.assertLeadAccess(actor, id);
    return this.admissionsService.restoreLead(id, actor.id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'branch_admin', 'academic_staff')
  @ApiBearerAuth('JWT-auth')
  @Delete(':id')
  @ApiOperation({
    summary: 'Xóa vĩnh viễn Lead thử nghiệm khi đủ điều kiện an toàn dữ liệu',
  })
  async deleteLead(
    @Param('id') id: string,
    @CurrentUser() actor: { roles: string[]; branchId?: string | null },
  ) {
    await this.assertLeadAccess(actor, id);
    return this.admissionsService.deleteLead(id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'branch_admin', 'academic_staff')
  @ApiBearerAuth('JWT-auth')
  @Post(':id/convert')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Chuyển đổi hồ sơ tư vấn thành Học viên chính thức & Cấp phát tài khoản',
    description:
      'Tự động tạo mã học viên (HV-YYYY-XXXX), cấp mật khẩu tạm, kích hoạt tài khoản và gửi email chào mừng.',
  })
  @ApiResponse({
    status: 200,
    description: 'Chuyển đổi thành công học viên và cấp tài khoản',
  })
  @ApiResponse({
    status: 400,
    description: 'Hồ sơ đã được chuyển đổi trước đó hoặc thiếu dữ liệu',
  })
  @ApiResponse({ status: 404, description: 'Không tìm thấy hồ sơ tư vấn' })
  async convertLead(
    @Param('id') id: string,
    @Body() dto: ConvertLeadDto,
    @CurrentUser() actor: { roles: string[]; branchId?: string | null },
  ) {
    await this.assertLeadAccess(actor, id);
    if (dto.branchId) dto.branchId = this.scopedBranch(actor, dto.branchId);
    return this.admissionsService.convertLead(id, dto);
  }
}
