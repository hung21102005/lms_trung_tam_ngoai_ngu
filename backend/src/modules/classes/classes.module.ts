import { Module } from '@nestjs/common';
import { ClassesController } from './classes.controller.js';
import { ClassesService } from './classes.service.js';
import { PublicClassesController } from './public-classes.controller.js';

@Module({
  controllers: [ClassesController, PublicClassesController],
  providers: [ClassesService],
  exports: [ClassesService],
})
export class ClassesModule {}
