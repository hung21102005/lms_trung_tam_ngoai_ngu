import { Module } from '@nestjs/common';
import { NotificationsService } from './notifications.service.js';
import { NotificationsController } from './notifications.controller.js';
import { FirebaseModule } from '../firebase/firebase.module.js';
import { MailModule } from '../mail/mail.module.js';

@Module({
  imports: [FirebaseModule, MailModule],
  controllers: [NotificationsController],
  providers: [NotificationsService],
  exports: [NotificationsService],
})
export class NotificationsModule {}
