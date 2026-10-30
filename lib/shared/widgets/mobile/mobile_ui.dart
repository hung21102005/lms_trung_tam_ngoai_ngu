import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Mobile-only presentation tokens; semantic colors remain shared with EduLMS.
abstract final class MobileTokens {
  static const double gutter = 16;
  static const double sectionGap = 20;
  static const double radius = 20;
  static const double touchTarget = 48;
  static const Duration motion = Duration(milliseconds: 180);
}

class MobileSectionCard extends StatelessWidget {
  const MobileSectionCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(MobileTokens.radius),
      side: const BorderSide(color: AppColors.borderLight),
    ),
    child: Padding(padding: padding ?? const EdgeInsets.all(16), child: child),
  );
}

class MobileStatusPill extends StatelessWidget {
  const MobileStatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withAlpha(24),
      borderRadius: BorderRadius.circular(100),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
    ),
  );
}
