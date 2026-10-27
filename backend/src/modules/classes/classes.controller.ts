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
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';
import { ClassesService } from './classes.service.js';
import {
  CreateClassDto,
  UpdateClassDto,
  EnrollStudentDto,
  UpdateClassSessionDto,
  QueryClassesDto,
} from './dto/index.js';
import { JwtAuthGuard, RolesGuard, Roles, CurrentUser } from '../auth/index.js';

@ApiTags('Classes & Scheduling')
@Controller()
@UseGuards(JwtAuthGuard)
@ApiBearerAuth('JWT-auth')
export class ClassesController {
  constructor(private readonly classesService: ClassesService) {}

  // --------------------------------------------------------------------------
  // MY CLASSES & MY SCHEDULE (Đặt trước các route có param :id)
  // --------------------------------------------------------------------------

  @Get('my/classes')
  @ApiOperation({
    summary:
      'Lấy danh sách các lớp học của người dùng hiện tại (Học viên, Giáo viên, Phụ huynh)',
  })
  @ApiResponse({ status: 200, description: 'Lấy danh sách lớp thành công' })
  getMyClasses(@CurrentUser() user: any) {
    return this.classesService.getMyClasses(user.id, user.roles, user.branchId);
  }

  @Get('my/schedule')
  @ApiOperation({
    summary: 'Lịch học/lịch giảng dạy của tôi (Thời khóa biểu theo ngày/tuần)',
  })
  @ApiQuery({
    name: 'fromDate',
    required: false,
    example: '2026-10-01',
    description: 'Từ ngày (YYYY-MM-DD)',
  })
  @ApiQuery({
    name: 'toDate',
    required: false,
    example: '2026-10-31',
    description: 'Đến ngày (YYYY-MM-DD)',
  })
  @ApiResponse({ status: 200, description: 'Lấy thời khóa biểu thành công' })
  getMySchedule(
    @CurrentUser() user: any,
    @Query('fromDate') fromDate?: string,
    @Query('toDate') toDate?: string,
  ) {
    return this.classesService.getMySchedule(
      user.id,
      user.roles,
      fromDate,
      toDate,
      user.branchId,
    );
  }

  // --------------------------------------------------------------------------
  // CLASSES CRUD
  // --------------------------------------------------------------------------

  @Get('classes')
  @ApiOperation({
    summary:
      'Lấy danh sách lớp học (phân trang, tìm kiếm, lọc theo khóa, chi nhánh, trạng thái)',
  })
  @ApiResponse({ status: 200, description: 'Lấy danh sách lớp học thành công' })
  findAll(@Query() query: QueryClassesDto, @CurrentUser() user: any) {
    return this.classesService.findAll(query, user);
  }

  @Get('classes/:id')
  @ApiOperation({
    summary: 'Xem chi tiết lớp học kèm danh sách học viên và toàn bộ buổi học',
  })
  @ApiResponse({
    status: 200,
    description: 'Lấy thông tin chi tiết lớp học thành công',
  })
  @ApiResponse({ status: 404, description: 'Không tìm thấy lớp học' })
  findOne(@Param('id') id: string, @CurrentUser() user: any) {
    return this.classesService.findOne(id, user);
  }

  @UseGuards(RolesGuard)
  @Roles('super_admin', 'branch_admin', 'academic_staff')
  @Post('classes')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary:
      'Tạo lớp học mới & Tự động sinh lịch học (Check trùng lịch phòng và giáo viên)',
  })
  @ApiResponse({
    status: 201,
    description: 'Tạo lớp học và sinh lịch thành công',
  })
  @ApiResponse({
    status: 409,
    description: 'Xung đột mã lớp, trùng lịch phòng học hoặc giáo viên',
  })
  create(@Body() dto: CreateClassDto, @CurrentUser() user: any) {
    return this.classesService.create(dto, user);
  }

  @UseGuards(RolesGuard)
  @Roles('super_admin', 'branch_admin', 'academic_staff')
  @Patch('classes/:id')
  @ApiOperation({ summary: 'Cập nhật thông tin lớp học' })
  @ApiResponse({ status: 200, description: 'Cập nhật thành công' })
  @ApiResponse({ status: 404, description: 'Không tìm thấy lớp học' })
  update(
    @Param('id') id: string,
    @Body() dto: UpdateClassDto,
    @CurrentUser() user: any,
  ) {
    return this.classesService.update(id, dto, user);
  }

  // --------------------------------------------------------------------------
  // HỌC VIÊN TRONG LỚP (ENROLLMENT)
  // --------------------------------------------------------------------------

  @UseGuards(RolesGuard)
  @Roles('super_admin', 'branch_admin', 'academic_staff')
  @Post('classes/:id/students')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Ghi danh học viên vào lớp (kiểm tra sĩ số tối đa)',
  })
  @ApiResponse({ status: 201, description: 'Ghi danh học viên thành công' })
  @ApiResponse({
    status: 409,
    description: 'Lớp đã đủ sĩ số hoặc học viên đã có trong lớp',
  })
  enrollStudent(
    @Param('id') classId: string,
    @Body() dto: EnrollStudentDto,
    @CurrentUser() user: any,
  ) {
    return this.classesService.enrollStudent(classId, dto, user);
  }

  @UseGuards(RolesGuard)
  @Roles('super_admin', 'branch_admin', 'academic_staff')
  @Delete('classes/:id/students/:studentId')
  @ApiOperation({ summary: 'Xóa học viên khỏi danh sách lớp' })
  @ApiResponse({ status: 200, description: 'Xóa học viên khỏi lớp thành công' })
  @ApiResponse({ status: 404, description: 'Học viên không có trong lớp' })
  removeStudent(
    @Param('id') classId: string,
    @Param('studentId') studentId: string,
    @CurrentUser() user: any,
  ) {
    return this.classesService.removeStudent(classId, studentId, user);
  }

  // --------------------------------------------------------------------------
  // BUỔI HỌC (SESSIONS)
  // --------------------------------------------------------------------------

  @Get('classes/:id/sessions')
  @ApiOperation({ summary: 'Lấy danh sách các buổi học của một lớp' })
  @ApiResponse({
    status: 200,
    description: 'Lấy danh sách buổi học thành công',
  })
  findSessionsByClass(@Param('id') classId: string, @CurrentUser() user: any) {
    return this.classesService.findSessionsByClass(classId, user);
  }

  @UseGuards(RolesGuard)
  @Roles('super_admin', 'branch_admin', 'academic_staff', 'teacher')
  @Patch('sessions/:id')
  @ApiOperation({
    summary:
      'Điều chỉnh buổi học (đổi phòng, giáo viên dạy thay, đổi ngày/giờ)',
  })
  @ApiResponse({ status: 200, description: 'Cập nhật buổi học thành công' })
  @ApiResponse({
    status: 409,
    description: 'Xung đột phòng hoặc giáo viên vào khung giờ mới',
  })
  updateSession(
    @Param('id') sessionId: string,
    @Body() dto: UpdateClassSessionDto,
    @CurrentUser() user: any,
  ) {
    return this.classesService.updateSession(sessionId, dto, user);
  }
}
