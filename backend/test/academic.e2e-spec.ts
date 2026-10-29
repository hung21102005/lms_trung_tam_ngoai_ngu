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

  it('should expose only the published catalog without authentication', async () => {
    const res = await request(app.getHttpServer()).get('/public/courses');
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    const internal = await request(app.getHttpServer()).get('/courses');
    expect(internal.status).toBe(401);
  });

  it('should expose public class offerings without authentication', async () => {
    const res = await request(app.getHttpServer()).get('/public/classes');
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.items)).toBe(true);
    expect(res.body).toHaveProperty('total');
  });

  it('validates public registration and protects student/staff requests', async () => {
    const invalid = await request(app.getHttpServer())
      .post('/public/registrations')
      .send({ classId: 'not-a-uuid', fullName: '', phone: 'invalid' });
    expect(invalid.status).toBe(400);

    const missing = await request(app.getHttpServer())
      .post('/public/registrations')
      .send({
        classId: '00000000-0000-4000-8000-000000000001',
        fullName: 'Nguyễn Văn An',
        phone: '0988776655',
      });
    expect(missing.status).toBe(404);

    const studentRequest = await request(app.getHttpServer())
      .post('/my/registrations')
      .send({ classId: '00000000-0000-4000-8000-000000000001' });
    expect(studentRequest.status).toBe(401);
    const staffList = await request(app.getHttpServer()).get(
      '/admissions/registrations',
    );
    expect(staffList.status).toBe(401);
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
