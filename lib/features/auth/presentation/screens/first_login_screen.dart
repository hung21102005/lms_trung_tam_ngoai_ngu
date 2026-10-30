import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class FirstLoginScreen extends StatefulWidget {
  const FirstLoginScreen({super.key});

  @override
  State<FirstLoginScreen> createState() => _FirstLoginScreenState();
}

class _FirstLoginScreenState extends State<FirstLoginScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            FirstLoginSetupSubmittedEvent(
              newPassword: _newPasswordController.text,
              confirmPassword: _confirmPasswordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailureState) {
          AppDialog.showErrorSnackBar(context, state.errorMessage);
        } else if (state is AuthenticatedState && !state.requiresPasswordChange) {
          final targetRoute = state.user.dashboardRoute;
          if (targetRoute == null) {
            AppDialog.showErrorSnackBar(
              context,
              'Không xác định được vai trò tài khoản. Vui lòng đăng nhập lại bằng mật khẩu mới.',
            );
            context.read<AuthBloc>().add(LogoutRequestedEvent());
            context.go(RouteNames.login);
            return;
          }
          AppDialog.showSuccessSnackBar(
            context,
            'Kích hoạt tài khoản thành công! Chào mừng bạn đến với LMS.',
          );
          context.go(targetRoute);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kích Hoạt Tài Khoản'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Đăng xuất',
              onPressed: () {
                context.read<AuthBloc>().add(LogoutRequestedEvent());
              },
            ),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: AppCard(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 56,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Đổi Mật Khẩu Lần Đầu',
                        style: AppTextStyles.h2(context),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Để đảm bảo an toàn bảo mật, bạn bắt buộc phải thiết lập mật khẩu cá nhân mới trong lần đăng nhập đầu tiên.',
                        style: AppTextStyles.bodyMedium(context),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      AppTextField(
                        controller: _newPasswordController,
                        label: 'Mật khẩu mới',
                        hintText: 'Tối thiểu 6 ký tự',
                        isPassword: true,
                        prefixIcon: const Icon(Icons.lock_outline),
                        validator: (val) {
                          if (val == null || val.length < 6) {
                            return 'Mật khẩu phải chứa ít nhất 6 ký tự';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _confirmPasswordController,
                        label: 'Xác nhận mật khẩu mới',
                        hintText: 'Nhập lại mật khẩu mới',
                        isPassword: true,
                        prefixIcon: const Icon(Icons.lock_outline),
                        validator: (val) {
                          if (val != _newPasswordController.text) {
                            return 'Mật khẩu xác nhận không khớp';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          return AppButton(
                            text: 'Hoàn Tất & Kích Hoạt',
                            onPressed: _onSubmit,
                            isLoading: state is AuthLoadingState,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
