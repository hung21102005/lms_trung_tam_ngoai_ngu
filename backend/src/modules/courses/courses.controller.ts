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
} from '@nestjs/swagger';
import { CoursesService } from './courses.service.js';
import {
  CreateCourseDto,
  UpdateCourseDto,
  CreateCourseLevelDto,
  UpdateCourseLevelDto,
  CreateModuleDto,
  UpdateModuleDto,
  CreateLessonDto,
  UpdateLessonDto,
  CreateLessonMaterialDto,
  QueryCoursesDto,
  CreateProgramDto,
  UpdateProgramDto,
  PublicationDto,
  ProgramVisibilityDto,
} from './dto/index.js';
import {
  JwtAuthGuard,
  RolesGuard,
  Roles,
  Public,
  CurrentUser,
} from '../auth/index.js';

@ApiTags('Courses & Curriculum')
@Controller()
export class CoursesController {
  constructor(private readonly coursesService: CoursesService) {}

  @Public()
  @Get('public/programs')
  @ApiOperation({ summary: 'Chương trình đã duyệt và bật hiển thị công khai' })
  findPublicPrograms() {
    return this.coursesService.findPublicPrograms();
  }

  @Public()
  @Get('public/courses')
  @ApiOperation({ summary: 'Khóa học đã duyệt trong chương trình công khai' })
  findPublicCourses() {
    return this.coursesService.findPublicCourses();
  }

  @Public()
  @Get('public/courses/:slug')
  @ApiOperation({ summary: 'Chi tiết khóa học công khai theo slug' })
  findPublicCourse(@Param('slug') slug: string) {
    return this.coursesService.findPublicCourse(slug);
  }

  // --------------------------------------------------------------------------
  // TRAINING PROGRAMS
  // --------------------------------------------------------------------------

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'branch_admin', 'academic_staff')
  @ApiBearerAuth('JWT-auth')
  @Get('programs')
  @ApiOperation({ summary: 'Danh mục chương trình đào tạo nội bộ' })
  findPrograms() {
    return this.coursesService.findPrograms();
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'branch_admin', 'academic_staff')
  @ApiBearerAuth('JWT-auth')
  @Get('programs/:id')
  @ApiOperation({ summary: 'Chi tiết chương trình và các khóa học' })
  findProgram(@Param('id') id: string) {
    return this.coursesService.findProgram(id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'academic_staff')
  @ApiBearerAuth('JWT-auth')
  @Post('programs')
  @ApiOperation({ summary: 'Tạo chương trình nháp' })
  createProgram(@Body() dto: CreateProgramDto) {
    return this.coursesService.createProgram(dto);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'academic_staff')
  @ApiBearerAuth('JWT-auth')
  @Patch('programs/:id')
  @ApiOperation({ summary: 'Chỉnh sửa chương trình đào tạo' })
  updateProgram(@Param('id') id: string, @Body() dto: UpdateProgramDto) {
    return this.coursesService.updateProgram(id, dto);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'academic_staff')
  @ApiBearerAuth('JWT-auth')
  @Patch('programs/:id/status')
  @ApiOperation({ summary: 'Duyệt hoặc lưu trữ chương trình theo trạng thái' })
  changeProgramStatus(@Param('id') id: string, @Body() dto: PublicationDto) {
    return this.coursesService.changeProgramStatus(id, dto.status);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'academic_staff')
  @ApiBearerAuth('JWT-auth')
  @Patch('programs/:id/visibility')
  @ApiOperation({ summary: 'Bật hoặc tắt hiển thị chương trình công khai' })
  setProgramVisibility(
    @Param('id') id: string,
    @Body() dto: ProgramVisibilityDto,
  ) {
    return this.coursesService.setProgramVisibility(id, dto.isPublic);
  }

  // --------------------------------------------------------------------------
  // COURSES
  // --------------------------------------------------------------------------

  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @Get('courses')
  @ApiOperation({ summary: 'Lấy danh sách khóa học nội bộ' })
  @ApiResponse({
    status: 200,
    description: 'Lấy danh sách khóa học thành công',
  })
  findAllCourses(@Query() query: QueryCoursesDto) {
    return this.coursesService.findAll(query);
  }

  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @Get('courses/:id')
  @ApiOperation({
    summary: 'Xem chi tiết khóa học kèm danh sách cấp độ & bài học',
  })
  @ApiResponse({ status: 200, description: 'Lấy chi tiết khóa học thành công' })
  @ApiResponse({ status: 404, description: 'Không tìm thấy khóa học' })
  findOneCourse(@Param('id') id: string) {
    return this.coursesService.findOne(id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'academic_staff')
  @ApiBearerAuth('JWT-auth')
  @Post('courses')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Tạo khóa học mới (Super Admin, Academic Staff)',
  })
  @ApiResponse({ status: 201, description: 'Tạo khóa học thành công' })
  @ApiResponse({ status: 409, description: 'Mã khóa học đã tồn tại' })
  createCourse(@Body() dto: CreateCourseDto) {
    return this.coursesService.create(dto);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'academic_staff')
  @ApiBearerAuth('JWT-auth')
  @Patch('courses/:id')
  @ApiOperation({ summary: 'Cập nhật thông tin khóa học' })
  @ApiResponse({ status: 200, description: 'Cập nhật thành công' })
  @ApiResponse({ status: 404, description: 'Không tìm thấy khóa học' })
  updateCourse(@Param('id') id: string, @Body() dto: UpdateCourseDto) {
    return this.coursesService.update(id, dto);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'academic_staff')
  @ApiBearerAuth('JWT-auth')
  @Patch('courses/:id/publication')
  @ApiOperation({ summary: 'Duyệt hoặc lưu trữ khóa học theo trạng thái' })
  changeCourseStatus(@Param('id') id: string, @Body() dto: PublicationDto) {
    return this.coursesService.changeCourseStatus(id, dto.status);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'academic_staff')
  @ApiBearerAuth('JWT-auth')
  @Get('courses/:id/publication-check')
  @ApiOperation({
    summary: 'Kiểm tra điều kiện công bố khóa và nội dung học thuật',
  })
  validateCoursePublication(@Param('id') id: string) {
    return this.coursesService.validateCoursePublication(id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'academic_staff')
  @ApiBearerAuth('JWT-auth')
  @Post('courses/:id/academic-review')
  @ApiOperation({ summary: 'Xác nhận đã rà soát nội dung học thuật hiện tại' })
  confirmCourseAcademicReview(
    @Param('id') id: string,
    @CurrentUser('id') reviewerId: string,
  ) {
    return this.coursesService.confirmCourseAcademicReview(id, reviewerId);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'academic_staff')
  @ApiBearerAuth('JWT-auth')
  @Delete('courses/:id')
  @ApiOperation({
    summary:
      'Xóa vĩnh viễn khóa học (chỉ áp dụng với khóa Bản nháp và chưa có lớp liên kết)',
  })
  @ApiResponse({ status: 200, description: 'Xóa khóa học thành công' })
  @ApiResponse({
    status: 400,
    description: 'Không thể xóa khóa học có lớp liên kết hoặc không ở trạng thái DRAFT',
  })
  deleteCourse(@Param('id') id: string) {
    return this.coursesService.deleteCourse(id);
  }

  // --------------------------------------------------------------------------
  // LEVELS
  // --------------------------------------------------------------------------

  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @Get('courses/:id/levels')
  @ApiOperation({ summary: 'Lấy danh sách cấp độ của khóa học' })
  @ApiResponse({ status: 200, description: 'Lấy danh sách cấp độ thành công' })
  findLevelsByCourse(@Param('id') courseId: string) {
    return this.coursesService.findLevelsByCourse(courseId);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'academic_staff')
  @ApiBearerAuth('JWT-auth')
  @Post('courses/:id/levels')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Tạo cấp độ mới trong khóa học' })
  @ApiResponse({ status: 201, description: 'Tạo cấp độ thành công' })
  @ApiResponse({
    status: 409,
    description: 'Mã cấp độ đã tồn tại trong khóa học',
  })
  createLevel(
    @Param('id') courseId: string,
    @Body() dto: CreateCourseLevelDto,
  ) {
    return this.coursesService.createLevel(courseId, dto);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'academic_staff')
  @ApiBearerAuth('JWT-auth')
  @Patch('levels/:id')
  @ApiOperation({ summary: 'Chỉnh sửa thông tin học thuật của cấp độ' })
  updateLevel(@Param('id') id: string, @Body() dto: UpdateCourseLevelDto) {
    return this.coursesService.updateLevel(id, dto);
  }

  // --------------------------------------------------------------------------
  // MODULES
  // --------------------------------------------------------------------------

  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @Get('levels/:id/modules')
  @ApiOperation({ summary: 'Lấy danh sách module/chương thuộc một cấp độ' })
  @ApiResponse({ status: 200, description: 'Lấy danh sách module thành công' })
  findModulesByLevel(@Param('id') levelId: string) {
    return this.coursesService.findModulesByLevel(levelId);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'academic_staff')
  @ApiBearerAuth('JWT-auth')
  @Post('levels/:id/modules')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Tạo module/chương mới cho cấp độ' })
  @ApiResponse({ status: 201, description: 'Tạo module thành công' })
  createModule(@Param('id') levelId: string, @Body() dto: CreateModuleDto) {
    return this.coursesService.createModule(levelId, dto);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'academic_staff')
  @ApiBearerAuth('JWT-auth')
  @Patch('modules/:id')
  @ApiOperation({ summary: 'Chỉnh sửa học phần' })
  updateModule(@Param('id') id: string, @Body() dto: UpdateModuleDto) {
    return this.coursesService.updateModule(id, dto);
  }

  // --------------------------------------------------------------------------
  // LESSONS
  // --------------------------------------------------------------------------

  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @Get('modules/:id/lessons')
  @ApiOperation({ summary: 'Lấy danh sách bài học thuộc một module' })
  @ApiResponse({ status: 200, description: 'Lấy danh sách bài học thành công' })
  findLessonsByModule(@Param('id') moduleId: string) {
    return this.coursesService.findLessonsByModule(moduleId);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'academic_staff')
  @ApiBearerAuth('JWT-auth')
  @Post('modules/:id/lessons')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Tạo bài học mới trong module' })
  @ApiResponse({ status: 201, description: 'Tạo bài học thành công' })
  createLesson(@Param('id') moduleId: string, @Body() dto: CreateLessonDto) {
    return this.coursesService.createLesson(moduleId, dto);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'academic_staff')
  @ApiBearerAuth('JWT-auth')
  @Patch('lessons/:id')
  @ApiOperation({ summary: 'Chỉnh sửa bài học' })
  updateLesson(@Param('id') id: string, @Body() dto: UpdateLessonDto) {
    return this.coursesService.updateLesson(id, dto);
  }

  // --------------------------------------------------------------------------
  // MATERIALS
  // --------------------------------------------------------------------------

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'academic_staff', 'teacher')
  @ApiBearerAuth('JWT-auth')
  @Post('lessons/:id/materials')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Đính kèm tài liệu học tập (slide, audio, pdf) vào bài học',
  })
  @ApiResponse({ status: 201, description: 'Thêm tài liệu thành công' })
  createMaterial(
    @Param('id') lessonId: string,
    @Body() dto: CreateLessonMaterialDto,
  ) {
    return this.coursesService.createLessonMaterial(lessonId, dto);
  }
}
