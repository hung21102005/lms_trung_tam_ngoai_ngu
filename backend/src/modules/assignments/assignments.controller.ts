import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  UseGuards,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { AssignmentsService } from './assignments.service.js';
import {
  CreateAssignmentDto,
  UpdateAssignmentDto,
  SubmitAssignmentDto,
  GradeSubmissionDto,
  ReturnSubmissionDto,
} from './dto/index.js';
import { JwtAuthGuard, RolesGuard, Roles, CurrentUser } from '../auth/index.js';

@ApiTags('Assignments & Submissions')
@Controller()
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth('JWT-auth')
export class AssignmentsController {
  constructor(private readonly assignmentsService: AssignmentsService) {}

  // --------------------------------------------------------------------------
  // CLASS ASSIGNMENTS
  // --------------------------------------------------------------------------

  @Get('classes/:id/assignments')
  @ApiOperation({ summary: 'Lấy danh sách bài tập của lớp học' })
  @ApiResponse({ status: 200, description: 'Lấy danh sách bài tập thành công' })
  getClassAssignments(@Param('id') classId: string, @CurrentUser() user: any) {
    return this.assignmentsService.getClassAssignments(classId, user);
  }

  @Post('classes/:id/assignments')
  @Roles('super_admin', 'branch_admin', 'academic_staff', 'teacher')
  @ApiOperation({ summary: 'Tạo bài tập mới cho lớp học (Giáo viên / Học vụ)' })
  @ApiResponse({ status: 201, description: 'Tạo bài tập thành công' })
  createAssignment(
    @Param('id') classId: string,
    @Body() dto: CreateAssignmentDto,
    @CurrentUser() user: any,
  ) {
    return this.assignmentsService.createAssignment(classId, dto, user);
  }

  // --------------------------------------------------------------------------
  // ASSIGNMENT DETAIL & SUBMISSION
  // --------------------------------------------------------------------------

  @Get('assignments/:id')
  @ApiOperation({
    summary: 'Xem chi tiết bài tập (+ bài nộp cá nhân nếu là học viên)',
  })
  @ApiResponse({ status: 200, description: 'Lấy thông tin bài tập thành công' })
  getAssignmentDetail(@Param('id') id: string, @CurrentUser() user: any) {
    return this.assignmentsService.getAssignmentDetail(id, user);
  }

  @Patch('assignments/:id')
  @Roles('super_admin', 'branch_admin', 'academic_staff', 'teacher')
  @ApiOperation({ summary: 'Sửa nội dung bài tập đã giao' })
  updateAssignment(
    @Param('id') id: string,
    @Body() dto: UpdateAssignmentDto,
    @CurrentUser() user: any,
  ) {
    return this.assignmentsService.updateAssignment(id, dto, user);
  }

  @Post('assignments/:id/submit')
  @Roles('student')
  @ApiOperation({
    summary: 'Học viên nộp bài tập (văn bản, link file, audio ghi âm)',
  })
  @ApiResponse({ status: 200, description: 'Nộp bài tập thành công' })
  submitAssignment(
    @Param('id') assignmentId: string,
    @Body() dto: SubmitAssignmentDto,
    @CurrentUser() user: any,
  ) {
    return this.assignmentsService.submitAssignment(assignmentId, user.id, dto);
  }

  @Post('assignments/:id/draft')
  @Roles('student')
  @ApiOperation({ summary: 'Lưu bản nháp bài làm của học viên' })
  saveDraft(
    @Param('id') assignmentId: string,
    @Body() dto: SubmitAssignmentDto,
    @CurrentUser() user: any,
  ) {
    return this.assignmentsService.saveDraft(assignmentId, user.id, dto);
  }

  // --------------------------------------------------------------------------
  // GRADING & SUBMISSIONS LIST (TEACHER)
  // --------------------------------------------------------------------------

  @Get('assignments/:id/submissions')
  @Roles('super_admin', 'branch_admin', 'academic_staff', 'teacher')
  @ApiOperation({
    summary: 'Xem toàn bộ bài nộp của bài tập để chấm điểm (Giáo viên)',
  })
  @ApiResponse({ status: 200, description: 'Lấy danh sách bài nộp thành công' })
  getAssignmentSubmissions(
    @Param('id') assignmentId: string,
    @CurrentUser() user: any,
  ) {
    return this.assignmentsService.getAssignmentSubmissions(assignmentId, user);
  }

  @Patch('submissions/:id/grade')
  @Roles('super_admin', 'branch_admin', 'academic_staff', 'teacher')
  @ApiOperation({
    summary: 'Chấm điểm và nhận xét bài nộp của học viên (Giáo viên)',
  })
  @ApiResponse({ status: 200, description: 'Chấm điểm thành công' })
  gradeSubmission(
    @Param('id') submissionId: string,
    @Body() dto: GradeSubmissionDto,
    @CurrentUser() user: any,
  ) {
    return this.assignmentsService.gradeSubmission(submissionId, dto, user);
  }

  @Patch('submissions/:id/publish')
  @Roles('super_admin', 'branch_admin', 'academic_staff', 'teacher')
  @ApiOperation({ summary: 'Công bố điểm bài tập cho học viên' })
  publishResult(@Param('id') id: string, @CurrentUser() user: any) {
    return this.assignmentsService.publishResult(id, user);
  }

  @Patch('submissions/:id/return')
  @Roles('super_admin', 'branch_admin', 'academic_staff', 'teacher')
  @ApiOperation({ summary: 'Yêu cầu học viên làm lại bài nộp' })
  returnSubmission(
    @Param('id') id: string,
    @Body() dto: ReturnSubmissionDto,
    @CurrentUser() user: any,
  ) {
    return this.assignmentsService.returnSubmission(id, dto, user);
  }
}
