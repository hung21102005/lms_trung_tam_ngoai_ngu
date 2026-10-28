import { PartialType } from '@nestjs/swagger';
import { CreateCourseLevelDto } from './create-level.dto.js';

export class UpdateCourseLevelDto extends PartialType(CreateCourseLevelDto) {}
