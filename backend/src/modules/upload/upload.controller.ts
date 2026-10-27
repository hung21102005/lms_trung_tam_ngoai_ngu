import {
  Controller,
  Post,
  UseInterceptors,
  UploadedFile,
  Body,
  UseGuards,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiConsumes,
  ApiBody,
} from '@nestjs/swagger';
import { UploadService } from './upload.service.js';
import { JwtAuthGuard } from '../auth/index.js';

@ApiTags('File Upload')
@Controller('upload')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth('JWT-auth')
export class UploadController {
  constructor(private readonly uploadService: UploadService) {}

  @Post()
  @UseInterceptors(FileInterceptor('file'))
  @ApiOperation({
    summary: 'Tải tệp lên Firebase Storage (hỗ trợ tài liệu, TXT, ZIP/RAR, âm thanh, video và hình ảnh — tối đa 50MB)',
  })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: {
          type: 'string',
          format: 'binary',
          description: 'Tệp cần tải lên',
        },
        folder: {
          type: 'string',
          example: 'materials',
          description: 'Thư mục phân loại (materials, avatars, assignments)',
        },
      },
    },
  })
  @ApiResponse({ status: 201, description: 'Tải tệp thành công, trả về URL truy cập' })
  @ApiResponse({ status: 400, description: 'Tệp không hợp lệ hoặc vượt quá dung lượng 50MB' })
  uploadFile(
    @UploadedFile() file: any,
    @Body('folder') folder?: string,
  ) {
    if (!file) {
      throw new BadRequestException('Vui lòng chọn tệp để tải lên');
    }
    return this.uploadService.uploadFile(file, folder || 'materials');
  }
}
