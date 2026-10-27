import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { AttendanceService } from './attendance.service.js';
import {
  BatchMarkAttendanceDto,
  UpdateAttendanceDto,
  CreateMakeupRequestDto,
  UpdateMakeupRequestDto,
  QueryMakeupRequestsDto,
} from './dto/index.js';
import { JwtAuthGuard, RolesGuard, Roles, CurrentUser } from '../auth/index.js';

@ApiTags('Attendance & Makeup')
@Controller()
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth('JWT-auth')
export class AttendanceController {
  constructor(private readonly attendanceService: AttendanceService) {}

  // --------------------------------------------------------------------------
  // SESSIONS ATTENDANCE
  // --------------------------------------------------------------------------

  @Get('sessions/:id/attendance')
  @Roles(
    'super_admin',
    'branch_admin',
    'academic_staff',
    'teacher',
    'teaching_assistant',
  )
  @ApiOperation({
    summary: 'Lấy danh sách điểm danh của 1 buổi học (gồm tất cả HV trong lớp)',
  })
  @ApiResponse({
    status: 200,
    description: 'Lấy danh sách điểm danh thành công',
  })
  getSessionAttendance(
    @Param('id') sessionId: string,
    @CurrentUser() user: any,
  ) {
    return this.attendanceService.getSessionAttendance(sessionId, user);
  }

  @Post('sessions/:id/attendance')
  @Roles(
    'super_admin',
    'branch_admin',
    'academic_staff',
    'teacher',
    'teaching_assistant',
  )
  @ApiOperation({
    summary: 'Điểm danh hàng loạt cho buổi học (Giáo viên / Trợ giảng)',
  })
  @ApiResponse({ status: 200, description: 'Điểm danh thành công' })
  batchMarkAttendance(
    @Param('id') sessionId: string,
    @Body() dto: BatchMarkAttendanceDto,
    @CurrentUser() user: any,
  ) {
    return this.attendanceService.batchMarkAttendance(sessionId, dto, user);
  }

  @Patch('attendance/:id')
  @Roles('super_admin', 'branch_admin', 'academic_staff', 'teacher')
  @ApiOperation({ summary: 'Cập nhật bản ghi điểm danh của 1 học viên' })
  @ApiResponse({ status: 200, description: 'Cập nhật thành công' })
  updateAttendance(
    @Param('id') id: string,
    @Body() dto: UpdateAttendanceDto,
    @CurrentUser() user: any,
  ) {
    return this.attendanceService.updateAttendance(id, dto, user);
  }

  // --------------------------------------------------------------------------
  // STUDENT ATTENDANCE HISTORY
  // --------------------------------------------------------------------------

  @Get('students/:id/attendance')
  @ApiOperation({
    summary: 'Xem lịch sử chuyên cần và tỷ lệ chuyên cần của 1 học viên',
  })
  @ApiResponse({
    status: 200,
    description: 'Lấy lịch sử chuyên cần thành công',
  })
  getStudentAttendance(
    @Param('id') studentId: string,
    @CurrentUser() user: any,
  ) {
    return this.attendanceService.getStudentAttendanceHistory(studentId, user);
  }

  // --------------------------------------------------------------------------
  // CLASS ATTENDANCE SUMMARY
  // --------------------------------------------------------------------------

  @Get('classes/:id/attendance-summary')
  @Roles('super_admin', 'branch_admin', 'academic_staff', 'teacher')
  @ApiOperation({
    summary: 'Thống kê tỷ lệ chuyên cần của toàn lớp và từng học viên',
  })
  @ApiResponse({ status: 200, description: 'Thống kê chuyên cần thành công' })
  getClassAttendanceSummary(
    @Param('id') classId: string,
    @CurrentUser() user: any,
  ) {
    return this.attendanceService.getClassAttendanceSummary(classId, user);
  }

  // --------------------------------------------------------------------------
  // MAKEUP REQUESTS (HỌC BÙ)
  // --------------------------------------------------------------------------

  @Post('makeup-requests')
  @ApiOperation({ summary: 'Đăng ký yêu cầu học bù (Học viên)' })
  @ApiResponse({ status: 201, description: 'Gửi yêu cầu học bù thành công' })
  createMakeupRequest(
    @CurrentUser() user: any,
    @Body() dto: CreateMakeupRequestDto,
  ) {
    return this.attendanceService.createMakeupRequest(user.id, dto);
  }

  @Get('makeup-requests')
  @ApiOperation({ summary: 'Danh sách các yêu cầu học bù' })
  @ApiResponse({
    status: 200,
    description: 'Lấy danh sách yêu cầu học bù thành công',
  })
  getMakeupRequests(
    @Query() query: QueryMakeupRequestsDto,
    @CurrentUser() user: any,
  ) {
    const isStaff = user.roles.some((r: string) =>
      ['super_admin', 'branch_admin', 'academic_staff'].includes(r),
    );

    // Nếu là học viên thì chỉ xem của mình
    if (!isStaff) {
      query.studentId = user.id;
    }

    return this.attendanceService.getMakeupRequests(query);
  }

  @Patch('makeup-requests/:id')
  @Roles('super_admin', 'branch_admin', 'academic_staff')
  @ApiOperation({
    summary: 'Duyệt hoặc từ chối yêu cầu học bù (Nhân viên học vụ / Admin)',
  })
  @ApiResponse({ status: 200, description: 'Phê duyệt yêu cầu thành công' })
  updateMakeupRequest(
    @Param('id') id: string,
    @Body() dto: UpdateMakeupRequestDto,
    @CurrentUser() user: any,
  ) {
    return this.attendanceService.updateMakeupRequest(id, dto, user.id);
  }
}
