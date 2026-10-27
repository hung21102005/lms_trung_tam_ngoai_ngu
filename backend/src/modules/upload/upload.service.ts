import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { FirebaseService } from '../firebase/firebase.service.js';
import * as fs from 'fs';
import * as path from 'path';
import { randomUUID } from 'crypto';

export interface UploadResult {
  url: string;
  filename: string;
  originalName: string;
  mimetype: string;
  size: number;
}

@Injectable()
export class UploadService {
  private readonly logger = new Logger(UploadService.name);
  private readonly maxSizeBytes = 50 * 1024 * 1024; // 50MB
  private readonly allowedMimeTypes = [
    // Documents
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'text/plain',
    'application/zip',
    'application/x-zip-compressed',
    'application/vnd.rar',
    'application/x-rar-compressed',
    // Images
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif',
    // Audio
    'audio/mpeg',
    'audio/mp3',
    'audio/wav',
    'audio/x-wav',
    'audio/wave',
    'audio/ogg',
    'audio/x-m4a',
    // Video
    'video/mp4',
    'video/webm',
    'video/quicktime',
  ];

  constructor(private readonly firebaseService: FirebaseService) {}

  async uploadFile(
    file: {
      buffer: Buffer;
      originalname: string;
      mimetype: string;
      size: number;
    },
    folder: string = 'materials',
  ): Promise<UploadResult> {
    if (!file || !file.buffer) {
      throw new BadRequestException('Không tìm thấy tệp tải lên.');
    }
    if (!['materials', 'avatars', 'assignments'].includes(folder)) {
      throw new BadRequestException('Thư mục tải tệp không hợp lệ.');
    }

    // 1. Kiểm tra kích thước file
    if (file.size > this.maxSizeBytes) {
      throw new BadRequestException(
        `Dung lượng tệp (${(file.size / (1024 * 1024)).toFixed(1)}MB) vượt quá giới hạn cho phép tối đa 50MB.`,
      );
    }

    // 2. Kiểm tra định dạng file
    const extension = path.extname(file.originalname).toLowerCase();
    const isArchiveWithGenericMime =
      ['.zip', '.rar'].includes(extension) &&
      file.mimetype === 'application/octet-stream';
    if (!this.allowedMimeTypes.includes(file.mimetype) && !isArchiveWithGenericMime) {
      throw new BadRequestException(
        `Loại tệp '${file.mimetype}' không được hỗ trợ. Chỉ chấp nhận PDF, Word, Excel, PPT, TXT, ZIP, RAR, hình ảnh, âm thanh và video MP4.`,
      );
    }

    const ext = path.extname(file.originalname) || '';
    const safeFilename = `${folder}/${Date.now()}-${randomUUID()}${ext}`;

    // 3. Thử tải lên Firebase Storage
    const bucket = this.firebaseService.getStorageBucket();
    if (bucket) {
      try {
        const fileRef = bucket.file(safeFilename);
        await fileRef.save(file.buffer, {
          metadata: {
            contentType: file.mimetype,
          },
          resumable: false,
        });

        // Tạo signed URL hạn dùng 1 năm (hoặc 7 ngày)
        const [signedUrl] = await fileRef.getSignedUrl({
          action: 'read',
          expires: Date.now() + 365 * 24 * 60 * 60 * 1000,
        });

        this.logger.log(
          `Tải tệp lên Firebase Storage thành công: ${safeFilename}`,
        );
        return {
          url: signedUrl,
          filename: safeFilename,
          originalName: file.originalname,
          mimetype: file.mimetype,
          size: file.size,
        };
      } catch (err) {
        this.logger.error('Lỗi khi tải tệp lên Firebase Storage:', err);
      }
    }

    // 4. Fallback lưu local nếu Firebase chưa cấu hình credentials
    const localUploadsDir = path.resolve(process.cwd(), 'uploads', folder);
    if (!fs.existsSync(localUploadsDir)) {
      fs.mkdirSync(localUploadsDir, { recursive: true });
    }

    const localFilename = `${Date.now()}-${randomUUID()}${ext}`;
    const localFilePath = path.join(localUploadsDir, localFilename);
    fs.writeFileSync(localFilePath, file.buffer);

    const localUrl = `/uploads/${folder}/${localFilename}`;

    this.logger.log(`Tệp được lưu cục bộ tại: ${localFilePath}`);
    return {
      url: localUrl,
      filename: `${folder}/${localFilename}`,
      originalName: file.originalname,
      mimetype: file.mimetype,
      size: file.size,
    };
  }
}
