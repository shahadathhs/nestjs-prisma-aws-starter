import { PrismaService } from '@/lib/prisma/prisma.service';
import { forwardRef, Inject, Injectable, Logger } from '@nestjs/common';
import { CallStatus } from '@prisma';
import { ChatGateway } from '../chat.gateway';

@Injectable()
export class CallService {
  private readonly logger = new Logger(CallService.name);

  // callId -> ( userId -> socketId )
  private callSocketMap = new Map<string, Map<string, string>>();

  // short-lived ring timers
  private ringTimeouts = new Map<string, NodeJS.Timeout>();

  constructor(
    private readonly prisma: PrismaService,
    @Inject(forwardRef(() => ChatGateway))
    private readonly chatGateway: ChatGateway,
  ) {
    this.logger.log('CallService initialized');
  }

  /** -------------------- Helpers -------------------- */
  private ensureCallSocketEntry(callId: string) {
    if (!this.callSocketMap.has(callId)) {
      this.logger.debug(`Creating new socket map entry for call ${callId}`);
      this.callSocketMap.set(callId, new Map());
    }
    return this.callSocketMap.get(callId)!;
  }

  private findTargetSocketForRecipient(
    callId: string,
    recipientUserId: string,
    // allow client to hint socket/userId; prefer recorded socket then active sockets
    payloadTo?: string,
    excludeSocketId?: string,
  ): string | null {
    this.logger.debug(
      `Finding target socket for recipient ${recipientUserId} in call ${callId}`,
    );

    // prefer explicit socket id if it matches active sockets
    if (payloadTo && typeof payloadTo === 'string') {
      this.logger.debug(`Checking explicit socket hint: ${payloadTo}`);
      const active = this.chatGateway.getActiveSocketIdsForUser(
        recipientUserId,
        excludeSocketId,
      );
      if (active.includes(payloadTo)) {
        this.logger.debug(`Using hinted socket: ${payloadTo}`);
        return payloadTo;
      }
    }

    // prefer recorded socket for this call
    const map = this.callSocketMap.get(callId);
    if (map) {
      const recorded = map.get(recipientUserId);
      if (recorded && recorded !== excludeSocketId) {
        this.logger.debug(`Using recorded socket: ${recorded}`);
        return recorded;
      }
    }

    // fallback to first active socket for user
    const active = this.chatGateway.getActiveSocketIdsForUser(
      recipientUserId,
      excludeSocketId,
    );
    if (active.length) {
      this.logger.debug(`Using first active socket: ${active[0]}`);
      return active[0];
    }

    this.logger.warn(`No socket found for recipient ${recipientUserId}`);
    return null;
  }

  private setRingTimeout(callId: string, ms = 30_000) {
    this.logger.debug(`Setting ring timeout for call ${callId}: ${ms}ms`);
    this.clearRingTimeout(callId);

    const t = setTimeout(async () => {
      try {
        this.logger.log(`Call ${callId} ring timeout -> marking missed`);
        await this.prisma.client.privateCall.update({
          where: { id: callId },
          data: { status: CallStatus.MISSED, endedAt: new Date() },
        });
        this.callSocketMap.delete(callId);
        this.logger.log(`Call ${callId} marked as missed due to timeout`);
      } catch (err) {
        this.logger.error(
          `Failed to mark call ${callId} as missed`,
          err as any,
        );
      } finally {
        this.clearRingTimeout(callId);
      }
    }, ms);

    this.ringTimeouts.set(callId, t);
  }

  private clearRingTimeout(callId: string) {
    const t = this.ringTimeouts.get(callId);
    if (t) {
      this.logger.debug(`Clearing ring timeout for call ${callId}`);
      clearTimeout(t);
      this.ringTimeouts.delete(callId);
    }
  }
}
