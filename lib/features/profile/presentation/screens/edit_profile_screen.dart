import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/adaptive/adaptive_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/mobile/mobile_ui.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  String? _gender;

  @override
  void initState() {
    super.initState();
    final state = context.read<ProfileBloc>().state;
    final user = state is ProfileLoaded ? state.user : null;

    _nameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _gender = user?.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<ProfileBloc>().add(
        UpdateProfileEvent(
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          gender: _gender,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa thông tin cá nhân')),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded && state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
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
          final isUpdating = state is ProfileUpdating;

          if (MediaQuery.sizeOf(context).width < AdaptiveBreakpoints.desktop) {
            return _buildMobileForm(isUpdating);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.primaryLight.withAlpha(
                                50,
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 60,
                                color: AppColors.primary,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Tính năng chọn ảnh từ thư viện',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            AppTextField(
                              controller: _nameController,
                              label: 'Họ và tên *',
                              hintText: 'Nhập họ và tên',
                              prefixIcon: const Icon(Icons.person_outline),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Họ tên không được để trống';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _phoneController,
                              label: 'Số điện thoại',
                              hintText: 'Nhập số điện thoại',
                              keyboardType: TextInputType.phone,
                              prefixIcon: const Icon(Icons.phone_outlined),
                            ),
                            const SizedBox(height: 16),
                            AppDropdown<String>(
                              label: 'Giới tính',
                              hintText: 'Chọn giới tính',
                              value: _gender,
                              items: const [
                                AppDropdownItem(value: 'MALE', label: 'Nam'),
                                AppDropdownItem(value: 'FEMALE', label: 'Nữ'),
                                AppDropdownItem(value: 'OTHER', label: 'Khác'),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _gender = val;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _addressController,
                              label: 'Địa chỉ thường trú',
                              hintText: 'Nhập địa chỉ nhà',
                              prefixIcon: const Icon(
                                Icons.location_on_outlined,
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      AppButton(
                        text: 'Lưu thay đổi',
                        isLoading: isUpdating,
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

  Widget _buildMobileForm(bool isUpdating) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              key: const ValueKey('edit-profile-mobile'),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                const MobileSectionCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 27,
                        backgroundColor: AppColors.primaryLight,
                        child: Icon(
                          Icons.person_outline,
                          color: AppColors.primary,
                          size: 30,
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thông tin cá nhân',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Cập nhật thông tin liên hệ của bạn',
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
                      const Text(
                        'Thông tin cơ bản',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _nameController,
                        label: 'Họ và tên *',
                        hintText: 'Nhập họ và tên',
                        prefixIcon: const Icon(Icons.person_outline),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Họ tên không được để trống'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      AppDropdown<String>(
                        label: 'Giới tính',
                        hintText: 'Chọn giới tính',
                        value: _gender,
                        items: const [
                          AppDropdownItem(value: 'MALE', label: 'Nam'),
                          AppDropdownItem(value: 'FEMALE', label: 'Nữ'),
                          AppDropdownItem(value: 'OTHER', label: 'Khác'),
                        ],
                        onChanged: (value) => setState(() => _gender = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                MobileSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Liên hệ',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _phoneController,
                        label: 'Số điện thoại',
                        hintText: 'Nhập số điện thoại',
                        keyboardType: TextInputType.phone,
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _addressController,
                        label: 'Địa chỉ thường trú',
                        hintText: 'Nhập địa chỉ nhà',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        maxLines: 2,
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
                  onPressed: isUpdating ? null : _submit,
                  child: isUpdating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Lưu thay đổi'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
