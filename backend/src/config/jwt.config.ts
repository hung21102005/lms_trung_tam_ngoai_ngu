import { registerAs } from '@nestjs/config';

export const jwtConfig = registerAs('jwt', () => ({
  secret: process.env.JWT_SECRET || 'lms_super_secret_access_key_change_in_production_2026',
  refreshSecret: process.env.JWT_REFRESH_SECRET || 'lms_super_secret_refresh_key_change_in_production_2026',
  accessExpiration: process.env.JWT_ACCESS_EXPIRATION || '15m',
  refreshExpiration: process.env.JWT_REFRESH_EXPIRATION || '7d',
}));
