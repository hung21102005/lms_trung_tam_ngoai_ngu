import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { AppService } from './app.service.js';

@ApiTags('Health')
@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  @ApiOperation({ summary: 'Lấy thông tin hệ thống LMS API' })
  @ApiResponse({ status: 200, description: 'Thông tin hệ thống' })
  getHello() {
    return this.appService.getSystemInfo();
  }

  @Get('health')
  @ApiOperation({ summary: 'Kiểm tra trạng thái sức khỏe hệ thống (Database, Redis)' })
  @ApiResponse({ status: 200, description: 'Trạng thái hoạt động của các dịch vụ' })
  getHealth() {
    return this.appService.checkHealth();
  }
}
