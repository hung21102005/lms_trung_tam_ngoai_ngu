import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Request,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { RolesGuard } from '../auth/guards/roles.guard.js';
import { Roles } from '../auth/decorators/roles.decorator.js';
import { ExamsService } from './exams.service.js';
import {
  CreateExamDto,
  CreateQuestionBankDto,
  CreateQuestionDto,
  GradeExamAnswerDto,
  SaveExamAnswersDto,
} from './dto/index.js';

@ApiTags('Exams & Assessments (Thi & Kiểm tra)')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller()
export class ExamsController {
  constructor(private readonly examsService: ExamsService) {}

  // ---------------------------------------------------------------------------
  // 1. QUESTION BANKS
  // ---------------------------------------------------------------------------

  @Get('question-banks')
  @Roles('super_admin', 'branch_admin', 'academic_staff', 'teacher')
  @ApiOperation({ summary: 'Lấy danh sách các ngân hàng câu hỏi' })
  @ApiQuery({ name: 'language', required: false })
  @ApiQuery({ name: 'level', required: false })
  @ApiQuery({ name: 'search', required: false })
  async getQuestionBanks(
    @Query('language') language?: string,
    @Query('level') level?: string,
    @Query('search') search?: string,
  ) {
    return this.examsService.getQuestionBanks({ language, level, search });
  }

  @Post('question-banks')
  @Roles('super_admin', 'branch_admin', 'academic_staff', 'teacher')
  @ApiOperation({ summary: 'Tạo mới một ngân hàng câu hỏi' })
  async createQuestionBank(@Request() req: any, @Body() dto: CreateQuestionBankDto) {
    return this.examsService.createQuestionBank(req.user.id, dto);
  }

  @Get('question-banks/:id')
  @Roles('super_admin', 'branch_admin', 'academic_staff', 'teacher')
  @ApiOperation({ summary: 'Xem chi tiết ngân hàng câu hỏi kèm danh sách câu hỏi' })
  async getQuestionBankById(@Param('id') id: string) {
    return this.examsService.getQuestionBankById(id);
  }

  @Post('question-banks/:id/questions')
  @Roles('super_admin', 'branch_admin', 'academic_staff', 'teacher')
  @ApiOperation({ summary: 'Thêm một câu hỏi vào ngân hàng' })
  async addQuestionToBank(@Param('id') id: string, @Body() dto: CreateQuestionDto) {
    return this.examsService.addQuestionToBank(id, dto);
  }

  @Patch('questions/:id')
  @Roles('super_admin', 'branch_admin', 'academic_staff', 'teacher')
  @ApiOperation({ summary: 'Cập nhật nội dung hoặc đáp án câu hỏi' })
  async updateQuestion(@Param('id') id: string, @Body() dto: CreateQuestionDto) {
    return this.examsService.updateQuestion(id, dto);
  }

  @Delete('questions/:id')
  @Roles('super_admin', 'branch_admin', 'academic_staff', 'teacher')
  @ApiOperation({ summary: 'Xóa câu hỏi khỏi ngân hàng' })
  async deleteQuestion(@Param('id') id: string) {
    return this.examsService.deleteQuestion(id);
  }

  @Post('question-banks/:id/questions/import')
  @Roles('super_admin', 'branch_admin', 'academic_staff', 'teacher')
  @ApiOperation({ summary: 'Import hàng loạt câu hỏi vào ngân hàng từ file JSON' })
  async importQuestions(@Param('id') id: string, @Body() body: { questions: CreateQuestionDto[] }) {
    return this.examsService.importQuestions(id, body.questions);
  }

  // ---------------------------------------------------------------------------
  // 2. EXAMS
  // ---------------------------------------------------------------------------

  @Get('exams')
  @Roles('super_admin', 'branch_admin', 'academic_staff', 'teacher', 'student')
  @ApiOperation({ summary: 'Lấy danh sách các đề thi' })
  @ApiQuery({ name: 'classId', required: false })
  @ApiQuery({ name: 'status', required: false })
  async getExams(
    @Request() req: any,
    @Query('classId') classId?: string,
    @Query('status') status?: string,
  ) {
    const isStudent = req.user.role === 'student';
    return this.examsService.getExams({
      classId,
      status,
      studentId: isStudent ? req.user.id : undefined,
    });
  }

  @Post('exams')
  @Roles('super_admin', 'branch_admin', 'academic_staff', 'teacher')
  @ApiOperation({ summary: 'Tạo mới một đề thi / bài kiểm tra' })
  async createExam(@Request() req: any, @Body() dto: CreateExamDto) {
    return this.examsService.createExam(req.user.id, dto);
  }

  @Get('exams/:id')
  @Roles('super_admin', 'branch_admin', 'academic_staff', 'teacher', 'student')
  @ApiOperation({ summary: 'Xem chi tiết đề thi' })
  async getExamById(@Request() req: any, @Param('id') id: string) {
    return this.examsService.getExamById(id, { id: req.user.id, role: req.user.role });
  }

  @Post('exams/:id/start')
  @Roles('student')
  @ApiOperation({ summary: 'Học viên bắt đầu làm bài thi' })
  async startExam(@Request() req: any, @Param('id') id: string) {
    return this.examsService.startExam(id, req.user.id);
  }

  @Patch('exam-attempts/:id/answers')
  @Roles('student')
  @ApiOperation({ summary: 'Học viên lưu tạm đáp án (auto-save)' })
  async saveAnswers(
    @Request() req: any,
    @Param('id') id: string,
    @Body() dto: SaveExamAnswersDto,
  ) {
    return this.examsService.saveAnswers(id, req.user.id, dto);
  }

  @Post('exams/:id/submit')
  @Roles('student')
  @ApiOperation({ summary: 'Học viên nộp bài thi (tự động chấm điểm)' })
  async submitExam(@Request() req: any, @Param('id') id: string) {
    return this.examsService.submitExam(id, req.user.id);
  }

  @Get('exams/:id/results')
  @Roles('super_admin', 'branch_admin', 'academic_staff', 'teacher')
  @ApiOperation({ summary: 'Xem bảng điểm và kết quả thi của toàn bộ học viên' })
  async getExamResults(@Param('id') id: string) {
    return this.examsService.getExamResults(id);
  }

  @Get('my/exam-results')
  @Roles('student')
  @ApiOperation({ summary: 'Học viên xem lại lịch sử và kết quả tất cả các bài thi của mình' })
  async getMyExamResults(@Request() req: any) {
    return this.examsService.getMyExamResults(req.user.id);
  }

  @Patch('exam-answers/:id/grade')
  @Roles('super_admin', 'branch_admin', 'academic_staff', 'teacher')
  @ApiOperation({ summary: 'Giáo viên chấm điểm & nhận xét cho câu tự luận' })
  async gradeExamAnswer(
    @Request() req: any,
    @Param('id') id: string,
    @Body() dto: GradeExamAnswerDto,
  ) {
    return this.examsService.gradeExamAnswer(id, req.user.id, dto);
  }
}
