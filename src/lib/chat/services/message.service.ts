import { PrismaService } from '@/lib/prisma/prisma.service';
import { forwardRef, Inject, Injectable } from '@nestjs/common';
import { ChatGateway } from '../chat.gateway';

@Injectable()
export class MessageService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(forwardRef(() => ChatGateway))
    private readonly chatGateway: ChatGateway,
  ) {}
}
