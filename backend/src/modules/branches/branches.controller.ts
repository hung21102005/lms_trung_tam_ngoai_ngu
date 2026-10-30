import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
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
import { BranchesService } from './branches.service.js';
import {
  CreateBranchDto,
  UpdateBranchDto,
  CreateRoomDto,
  UpdateRoomDto,
} from './dto/index.js';
import { JwtAuthGuard, RolesGuard, Roles, Public } from '../auth/index.js';

@ApiTags('Branches & Rooms')
@Controller()
export class BranchesController {
  constructor(private readonly branchesService: BranchesService) {}

  // --------------------------------------------------------------------------
  // BRANCHES
  // --------------------------------------------------------------------------

  @Public()
  @Get('branches')
  @ApiOperation({
    summary: 'Danh sách các chi nhánh trung tâm (Công khai để chọn cơ sở học)',
  })
  @ApiResponse({ status: 200, description: 'Lấy danh sách chi nhánh thành công' })
  findAllBranches() {
    return this.branchesService.findAllBranches();
  }

  @Public()
  @Get('branches/:id')
  @ApiOperation({
    summary: 'Chi tiết thông tin một chi nhánh và các phòng học',
  })
  @ApiResponse({ status: 200, description: 'Lấy thông tin chi nhánh thành công' })
  @ApiResponse({ status: 404, description: 'Không tìm thấy chi nhánh' })
  findOneBranch(@Param('id') id: string) {
    return this.branchesService.findOneBranch(id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin')
  @ApiBearerAuth('JWT-auth')
  @Post('branches')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Tạo mới một chi nhánh trung tâm (Chỉ Super Admin)',
  })
  @ApiResponse({ status: 201, description: 'Tạo chi nhánh thành công' })
  @ApiResponse({ status: 409, description: 'Mã chi nhánh đã tồn tại' })
  createBranch(@Body() dto: CreateBranchDto) {
    return this.branchesService.createBranch(dto);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'branch_admin')
  @ApiBearerAuth('JWT-auth')
  @Patch('branches/:id')
  @ApiOperation({
    summary: 'Cập nhật thông tin chi nhánh (Super Admin hoặc Branch Admin)',
  })
  @ApiResponse({ status: 200, description: 'Cập nhật chi nhánh thành công' })
  @ApiResponse({ status: 404, description: 'Không tìm thấy chi nhánh' })
  updateBranch(@Param('id') id: string, @Body() dto: UpdateBranchDto) {
    return this.branchesService.updateBranch(id, dto);
  }

  // --------------------------------------------------------------------------
  // ROOMS
  // --------------------------------------------------------------------------

  @Public()
  @Get('branches/:id/rooms')
  @ApiOperation({
    summary: 'Danh sách các phòng học của một chi nhánh',
  })
  @ApiResponse({ status: 200, description: 'Lấy danh sách phòng học thành công' })
  @ApiResponse({ status: 404, description: 'Không tìm thấy chi nhánh' })
  findRoomsByBranch(@Param('id') id: string) {
    return this.branchesService.findRoomsByBranch(id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'branch_admin')
  @ApiBearerAuth('JWT-auth')
  @Post('rooms')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Tạo mới một phòng học trong chi nhánh',
  })
  @ApiResponse({ status: 201, description: 'Tạo phòng học thành công' })
  @ApiResponse({ status: 409, description: 'Mã phòng học đã tồn tại trong chi nhánh' })
  createRoom(@Body() dto: CreateRoomDto) {
    return this.branchesService.createRoom(dto);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'branch_admin')
  @ApiBearerAuth('JWT-auth')
  @Patch('rooms/:id')
  @ApiOperation({
    summary: 'Cập nhật thông tin hoặc trang thiết bị phòng học',
  })
  @ApiResponse({ status: 200, description: 'Cập nhật phòng học thành công' })
  @ApiResponse({ status: 404, description: 'Không tìm thấy phòng học' })
  updateRoom(@Param('id') id: string, @Body() dto: UpdateRoomDto) {
    return this.branchesService.updateRoom(id, dto);
  }
}
