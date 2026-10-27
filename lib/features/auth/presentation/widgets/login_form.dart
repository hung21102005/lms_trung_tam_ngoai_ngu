import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            LoginSubmittedEvent(
              identifier: _identifierController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoadingState;

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _identifierController,
                label: 'Tài khoản đăng nhập',
                hintText: 'Email, Số điện thoại hoặc Mã định danh',
                prefixIcon: const Icon(Icons.person_outline, color: AppColors.primaryLight),
                textInputAction: TextInputAction.next,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập email, số điện thoại hoặc mã người dùng';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              AppTextField(
                controller: _passwordController,
                label: 'Mật khẩu',
                hintText: 'Nhập mật khẩu của bạn',
                isPassword: true,
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primaryLight),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _onLogin(),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Vui lòng nhập mật khẩu';
                  }
                  if (val.length < 6) {
                    return 'Mật khẩu phải chứa ít nhất 6 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(RouteNames.forgotPassword),
                  child: Text(
                    'Quên mật khẩu?',
                    style: AppTextStyles.label(context).copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                text: 'Đăng nhập',
                onPressed: _onLogin,
                isLoading: isLoading,
                height: 50,
              ),
            ],
          ),
        );
      },
    );
  }
}
