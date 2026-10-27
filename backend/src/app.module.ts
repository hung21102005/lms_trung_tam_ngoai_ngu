import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import {
  appConfig,
  databaseConfig,
  redisConfig,
  firebaseConfig,
  jwtConfig,
  mailConfig,
  vnpayConfig,
} from './config/index.js';
import { DatabaseModule } from './database/index.js';
import { RedisModule } from './modules/redis/index.js';
import { FirebaseModule } from './modules/firebase/index.js';
import { MailModule } from './modules/mail/index.js';
import { AuthModule } from './modules/auth/index.js';
import { AdmissionsModule } from './modules/admissions/index.js';
import { BranchesModule } from './modules/branches/index.js';
import { UsersModule } from './modules/users/index.js';
import { CoursesModule } from './modules/courses/index.js';
import { ClassesModule } from './modules/classes/index.js';
import { UploadModule } from './modules/upload/index.js';
import { AttendanceModule } from './modules/attendance/index.js';
import { AssignmentsModule } from './modules/assignments/index.js';
import { ExamsModule } from './modules/exams/index.js';
import { NotificationsModule } from './modules/notifications/index.js';
import { FinanceModule } from './modules/finance/index.js';
import { ReportsModule } from './modules/reports/index.js';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';
import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [
        appConfig,
        databaseConfig,
        redisConfig,
        firebaseConfig,
        jwtConfig,
        mailConfig,
        vnpayConfig,
      ],
    }),
    ThrottlerModule.forRoot([
      {
        ttl: 60000,
        limit: 120,
      },
    ]),
    DatabaseModule,
    RedisModule,
    FirebaseModule,
    MailModule,
    AuthModule,
    AdmissionsModule,
    BranchesModule,
    UsersModule,
    CoursesModule,
    ClassesModule,
    UploadModule,
    AttendanceModule,
    AssignmentsModule,
    ExamsModule,
    NotificationsModule,
    FinanceModule,
    ReportsModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}
