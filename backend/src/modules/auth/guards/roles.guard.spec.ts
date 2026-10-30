import { Reflector } from '@nestjs/core';
import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { RolesGuard } from './roles.guard.js';

describe('RolesGuard', () => {
  let guard: RolesGuard;
  let reflector: Reflector;

  beforeEach(() => {
    reflector = new Reflector();
    guard = new RolesGuard(reflector);
  });

  const createMockContext = (user: any): ExecutionContext => {
    return {
      getHandler: vi.fn(),
      getClass: vi.fn(),
      switchToHttp: () => ({
        getRequest: () => ({ user }),
      }),
    } as unknown as ExecutionContext;
  };

  it('should be defined', () => {
    expect(guard).toBeDefined();
  });

  it('should allow access if no roles are required', () => {
    vi.spyOn(reflector, 'getAllAndOverride').mockReturnValue(undefined);
    const context = createMockContext({ roles: ['student'] });

    expect(guard.canActivate(context)).toBe(true);
  });

  it('should allow access if user has super_admin role', () => {
    vi.spyOn(reflector, 'getAllAndOverride').mockReturnValue(['teacher', 'academic_staff']);
    const context = createMockContext({ roles: ['super_admin'] });

    expect(guard.canActivate(context)).toBe(true);
  });

  it('should allow access if user has matching required role', () => {
    vi.spyOn(reflector, 'getAllAndOverride').mockReturnValue(['teacher', 'branch_admin']);
    const context = createMockContext({ roles: ['teacher'] });

    expect(guard.canActivate(context)).toBe(true);
  });

  it('should throw ForbiddenException if user does not have matching role', () => {
    vi.spyOn(reflector, 'getAllAndOverride').mockReturnValue(['branch_admin']);
    const context = createMockContext({ roles: ['student'] });

    expect(() => guard.canActivate(context)).toThrow(ForbiddenException);
  });

  it('should throw ForbiddenException if user has no roles defined', () => {
    vi.spyOn(reflector, 'getAllAndOverride').mockReturnValue(['student']);
    const context = createMockContext({});

    expect(() => guard.canActivate(context)).toThrow(ForbiddenException);
  });
});
