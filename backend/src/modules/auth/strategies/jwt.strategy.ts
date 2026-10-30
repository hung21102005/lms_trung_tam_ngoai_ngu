import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../../database/index.js';
import { UserStatus } from '@prisma/client';

export interface JwtPayload {
  sub: string;
  userCode: string;
  email?: string;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get<string>('jwt.secret') || 'lms_super_secret_access_key_change_in_production_2026',
    });
  }

  async validate(payload: JwtPayload) {
    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      include: {
        userRoles: {
          include: {
            role: {
              include: {
                rolePermissions: {
                  include: {
                    permission: true,
                  },
                },
              },
            },
          },
        },
      },
    });

    if (!user) {
      throw new UnauthorizedException('Tài khoản không tồn tại hoặc phiên đăng nhập đã hết hạn.');
    }

    if (user.status === UserStatus.LOCKED) {
      throw new UnauthorizedException('Tài khoản của bạn đã bị khóa. Vui lòng liên hệ quản trị viên.');
    }

    if (user.status === UserStatus.INACTIVE) {
      throw new UnauthorizedException('Tài khoản đang tạm ngưng hoạt động.');
    }

    const roles = user.userRoles.map((ur) => ur.role.code);
    const permissionSet = new Set<string>();
    for (const ur of user.userRoles) {
      for (const rp of ur.role.rolePermissions) {
        permissionSet.add(rp.permission.code);
      }
    }

    return {
      id: user.id,
      userCode: user.userCode,
      email: user.email,
      fullName: user.fullName,
      status: user.status,
      isFirstLogin: user.isFirstLogin,
      branchId: user.branchId,
      roles,
      permissions: Array.from(permissionSet),
    };
  }
}
