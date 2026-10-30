import { registerAs } from '@nestjs/config';

export const vnpayConfig = registerAs('vnpay', () => ({
  tmnCode: process.env.VNPAY_TMN_CODE || '',
  hashSecret: process.env.VNPAY_HASH_SECRET || '',
  url: process.env.VNPAY_URL || 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html',
  returnUrl: process.env.VNPAY_RETURN_URL || 'http://localhost:3000/api/v1/finance/payments/vnpay-return',
}));
