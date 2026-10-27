import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module.js';
import { describe, it, expect, beforeAll, afterAll } from 'vitest';

describe('Academic Core Flow (e2e)', () => {
  let app: INestApplication;
  let adminToken: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        transform: true,
      }),
    );
    await app.init();

    // Login as Super Admin
    const loginRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({
        identifier: 'admin@lms-edu.vn',
        password: 'Admin@123456',
      });

    if (loginRes.status === 200 && loginRes.body.accessToken) {
      adminToken = loginRes.body.accessToken;
    }
  }, 30000);

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  it('should fetch public courses list (GET /courses)', async () => {
    const res = await request(app.getHttpServer()).get('/courses');
    expect(res.status).toBe(200);
    expect(res.body.items).toBeDefined();
    expect(Array.isArray(res.body.items)).toBe(true);
  });

  it('should fetch classes list with auth (GET /classes)', async () => {
    if (!adminToken) return;

    const res = await request(app.getHttpServer())
      .get('/classes')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.items).toBeDefined();
    expect(Array.isArray(res.body.items)).toBe(true);
  });

  it('should fetch schedule (GET /my/schedule)', async () => {
    if (!adminToken) return;

    const res = await request(app.getHttpServer())
      .get('/my/schedule')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });
});
