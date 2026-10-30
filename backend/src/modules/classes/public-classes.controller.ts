import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard, Public } from '../auth/index.js';
import { ClassesService } from './classes.service.js';
import { QueryPublicClassesDto } from './dto/query-public-classes.dto.js';

@ApiTags('Public class offerings')
@Controller('public/classes')
@UseGuards(JwtAuthGuard)
export class PublicClassesController {
  constructor(private readonly classesService: ClassesService) {}

  @Public()
  @Get()
  @ApiOperation({ summary: 'Lớp đang mở đăng ký thuộc khóa học đã công bố' })
  findAll(@Query() query: QueryPublicClassesDto) {
    return this.classesService.findPublicOfferings(query);
  }

  @Public()
  @Get(':id')
  @ApiOperation({ summary: 'Chi tiết lớp đang mở đăng ký' })
  findOne(@Param('id') id: string) {
    return this.classesService.findPublicOffering(id);
  }
}
