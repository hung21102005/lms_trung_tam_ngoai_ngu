import { IsString, IsOptional } from 'class-validator';

export class PayOnlineDto {
  @IsString()
  @IsOptional()
  bankCode?: string;

  @IsString()
  @IsOptional()
  language?: string;
}
