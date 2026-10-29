import {
  Body,
  Controller,
  ForbiddenException,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import {
  JwtAuthGuard,
  Roles,
  RolesGuard,
  Public,
  CurrentUser,
} from '../auth/index.js';
import { ClassRegistrationsService } from './class-registrations.service.js';
import {
  CreateGuestRegistrationDto,
  CreateStudentRegistrationDto,
} from './dto/create-class-registration.dto.js';
import {
  ApproveClassRegistrationDto,
  ReviewClassRegistrationDto,
} from './dto/review-class-registration.dto.js';

@ApiTags('Class registrations')
@Controller()
@UseGuards(JwtAuthGuard)
export class ClassRegistrationsController {
  constructor(private readonly service: ClassRegistrationsService) {}

  @Public()
  @Post('public/registrations')
  @ApiOperation({ summary: 'Khách mới gửi yêu cầu đăng ký lớp' })
  createGuest(@Body() dto: CreateGuestRegistrationDto) {
    return this.service.createGuest(dto);
  }

  @Post('my/registrations')
  @ApiOperation({ summary: 'Học viên hiện có gửi yêu cầu đăng ký lớp' })
  createStudent(
    @Body() dto: CreateStudentRegistrationDto,
    @CurrentUser() user: { id: string; roles: string[] },
  ) {
    return this.service.createStudent(dto, user);
  }

  @Get('my/registrations')
  @ApiOperation({ summary: 'Danh sách đơn đăng ký lớp của học viên hiện tại' })
  myRegistrations(@CurrentUser() user: { id: string; roles: string[] }) {
    if (!user.roles.includes('student')) {
      throw new ForbiddenException('Chỉ học viên được xem đơn của mình');
    }
    return this.service.myRegistrations(user.id);
  }

  @UseGuards(RolesGuard)
  @Roles('super_admin', 'branch_admin', 'academic_staff')
  @Get('admissions/registrations')
  @ApiOperation({ summary: 'Học vụ xem yêu cầu đăng ký lớp' })
  listForStaff(
    @CurrentUser() user: { roles: string[]; branchId?: string | null },
    @Query('classId') classId?: string,
  ) {
    return this.service.listForStaff(user, classId);
  }

  @UseGuards(RolesGuard)
  @Roles('super_admin', 'branch_admin', 'academic_staff')
  @Patch('admissions/registrations/:id/review')
  @ApiOperation({ summary: 'Học vụ đánh dấu đã liên hệ hoặc từ chối đơn' })
  review(
    @Param('id') id: string,
    @Body() dto: ReviewClassRegistrationDto,
    @CurrentUser() user: { roles: string[]; branchId?: string | null },
  ) {
    return this.service.review(id, dto, user);
  }

  @UseGuards(RolesGuard)
  @Roles('super_admin', 'branch_admin', 'academic_staff')
  @Post('admissions/registrations/:id/approve')
  @ApiOperation({
    summary: 'Xác nhận nhập học và tạo ghi danh/hóa đơn trong transaction',
  })
  approve(
    @Param('id') id: string,
    @Body() dto: ApproveClassRegistrationDto,
    @CurrentUser()
    user: { id: string; roles: string[]; branchId?: string | null },
  ) {
    return this.service.approve(id, dto, user);
  }
}
