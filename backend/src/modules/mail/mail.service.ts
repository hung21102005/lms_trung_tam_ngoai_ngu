import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);
  private transporter: nodemailer.Transporter;

  constructor(private readonly configService: ConfigService) {
    const host = this.configService.get<string>('mail.host') || 'smtp.gmail.com';
    const port = this.configService.get<number>('mail.port') || 587;
    const user = this.configService.get<string>('mail.user');
    const pass = this.configService.get<string>('mail.password');

    this.transporter = nodemailer.createTransport({
      host,
      port,
      secure: port === 465,
      auth: user && pass ? { user, pass } : undefined,
    });
  }

  async sendOtpEmail(toEmail: string, fullName: string, otpCode: string): Promise<boolean> {
    try {
      const fromName = this.configService.get<string>('mail.fromName') || 'LMS Trung Tâm Ngoại Ngữ';
      const fromEmail = this.configService.get<string>('mail.fromEmail') || 'tvihung2005@gmail.com';

      const html = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
          <h2 style="color: #1a5276; text-align: center;">Hệ Thống LMS Trung Tâm Ngoại Ngữ</h2>
          <p>Xin chào <strong>${fullName}</strong>,</p>
          <p>Hệ thống nhận được yêu cầu đặt lại mật khẩu cho tài khoản của bạn. Dưới đây là mã xác thực OTP (hiệu lực trong vòng <strong>5 phút</strong>):</p>
          <div style="background-color: #f4f6f7; padding: 15px; text-align: center; font-size: 28px; font-weight: bold; letter-spacing: 5px; color: #c0392b; border-radius: 6px; margin: 20px 0;">
            ${otpCode}
          </div>
          <p style="color: #7f8c8d; font-size: 13px;">Nếu bạn không thực hiện yêu cầu này, vui lòng bỏ qua email hoặc thông báo ngay cho ban quản trị trung tâm để bảo mật tài khoản.</p>
          <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
          <p style="font-size: 12px; color: #95a5a6; text-align: center;">© 2026 LMS Trung Tâm Ngoại Ngữ. Email tự động, vui lòng không phản hồi.</p>
        </div>
      `;

      await this.transporter.sendMail({
        from: `"${fromName}" <${fromEmail}>`,
        to: toEmail,
        subject: `[LMS] Mã xác thực OTP đặt lại mật khẩu: ${otpCode}`,
        html,
      });

      this.logger.log(`Đã gửi email OTP thành công tới ${toEmail}`);
      return true;
    } catch (error) {
      this.logger.error(`Lỗi khi gửi email OTP tới ${toEmail}:`, error);
      return false;
    }
  }

  async sendWelcomeEmail(toEmail: string, fullName: string, userCode: string, temporaryPass: string): Promise<boolean> {
    try {
      const fromName = this.configService.get<string>('mail.fromName') || 'LMS Trung Tâm Ngoại Ngữ';
      const fromEmail = this.configService.get<string>('mail.fromEmail') || 'tvihung2005@gmail.com';

      const html = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
          <h2 style="color: #1a5276; text-align: center;">Chào Mừng Đến Với Trung Tâm Ngoại Ngữ!</h2>
          <p>Xin chào <strong>${fullName}</strong>,</p>
          <p>Tài khoản học tập và tra cứu của bạn trên hệ thống LMS đã được tạo thành công với thông tin như sau:</p>
          <div style="background-color: #eaf2f8; padding: 15px; border-radius: 6px; margin: 20px 0;">
            <p style="margin: 5px 0;"><strong>Mã tài khoản:</strong> <code style="font-size: 16px; color: #2980b9;">${userCode}</code></p>
            <p style="margin: 5px 0;"><strong>Email đăng nhập:</strong> ${toEmail}</p>
            <p style="margin: 5px 0;"><strong>Mật khẩu tạm thời:</strong> <code style="font-size: 16px; color: #c0392b;">${temporaryPass}</code></p>
          </div>
          <p style="color: #d35400;"><strong>Lưu ý quan trọng:</strong> Trong lần đăng nhập đầu tiên trên ứng dụng, bạn bắt buộc phải đổi mật khẩu mới để kích hoạt tài khoản.</p>
          <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
          <p style="font-size: 12px; color: #95a5a6; text-align: center;">© 2026 LMS Trung Tâm Ngoại Ngữ.</p>
        </div>
      `;

      await this.transporter.sendMail({
        from: `"${fromName}" <${fromEmail}>`,
        to: toEmail,
        subject: `[LMS] Thông tin tài khoản đăng nhập trung tâm ngoại ngữ của ${fullName}`,
        html,
      });

      this.logger.log(`Đã gửi email thông tin tài khoản tới ${toEmail}`);
      return true;
    } catch (error) {
      this.logger.error(`Lỗi khi gửi email chào mừng tới ${toEmail}:`, error);
      return false;
    }
  }

  async sendResetPasswordEmail(toEmail: string, fullName: string, newTempPass: string): Promise<boolean> {
    try {
      const fromName = this.configService.get<string>('mail.fromName') || 'LMS Trung Tâm Ngoại Ngữ';
      const fromEmail = this.configService.get<string>('mail.fromEmail') || 'tvihung2005@gmail.com';

      const html = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
          <h2 style="color: #1a5276; text-align: center;">Cấp Lại Mật Khẩu Truy Cập LMS</h2>
          <p>Xin chào <strong>${fullName}</strong>,</p>
          <p>Quản trị viên hệ thống đã cấp lại mật khẩu đăng nhập tạm thời cho tài khoản của bạn:</p>
          <div style="background-color: #fcf3cf; padding: 15px; border-radius: 6px; margin: 20px 0; text-align: center;">
            <p style="margin: 5px 0;">Mật khẩu tạm thời mới:</p>
            <p style="font-size: 24px; font-weight: bold; color: #b7950b; letter-spacing: 2px; margin: 5px 0;">${newTempPass}</p>
          </div>
          <p style="color: #d35400;"><strong>Lưu ý:</strong> Vui lòng đổi lại mật khẩu cá nhân ngay sau khi đăng nhập thành công.</p>
          <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
          <p style="font-size: 12px; color: #95a5a6; text-align: center;">© 2026 LMS Trung Tâm Ngoại Ngữ.</p>
        </div>
      `;

      await this.transporter.sendMail({
        from: `"${fromName}" <${fromEmail}>`,
        to: toEmail,
        subject: `[LMS] Mật khẩu tạm thời mới của tài khoản ${fullName}`,
        html,
      });

      this.logger.log(`Đã gửi email cấp lại mật khẩu tạm thời tới ${toEmail}`);
      return true;
    } catch (error) {
      this.logger.error(`Lỗi khi gửi email cấp lại mật khẩu tới ${toEmail}:`, error);
      return false;
    }
  }

  async sendTuitionReminderEmail(toEmail: string, fullName: string, invoiceCode: string, formattedAmount: string): Promise<boolean> {
    try {
      const fromName = this.configService.get<string>('mail.fromName') || 'LMS Trung Tâm Ngoại Ngữ';
      const fromEmail = this.configService.get<string>('mail.fromEmail') || 'tvihung2005@gmail.com';

      const html = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
          <h2 style="color: #c0392b; text-align: center;">Thông Báo Học Phí Quá Hạn</h2>
          <p>Kính gửi Quý phụ huynh / Học viên <strong>${fullName}</strong>,</p>
          <p>Hệ thống LMS xin gửi thông báo nhắc nhở về khoản học phí cần thanh toán:</p>
          <div style="background-color: #fcf3cf; padding: 15px; border-radius: 6px; margin: 20px 0;">
            <p style="margin: 5px 0;"><strong>Mã hóa đơn:</strong> <code style="font-size: 16px; color: #2980b9;">${invoiceCode}</code></p>
            <p style="margin: 5px 0;"><strong>Số tiền còn lại:</strong> <span style="font-size: 18px; font-weight: bold; color: #c0392b;">${formattedAmount}</span></p>
          </div>
          <p>Quý phụ huynh/học viên có thể thanh toán trực tiếp tại phòng ghi danh trung tâm hoặc chuyển khoản trực tuyến qua cổng VNPay/VietQR trên ứng dụng di động.</p>
          <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
          <p style="font-size: 12px; color: #95a5a6; text-align: center;">© 2026 LMS Trung Tâm Ngoại Ngữ. Email tự động, vui lòng không phản hồi.</p>
        </div>
      `;

      await this.transporter.sendMail({
        from: `"${fromName}" <${fromEmail}>`,
        to: toEmail,
        subject: `[LMS] Nhắc nhở thanh toán học phí quá hạn: Hóa đơn ${invoiceCode}`,
        html,
      });

      this.logger.log(`Đã gửi email nhắc học phí tới ${toEmail}`);
      return true;
    } catch (error) {
      this.logger.error(`Lỗi khi gửi email nhắc học phí tới ${toEmail}:`, error);
      return false;
    }
  }
}
