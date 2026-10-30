import { IsString, IsNotEmpty } from 'class-validator';

export class UpdateFcmTokenDto {
  @IsString()
  @IsNotEmpty({ message: 'FCM Token không được để trống' })
  token!: string;
}
