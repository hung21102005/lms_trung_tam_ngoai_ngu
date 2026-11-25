import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Branding Colors
  static const Color primary = Color(0xFF1E40AF); // Classic Education Royal Blue
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1E3A8A);
  static const Color primaryGradientStart = Color(0xFF1E40AF);
  static const Color primaryGradientEnd = Color(0xFF2563EB);

  // Secondary & Accents
  static const Color secondary = Color(0xFF0D9488); // Teal
  static const Color accent = Color(0xFFF59E0B); // Amber Accent

  // Status & Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Background & Surface (Light Mode)
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFF8FAFC);
  static const Color surfaceSubtleLight = Color(0xFFF1F5F9);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderStrongLight = Color(0xFFCBD5E1);
  static const Color dividerLight = Color(0xFFEDF2F7);

  // Text Colors (Light Mode)
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textBodyLight = Color(0xFF334155);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // Background & Surface (Dark Mode)
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceElevatedDark = Color(0xFF263348);
  static const Color surfaceSubtleDark = Color(0xFF283548);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color borderDark = Color(0xFF334155);
  static const Color borderStrongDark = Color(0xFF475569);
  static const Color dividerDark = Color(0xFF334155);

  // Text Colors (Dark Mode - WCAG AA+ on #0F172A and #1E293B)
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textBodyDark = Color(0xFFE2E8F0);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  static const Color textMutedDark = Color(0xFF94A3B8);

  // Neutral Colors
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral900 = Color(0xFF0F172A);

  // Theme-aware semantic helpers
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) =>
      isDark(context) ? backgroundDark : backgroundLight;

  static Color surface(BuildContext context) =>
      isDark(context) ? surfaceDark : surfaceLight;

  static Color surfaceElevated(BuildContext context) =>
      isDark(context) ? surfaceElevatedDark : surfaceElevatedLight;

  static Color surfaceSubtle(BuildContext context) =>
      isDark(context) ? surfaceSubtleDark : surfaceSubtleLight;

  static Color card(BuildContext context) =>
      isDark(context) ? cardDark : cardLight;

  static Color border(BuildContext context) =>
      isDark(context) ? borderDark : borderLight;

  static Color borderStrong(BuildContext context) =>
      isDark(context) ? borderStrongDark : borderStrongLight;

  static Color divider(BuildContext context) =>
      isDark(context) ? dividerDark : dividerLight;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? textPrimaryDark : textPrimaryLight;

  static Color textBody(BuildContext context) =>
      isDark(context) ? textBodyDark : textBodyLight;

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? textSecondaryDark : textSecondaryLight;

  static Color textMuted(BuildContext context) =>
      isDark(context) ? textMutedDark : textMutedLight;

  // Brand & status foreground colors with guaranteed contrast on surface
  static Color brand(BuildContext context) =>
      isDark(context) ? const Color(0xFF60A5FA) : const Color(0xFF003FB1);

  static Color primaryOf(BuildContext context) =>
      isDark(context) ? const Color(0xFF60A5FA) : primary;

  static Color successFg(BuildContext context) =>
      isDark(context) ? const Color(0xFF34D399) : const Color(0xFF047857);

  static Color warningFg(BuildContext context) =>
      isDark(context) ? const Color(0xFFFBBF24) : const Color(0xFFD97706);

  static Color errorFg(BuildContext context) =>
      isDark(context) ? const Color(0xFFF87171) : const Color(0xFFDC2626);

  static Color infoFg(BuildContext context) =>
      isDark(context) ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);

  static Color tealFg(BuildContext context) =>
      isDark(context) ? const Color(0xFF2DD4BF) : secondary;

  static Color purpleFg(BuildContext context) =>
      isDark(context) ? const Color(0xFFC084FC) : const Color(0xFF7C3AED);

  // Tinted backgrounds for badges, pills, banners, icon tiles
  static Color brandBg(BuildContext context) =>
      isDark(context) ? const Color(0x2E3B82F6) : const Color(0xFFEFF6FF);

  static Color infoBg(BuildContext context) =>
      isDark(context) ? const Color(0x2E3B82F6) : const Color(0xFFEEF2FF);

  static Color successBg(BuildContext context) =>
      isDark(context) ? const Color(0x2E10B981) : const Color(0xFFECFDF5);

  static Color warningBg(BuildContext context) =>
      isDark(context) ? const Color(0x2EF59E0B) : const Color(0xFFFEF3C7);

  static Color errorBg(BuildContext context) =>
      isDark(context) ? const Color(0x2EEF4444) : const Color(0xFFFEF2F2);

  static Color purpleBg(BuildContext context) =>
      isDark(context) ? const Color(0x2EA855F7) : const Color(0xFFF5F3FF);

  static Color shadow(BuildContext context) =>
      isDark(context) ? Colors.black.withAlpha(48) : const Color(0x0A000000);

  /// Lightens dark accent/status colors when rendered on dark surfaces so
  /// pills, badges, and icons keep readable contrast in dark mode.
  static Color adaptAccent(BuildContext context, Color color) {
    if (!isDark(context)) return color;
    final hsl = HSLColor.fromColor(color);
    if (hsl.lightness >= 0.62) return color;
    return hsl
        .withLightness((hsl.lightness + 0.30).clamp(0.62, 0.78))
        .withSaturation((hsl.saturation * 0.92).clamp(0.0, 1.0))
        .toColor();
  }
}
