import { UserResponseDto } from '@/common/dto/user-response.dto';
import { ENVEnum } from '@/common/enum/env.enum';
import { JWTPayload, TokenPair } from '@/common/jwt/jwt.interface';
import { PrismaService } from '@/lib/prisma/prisma.service';
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { FileInstance, User } from '@prisma';
import * as bcrypt from 'bcrypt';
import { plainToInstance } from 'class-transformer';
import { randomBytes, randomInt } from 'crypto';

@Injectable()
export class AuthUtilsService {
  private saltRounds = 10;
  private refreshTokenDays = 30;
  private refreshTokenLength = 32;

  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
  ) {}

  async sanitizeUser<T = UserResponseDto>(
    user: User & { profilePicture?: FileInstance | null },
  ): Promise<T> {
    if (!user) return null as T;

    const profilePictureUrl =
      user?.profilePictureId && user?.profilePicture
        ? (user.profilePicture.url ?? null)
        : null;

    const flatData = {
      ...user,
      profilePictureId: user?.profilePictureId ?? null,
      profilePictureUrl,
    };

    return plainToInstance(UserResponseDto, flatData, {
      excludeExtraneousValues: true,
    }) as T;
  }

  generateToken(payload: JWTPayload): string {
    const token = this.jwtService.sign(payload, {
      secret: this.configService.getOrThrow(ENVEnum.JWT_SECRET),
      expiresIn: this.configService.getOrThrow(ENVEnum.JWT_EXPIRES_IN),
    });

    return token;
  }

  async generateTokenPairAndSave(
    userId: string,
    payload: JWTPayload,
  ): Promise<TokenPair> {
    const accessToken = this.generateToken(payload);

    const refreshToken = randomBytes(
      Math.max(32, Math.floor(this.refreshTokenLength / 2)),
    ).toString('hex');

    const refreshTokenExpiresAt = new Date(
      Date.now() + this.refreshTokenDays * 24 * 60 * 60 * 1000,
    );

    await this.prisma.client.refreshToken.create({
      data: {
        token: refreshToken,
        userId,
        expiresAt: refreshTokenExpiresAt,
      },
    });

    return {
      accessToken,
      refreshToken,
      refreshTokenExpiresAt,
    };
  }

  verifyToken<T extends object = any>(token: string): T {
    const secret = this.configService.getOrThrow<string>(ENVEnum.JWT_SECRET);
    try {
      return this.jwtService.verify<T>(token, { secret });
    } catch (err) {
      console.error(err);
      throw new UnauthorizedException('Invalid or expired token');
    }
  }

  decodeToken(token: string): any {
    return this.jwtService.decode(token);
  }

  async revokeRefreshToken(token: string) {
    await this.prisma.client.refreshToken.deleteMany({ where: { token } });
  }

  async revokeAllRefreshTokensForUser(userId: string) {
    await this.prisma.client.refreshToken.deleteMany({ where: { userId } });
  }

  async findRefreshToken(token: string) {
    return this.prisma.client.refreshToken.findUnique({ where: { token } });
  }

  generateOtpAndExpiry(minutes = 10): { otp: number; expiryTime: Date } {
    const otp = randomInt(1000, 10000);
    const expiryTime = new Date(Date.now() + minutes * 60 * 1000);
    return { otp, expiryTime };
  }

  async validateUserCredentials(email: string, plainPassword: string) {
    const user = await this.prisma.client.user.findUnique({
      where: { email },
      include: { profilePicture: true },
    });

    if (!user) return null;

    const isValid = await this.compare(plainPassword, user.password);
    if (!isValid) return null;

    return this.sanitizeUser<UserResponseDto>(user);
  }

  async getSanitizedUserById(id: string) {
    const user = await this.prisma.client.user.findUniqueOrThrow({
      where: { id },
      include: { profilePicture: true },
    });

    return this.sanitizeUser<UserResponseDto>(user);
  }

  async getUserByEmail(email: string) {
    const user = await this.prisma.client.user.findUnique({
      where: { email },
      include: { profilePicture: true },
    });

    if (!user) return null;

    return this.sanitizeUser<UserResponseDto>(user);
  }

  async prepareHashedOtp(plainOtp: number | string) {
    const otpString = String(plainOtp);
    const hashed = await this.hash(otpString);
    return hashed;
  }

  async hash(value: string): Promise<string> {
    return bcrypt.hash(value, this.saltRounds);
  }

  async compare(value: string, hash: string): Promise<boolean> {
    return bcrypt.compare(value, hash);
  }
}
