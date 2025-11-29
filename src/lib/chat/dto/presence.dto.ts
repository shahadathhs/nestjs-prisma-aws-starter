import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty } from 'class-validator';

export enum PresenceStatus {
  ONLINE = 'online',
  OFFLINE = 'offline',
  IDLE = 'idle',
}

/** ---------------- Presence updates ---------------- */
export class PresenceUpdateDto {
  @ApiProperty({
    enum: PresenceStatus,
    description: 'User presence status',
  })
  @IsNotEmpty()
  @IsEnum(PresenceStatus)
  status: PresenceStatus;
}
