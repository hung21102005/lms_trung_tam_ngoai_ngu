import {
  Body,
  Controller,
  ForbiddenException,
  Get,
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
}
