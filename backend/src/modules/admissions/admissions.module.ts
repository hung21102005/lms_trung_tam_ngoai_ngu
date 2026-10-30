import { Module } from '@nestjs/common';
import { AdmissionsController } from './admissions.controller.js';
import { AdmissionsService } from './admissions.service.js';
import { ClassesModule } from '../classes/classes.module.js';
import { ClassRegistrationsController } from './class-registrations.controller.js';
import { ClassRegistrationsService } from './class-registrations.service.js';

@Module({
  imports: [ClassesModule],
  controllers: [AdmissionsController, ClassRegistrationsController],
  providers: [AdmissionsService, ClassRegistrationsService],
  exports: [AdmissionsService],
})
export class AdmissionsModule {}
