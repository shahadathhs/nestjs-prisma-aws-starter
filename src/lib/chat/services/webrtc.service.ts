import { PrismaService } from '@/lib/prisma/prisma.service';
import { forwardRef, Inject, Injectable, Logger } from '@nestjs/common';
import { ChatGateway } from '../chat.gateway';
import { CallService } from './call.service';

@Injectable()
export class WebRTCService {
  private readonly logger = new Logger(WebRTCService.name);

  constructor(
    private readonly prisma: PrismaService,
    @Inject(forwardRef(() => ChatGateway))
    private readonly chatGateway: ChatGateway,
    private readonly callService: CallService,
  ) {
    this.logger.log('WebRTCService initialized');
  }
}
