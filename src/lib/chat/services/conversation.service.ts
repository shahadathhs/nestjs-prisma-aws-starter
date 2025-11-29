import { forwardRef, Inject, Injectable, Logger } from '@nestjs/common';
import { ChatGateway } from '../chat.gateway';
import { PrismaService } from '@/lib/prisma/prisma.service';

@Injectable()
export class ConversationService {
  private logger = new Logger(ConversationService.name);

  constructor(
    private readonly prisma: PrismaService,
    @Inject(forwardRef(() => ChatGateway))
    private readonly chatGateway: ChatGateway,
  ) {}
}
