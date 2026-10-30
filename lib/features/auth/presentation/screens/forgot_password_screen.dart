import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../domain/repositories/auth_repository.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isOtpSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      AppDialog.showErrorSnackBar(context, 'Vui lòng nhập địa chỉ email hợp lệ.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = getIt<AuthRepository>();
      await repo.forgotPassword(email);
      setState(() => _isOtpSent = true);
      if (mounted) {
        AppDialog.showSuccessSnackBar(
          context,
          'Mã xác thực OTP đã được gửi đến email $email (hiệu lực 5 phút).',
        );
      }
    } on ApiException catch (e) {
      if (mounted) AppDialog.showErrorSnackBar(context, e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (otp.length != 6) {
      AppDialog.showErrorSnackBar(context, 'Mã OTP bao gồm 6 chữ số.');
      return;
    }
    if (newPass.length < 6) {
      AppDialog.showErrorSnackBar(context, 'Mật khẩu mới tối thiểu 6 ký tự.');
      return;
    }
    if (newPass != confirmPass) {
      AppDialog.showErrorSnackBar(context, 'Mật khẩu xác nhận không khớp.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = getIt<AuthRepository>();
      await repo.resetPassword(email, otp, newPass);
      if (mounted) {
        AppDialog.showSuccessSnackBar(context, 'Đặt lại mật khẩu thành công! Vui lòng đăng nhập lại.');
        context.go(RouteNames.login);
      }
    } on ApiException catch (e) {
      if (mounted) AppDialog.showErrorSnackBar(context, e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quên Mật Khẩu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: AppCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isOtpSent ? Icons.mark_email_read_outlined : Icons.lock_reset_rounded,
                    size: 54,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isOtpSent ? 'Nhập Mã Xác Thực OTP' : 'Khôi Phục Mật Khẩu',
                    style: AppTextStyles.h2(context),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isOtpSent
                        ? 'Kiểm tra hộp thư email và nhập mã 6 số cùng mật khẩu mới của bạn.'
                        : 'Nhập email đã đăng ký tài khoản tại trung tâm để nhận mã OTP khôi phục.',
                    style: AppTextStyles.bodyMedium(context),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (!_isOtpSent) ...[
                    AppTextField(
                      controller: _emailController,
                      label: 'Địa chỉ Email',
                      hintText: 'example@email.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      text: 'Gửi Mã Xác Thực',
                      onPressed: _sendOtp,
                      isLoading: _isLoading,
                    ),
                  ] else ...[
                    AppTextField(
                      controller: _otpController,
                      label: 'Mã OTP (6 chữ số)',
                      hintText: 'VD: 123456',
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.pin_outlined),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _newPasswordController,
                      label: 'Mật khẩu mới',
                      hintText: 'Tối thiểu 6 ký tự',
                      isPassword: true,
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _confirmPasswordController,
                      label: 'Xác nhận mật khẩu mới',
                      hintText: 'Nhập lại mật khẩu mới',
                      isPassword: true,
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      text: 'Xác Nhận & Đổi Mật Khẩu',
                      onPressed: _resetPassword,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() => _isOtpSent = false),
                      child: const Text('Gửi lại mã OTP tới email khác'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
