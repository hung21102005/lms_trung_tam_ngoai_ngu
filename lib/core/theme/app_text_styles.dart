import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Headings
  static TextStyle h1([BuildContext? context]) {
    final isDark = context != null && Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.beVietnamPro(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      letterSpacing: -0.5,
    );
  }

  static TextStyle h2([BuildContext? context]) {
    final isDark = context != null && Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.beVietnamPro(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      letterSpacing: -0.3,
    );
  }

  static TextStyle h3([BuildContext? context]) {
    final isDark = context != null && Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.beVietnamPro(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    );
  }

  static TextStyle h4([BuildContext? context]) {
    final isDark = context != null && Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.beVietnamPro(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    );
  }

  // Body Texts
  static TextStyle bodyLarge([BuildContext? context]) {
    final isDark = context != null && Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.beVietnamPro(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    );
  }

  static TextStyle bodyMedium([BuildContext? context]) {
    final isDark = context != null && Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.beVietnamPro(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
    );
  }

  static TextStyle bodySmall([BuildContext? context]) {
    final isDark = context != null && Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.beVietnamPro(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
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
    final isDark = context != null && Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.beVietnamPro(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
    );
  }

  static TextStyle caption([BuildContext? context]) {
    final isDark = context != null && Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.beVietnamPro(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
    );
  }
}
