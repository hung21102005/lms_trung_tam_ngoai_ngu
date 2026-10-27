import { registerAs } from '@nestjs/config';
import * as path from 'path';

export const firebaseConfig = registerAs('firebase', () => ({
  projectId: process.env.FIREBASE_PROJECT_ID || 'lms-trung-tam-ngoai-ngu',
  clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
  privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET || 'lms-trung-tam-ngoai-ngu.appspot.com',
  serviceAccountPath: process.env.FIREBASE_CREDENTIALS_PATH || path.resolve(process.cwd(), 'secrets', 'firebase-service-account.json'),
}));
