import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

/** ---------------- Typing indicators ---------------- */
export class TypingDto {
  @ApiProperty({ description: 'ID of the conversation where user is typing' })
  @IsNotEmpty()
  @IsString()
  conversationId: string;
}
