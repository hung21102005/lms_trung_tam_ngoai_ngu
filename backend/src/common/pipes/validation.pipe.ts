import { ValidationPipe as NestValidationPipe, ValidationPipeOptions } from '@nestjs/common';

export const appValidationPipe = new NestValidationPipe({
  whitelist: true,
  transform: true,
  forbidNonWhitelisted: true,
  transformOptions: {
    enableImplicitConversion: true,
  },
});

export const createValidationPipe = (options?: ValidationPipeOptions) =>
  new NestValidationPipe({
    whitelist: true,
    transform: true,
    forbidNonWhitelisted: true,
    transformOptions: {
      enableImplicitConversion: true,
    },
    ...options,
  });
