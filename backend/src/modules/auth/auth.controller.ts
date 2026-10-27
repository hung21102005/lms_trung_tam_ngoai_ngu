import {
  Controller,
  Post,
  Get,
  Body,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { AuthService } from './auth.service.js';
import {
  LoginDto,
  FirstLoginSetupDto,
  ChangePasswordDto,
  RefreshTokenDto,
  ForgotPasswordDto,
  ResetPasswordDto,
} from './dto/index.js';
import { JwtAuthGuard } from './guards/jwt-auth.guard.js';
import { CurrentUser } from './decorators/current-user.decorator.js';
import { Public } from './decorators/public.decorator.js';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Public()
  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Đăng nhập hệ thống (Email, Số điện thoại hoặc Mã định danh)',
    description: 'Trả về JWT tokens và cờ requiresPasswordChange nếu là tài khoản mới cấp phát cần đổi mật khẩu lần đầu.',
  })
  @ApiResponse({ status: 200, description: 'Đăng nhập thành công' })
  @ApiResponse({ status: 401, description: 'Sai thông tin đăng nhập hoặc tài khoản bị khóa' })
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @Post('first-login-setup')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Kích hoạt tài khoản & Đổi mật khẩu lần đầu',
    description: 'Học viên/Phụ huynh/Giáo viên bắt buộc thực hiện sau khi đăng nhập lần đầu với mật khẩu trung tâm cấp.',
  })
  @ApiResponse({ status: 200, description: 'Kích hoạt và đổi mật khẩu thành công' })
  @ApiResponse({ status: 400, description: 'Mật khẩu xác nhận không khớp hoặc vi phạm độ phức tạp' })
  firstLoginSetup(
    @CurrentUser('id') userId: string,
    @Body() dto: FirstLoginSetupDto,
  ) {
    return this.authService.firstLoginSetup(userId, dto);
  }

  @Public()
  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Làm mới Access Token bằng Refresh Token',
  })
  @ApiResponse({ status: 200, description: 'Cấp mới Access Token thành công' })
  @ApiResponse({ status: 401, description: 'Refresh token không hợp lệ hoặc đã hết hạn' })
  refreshTokens(@Body() dto: RefreshTokenDto) {
    return this.authService.refreshTokens(dto);
  }

  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @Get('me')
  @ApiOperation({
    summary: 'Lấy thông tin hồ sơ và phân quyền của người dùng hiện tại',
  })
  @ApiResponse({ status: 200, description: 'Trả về thông tin chi tiết user, roles, permissions, profile' })
  @ApiResponse({ status: 401, description: 'Chưa xác thực hoặc token hết hạn' })
  getMe(@CurrentUser('id') userId: string) {
    return this.authService.getMe(userId);
  }

  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @Post('change-password')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Đổi mật khẩu người dùng',
  })
  @ApiResponse({ status: 200, description: 'Đổi mật khẩu thành công' })
  @ApiResponse({ status: 400, description: 'Mật khẩu cũ không chính xác' })
  changePassword(
    @CurrentUser('id') userId: string,
    @Body() dto: ChangePasswordDto,
  ) {
    return this.authService.changePassword(userId, dto);
  }

  @Public()
  @Post('forgot-password')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Yêu cầu gửi mã OTP đặt lại mật khẩu qua Email',
  })
  @ApiResponse({ status: 200, description: 'Đã gửi mã OTP đến email nếu tài khoản tồn tại' })
  forgotPassword(@Body() dto: ForgotPasswordDto) {
    return this.authService.forgotPassword(dto);
  }

  @Public()
  @Post('reset-password')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Xác thực OTP và đặt lại mật khẩu mới',
  })
  @ApiResponse({ status: 200, description: 'Đặt lại mật khẩu thành công' })
  @ApiResponse({ status: 400, description: 'Mã OTP không đúng hoặc đã hết hạn' })
  resetPassword(@Body() dto: ResetPasswordDto) {
    return this.authService.resetPassword(dto);
  }
}
