import { Injectable } from '@nestjs/common';
import { PrismaService } from './database/index.js';
import { RedisService } from './modules/redis/index.js';

@Injectable()
export class AppService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  getSystemInfo() {
    return {
      name: 'LMS Trung Tâm Ngoại Ngữ API',
      version: '1.0.0',
      description: 'Hệ thống Quản lý Học tập Trung tâm Ngoại ngữ',
      status: 'online',
      environment: process.env.NODE_ENV || 'development',
    };
  }

  async checkHealth() {
    let dbStatus = 'healthy';
    let redisStatus = 'healthy';

    try {
      await this.prisma.$queryRaw`SELECT 1`;
    } catch {
      dbStatus = 'unhealthy';
    }

    try {
      const ping = await this.redis.getClient().ping();
      if (ping !== 'PONG') {
        redisStatus = 'unhealthy';
      }
    } catch {
      redisStatus = 'unhealthy';
    }

    return {
      status: dbStatus === 'healthy' && redisStatus === 'healthy' ? 'ok' : 'degraded',
      services: {
        database: dbStatus,
        redis: redisStatus,
      },
      uptime: process.uptime(),
      timestamp: new Date().toISOString(),
    };
  }
}
