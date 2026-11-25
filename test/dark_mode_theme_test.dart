import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lms_trung_tam_ngoai_ngu/core/theme/app_colors.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/theme/app_theme.dart';
import 'package:lms_trung_tam_ngoai_ngu/shared/widgets/app_button.dart';
import 'package:lms_trung_tam_ngoai_ngu/shared/widgets/app_card.dart';
import 'package:lms_trung_tam_ngoai_ngu/shared/widgets/app_text_field.dart';
import 'package:lms_trung_tam_ngoai_ngu/shared/widgets/empty_state_widget.dart';
import 'package:lms_trung_tam_ngoai_ngu/shared/widgets/mobile/mobile_ui.dart';

double _contrastRatio(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  testWidgets('AppColors dark mode tokens maintain WCAG AA contrast on dark surfaces', (
    tester,
  ) async {
    late BuildContext darkCtx;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (context) {
            darkCtx = context;
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    );

    expect(AppColors.isDark(darkCtx), isTrue);
    final bg = AppColors.background(darkCtx);
    final surface = AppColors.surface(darkCtx);

    expect(bg.computeLuminance(), lessThan(0.05));
    expect(surface.computeLuminance(), lessThan(0.08));

    // Text contrast on dark surface >= 4.5:1 (WCAG AA)
    expect(_contrastRatio(AppColors.textPrimary(darkCtx), surface), greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(AppColors.textBody(darkCtx), surface), greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(AppColors.textSecondary(darkCtx), surface), greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(AppColors.textMuted(darkCtx), surface), greaterThanOrEqualTo(4.5));

    // Brand and semantic foreground contrast on dark surface >= 4.5:1
    expect(_contrastRatio(AppColors.brand(darkCtx), surface), greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(AppColors.primaryOf(darkCtx), surface), greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(AppColors.successFg(darkCtx), surface), greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(AppColors.warningFg(darkCtx), surface), greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(AppColors.errorFg(darkCtx), surface), greaterThanOrEqualTo(4.5));

    // adaptAccent lightens dark royal blue for dark mode readability
    final adaptedBlue = AppColors.adaptAccent(darkCtx, const Color(0xFF003FB1));
    expect(_contrastRatio(adaptedBlue, surface), greaterThanOrEqualTo(4.5));
  });

  testWidgets('Shared widgets render cleanly in Dark Mode with dark surfaces', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: Scaffold(
          appBar: AppBar(title: const Text('Dark Mode Check')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              MobileSectionCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Lớp IELTS 6.5'),
                    MobileStatusPill(
                      label: 'Đang tuyển',
                      color: Color(0xFF003FB1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const AppTextField(
                label: 'Tìm kiếm',
                hintText: 'Nhập từ khóa',
              ),
              const SizedBox(height: 12),
              AppButton(text: 'Tạo lớp học', onPressed: () {}),
              const SizedBox(height: 8),
              AppButton(
                text: 'Hủy',
                variant: AppButtonVariant.outline,
                onPressed: () {},
              ),
              const SizedBox(height: 12),
              const AppCard(child: Text('Nội dung thẻ')),
              const SizedBox(height: 12),
              const EmptyStateWidget(
                title: 'Trống',
                description: 'Không có dữ liệu',
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Lớp IELTS 6.5'), findsOneWidget);
    expect(find.text('Đang tuyển'), findsOneWidget);
    expect(find.text('Tạo lớp học'), findsOneWidget);
  });
}
