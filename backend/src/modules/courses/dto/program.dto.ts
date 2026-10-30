import { PartialType, ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  Min,
} from 'class-validator';

export class CreateProgramDto {
  @ApiProperty({ example: 'PRG-GEN' })
  @IsString()
  @IsNotEmpty()
  @Matches(/^[A-Z0-9_-]+$/)
  code!: string;

  @ApiProperty({ example: 'general-english' })
  @IsString()
  @IsNotEmpty()
  @Matches(/^[a-z0-9]+(?:-[a-z0-9]+)*$/)
  slug!: string;

  @ApiProperty({ example: 'Tiếng Anh tổng quát' })
  @IsString()
  @IsNotEmpty()
  nameVi!: string;

  @ApiProperty({ example: 'General English' })
  @IsString()
  @IsNotEmpty()
  nameEn!: string;

  @ApiProperty({ example: 'GENERAL' })
  @IsString()
  @IsNotEmpty()
  category!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  targetAudience?: string;

  @ApiPropertyOptional({ default: 'English' })
  @IsOptional()
  @IsString()
  language?: string;

  @ApiPropertyOptional({ minimum: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  displayOrder?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  thumbnailUrl?: string;
}

export class UpdateProgramDto extends PartialType(CreateProgramDto) {}

export class ProgramVisibilityDto {
  @ApiProperty()
  @IsBoolean()
  isPublic!: boolean;
}
