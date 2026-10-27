import { Test, TestingModule } from '@nestjs/testing';
import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';
import { PrismaService } from './database/index.js';
import { RedisService } from './modules/redis/index.js';

describe('AppController', () => {
  let appController: AppController;

  const mockPrismaService = {
    $queryRaw: vi.fn().mockResolvedValue([{ 1: 1 }]),
  };

  const mockRedisService = {
    getClient: vi.fn().mockReturnValue({
      ping: vi.fn().mockResolvedValue('PONG'),
    }),
  };

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [AppController],
      providers: [
        AppService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: RedisService, useValue: mockRedisService },
      ],
    }).compile();

    appController = app.get<AppController>(AppController);
  });

  describe('root', () => {
    it('should return system info', () => {
      const res = appController.getHello();
      expect(res.name).toBe('LMS Trung Tâm Ngoại Ngữ API');
      expect(res.status).toBe('online');
    });

    it('should return health check status', async () => {
      const res = await appController.getHealth();
      expect(res.status).toBe('ok');
      expect(res.services.database).toBe('healthy');
      expect(res.services.redis).toBe('healthy');
    });
  });
});
