import { PaginationDto } from '@/common/dto/pagination.dto';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

/** ---------------- Load multiple conversations (with pagination + search) ---------------- */
export class LoadConversationsDto extends PaginationDto {
  @ApiPropertyOptional({
    description: 'Search query (e.g., name or message content)',
  })
  @IsOptional()
  @IsString()
  search?: string;
}

/** ---------------- Load a single conversation with paginated messages ---------------- */
export class LoadSingleConversationDto extends PaginationDto {
  @ApiProperty({ description: 'ID of the conversation to load' })
  @IsNotEmpty()
  @IsString()
  conversationId: string;
}

/** ---------------- Initiate a new conversation with a specific user ---------------- */
export class InitConversationWithUserDto {
  @ApiProperty({ description: 'ID of the user to initiate conversation with' })
  @IsNotEmpty()
  @IsString()
  userId: string;
}

/** ---------------- Conversation actions (delete, archive, block, unblock) ---------------- */
export class ConversationActionDto {
  @ApiProperty({ description: 'ID of the conversation' })
  @IsNotEmpty()
  @IsString()
  conversationId: string;
}
