import { PartialType } from '@nestjs/swagger';
import { CreateClassDto } from './create-class.dto.js';

export class UpdateClassDto extends PartialType(CreateClassDto) {}
