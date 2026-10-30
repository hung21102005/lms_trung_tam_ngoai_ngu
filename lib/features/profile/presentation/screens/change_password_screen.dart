import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/adaptive/adaptive_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/mobile/mobile_ui.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<ProfileBloc>().add(
        ChangePasswordSubmittedEvent(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
          confirmPassword: _confirmPasswordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đổi mật khẩu tài khoản')),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfilePasswordChangeSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context);
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is ProfilePasswordChanging;

          if (MediaQuery.sizeOf(context).width < AdaptiveBreakpoints.desktop) {
            return _buildMobileForm(isLoading);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bảo mật tài khoản',
                              style: AppTextStyles.h4(context),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Mật khẩu mới phải có tối thiểu 6 ký tự, bao gồm chữ hoa, chữ thường và chữ số.',
                              style: AppTextStyles.bodySmall(
                                context,
                              ).copyWith(color: AppColors.textSecondaryLight),
                            ),
                            const SizedBox(height: 20),
                            AppTextField(
                              controller: _currentPasswordController,
                              label: 'Mật khẩu hiện tại *',
                              hintText: 'Nhập mật khẩu hiện tại',
                              isPassword: true,
                              prefixIcon: const Icon(Icons.lock_outline),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Vui lòng nhập mật khẩu hiện tại';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _newPasswordController,
                              label: 'Mật khẩu mới *',
                              hintText: 'Nhập mật khẩu mới',
                              isPassword: true,
                              prefixIcon: const Icon(Icons.lock_reset),
                              validator: (val) {
                                if (val == null || val.length < 6) {
                                  return 'Mật khẩu mới phải từ 6 ký tự trở lên';
                                }
                                if (val == _currentPasswordController.text) {
                                  return 'Mật khẩu mới không được trùng mật khẩu cũ';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _confirmPasswordController,
                              label: 'Xác nhận mật khẩu mới *',
                              hintText: 'Nhập lại mật khẩu mới',
                              isPassword: true,
                              prefixIcon: const Icon(
                                Icons.check_circle_outline,
                              ),
                              validator: (val) {
                                if (val != _newPasswordController.text) {
                                  return 'Mật khẩu xác nhận không khớp';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      AppButton(
                        text: 'Cập nhật mật khẩu',
                        isLoading: isLoading,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileForm(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              key: const ValueKey('change-password-mobile'),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                const MobileSectionCard(
                  child: Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: AppColors.primary,
                        size: 32,
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bảo vệ tài khoản',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Đặt mật khẩu riêng và dễ ghi nhớ với bạn.',
                              style: TextStyle(
                                color: AppColors.neutral600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MobileTokens.sectionGap),
                MobileSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Mật khẩu hiện tại',
                        style: AppTextStyles.h4(context),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _currentPasswordController,
                        label: 'Mật khẩu hiện tại *',
                        hintText: 'Nhập mật khẩu hiện tại',
                        isPassword: true,
                        prefixIcon: const Icon(Icons.lock_outline),
                        validator: (val) => val == null || val.isEmpty
                            ? 'Vui lòng nhập mật khẩu hiện tại'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                MobileSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Mật khẩu mới', style: AppTextStyles.h4(context)),
                      const SizedBox(height: 6),
                      Text(
                        'Tối thiểu 6 ký tự, gồm chữ hoa, chữ thường và chữ số.',
                        style: AppTextStyles.bodySmall(context)
                            .copyWith(color: AppColors.textSecondaryLight),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _newPasswordController,
                        label: 'Mật khẩu mới *',
                        hintText: 'Nhập mật khẩu mới',
                        isPassword: true,
                        prefixIcon: const Icon(Icons.lock_reset),
                        validator: (val) {
                          if (val == null || val.length < 6) {
                            return 'Mật khẩu mới phải từ 6 ký tự trở lên';
                          }
                          if (val == _currentPasswordController.text) {
                            return 'Mật khẩu mới không được trùng mật khẩu cũ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _confirmPasswordController,
                        label: 'Xác nhận mật khẩu mới *',
                        hintText: 'Nhập lại mật khẩu mới',
                        isPassword: true,
                        prefixIcon: const Icon(Icons.check_circle_outline),
                        validator: (val) => val != _newPasswordController.text
                            ? 'Mật khẩu xác nhận không khớp'
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: SizedBox(
                width: double.infinity,
                height: MobileTokens.touchTarget,
                child: FilledButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Cập nhật mật khẩu'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
