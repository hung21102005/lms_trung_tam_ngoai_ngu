import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import * as path from 'path';
import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import compression from 'compression';
import { AppModule } from './app.module.js';
import {
  HttpExceptionFilter,
  TransformInterceptor,
  LoggingInterceptor,
  appValidationPipe,
} from './common/index.js';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  app.useStaticAssets(path.resolve(process.cwd(), 'uploads'), {
    prefix: '/uploads/',
  });

  const configService = app.get(ConfigService);
  const port = configService.get<number>('app.port') || 3000;
  const apiPrefix = configService.get<string>('app.apiPrefix') || 'api/v1';

  // 1. Security & Performance Middlewares (Helmet & Compression)
  app.use(
    helmet({
      crossOriginEmbedderPolicy: false,
      contentSecurityPolicy: false, // Giữ CSP mở để Swagger UI và WebViews hiển thị mượt mà
      crossOriginResourcePolicy: { policy: 'cross-origin' },
      crossOriginOpenerPolicy: false,
    }),
  );
  app.use(compression());

  // 2. CORS
  app.enableCors({
    origin: true,
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: true,
    allowedHeaders: [
      'Content-Type',
      'Accept',
      'Authorization',
      'X-Requested-With',
    ],
  });

  // 3. Fallback compatibility: Rewrite /api/... to /api/v1/... (tránh 404 nếu client gọi thiếu /v1)
  app.use((req: any, _res: any, next: any) => {
    if (
      req.url &&
      req.url.startsWith('/api/') &&
      !req.url.startsWith('/api/v1/') &&
      !req.url.startsWith('/api/docs')
    ) {
      req.url = req.url.replace('/api/', '/api/v1/');
    }
    next();
  });

  // 4. Global Prefix
  app.setGlobalPrefix(apiPrefix);

  // 4. Global Filters, Pipes, Interceptors
  app.useGlobalPipes(appValidationPipe);
  app.useGlobalFilters(new HttpExceptionFilter());
  app.useGlobalInterceptors(
    new LoggingInterceptor(),
    new TransformInterceptor(),
  );

  // 5. Swagger / OpenAPI Documentation
  const swaggerConfig = new DocumentBuilder()
    .setTitle('LMS Trung Tâm Ngoại Ngữ API')
    .setDescription(
      'Hệ thống Quản lý Học tập (LMS) Trung tâm Ngoại ngữ - RESTful APIs Specification',
    )
    .setVersion('1.0.0')
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        name: 'Authorization',
        description: 'Nhập JWT Bearer token theo định dạng: Bearer <token>',
        in: 'header',
      },
      'JWT-auth',
    )
    .addTag('Health', 'Kiểm tra trạng thái máy chủ')
    .addTag('Auth', 'Xác thực và phân quyền tài khoản')
    .addTag('Users', 'Quản lý thông tin học viên, giáo viên, phụ huynh')
    .addTag('Branches & Rooms', 'Quản lý chi nhánh và phòng học')
    .addTag('Courses & Classes', 'Quản lý khóa học, lớp học và thời khóa biểu')
    .addTag('Attendance', 'Điểm danh và chuyên cần')
    .addTag(
      'Exams & Assignments',
      'Ngân hàng đề thi, làm bài và chấm điểm phát âm',
    )
    .addTag('Finance & Payments', 'Học phí, hóa đơn và cổng thanh toán VNPay')
    .addTag('Notifications', 'Thông báo đẩy FCM và hàng đợi tác vụ')
    .addTag(
      'Reports & Analytics',
      'Báo cáo thống kê, doanh thu, chuyên cần, công nợ và xuất Excel',
    )
    .build();

  const document = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('api/docs', app, document, {
    customSiteTitle: 'LMS API Documentation',
    swaggerOptions: {
      persistAuthorization: true,
    },
  });

  await app.listen(port);
  logger.log(
    `🚀 Máy chủ LMS Backend đang chạy tại: http://localhost:${port}/${apiPrefix}`,
  );
  logger.log(`📚 Tài liệu Swagger API tại: http://localhost:${port}/api/docs`);
}

await bootstrap();
