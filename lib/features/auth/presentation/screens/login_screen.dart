import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../widgets/login_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktopOrWeb = size.width > 768;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailureState) {
          AppDialog.showErrorSnackBar(context, state.errorMessage);
        } else if (state is AuthenticatedState) {
          if (state.requiresPasswordChange) {
            context.go(RouteNames.firstLoginSetup);
          } else if (state.user.isSuperAdmin ||
              state.user.isBranchAdmin ||
              state.user.isAcademicStaff) {
            context.go(RouteNames.adminHome);
          } else if (state.user.isTeacher) {
            context.go(RouteNames.teacherHome);
          } else if (state.user.isParent) {
            context.go(RouteNames.parentHome);
          } else {
            context.go(RouteNames.studentHome);
          }
        }
      },
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktopOrWeb ? 460 : double.infinity,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo & Brand Header
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(76),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Đăng Nhập LMS',
                    style: AppTextStyles.h1(context),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hệ thống quản lý học tập & đào tạo trung tâm ngoại ngữ',
                    style: AppTextStyles.bodyMedium(context),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Card Form
                  const AppCard(
                    padding: EdgeInsets.all(28),
                    child: LoginForm(),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => context.go(RouteNames.publicHome),
                    icon: const Icon(Icons.explore_outlined),
                    label: const Text('Khám phá chương trình học'),
                  ),

                  const SizedBox(height: 28),
                  Center(
                    child: Text(
                      '© 2026 LMS Trung Tâm Ngoại Ngữ • All rights reserved.',
                      style: AppTextStyles.bodySmall(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
