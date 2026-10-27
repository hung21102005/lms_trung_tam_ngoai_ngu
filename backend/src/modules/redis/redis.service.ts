import { Injectable, OnModuleInit, OnModuleDestroy, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Redis } from 'ioredis';

@Injectable()
export class RedisService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(RedisService.name);
  private client!: Redis;

  constructor(private readonly configService: ConfigService) {}

  onModuleInit() {
    const redisUrl = this.configService.get<string>('redis.url') || 'redis://localhost:6379';
    const redisHost = this.configService.get<string>('redis.host') || 'localhost';
    const redisPort = this.configService.get<number>('redis.port') || 6379;
    const redisPassword = this.configService.get<string>('redis.password');

    this.client = new Redis({
      host: redisHost,
      port: redisPort,
      password: redisPassword,
      lazyConnect: true,
      maxRetriesPerRequest: 3,
      retryStrategy: (times) => {
        if (times > 3) {
          this.logger.warn('Không thể kết nối lại Redis sau 3 lần thử.');
          return null;
        }
        return Math.min(times * 1000, 3000);
      },
    });

    this.client.connect().then(() => {
      this.logger.log(`Đã kết nối thành công tới Redis tại ${redisHost}:${redisPort}`);
    }).catch((err) => {
      this.logger.warn(`Chưa kết nối được tới Redis (${err.message}). Vui lòng đảm bảo container redis đang chạy.`);
    });
  }

  async onModuleDestroy() {
    if (this.client) {
      await this.client.quit();
      this.logger.log('Đã ngắt kết nối an toàn khỏi Redis.');
    }
  }

  getClient(): Redis {
    return this.client;
  }

  async get(key: string): Promise<string | null> {
    try {
      return await this.client.get(key);
    } catch (error) {
      this.logger.error(`Lỗi khi get key [${key}] từ Redis:`, error);
      return null;
    }
  }

  async set(key: string, value: string, ttlSeconds?: number): Promise<boolean> {
    try {
      if (ttlSeconds) {
        await this.client.set(key, value, 'EX', ttlSeconds);
      } else {
        await this.client.set(key, value);
      }
      return true;
    } catch (error) {
      this.logger.error(`Lỗi khi set key [${key}] vào Redis:`, error);
      return false;
    }
  }

  async del(key: string): Promise<boolean> {
    try {
      await this.client.del(key);
      return true;
    } catch (error) {
      this.logger.error(`Lỗi khi xóa key [${key}] từ Redis:`, error);
      return false;
    }
  }

  async exists(key: string): Promise<boolean> {
    try {
      const res = await this.client.exists(key);
      return res === 1;
    } catch (error) {
      this.logger.error(`Lỗi khi kiểm tra key [${key}] từ Redis:`, error);
      return false;
    }
  }

  async ttl(key: string): Promise<number> {
    try {
      return await this.client.ttl(key);
    } catch (error) {
      this.logger.error(`Lỗi khi lấy TTL key [${key}] từ Redis:`, error);
      return -1;
    }
  }
}
