import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Headings: when context is omitted, leave color null so DefaultTextStyle /
  // Theme.textTheme supplies the proper onSurface color in both light and dark mode.
  static TextStyle h1([BuildContext? context]) {
    return GoogleFonts.beVietnamPro(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: context == null ? null : AppColors.textPrimary(context),
      letterSpacing: -0.5,
    );
  }

  static TextStyle h2([BuildContext? context]) {
    return GoogleFonts.beVietnamPro(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: context == null ? null : AppColors.textPrimary(context),
      letterSpacing: -0.3,
    );
  }

  static TextStyle h3([BuildContext? context]) {
    return GoogleFonts.beVietnamPro(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: context == null ? null : AppColors.textPrimary(context),
    );
  }

  static TextStyle h4([BuildContext? context]) {
    return GoogleFonts.beVietnamPro(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: context == null ? null : AppColors.textPrimary(context),
    );
  }

  // Body Texts
  static TextStyle bodyLarge([BuildContext? context]) {
    return GoogleFonts.beVietnamPro(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: context == null ? null : AppColors.textPrimary(context),
    );
  }

  static TextStyle bodyMedium([BuildContext? context]) {
    return GoogleFonts.beVietnamPro(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: context == null ? null : AppColors.textSecondary(context),
    );
  }

  static TextStyle bodySmall([BuildContext? context]) {
    return GoogleFonts.beVietnamPro(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: context == null ? null : AppColors.textMuted(context),
    );
  }

  // Buttons, Labels & Captions
  static TextStyle button([BuildContext? context]) {
    return GoogleFonts.beVietnamPro(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      letterSpacing: 0.2,
    );
  }

  static TextStyle label([BuildContext? context]) {
    return GoogleFonts.beVietnamPro(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: context == null ? null : AppColors.textSecondary(context),
    );
  }

  static TextStyle caption([BuildContext? context]) {
    return GoogleFonts.beVietnamPro(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: context == null ? null : AppColors.textMuted(context),
    );
  }
}
