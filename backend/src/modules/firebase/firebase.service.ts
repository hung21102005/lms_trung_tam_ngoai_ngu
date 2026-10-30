import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { initializeApp, getApps, getApp, cert, App } from 'firebase-admin/app';
import { getMessaging, Messaging } from 'firebase-admin/messaging';
import { getStorage } from 'firebase-admin/storage';
import { getAuth, Auth } from 'firebase-admin/auth';
import * as fs from 'fs';

@Injectable()
export class FirebaseService implements OnModuleInit {
  private readonly logger = new Logger(FirebaseService.name);
  private firebaseApp!: App;
  private isInitialized = false;

  constructor(private readonly configService: ConfigService) {}

  onModuleInit() {
    try {
      const serviceAccountPath = this.configService.get<string>('firebase.serviceAccountPath');
      const storageBucket = this.configService.get<string>('firebase.storageBucket');

      const apps = getApps();
      if (apps.length > 0) {
        this.firebaseApp = getApp();
        this.isInitialized = true;
        this.logger.log('Firebase Admin SDK đã được khởi tạo trước đó.');
        return;
      }

      if (serviceAccountPath && fs.existsSync(serviceAccountPath)) {
        const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
        this.firebaseApp = initializeApp({
          credential: cert(serviceAccount),
          storageBucket,
        });
        this.isInitialized = true;
        this.logger.log(`Khởi tạo thành công Firebase Admin SDK từ file: ${serviceAccountPath}`);
      } else {
        const projectId = this.configService.get<string>('firebase.projectId');
        const clientEmail = this.configService.get<string>('firebase.clientEmail');
        const privateKey = this.configService.get<string>('firebase.privateKey');

        if (projectId && clientEmail && privateKey) {
          this.firebaseApp = initializeApp({
            credential: cert({
              projectId,
              clientEmail,
              privateKey,
            }),
            storageBucket,
          });
          this.isInitialized = true;
          this.logger.log('Khởi tạo thành công Firebase Admin SDK từ biến môi trường.');
        } else {
          this.logger.warn('Chưa tìm thấy Service Account Key cho Firebase. Các tính năng Push Notification và Storage sẽ tạm thời không khả dụng cho đến khi cấu hình file secrets.');
        }
      }
    } catch (error) {
      this.logger.error('Lỗi khi khởi tạo Firebase Admin SDK:', error);
    }
  }

  getMessaging(): Messaging | null {
    if (!this.isInitialized) {
      this.logger.warn('Firebase Messaging được gọi nhưng Firebase chưa được khởi tạo thành công.');
      return null;
    }
    return getMessaging(this.firebaseApp);
  }

  getStorageBucket(): any {
    if (!this.isInitialized) {
      this.logger.warn('Firebase Storage được gọi nhưng Firebase chưa được khởi tạo thành công.');
      return null;
    }
    return getStorage(this.firebaseApp).bucket();
  }

  getAuth(): Auth | null {
    if (!this.isInitialized) {
      return null;
    }
    return getAuth(this.firebaseApp);
  }
}
