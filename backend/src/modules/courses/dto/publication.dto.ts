import { ApiProperty } from '@nestjs/swagger';
import { PublicationStatus } from '@prisma/client';
import { IsEnum } from 'class-validator';

export class PublicationDto {
  @ApiProperty({ enum: PublicationStatus })
  @IsEnum(PublicationStatus)
  status!: PublicationStatus;
}
