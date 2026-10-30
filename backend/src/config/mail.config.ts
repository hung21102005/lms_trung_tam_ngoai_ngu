import { registerAs } from '@nestjs/config';

export const mailConfig = registerAs('mail', () => ({
  host: process.env.SMTP_HOST || 'smtp.gmail.com',
  port: parseInt(process.env.SMTP_PORT || '587', 10),
  user: process.env.SMTP_USER || process.env.GMAIL_USER || 'tvihung2005@gmail.com',
  password: process.env.SMTP_PASSWORD || process.env.GMAIL_APP_PASSWORD || 'zidimptezpkcizty',
  fromEmail: process.env.FROM_EMAIL || 'tvihung2005@gmail.com',
  fromName: process.env.FROM_NAME || 'LMS Trung Tâm Ngoại Ngữ',
}));
