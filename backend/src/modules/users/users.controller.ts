import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  Query,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  HttpCode,
  HttpStatus,
  BadRequestException,
  ForbiddenException,
  Res,
} from '@nestjs/common';
import type { Response } from 'express';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiConsumes,
  ApiBody,
} from '@nestjs/swagger';
import { UsersService } from './users.service.js';
import {
  QueryUsersDto,
  CreateStudentDto,
  CreateParentDto,
  CreateStaffDto,
  UpdateUserDto,
  UpdateUserStatusDto,
  AdminResetPasswordDto,
  AssignRolesDto,
} from './dto/index.js';
import { JwtAuthGuard, RolesGuard, Roles, CurrentUser } from '../auth/index.js';

@ApiTags('Users Management (Quản lý người dùng & Cấp phát tài khoản)')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  private scopedBranch(
    actor: { roles: string[]; branchId?: string | null },
    branchId?: string,
  ) {
    if (actor.roles.includes('super_admin')) return branchId;
    if (!actor.branchId || (branchId && branchId !== actor.branchId)) {
      throw new ForbiddenException(
        'Bạn chỉ được quản lý dữ liệu chi nhánh của mình.',
      );
    }
    return actor.branchId;
  }

  // --------------------------------------------------------------------------
  // 1. GET /users — Danh sách người dùng
  // --------------------------------------------------------------------------
  @Roles('super_admin', 'branch_admin', 'academic_staff')
  @Get()
  @ApiOperation({
    summary:
      'Danh sách người dùng phân trang, tìm kiếm theo tên/email/phone, lọc theo role/chi nhánh/trạng thái',
  })
  @ApiResponse({
    status: 200,
    description: 'Lấy danh sách người dùng thành công',
  })
  findAll(
    @Query() query: QueryUsersDto,
    @CurrentUser() actor: { roles: string[]; branchId?: string | null },
  ) {
    query.branchId = this.scopedBranch(actor, query.branchId);
    return this.usersService.findAll(query);
  }

  @Roles('super_admin', 'branch_admin', 'academic_staff')
  @Get('export/xlsx')
  async exportUsers(
    @Res() res: Response,
    @CurrentUser() actor: { roles: string[]; branchId?: string | null },
  ) {
    const buffer = await this.usersService.exportUsersExcel(
      this.scopedBranch(actor),
    );
    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    res.setHeader('Content-Disposition', 'attachment; filename="users.xlsx"');
    res.end(buffer);
  }

  @Roles('super_admin', 'branch_admin', 'academic_staff', 'teacher')
  @Get('teachers/lookup')
  findTeacherOptions(
    @Query('branchId') branchId: string | undefined,
    @CurrentUser() actor: { roles: string[]; branchId?: string | null },
  ) {
    const scopedBranch = this.scopedBranch(actor, branchId);
    if (!scopedBranch) {
      throw new BadRequestException(
        'Vui lòng chọn chi nhánh để tra cứu giáo viên.',
      );
    }
    return this.usersService.findTeacherOptions(scopedBranch);
  }

  // --------------------------------------------------------------------------
  // 2. POST /users/students — Cấp tài khoản học viên mới
  // --------------------------------------------------------------------------
  @Roles('super_admin', 'branch_admin', 'academic_staff')
  @Post('students')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary:
      'Admin hoặc Nhân viên học vụ cấp tài khoản học viên mới kèm hồ sơ đào tạo',
  })
  @ApiResponse({
    status: 201,
    description: 'Cấp tài khoản học viên thành công',
  })
  @ApiResponse({
    status: 409,
    description: 'Email hoặc số điện thoại đã tồn tại',
  })
  createStudent(
    @Body() dto: CreateStudentDto,
    @CurrentUser() actor: { roles: string[]; branchId?: string | null },
  ) {
    dto.branchId = this.scopedBranch(actor, dto.branchId);
    return this.usersService.createStudent(dto);
  }

  // --------------------------------------------------------------------------
  // 3. POST /users/parents — Cấp tài khoản phụ huynh & liên kết con
  // --------------------------------------------------------------------------
  @Roles('super_admin', 'branch_admin', 'academic_staff')
  @Post('parents')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Cấp tài khoản phụ huynh và liên kết danh sách học viên là con em',
  })
  @ApiResponse({
    status: 201,
    description: 'Cấp tài khoản phụ huynh thành công',
  })
  @ApiResponse({
    status: 409,
    description: 'Số điện thoại hoặc email đã tồn tại',
  })
  async createParent(
    @Body() dto: CreateParentDto,
    @CurrentUser() actor: { roles: string[]; branchId?: string | null },
  ) {
    dto.branchId = this.scopedBranch(actor, dto.branchId);
    if (!actor.roles.includes('super_admin')) {
      for (const studentId of dto.studentIds ?? []) {
        await this.usersService.assertBranchAccess(actor, studentId);
      }
    }
    return this.usersService.createParent(dto);
  }

  // --------------------------------------------------------------------------
  // 4. POST /users/staff — Cấp tài khoản nhân sự (giáo viên, trợ giảng, học vụ, thu ngân)
  // --------------------------------------------------------------------------
  @Roles('super_admin', 'branch_admin')
  @Post('staff')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Admin cấp tài khoản nhân viên / giáo viên kèm hồ sơ chuyên môn',
  })
  @ApiResponse({
    status: 201,
    description: 'Cấp tài khoản nhân viên thành công',
  })
  @ApiResponse({ status: 409, description: 'Email đã tồn tại' })
  createStaff(
    @Body() dto: CreateStaffDto,
    @CurrentUser() actor: { roles: string[]; branchId?: string | null },
  ) {
    if (
      dto.roleCode === 'super_admin' ||
      (dto.roleCode === 'branch_admin' && !actor.roles.includes('super_admin'))
    ) {
      throw new ForbiddenException(
        'Chỉ Super Admin được cấp tài khoản quản trị.',
      );
    }
    dto.branchId = this.scopedBranch(actor, dto.branchId);
    return this.usersService.createStaff(dto);
  }

  // --------------------------------------------------------------------------
  // 5. POST /users/import — Nhập danh sách học viên từ file Excel
  // --------------------------------------------------------------------------
  @Roles('super_admin', 'branch_admin', 'academic_staff')
  @Post('import')
  @HttpCode(HttpStatus.OK)
  @UseInterceptors(FileInterceptor('file'))
  @ApiOperation({
    summary: 'Nhập danh sách học viên hàng loạt từ file Excel (.xlsx, .xls)',
  })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: {
          type: 'string',
          format: 'binary',
          description: 'File Excel (.xlsx) danh sách học viên',
        },
        branchId: {
          type: 'string',
          description: 'ID chi nhánh tiếp nhận các học viên này (tùy chọn)',
        },
      },
    },
  })
  @ApiResponse({ status: 200, description: 'Xử lý file Excel thành công' })
  importStudents(
    @UploadedFile()
    file: { buffer: Buffer; originalname?: string; mimetype?: string },
    @Body('branchId') branchId?: string,
    @CurrentUser() actor?: { roles: string[]; branchId?: string | null },
  ) {
    if (!file) {
      throw new BadRequestException('Vui lòng chọn file Excel tải lên.');
    }
    return this.usersService.importStudentsFromExcel(
      file.buffer,
      this.scopedBranch(actor!, branchId),
    );
  }

  // --------------------------------------------------------------------------
  // 6. GET /users/:id — Chi tiết người dùng kèm thông tin hồ sơ
  // --------------------------------------------------------------------------
  @Get(':id')
  @Roles('super_admin', 'branch_admin', 'academic_staff')
  @ApiOperation({
    summary:
      'Xem chi tiết thông tin người dùng kèm hồ sơ học tập / giảng dạy và quan hệ gia đình',
  })
  @ApiResponse({
    status: 200,
    description: 'Lấy chi tiết người dùng thành công',
  })
  @ApiResponse({ status: 404, description: 'Không tìm thấy người dùng' })
  async findOne(
    @Param('id') id: string,
    @CurrentUser() actor: { roles: string[]; branchId?: string | null },
  ) {
    await this.usersService.assertBranchAccess(actor, id);
    return this.usersService.findOne(id);
  }

  // --------------------------------------------------------------------------
  // 6b. PATCH /users/profile/me — Người dùng tự cập nhật thông tin cá nhân
  // --------------------------------------------------------------------------
  @Patch('profile/me')
  @ApiOperation({
    summary:
      'Người dùng tự cập nhật thông tin cá nhân (họ tên, SĐT, địa chỉ, ngày sinh, avatar)',
  })
  @ApiResponse({
    status: 200,
    description: 'Cập nhật hồ sơ cá nhân thành công',
  })
  updateMyProfile(
    @CurrentUser('id') userId: string,
    @Body() dto: UpdateUserDto,
  ) {
    return this.usersService.updateUser(userId, {
      fullName: dto.fullName,
      email: dto.email,
      phone: dto.phone,
      avatarUrl: dto.avatarUrl,
      gender: dto.gender,
      dateOfBirth: dto.dateOfBirth,
      address: dto.address,
    });
  }

  // --------------------------------------------------------------------------
  // 7. PATCH /users/:id — Cập nhật thông tin người dùng
  // --------------------------------------------------------------------------
  @Roles('super_admin', 'branch_admin', 'academic_staff')
  @Patch(':id')
  @ApiOperation({
    summary: 'Cập nhật thông tin cá nhân và hồ sơ chuyên biệt của người dùng',
  })
  @ApiResponse({ status: 200, description: 'Cập nhật thành công' })
  @ApiResponse({ status: 404, description: 'Không tìm thấy người dùng' })
  async updateUser(
    @Param('id') id: string,
    @Body() dto: UpdateUserDto,
    @CurrentUser() actor: { roles: string[]; branchId?: string | null },
  ) {
    await this.usersService.assertBranchAccess(actor, id);
    if (dto.branchId) dto.branchId = this.scopedBranch(actor, dto.branchId);
    return this.usersService.updateUser(id, dto);
  }

  // --------------------------------------------------------------------------
  // 8. PATCH /users/:id/status — Khóa / Mở khóa tài khoản
  // --------------------------------------------------------------------------
  @Roles('super_admin', 'branch_admin')
  @Patch(':id/status')
  @ApiOperation({
    summary:
      'Khóa hoặc mở khóa trạng thái tài khoản (ACTIVE, LOCKED, INACTIVE)',
  })
  @ApiResponse({ status: 200, description: 'Cập nhật trạng thái thành công' })
  @ApiResponse({
    status: 400,
    description: 'Không thể khóa Super Admin duy nhất',
  })
  async updateUserStatus(
    @Param('id') id: string,
    @Body() dto: UpdateUserStatusDto,
    @CurrentUser() actor: { roles: string[]; branchId?: string | null },
  ) {
    await this.usersService.assertBranchAccess(actor, id);
    return this.usersService.updateUserStatus(id, dto);
  }

  // --------------------------------------------------------------------------
  // 8b. DELETE /users/:id — Xóa vĩnh viễn tài khoản chưa phát sinh dữ liệu
  // --------------------------------------------------------------------------
  @Roles('super_admin')
  @Delete(':id')
  @ApiOperation({
    summary: 'Xóa vĩnh viễn tài khoản chưa phát sinh dữ liệu (Chỉ Super Admin)',
  })
  @ApiResponse({ status: 200, description: 'Xóa tài khoản thành công' })
  @ApiResponse({
    status: 400,
    description:
      'Không thể xóa tài khoản đã có lịch sử học tập, giảng dạy hoặc hóa đơn',
  })
  async deleteUser(
    @Param('id') id: string,
    @CurrentUser('id') actorId: string,
    @CurrentUser() actor: { roles: string[]; branchId?: string | null },
  ) {
    await this.usersService.assertBranchAccess(actor, id);
    return this.usersService.deleteUser(id, actorId);
  }

  // --------------------------------------------------------------------------
  // 9. POST /users/:id/reset-password — Admin cấp lại mật khẩu tạm thời
  // --------------------------------------------------------------------------
  @Roles('super_admin', 'branch_admin')
  @Post(':id/reset-password')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Admin cấp lại mật khẩu tạm thời cho người dùng (bắt buộc đổi mật khẩu khi đăng nhập)',
  })
  @ApiResponse({ status: 200, description: 'Cấp lại mật khẩu thành công' })
  async adminResetPassword(
    @Param('id') id: string,
    @Body() dto: AdminResetPasswordDto,
    @CurrentUser() actor: { roles: string[]; branchId?: string | null },
  ) {
    await this.usersService.assertBranchAccess(actor, id);
    return this.usersService.adminResetPassword(id, dto);
  }

  // --------------------------------------------------------------------------
  // 10. GET /users/:id/roles — Xem danh sách vai trò
  // --------------------------------------------------------------------------
  @Get(':id/roles')
  @Roles('super_admin', 'branch_admin', 'academic_staff')
  @ApiOperation({
    summary: 'Xem danh sách các vai trò (roles) hiện tại của người dùng',
  })
  @ApiResponse({ status: 200, description: 'Lấy vai trò thành công' })
  async getUserRoles(
    @Param('id') id: string,
    @CurrentUser() actor: { roles: string[]; branchId?: string | null },
  ) {
    await this.usersService.assertBranchAccess(actor, id);
    return this.usersService.getUserRoles(id);
  }

  // --------------------------------------------------------------------------
  // 11. POST /users/:id/roles — Gán vai trò cho người dùng
  // --------------------------------------------------------------------------
  @Roles('super_admin')
  @Post(':id/roles')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Gán hoặc thay đổi danh sách vai trò của người dùng (Chỉ Super Admin)',
  })
  @ApiResponse({ status: 200, description: 'Gán vai trò thành công' })
  assignRoles(@Param('id') id: string, @Body() dto: AssignRolesDto) {
    return this.usersService.assignRoles(id, dto);
  }
}
