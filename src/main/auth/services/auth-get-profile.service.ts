import { successResponse, TResponse } from '@/common/utils/response.util';
import { HandleError } from '@/core/error/handle-error.decorator';
import { PrismaService } from '@/lib/prisma/prisma.service';
import { AuthUtilsService } from '@/lib/utils/services/auth-utils.service';
import { Injectable } from '@nestjs/common';

@Injectable()
export class AuthGetProfileService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly authUtils: AuthUtilsService,
  ) {}

  @HandleError("Can't get user profile")
  async getProfile(userId: string) {
    const user = await this.findUserBy('id', userId);
    return user;
  }

  private async findUserBy(
    key: 'id' | 'email',
    value: string,
  ): Promise<TResponse<any>> {
    const where: any = {};
    where[key] = value;

    const user = await this.prisma.client.user.findUniqueOrThrow({
      where,
      include: {
        notifications: true,
        profilePicture: true,
      },
    });

    // Extract only the main user fields
    const { notifications, ...mainUser } = user;

    const sanitizedUser = await this.authUtils.sanitizeUser(mainUser);

    // Rebuild the full object: sanitized user + full raw relations
    const data = {
      ...sanitizedUser,
      notifications,
    };

    return successResponse(data, 'User data fetched successfully');
  }
}
