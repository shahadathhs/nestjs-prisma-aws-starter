import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { MessageDeliveryStatus, MessageType } from '@prisma';
import {
  IsArray,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
} from 'class-validator';

export class BaseMessageDto {
  @ApiPropertyOptional({ description: 'Message content' })
  @IsOptional()
  @IsString()
  content?: string;

  @ApiPropertyOptional({ enum: MessageType, description: 'Type of message' })
  @IsOptional()
  @IsEnum(MessageType)
  type?: MessageType;

  @ApiPropertyOptional({ description: 'File ID if sending a file' })
  @IsOptional()
  @IsString()
  fileId?: string;
}

// ----------------------
// Send message
// ----------------------
export class SendMessageDto extends BaseMessageDto {
  @ApiProperty({ description: 'ID of the conversation to send message to' })
  @IsNotEmpty()
  @IsString()
  conversationId: string;
}

// ----------------------
// Edit message
// ----------------------
export class EditMessageDto {
  @ApiProperty({ description: 'ID of the message to edit' })
  @IsNotEmpty()
  @IsString()
  messageId: string;

  @ApiProperty({ description: 'New content for the message' })
  @IsNotEmpty()
  @IsString()
  content: string;
}

// ----------------------
// Reaction management
// ----------------------
export class ReactionDto {
  @ApiProperty({ description: 'ID of the message to react to' })
  @IsNotEmpty()
  @IsString()
  messageId: string;

  @ApiProperty({ description: 'Reaction emoji' })
  @IsNotEmpty()
  @IsString()
  reaction: string;
}

// ----------------------
// Mark message as read
// ----------------------
export class MarkReadDto {
  @ApiProperty({ description: 'IDs of messages to mark as read' })
  @IsNotEmpty()
  @IsArray()
  @IsString({ each: true })
  messageIds: string[];
}

// ----------------------
// Delete message
// ----------------------
export class DeleteMessageDto {
  @ApiProperty({ description: 'ID of the message to delete' })
  @IsNotEmpty()
  @IsString()
  messageId: string;
}

export class MessageDeliveryStatusDto {
  @ApiProperty({ description: 'ID of the message to update status' })
  @IsNotEmpty()
  @IsString()
  messageId: string;

  @ApiProperty({
    enum: MessageDeliveryStatus,
    description: 'Status of message',
  })
  @IsNotEmpty()
  @IsEnum(MessageDeliveryStatus)
  status: MessageDeliveryStatus;

  @ApiProperty({ description: 'User ID to update status for' })
  @IsNotEmpty()
  @IsString()
  userId: string;
}
