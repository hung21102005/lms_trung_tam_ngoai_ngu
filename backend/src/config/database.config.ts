import { registerAs } from '@nestjs/config';

export const databaseConfig = registerAs('database', () => ({
  url: process.env.DATABASE_URL || 'postgresql://lms_user:lms_password_dev@localhost:5432/lms_db?schema=public',
  host: process.env.POSTGRES_HOST || 'localhost',
  port: parseInt(process.env.POSTGRES_PORT || '5432', 10),
  user: process.env.POSTGRES_USER || 'lms_user',
  password: process.env.POSTGRES_PASSWORD || 'lms_password_dev',
  dbName: process.env.POSTGRES_DB || 'lms_db',
}));
