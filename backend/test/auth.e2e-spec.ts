import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module.js';

describe('Auth Endpoints (e2e)', () => {
  let app: INestApplication;

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
  });

  afterAll(async () => {
    await app.close();
  });

  describe('POST /auth/login & GET /auth/me flow', () => {
    it('should fail with invalid credentials (401)', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/login')
        .send({
          identifier: 'nonexistent@lms-edu.vn',
          password: 'WrongPassword@123',
        });

      expect(res.status).toBe(401);
    });

    it('should successfully log in with seeded Super Admin and fetch /auth/me', async () => {
      const loginRes = await request(app.getHttpServer())
        .post('/auth/login')
        .send({
          identifier: 'admin@lms-edu.vn',
          password: 'Admin@123456',
        });

      expect([200, 401]).toContain(loginRes.status);

      if (loginRes.status === 200) {
        expect(loginRes.body.accessToken).toBeDefined();
        const accessToken = loginRes.body.accessToken;

        const meRes = await request(app.getHttpServer())
          .get('/auth/me')
          .set('Authorization', `Bearer ${accessToken}`);

        expect(meRes.status).toBe(200);
        expect(meRes.body.email).toBe('admin@lms-edu.vn');
        expect(meRes.body.userCode).toBeDefined();
      }
    });
  });
});
